"""
Databricks client for connecting to Databricks and performing operations.
"""
from databricks.sdk import WorkspaceClient
from databricks.sql import connect
from config.app_config import AppConfig

# Define a timeout exception for cross-platform compatibility
class TimeoutException(Exception):
    """Exception raised when an operation times out."""
    pass

class DatabricksClient:
    """Client for interacting with Databricks APIs."""
    
    def __init__(self, config: AppConfig):
        """Initialize the Databricks client."""
        self.config = config
        self.workspace_client = None
        self.sql_client = None
        
    def test_connection(self) -> bool:
        """Test the connection to Databricks."""
        try:
            print(f"Testing workspace API connection to {self.config.host}...")
            # Test workspace API connection
            self.workspace_client = WorkspaceClient(
                host=self.config.host,
                token=self.config.token
            )
            
            # Get current user to test connection
            print("Testing API authentication...")
            user = self.workspace_client.current_user.me()
            print(f"API authentication successful. Connected as: {user.user_name if hasattr(user, 'user_name') else 'Unknown'}")
            
            # Test SQL connection with timeout using threading approach (Windows compatible)
            import threading
            import socket
            
            # Set a timeout for socket operations as a backup
            default_timeout = socket.getdefaulttimeout()
            socket.setdefaulttimeout(30)  # Increased to 30 seconds timeout
            sql_success = False            
            sql_error = None
            
            def _test_sql_connection():
                nonlocal sql_success, sql_error
                try:
                    server_hostname = self.config.host.replace("https://", "")
                    # Try to use warehouse_id if available
                    if hasattr(self.config, 'warehouse_id') and self.config.warehouse_id:
                        print(f"Using warehouse ID: {self.config.warehouse_id}")
                        http_path = f"sql/1.0/warehouses/{self.config.warehouse_id}"
                    else:
                        print("No warehouse ID provided, using default path")
                        http_path = "sql/1.0/warehouses/auto"
                    
                    print(f"Testing SQL connection to {server_hostname} with http_path={http_path}...")
                    print("Connection timeout set to 30 seconds...")
                    # Use a more specific SQL endpoint path for Databricks
                    with connect(
                        server_hostname=server_hostname,
                        http_path=http_path,
                        access_token=self.config.token,
                        connect_timeout=30
                    ) as connection:
                        with connection.cursor() as cursor:
                            print("Executing test query...")
                            cursor.execute("SELECT 1")
                            result = cursor.fetchall()
                            print(f"Query result: {result}")
                            sql_success = True
                except Exception as e:
                    sql_success = False
                    sql_error = str(e)
                    print(f"SQL connection error: {sql_error}")
            
            # Use threading for a more robust timeout solution
            sql_success = False
            sql_thread = threading.Thread(target=_test_sql_connection)
            sql_thread.daemon = True
            sql_thread.start()
            sql_thread.join(timeout=30)  # Increased to 30 seconds
            
            # Restore default socket timeout
            socket.setdefaulttimeout(default_timeout)
            
            if not sql_success:
                if sql_thread.is_alive():
                    print("SQL connection test timed out")
                    raise TimeoutError("SQL connection test timed out after 30 seconds")
                else:
                    print("SQL connection test failed")                    
                    if sql_error:
                        raise ConnectionError(f"SQL connection test failed: {sql_error}")
                    else:
                        raise ConnectionError("SQL connection test failed")
            
            print("Connection test successful!")
            return True
        except Exception as e:
            print(f"Connection error: {type(e).__name__}: {str(e)}")
            import traceback
            traceback.print_exc()            
            return False
    
    def execute_query(self, query: str, params: tuple = None) -> list:
        """Execute a SQL query and return the results."""
        try:
            server_hostname = self.config.host.replace("https://", "")
            # Try to use warehouse_id if available
            if hasattr(self.config, 'warehouse_id') and self.config.warehouse_id:
                http_path = f"sql/1.0/warehouses/{self.config.warehouse_id}"
            else:
                http_path = "sql/1.0/warehouses/auto"
                
            with connect(
                server_hostname=server_hostname,
                http_path=http_path,
                access_token=self.config.token,
                connect_timeout=30
            ) as connection:
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
                    
                    return result_dicts
        except Exception as e:
            print(f"Query execution error: {str(e)}")
            raise
    
    def get_job_status(self, job_id: str) -> dict:
        """Get the status of a Databricks job."""
        try:
            runs = self.workspace_client.jobs.list_runs(
                job_id=job_id,
                limit=1
            )
            
            if runs:
                return runs[0]
            return None
        except Exception as e:
            print(f"Error getting job status: {str(e)}")
            raise
