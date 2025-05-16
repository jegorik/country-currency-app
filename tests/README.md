# Country Currency App - Tests

This directory contains unit tests for the Country Currency App.

## Test Structure

The tests are organized by module:

- `test_data_operations.py`: Tests for the data operations module (CRUD operations)

## Running Tests

To run all tests:

```bash
cd country-currency-app
python -m unittest discover tests
```

To run a specific test file:

```bash
cd country-currency-app
python -m unittest tests/test_data_operations.py
```

To run a specific test case:

```bash
cd country-currency-app
python -m unittest tests.test_data_operations.TestDataOperations.test_get_all_records
```

## Test Coverage

The tests cover the following functionality:

### Data Operations Tests

- Getting all records
- Getting records with filters
- Getting a record by ID
- Creating new records
- Updating existing records
- Deleting records
- Counting records

## Adding New Tests

When adding new tests:

1. Create a new test file in the `tests` directory
2. Import the necessary modules
3. Create a test class that inherits from `unittest.TestCase`
4. Add test methods that start with `test_`
5. Use assertions to verify the expected behavior

Example:

```python
import unittest
from unittest.mock import MagicMock

class TestNewFeature(unittest.TestCase):
    def setUp(self):
        # Set up test fixtures
        pass
        
    def test_some_functionality(self):
        # Test code here
        self.assertEqual(expected_result, actual_result)
```

## Mocking

The tests use the `unittest.mock` module to mock external dependencies like the Databricks client. This allows testing the code without actual database connections.

Example of mocking:

```python
from unittest.mock import MagicMock

# Create a mock object
mock_client = MagicMock()

# Configure the mock to return specific values
mock_client.execute_query.return_value = [{'id': 1, 'name': 'Test'}]

# Use the mock in your test
result = your_function(mock_client)

# Verify the mock was called correctly
mock_client.execute_query.assert_called_once_with("SELECT * FROM table")
```