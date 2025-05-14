# Scripts - Testing

This directory contains scripts used for testing the Country Currency App.

## Files

- `run_tests.sh` - Main test runner script
- `test_databricks_connection.sh` - Tests connectivity to Databricks
- `validate_notebook.sh` - Validates notebook syntax and functionality

## Usage

### Run all tests

```bash
./run_tests.sh
```

### Test Databricks connection

```bash
./test_databricks_connection.sh --workspace-url your-workspace-url --token your-token
```

### Validate notebook

```bash
./validate_notebook.sh path/to/notebook.ipynb
```
