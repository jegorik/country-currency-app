"""
Databricks client for connecting to Databricks and performing operations.
"""
import logging
import threading
import socket
from queue import Queue, Empty
from databricks.sdk import WorkspaceClient
from databricks.sql import connect
from config.app_config import AppConfig

# Configure logger
logger = logging.getLogger(__name__)

# Define a timeout exception for cross-platform compatibility
class TimeoutException(Exception):
    """Exception raised when an operation times out."""
    pass

class ConnectionPool:
    """A simple connection pool for Databricks SQL connections."""

    def __init__(self, config, max_connections=5, connection_timeout=30):
        """Initialize the connection pool.

        Args:
            config: The AppConfig object with connection details
            max_connections: Maximum number of connections to keep in the pool
            connection_timeout: Timeout for connection operations in seconds
        """
        self.config = config
        self.max_connections = max_connections
        self.connection_timeout = connection_timeout
        self.pool = Queue(maxsize=max_connections)
        self.active_connections = 0
        self.lock = threading.Lock()
        self.server_hostname = config.host.replace("https://", "")

        # Determine the HTTP path based on warehouse_id
        if hasattr(config, 'warehouse_id') and config.warehouse_id:
            self.http_path = f"sql/1.0/warehouses/{config.warehouse_id}"
        else:
            self.http_path = "sql/1.0/warehouses/auto"

        logger.info(f"Initialized connection pool with max_connections={max_connections}")

    def get_connection(self):
        """Get a connection from the pool or create a new one if needed."""
        # Try to get a connection from the pool first
        try:
            connection = self.pool.get(block=False)
            logger.debug("Reusing existing connection from pool")
            return connection
        except Empty:
            # No connections available in the pool, create a new one if under the limit
            with self.lock:
                if self.active_connections < self.max_connections:
                    self.active_connections += 1
                    logger.debug(f"Creating new connection (active: {self.active_connections})")
                    try:
                        connection = connect(
                            server_hostname=self.server_hostname,
                            http_path=self.http_path,
                            access_token=self.config.token,
                            connect_timeout=self.connection_timeout
                        )
                        return connection
                    except Exception as e:
                        self.active_connections -= 1
                        logger.error(f"Error creating connection: {str(e)}")
                        raise
                else:
                    # Wait for a connection to become available
                    logger.warning(f"Connection pool exhausted, waiting for a connection")
                    try:
                        return self.pool.get(block=True, timeout=self.connection_timeout)
                    except Empty:
                        logger.error("Timeout waiting for a connection")
                        raise TimeoutException("Timeout waiting for a database connection")

    def release_connection(self, connection):
        """Return a connection to the pool."""
        try:
            # Check if the connection is still valid
            cursor = connection.cursor()
            cursor.execute("SELECT 1")
            cursor.close()

            # Return to the pool
            self.pool.put(connection, block=False)
            logger.debug("Connection returned to pool")
        except Exception as e:
            # Connection is no longer valid, close it and decrement counter
            logger.warning(f"Closing invalid connection: {str(e)}")
            try:
                connection.close()
            except:
                pass
            with self.lock:
                self.active_connections -= 1

    def close_all(self):
        """Close all connections in the pool."""
        logger.info("Closing all connections in the pool")
        # Close connections in the pool
        while not self.pool.empty():
            try:
                connection = self.pool.get(block=False)
                connection.close()
                with self.lock:
                    self.active_connections -= 1
            except Empty:
                break
            except Exception as e:
                logger.error(f"Error closing connection: {str(e)}")

        logger.info(f"Connection pool closed, active connections: {self.active_connections}")

