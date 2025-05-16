"""
Unit tests for the data operations module.
"""
import unittest
from unittest.mock import MagicMock, patch
import sys
import os
from pathlib import Path

# Add the project root to the Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# Import the modules to test
from streamlit.operations.data_operations import DataOperations
from streamlit.models.country_currency import CountryCurrency

class TestDataOperations(unittest.TestCase):
    """Test cases for the DataOperations class."""

    def setUp(self):
        """Set up test fixtures."""
        # Create a mock DatabricksClient
        self.mock_client = MagicMock()
        self.mock_client.config.full_table_name = "test_catalog.test_schema.test_table"
        
        # Create a DataOperations instance with the mock client
        self.data_ops = DataOperations(self.mock_client)
        
        # Sample test data
        self.test_record = {
            'country_code': 'TST',
            'country': 'Test Country',
            'country_number': 999,
            'currency_code': 'TSC',
            'currency_name': 'Test Currency',
            'currency_number': 999
        }
        
        # Sample test record as CountryCurrency object
        self.test_record_obj = CountryCurrency(
            country_code='TST',
            country='Test Country',
            country_number=999,
            currency_code='TSC',
            currency_name='Test Currency',
            currency_number=999
        )

    def test_get_all_records(self):
        """Test getting all records."""
        # Set up the mock to return test data
        self.mock_client.execute_query.return_value = [self.test_record]
        
        # Call the method
        result = self.data_ops.get_all_records()
        
        # Verify the result
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]['country_code'], 'TST')
        
        # Verify the mock was called correctly
        self.mock_client.execute_query.assert_called_once()
        call_args = self.mock_client.execute_query.call_args[0][0]
        self.assertIn("SELECT * FROM test_catalog.test_schema.test_table", call_args)

    def test_get_all_records_with_filter(self):
        """Test getting records with a filter."""
        # Set up the mock to return test data
        self.mock_client.execute_query.return_value = [self.test_record]
        
        # Call the method with a filter
        result = self.data_ops.get_all_records(filter_query="Test")
        
        # Verify the result
        self.assertEqual(len(result), 1)
        
        # Verify the mock was called correctly
        self.mock_client.execute_query.assert_called_once()
        call_args = self.mock_client.execute_query.call_args[0][0]
        self.assertIn("WHERE", call_args)
        self.assertIn("LIKE", call_args)

    def test_get_record_by_id(self):
        """Test getting a record by ID."""
        # Set up the mock to return test data
        self.mock_client.execute_query.return_value = [self.test_record]
        
        # Call the method
        result = self.data_ops.get_record_by_id('TST')
        
        # Verify the result
        self.assertEqual(result['country_code'], 'TST')
        
        # Verify the mock was called correctly
        self.mock_client.execute_query.assert_called_once()
        call_args = self.mock_client.execute_query.call_args[0][0]
        self.assertIn("WHERE country_code = ?", call_args)

    def test_get_record_by_id_not_found(self):
        """Test getting a record by ID when it doesn't exist."""
        # Set up the mock to return empty list
        self.mock_client.execute_query.return_value = []
        
        # Call the method
        result = self.data_ops.get_record_by_id('NONEXISTENT')
        
        # Verify the result is None
        self.assertIsNone(result)

    def test_create_record(self):
        """Test creating a new record."""
        # Set up the mock
        self.mock_client.execute_query.return_value = None
        
        # Call the method
        result = self.data_ops.create_record(self.test_record)
        
        # Verify the result
        self.assertTrue(result)
        
        # Verify the mock was called correctly
        self.mock_client.execute_query.assert_called_once()
        call_args = self.mock_client.execute_query.call_args[0][0]
        self.assertIn("INSERT INTO", call_args)

    def test_add_record(self):
        """Test adding a record using a CountryCurrency object."""
        # Set up the mock
        self.mock_client.execute_query.return_value = None
        
        # Call the method
        result = self.data_ops.add_record(self.test_record_obj)
        
        # Verify the result
        self.assertTrue(result)
        
        # Verify the mock was called correctly
        self.mock_client.execute_query.assert_called_once()
        call_args = self.mock_client.execute_query.call_args[0][0]
        self.assertIn("INSERT INTO", call_args)

    def test_update_record(self):
        """Test updating a record."""
        # Set up the mock for the check query
        check_result = [{'count': 1}]
        verify_result = [self.test_record]
        
        # Configure the mock to return different values for different calls
        self.mock_client.execute_query.side_effect = [check_result, None, verify_result]
        
        # Call the method
        result = self.data_ops.update_record(self.test_record_obj)
        
        # Verify the result
        self.assertTrue(result)
        
        # Verify the mock was called correctly
        self.assertEqual(self.mock_client.execute_query.call_count, 3)
        update_call_args = self.mock_client.execute_query.call_args_list[1][0][0]
        self.assertIn("UPDATE", update_call_args)

    def test_update_record_not_found(self):
        """Test updating a record that doesn't exist."""
        # Set up the mock for the check query to return no records
        self.mock_client.execute_query.return_value = [{'count': 0}]
        
        # Call the method
        result = self.data_ops.update_record(self.test_record_obj)
        
        # Verify the result is False
        self.assertFalse(result)

    def test_delete_record(self):
        """Test deleting a record."""
        # Set up the mock
        self.mock_client.execute_query.return_value = None
        
        # Call the method
        result = self.data_ops.delete_record('TST')
        
        # Verify the result
        self.assertTrue(result)
        
        # Verify the mock was called correctly
        self.mock_client.execute_query.assert_called_once()
        call_args = self.mock_client.execute_query.call_args[0][0]
        self.assertIn("DELETE FROM", call_args)

    def test_count_records(self):
        """Test counting records."""
        # Set up the mock to return a count
        self.mock_client.execute_query.return_value = [{'count': 42}]
        
        # Call the method
        result = self.data_ops.count_records()
        
        # Verify the result
        self.assertEqual(result, 42)
        
        # Verify the mock was called correctly
        self.mock_client.execute_query.assert_called_once()
        call_args = self.mock_client.execute_query.call_args[0][0]
        self.assertIn("COUNT(*)", call_args)

if __name__ == '__main__':
    unittest.main()