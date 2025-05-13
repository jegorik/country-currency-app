"""
App configuration module for Streamlit application.
"""

class AppConfig:
    """Configuration for the Streamlit app."""
    
    def __init__(self, host: str, token: str, catalog: str, schema: str, table: str, job_id: str = None, warehouse_id: str = None):
        """Initialize the application configuration."""
        self.host = host
        self.token = token
        self.catalog = catalog
        self.schema = schema
        self.table = table
        self.job_id = job_id
        self.warehouse_id = warehouse_id
        
    @property
    def full_table_name(self) -> str:
        """Return the fully qualified table name."""
        return f"{self.catalog}.{self.schema}.{self.table}"
