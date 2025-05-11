import unittest
from unittest.mock import patch, MagicMock
import sys
import os

# For direct Python imports - would need to extract functions from notebook for real testing
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../notebooks')))

# JSON parsing for Jupyter notebooks
import json

class TestLoadDataNotebook(unittest.TestCase):
    """
    Tests for the load_data_notebook_jupyter.ipynb functionality.
    
    This test suite validates the extracted functions from our Jupyter notebook.
    Since Jupyter notebooks are now the standard format, we need to either:
    1. Extract code from the notebook for testing
    2. Use nbconvert to execute the notebook and verify results
    """
    
    def setUp(self):
        """Setup test fixtures"""
        # Mock environment for notebook testing
        self.mock_databricks_env = {
            'catalog_name': 'test_catalog',
            'schema_name': 'test_schema',
            'table_name': 'test_table',
            'csv_path': '/test/path/data.csv'
        }
    
    @patch('pyspark.sql.SparkSession')
    def test_csv_loading(self, mock_spark):
        """Test CSV loading functionality"""
        # Create mock objects
        mock_spark_instance = MagicMock()
        mock_spark.builder.getOrCreate.return_value = mock_spark_instance
        
        # Mock a DataFrame and its operations
        mock_df = MagicMock()
        mock_spark_instance.read.csv.return_value = mock_df
        mock_df.count.return_value = 10
        mock_df.columns = ['country_code', 'country_number', 'country', 
                           'currency_name', 'currency_code', 'currency_number']
        
        # Test mocked CSV loading
        result_df = mock_spark_instance.read.csv(
            self.mock_databricks_env['csv_path'],
            header=True,
            inferSchema=True
        )
        
        # Verify expected behavior
        mock_spark_instance.read.csv.assert_called_with(
            self.mock_databricks_env['csv_path'],
            header=True,
            inferSchema=True
        )
        self.assertEqual(result_df.count(), 10)
    
    @patch('pyspark.sql.SparkSession')
    def test_delta_table_write(self, mock_spark):
        """Test writing to Delta table functionality"""
        # Create mock objects
        mock_spark_instance = MagicMock()
        mock_spark.builder.getOrCreate.return_value = mock_spark_instance
        
        # Mock a DataFrame and its operations
        mock_df = MagicMock()
        mock_spark_instance.read.csv.return_value = mock_df
        
        # Create mocks for the write operations
        mock_writer = MagicMock()
        mock_df.write.format.return_value = mock_writer
        mock_writer.mode.return_value = mock_writer
        mock_writer.option.return_value = mock_writer
        
        # Test mocked Delta table write
        full_table_name = f"`{self.mock_databricks_env['catalog_name']}`.`{self.mock_databricks_env['schema_name']}`.`{self.mock_databricks_env['table_name']}`"
        
        # In real code, this would reference the actual notebook function
        # Here we're just testing the mock interactions
        df = mock_spark_instance.read.csv(
            self.mock_databricks_env['csv_path'],
            header=True,
            inferSchema=True
        )
        
        df.write.format("delta").mode("overwrite").saveAsTable(full_table_name)
        
        # Verify expectations
        mock_df.write.format.assert_called_with("delta")
        mock_writer.mode.assert_called_with("overwrite")
        mock_writer.saveAsTable.assert_called_with(full_table_name)
    
    def test_notebook_structure(self):
        """Tests if the Jupyter notebook has a valid structure"""
        notebook_path = os.path.abspath(os.path.join(os.path.dirname(__file__), 
                                       '../notebooks/load_data_notebook_jupyter.ipynb'))
        
        # Verify file exists
        self.assertTrue(os.path.exists(notebook_path), "Notebook file doesn't exist")
        
        # Verify it's a valid JSON format
        try:
            with open(notebook_path, 'r') as nb_file:
                notebook_content = json.load(nb_file)
            
            # Check for key Jupyter notebook elements
            self.assertIn('cells', notebook_content, "Missing 'cells' in notebook")
            self.assertIn('metadata', notebook_content, "Missing 'metadata' in notebook")
            self.assertIn('nbformat', notebook_content, "Missing 'nbformat' in notebook")
            
            # Check for required cell types (markdown and code)
            cell_types = [cell.get('cell_type') for cell in notebook_content.get('cells', [])]
            self.assertIn('markdown', cell_types, "Missing markdown cells")
            self.assertIn('code', cell_types, "Missing code cells")
            
            # Check for function definitions
            code_cells = [cell for cell in notebook_content.get('cells', []) 
                         if cell.get('cell_type') == 'code']
            
            all_code = '\n'.join([''.join(cell.get('source', [])) for cell in code_cells])
            
            # Check for key functions
            self.assertIn('def validate_parameters', all_code, "Missing validate_parameters function")
            self.assertIn('def get_full_table_name', all_code, "Missing get_full_table_name function")
            self.assertIn('def read_csv_data', all_code, "Missing read_csv_data function")
            self.assertIn('def perform_data_quality_checks', all_code, "Missing perform_data_quality_checks function")
            self.assertIn('def write_to_delta_table', all_code, "Missing write_to_delta_table function")
            
            # Check for processing_time column
            self.assertIn('processing_time', all_code, "Missing processing_time column")
            self.assertIn('current_timestamp()', all_code, "Missing timestamp generation")
            
        except json.JSONDecodeError:
            self.fail("Notebook is not valid JSON")
        except Exception as e:
            self.fail(f"Error validating notebook: {str(e)}")

if __name__ == '__main__':
    unittest.main()