class DatabricksClient:
    """Client for interacting with Databricks APIs."""

    def __init__(self, config: AppConfig, pool_size=5):
        """Initialize the Databricks client.

        Args:
            config: The AppConfig object with connection details
            pool_size: Size of the connection pool
        """
        self.config = config
        self.workspace_client = None
        self.connection_pool = None

        # Initialize the workspace client
        try:
            self.workspace_client = WorkspaceClient(
                host=config.host,
                token=config.token
            )
            logger.info("Workspace client initialized")
        except Exception as e:
            logger.error(f"Error initializing workspace client: {str(e)}")

        # Initialize the connection pool
        self.connection_pool = ConnectionPool(config, max_connections=pool_size)
        logger.info(f"Connection pool initialized with size {pool_size}")

    def test_connection(self) -> bool:
        """Test the connection to Databricks."""
        try:
            logger.info(f"Testing workspace API connection to {self.config.host}")

            # Test workspace API connection if not already initialized
            if not self.workspace_client:
                self.workspace_client = WorkspaceClient(
                    host=self.config.host,
                    token=self.config.token
                )

            # Get current user to test connection
            logger.info("Testing API authentication...")
            user = self.workspace_client.current_user.me()
            username = user.user_name if hasattr(user, 'user_name') else 'Unknown'
            logger.info(f"API authentication successful. Connected as: {username}")

            # Test SQL connection using the connection pool
            logger.info("Testing SQL connection...")

            try:
                # Get a connection from the pool and execute a simple query
                connection = self.connection_pool.get_connection()
                try:
                    with connection.cursor() as cursor:
                        logger.info("Executing test query...")
                        cursor.execute("SELECT 1")
                        result = cursor.fetchall()
                        logger.info(f"SQL connection test successful. Result: {result}")
                finally:
                    # Return the connection to the pool
                    self.connection_pool.release_connection(connection)

                logger.info("Connection test successful!")
                return True

            except Exception as e:
                logger.error(f"SQL connection test failed: {str(e)}")
                raise

        except TimeoutException as e:
            logger.error(f"Connection timeout: {str(e)}")
            return False
        except Exception as e:
            logger.error(f"Connection error: {type(e).__name__}: {str(e)}")
            logger.exception("Connection test failed with exception:")
            return False

    def execute_query(self, query: str, params: tuple = None) -> list:
        """Execute a SQL query and return the results using a connection from the pool."""
        connection = None
        try:
            # Get a connection from the pool
            logger.debug(f"Executing query: {query[:100]}{'...' if len(query) > 100 else ''}")
            if params:
                logger.debug(f"Query parameters: {params}")

            connection = self.connection_pool.get_connection()

            with connection.cursor() as cursor:
                if params:
                    cursor.execute(query, params)
                else:
                    cursor.execute(query)

                # Get column names
                columns = [desc[0] for desc in cursor.description] if cursor.description else []

                # Fetch results
                result = cursor.fetchall()

                # Convert to list of dictionaries
                result_dicts = []
                for row in result:
                    row_dict = {}
                    for i, col_name in enumerate(columns):
                        row_dict[col_name] = row[i]
                    result_dicts.append(row_dict)

                logger.debug(f"Query returned {len(result_dicts)} results")
                return result_dicts

        except Exception as e:
            logger.error(f"Query execution error: {str(e)}")
            raise
        finally:
            # Return the connection to the pool if it was obtained
            if connection:
                self.connection_pool.release_connection(connection)

    def get_job_status(self, job_id: str) -> dict:
        """Get the status of a Databricks job."""
        try:
            logger.info(f"Getting status for job ID: {job_id}")

            if not self.workspace_client:
                logger.error("Workspace client not initialized")
                return None

            runs = self.workspace_client.jobs.list_runs(
                job_id=job_id,
                limit=1
            )

            if runs:
                logger.info(f"Found run for job ID {job_id}")
                return runs[0]
            else:
                logger.warning(f"No runs found for job ID {job_id}")
                return None

        except Exception as e:
            logger.error(f"Error getting job status: {str(e)}")
            logger.exception("Exception details:")
            raise

    def close(self):
        """Close all connections and clean up resources."""
        logger.info("Closing Databricks client and connection pool")
        if self.connection_pool:
            try:
                self.connection_pool.close_all()
                logger.info("Connection pool closed successfully")
            except Exception as e:
                logger.error(f"Error closing connection pool: {str(e)}")
                logger.exception("Exception details:")
