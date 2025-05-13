"""
Data operations module for performing CRUD operations on country-currency data.
"""
from utils.databricks_client import DatabricksClient

class DataOperations:
    """Class for handling CRUD operations on the country-currency data."""
    
    def __init__(self, client: DatabricksClient):
        """Initialize the data operations with a Databricks client."""
        self.client = client
        self.table_name = client.config.full_table_name
        
    def get_all_records(self, filter_query: str = None) -> list:
        """Get all records from the country-currency table."""
        query = f"SELECT * FROM {self.table_name}"
        if filter_query:
            query += f" WHERE country LIKE '%{filter_query}%' OR country_code LIKE '%{filter_query}%' " \
                     f"OR currency_name LIKE '%{filter_query}%' OR currency_code LIKE '%{filter_query}%'"
        query += " ORDER BY country_code"
        return self.client.execute_query(query)
    
    def get_record_by_id(self, country_code: str) -> dict:
        """Get a record by country code."""
        query = f"SELECT * FROM {self.table_name} WHERE country_code = ?"
        result = self.client.execute_query(query, (country_code,))
        if result:
            return result[0]
        return None
    
    def create_record(self, record: dict) -> bool:
        """Create a new country-currency record."""
        query = f"""
        INSERT INTO {self.table_name} (
            country_code, country_number, country, currency_name, currency_code, currency_number
        ) VALUES (?, ?, ?, ?, ?, ?)
        """
        
        params = (
            record['country_code'],
            record['country_number'],
            record['country'],
            record['currency_name'],
            record['currency_code'],
            record['currency_number']
        )
        
        try:
            self.client.execute_query(query, params)
            return True
        except Exception as e:
            print(f"Error creating record: {str(e)}")
            return False
    
    def update_record(self, record: dict) -> bool:
        """Update an existing country-currency record."""
        query = f"""
        UPDATE {self.table_name}
        SET country_number = ?,
            country = ?,
            currency_name = ?,
            currency_code = ?,
            currency_number = ?
        WHERE country_code = ?
        """
        
        params = (
            record['country_number'],
            record['country'],
            record['currency_name'],
            record['currency_code'],
            record['currency_number'],
            record['country_code']
        )
        
        try:
            self.client.execute_query(query, params)
            return True
        except Exception as e:
            print(f"Error updating record: {str(e)}")
            return False
    
    def delete_record(self, country_code: str) -> bool:
        """Delete a country-currency record by country code."""
        query = f"DELETE FROM {self.table_name} WHERE country_code = ?"
        
        try:
            self.client.execute_query(query, (country_code,))
            return True
        except Exception as e:
            print(f"Error deleting record: {str(e)}")
            return False
            
    def count_records(self) -> int:
        """Count the total number of records in the country-currency table."""
        query = f"SELECT COUNT(*) as count FROM {self.table_name}"
        result = self.client.execute_query(query)
        if result:
            return result[0]['count']
        return 0
