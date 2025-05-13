"""
App configuration module for Streamlit application.
"""

class AppConfig:
    """Configuration for the Streamlit app."""
    
    def __init__(self, host: str = "", token: str = "", catalog: str = "main", schema: str = "default", 
                table: str = "country_currency", job_id: str = None, warehouse_id: str = None):
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
        """Return the fully qualified table name with proper quoting for identifiers with special characters."""
        # Quote catalog name if it contains hyphens or other special characters
        catalog = f"`{self.catalog}`" if "-" in self.catalog else self.catalog
        # Quote schema name if it contains hyphens or other special characters
        schema = f"`{self.schema}`" if "-" in self.schema else self.schema
        # Quote table name if it contains hyphens or other special characters
        table = f"`{self.table}`" if "-" in self.table else self.table
        
        return f"{catalog}.{schema}.{table}"
