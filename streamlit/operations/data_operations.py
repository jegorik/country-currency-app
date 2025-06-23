"""
Data operations module for performing CRUD operations on country-currency data.
"""
import logging
from utils.databricks_client import DatabricksClient

# Configure logger
logger = logging.getLogger(__name__)


class DataOperations:
    """Class for handling CRUD operations on the country-currency data."""

    def __init__(self, client: DatabricksClient):
        """Initialize the data operations with a Databricks client."""
        self.client = client
        self.table_name = client.config.full_table_name

    def get_all_records(self, filter_query: str = None) -> list:
        """Get all records from the country-currency table."""
        try:
            query = f"SELECT * FROM {self.table_name}"
            if filter_query:
                query += f" WHERE LOWER(country) LIKE LOWER('%{filter_query}%') OR LOWER(country_code) LIKE LOWER('%{filter_query}%') " \
                         f"OR LOWER(currency_name) LIKE LOWER('%{filter_query}%') OR LOWER(currency_code) LIKE LOWER('%{filter_query}%')"
            query += " ORDER BY country_code"

            logger.debug(f"Executing query to get all records with filter: {filter_query}")
            result = self.client.execute_query(query)
            logger.info(f"Retrieved {len(result)} records")
            return result
        except Exception as e:
            logger.error(f"Error retrieving records: {str(e)}")
            return []

    def get_record_by_id(self, country_code: str) -> dict:
        """Get a record by country code."""
        try:
            query = f"SELECT * FROM {self.table_name} WHERE country_code = ?"
            logger.debug(f"Executing query to get record by country_code: {country_code}")
            result = self.client.execute_query(query, (country_code,))

            if result:
                logger.info(f"Record found for country_code: {country_code}")
                return result[0]
            else:
                logger.warning(f"No record found for country_code: {country_code}")
                return None
        except Exception as e:
            logger.error(f"Error retrieving record by country_code {country_code}: {str(e)}")
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
            logger.info(f"Record created successfully: {record['country_code']}")
            return True
        except Exception as e:
            logger.error(f"Error creating record: {str(e)}")
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

        # Check if the record exists before updating
        check_query = f"SELECT COUNT(*) as count FROM {self.table_name} WHERE country_code = ?"
        check_result = self.client.execute_query(check_query, (record_dict['country_code'],))

        if not check_result or check_result[0]['count'] == 0:
            logger.warning(f"Cannot update: Record with country_code {record_dict['country_code']} does not exist")
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
            logger.debug(f"Executing update query for country_code: {record_dict['country_code']}")
            logger.debug(f"Update parameters: {params}")
            self.client.execute_query(query, params)

            # Check if the update was successful
            verify_query = f"SELECT * FROM {self.table_name} WHERE country_code = ?"
            verify_result = self.client.execute_query(verify_query, (record_dict['country_code'],))

            if verify_result:
                logger.info(f"Update successful for country_code: {record_dict['country_code']}")
                return True
            else:
                logger.warning(
                    f"Update may have failed, could not verify record in database for country_code: {record_dict['country_code']}")
                return False

        except Exception as e:
            logger.error(f"Error updating record: {str(e)}")
            logger.exception("Exception details:")
            return False

    def delete_record(self, country_code: str) -> bool:
        """Delete a country-currency record by country code."""
        query = f"DELETE FROM {self.table_name} WHERE country_code = ?"

        try:
            self.client.execute_query(query, (country_code,))
            logger.info(f"Record deleted successfully: {country_code}")
            return True
        except Exception as e:
            logger.error(f"Error deleting record: {str(e)}")
            return False

    def count_records(self) -> int:
        """Count the total number of records in the country-currency table."""
        try:
            query = f"SELECT COUNT(*) as count FROM {self.table_name}"
            logger.debug("Executing query to count records")
            result = self.client.execute_query(query)

            if result:
                count = result[0]['count']
                logger.info(f"Total record count: {count}")
                return count
            else:
                logger.warning("Count query returned no results")
                return 0
        except Exception as e:
            logger.error(f"Error counting records: {str(e)}")
            return 0
