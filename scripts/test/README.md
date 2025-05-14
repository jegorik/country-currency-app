# Scripts - Testing

This directory contains scripts used for testing the Country Currency App. These testing scripts were organized into this directory as part of the project structure cleanup.

## Files

- `run_tests.sh` - Main test runner script
- `test_databricks_connection.sh` - Tests connectivity to Databricks
- `validate_notebook.sh` - Validates notebook syntax and functionality

## Usage

### Run all tests

```bash
# Using from the scripts/test directory
bash run_tests.sh

# Using from project root
bash scripts/test/run_tests.sh
```

### Test Databricks connection

```bash
# Using from the scripts/test directory
bash test_databricks_connection.sh --workspace-url your-workspace-url --token your-token

# Using from project root
bash scripts/test/test_databricks_connection.sh --workspace-url your-workspace-url --token your-token
```

### Validate notebook

```bash
# Using from the scripts/test directory
bash validate_notebook.sh path/to/notebook.ipynb

# Using from project root
bash scripts/test/validate_notebook.sh path/to/notebook.ipynb
```
