"""
Enhanced data operations module for performing CRUD operations on country-currency data.
This module extends the original data_operations.py with additional functionality
needed by the new UI.
"""
from utils.databricks_client import DatabricksClient
from models.country_currency import CountryCurrency

class DataOperations:
    """Class for handling CRUD operations on the country-currency data."""
    
    def __init__(self, client: DatabricksClient):
        """Initialize the data operations with a Databricks client."""
        self.client = client
        self.table_name = client.config.full_table_name
    
    def get_all_records(self, filter_query: str = None, sort_by: str = None, 
                       sort_ascending: bool = True, limit: int = None, offset: int = None) -> list:
        """
        Get records from the country-currency table with advanced filtering and pagination.
        
        Args:
            filter_query: Optional filter query to apply
            sort_by: Optional column to sort by
            sort_ascending: Sort direction (True for ascending, False for descending)
            limit: Maximum number of records to return
            offset: Number of records to skip
            
        Returns:
            list: List of records as dictionaries
        """
        query = f"SELECT * FROM {self.table_name}"
        
        # Add filtering
        if filter_query:
            query += f" WHERE country LIKE '%{filter_query}%' OR country_code LIKE '%{filter_query}%' " \
                    f"OR currency_name LIKE '%{filter_query}%' OR currency_code LIKE '%{filter_query}%'"
        
        # Add sorting
        if sort_by:
            query += f" ORDER BY {sort_by} {'ASC' if sort_ascending else 'DESC'}"
        else:
            query += " ORDER BY country_code"
            
        # Add pagination
        if limit is not None:
            query += f" LIMIT {limit}"
            if offset is not None:
                query += f" OFFSET {offset}"
        
        return self.client.execute_query(query)
    
    def get_record_by_id(self, country_code: str) -> dict:
        """Get a record by country code."""
        query = f"SELECT * FROM {self.table_name} WHERE country_code = ?"
        result = self.client.execute_query(query, (country_code,))
        if result:
            return result[0]
        return None
    
    def add_record(self, record):
        """
        Add a new country-currency record.
        
        This method accepts a CountryCurrency object and converts it to a dictionary
        before calling the create_record method.
        
        Args:
            record: CountryCurrency object to add
            
        Returns:
            bool: True if the record was added successfully, False otherwise
        """
        # Convert the CountryCurrency object to a dictionary
        record_dict = {
            'country_code': record.country_code,
            'country_number': record.country_number,
            'country': record.country,
            'currency_name': record.currency_name,
            'currency_code': record.currency_code,
            'currency_number': record.currency_number
        }
        return self.create_record(record_dict)
    
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
    
    def update_record(self, record) -> bool:
        """
        Update an existing country-currency record.
        
        This method accepts either a CountryCurrency object or a dictionary.
        
        Args:
            record: CountryCurrency object or dictionary with record data
            
        Returns:
            bool: True if the record was updated successfully, False otherwise
        """
        # Convert the record to a dictionary if it's a CountryCurrency object
        if isinstance(record, CountryCurrency):
            record_dict = {
                'country_code': record.country_code,
                'country_number': record.country_number,
                'country': record.country,
                'currency_name': record.currency_name,
                'currency_code': record.currency_code,
                'currency_number': record.currency_number
            }
        else:
            record_dict = record
            
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
            record_dict['country_number'],
            record_dict['country'],
            record_dict['currency_name'],
            record_dict['currency_code'],
            record_dict['currency_number'],
            record_dict['country_code']
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
    
    def count_records(self, filter_query: str = None) -> int:
        """
        Count the total number of records in the country-currency table.
        
        Args:
            filter_query: Optional filter query to apply
            
        Returns:
            int: Total number of records
        """
        query = f"SELECT COUNT(*) as count FROM {self.table_name}"
        
        # Add filtering if provided
        if filter_query:
            query += f" WHERE country LIKE '%{filter_query}%' OR country_code LIKE '%{filter_query}%' " \
                    f"OR currency_name LIKE '%{filter_query}%' OR currency_code LIKE '%{filter_query}%'"
        
        result = self.client.execute_query(query)
        if result:
            return result[0]['count']
        return 0
    
    def get_table_schema(self) -> list:
        """
        Get the schema of the country-currency table.
        
        Returns:
            list: List of dictionaries with column information
        """
        query = f"DESCRIBE TABLE {self.table_name}"
        
        try:
            result = self.client.execute_query(query)
            return result
        except Exception as e:
            print(f"Error getting table schema: {str(e)}")
            return None
    
    def get_unique_values(self, column_name: str) -> list:
        """
        Get unique values for a specific column.
        
        Args:
            column_name: Name of the column to get unique values for
            
        Returns:
            list: List of unique values
        """
        query = f"SELECT DISTINCT {column_name} FROM {self.table_name} ORDER BY {column_name}"
        
        try:
            result = self.client.execute_query(query)
            return [row[column_name] for row in result]
        except Exception as e:
            print(f"Error getting unique values: {str(e)}")
            return []
    
    def execute_custom_query(self, query: str, params: tuple = None) -> list:
        """
        Execute a custom SQL query.
        
        Args:
            query: SQL query to execute
            params: Optional query parameters
            
        Returns:
            list: Query results
        """
        try:
            result = self.client.execute_query(query, params)
            return result
        except Exception as e:
            print(f"Error executing custom query: {str(e)}")
            return []
    
    def batch_upload_records(self, records: list) -> tuple:
        """
        Upload a batch of records.
        
        Args:
            records: List of CountryCurrency objects or dictionaries
            
        Returns:
            tuple: (success_count, error_count, errors)
        """
        success_count = 0
        error_count = 0
        errors = []
        
        for i, record in enumerate(records):
            try:
                # Convert to dictionary if it's a CountryCurrency object
                if isinstance(record, CountryCurrency):
                    result = self.add_record(record)
                else:
                    result = self.create_record(record)
                
                if result:
                    success_count += 1
                else:
                    error_count += 1
                    errors.append(f"Failed to add record at index {i}")
            except Exception as e:
                error_count += 1
                errors.append(f"Error at index {i}: {str(e)}")
        
        return success_count, error_count, errors