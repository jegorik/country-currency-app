# Databricks Notebook CI/CD Integration

This document describes how to properly validate Databricks notebooks in a CI/CD pipeline without requiring a live Databricks environment.

## The Challenge

Databricks notebooks typically depend on the Databricks runtime environment, which includes:

1. PySpark libraries and context (spark session, dbutils, etc.)
2. Delta Lake libraries
3. Pre-configured authentication to various services
4. A compute environment with required dependencies

When running validation in CI/CD pipelines like GitHub Actions, these dependencies are not available, which can cause validation failures even if the notebooks are correctly structured.

## Our Solution

To address this challenge, we've implemented a multi-layered validation approach:

### 1. JSON Format Validation

Ensures notebooks are properly formatted Jupyter notebooks (valid JSON with the correct structure).

### 2. Syntax Validation

Extracts Python code from notebook cells and performs static syntax checking without executing the code.

### 3. Mock Imports

Creates mock modules for Databricks-specific imports like PySpark to avoid import errors during validation.

## Implementation Details

The validation is implemented in the `ci/validate_notebooks.py` script, which:

1. Validates the JSON structure of each notebook
2. Creates a temporary Python file with the notebook code
3. Performs syntax checking without execution
4. Creates mocks for Databricks-specific modules

## How to Update the Validation

If your notebooks use additional Databricks-specific modules that aren't currently mocked, update the `setup_mock_modules()` function in `ci/validate_notebooks.py`.

## Running Validation Locally

```bash
python3 ci/validate_notebooks.py
```

## GitHub Actions Integration

The validation is automatically run as part of the CI/CD pipeline in GitHub Actions. The workflow configuration can be found in `.github/workflows/ci-cd.yml`.

## Troubleshooting

If validation fails, check the following:

1. Is the notebook valid JSON? (Use tools like jsonlint)
2. Does the Python code have syntax errors?
3. Are you using libraries that need to be mocked?
4. Are you directly accessing Databricks-specific variables without conditionals?

## Best Practices

1. Keep notebook code modular and testable
2. Separate business logic from Databricks-specific code when possible
3. Use conditional imports for Databricks-specific modules
4. Consider creating pure Python modules alongside notebooks for better testability

## Common Validation Errors and Solutions

| Error | Possible Cause | Solution |
|-------|---------------|----------|
| `ModuleNotFoundError: No module named 'pyspark'` | Missing mock module | Add the module to `setup_mock_modules()` in the validation script |
| `SyntaxError: invalid syntax` | Python version incompatibility | Ensure notebook code is compatible with Python 3.6+ |
| `Invalid notebook format` | Malformed JSON in notebook | Check cell metadata and notebook structure |
| `ImportError: cannot import name X from Y` | Using Databricks-specific features | Mock the specific function or class being imported |

## Version Compatibility

The validation script is compatible with:
- Python 3.6+
- Jupyter Notebook format 4.0+
- Databricks Runtime 7.0+

For notebooks using newer Databricks features, update the mocking logic in the validation script accordingly.
