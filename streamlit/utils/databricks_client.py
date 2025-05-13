"""
Databricks client for connecting to Databricks and performing operations.
"""
from databricks.sdk import WorkspaceClient
from databricks.sql import connect
from config.app_config import AppConfig

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
            # Test workspace API connection
            self.workspace_client = WorkspaceClient(
                host=self.config.host,
                token=self.config.token
            )
            
            # Get current user to test connection
            user = self.workspace_client.current_user.me()
            
            # Test SQL connection
            with connect(
                server_hostname=self.config.host.replace("https://", ""),
                http_path="sql/protocolv1/o/0/0",
                access_token=self.config.token
            ) as connection:
                with connection.cursor() as cursor:
                    cursor.execute(f"SELECT 1")
                    result = cursor.fetchall()
                    
            return True
        except Exception as e:
            print(f"Connection error: {str(e)}")
            return False
    
    def execute_query(self, query: str, params: tuple = None) -> list:
        """Execute a SQL query and return the results."""
        try:
            with connect(
                server_hostname=self.config.host.replace("https://", ""),
                http_path="sql/protocolv1/o/0/0",
                access_token=self.config.token
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
