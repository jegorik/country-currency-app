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
            query += f" WHERE LOWER(country) LIKE LOWER('%{filter_query}%') OR LOWER(country_code) LIKE LOWER('%{filter_query}%') " \
                     f"OR LOWER(currency_name) LIKE LOWER('%{filter_query}%') OR LOWER(currency_code) LIKE LOWER('%{filter_query}%')"
        query += " ORDER BY country_code"
        return self.client.execute_query(query)
    
    def get_record_by_id(self, country_code: str) -> dict:
        """Get a record by country code."""
        query = f"SELECT * FROM {self.table_name} WHERE country_code = ?"
        result = self.client.execute_query(query, (country_code,))
        if result:
            return result[0]
        return None
    
    def add_record(self, record):
        """Add a new country-currency record.
        
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
    
    def update_record(self, record):
        """Update an existing country-currency record.
        
        This method can accept either a dictionary or a CountryCurrency object.
        """
        # Check if we got a CountryCurrency object and convert it to dict if needed
        if not isinstance(record, dict):
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
        
        # Проверяем существует ли запись перед обновлением
        check_query = f"SELECT COUNT(*) as count FROM {self.table_name} WHERE country_code = ?"
        check_result = self.client.execute_query(check_query, (record_dict['country_code'],))
        
        if not check_result or check_result[0]['count'] == 0:
            print(f"Cannot update: Record with country_code {record_dict['country_code']} does not exist")
            return False
            
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
            print(f"Executing update query for country_code: {record_dict['country_code']}")
            print(f"Update parameters: {params}")
            self.client.execute_query(query, params)
            
            # Проверяем успешность обновления
            verify_query = f"SELECT * FROM {self.table_name} WHERE country_code = ?"
            verify_result = self.client.execute_query(verify_query, (record_dict['country_code'],))
            
            if verify_result:
                print("Update successful, record verified in database")
                return True
            else:
                print("Update may have failed, could not verify record in database")
                return False
                
        except Exception as e:
            print(f"Error updating record: {str(e)}")
            import traceback
            traceback.print_exc()
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
