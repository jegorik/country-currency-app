# Python and Library Compatibility Issues

## Python 3.12 Compatibility Warning

**Issue:** PySpark version 3.3.0 uses deprecated `typing.io` import which will be removed in Python 3.12

**Symptoms:**
- Deprecation warning: `typing.io is deprecated, import directly from typing instead. typing.io will be removed in Python 3.12`
- In Python 3.12, scripts may fail with `ImportError: cannot import name 'BinaryIO' from 'typing.io'`

**Solution for Local Development:**
1. Suppress deprecation warnings when running tests:
   ```bash
   python -W ignore::DeprecationWarning -m pytest tests/
   ```
   This has been implemented in the `run_tests.sh` script.

2. Pin the Python version to 3.11 or earlier until PySpark is updated:
   ```bash
   # In GitHub Actions workflow or other CI/CD systems
   uses: actions/setup-python@v4
   with:
     python-version: 3.11  # Do not upgrade to 3.12 until PySpark is compatible
   ```

**Long-term Solution:**
1. Update to a newer version of PySpark that uses direct imports from `typing`:
   ```bash
   pip install pyspark>=3.4.0
   ```

2. If using Databricks Runtime, ensure you're using DBR 12.0 or later which should have the fix.

3. For custom validation scripts, modify mock PySpark modules to use the newer import pattern:
   ```python
   # Instead of
   from typing.io import BinaryIO
   
   # Use
   from typing import BinaryIO
   ```
