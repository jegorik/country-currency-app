# Troubleshooting Guide

This document provides solutions for common issues encountered when working with the Country Currency App.

## Table of Contents
1. [Notebook Format Issues](#notebook-format-issues)
2. [Table Schema Conflicts](#table-schema-conflicts)
3. [Authentication Issues](#authentication-issues)
4. [Terraform Apply/Destroy Problems](#terraform-applydestroy-problems)
5. [SQL Warehouse Connectivity](#sql-warehouse-connectivity)
6. [Python Compatibility Issues](#python-compatibility-issues)
7. [Cross-Platform Issues](#cross-platform-issues)

## Notebook Format Issues

### Issue: Databricks Notebook Cell Structure Problems

**Symptoms:**
- Error messages about incomplete syntax in notebook execution
- Functions appear to be cut off or incomplete when executed
- Databricks UI shows syntax errors where the code looks valid

**Cause:**
The problem occurs because of mismatched notebook formats. Databricks requires notebooks in standard Jupyter JSON format with properly separated cells. Common issues include:

1. Using Databricks cell markers (`# COMMAND ----------`) inside function definitions
2. Using VS Code's notebook format with XML-style cell markers instead of Jupyter format
3. Embedding cell separators within logical code blocks

**Solution:**
1. Ensure notebooks are in proper Jupyter format (JSON-based .ipynb)
2. Separate function definitions into their own cells
3. Place execution code in separate cells from definitions
4. Use markdown cells for documentation sections
5. When referencing notebooks in Terraform, use `format = "JUPYTER"` for .ipynb files

## Table Schema Conflicts

### Issue: Terraform Destroy Fails with Schema Mismatch Error

**Symptoms:**
- Error message: "detected changes in both number of columns and existing column field values..."
- Terraform destroy fails with schema validation errors

**Cause:**
This typically happens when the notebook adds columns to the table that aren't defined in the Terraform configuration. For example, if the notebook adds a `processing_time` timestamp column but this isn't defined in the `main.tf` table resource.

**Solution:**
1. Ensure any columns added by notebooks are also defined in Terraform table resources
2. For timestamp columns automatically added to tables, add in the Terraform definition:
   ```terraform
   column {
     name    = "processing_time"
     type    = "TIMESTAMP"
     comment = "Timestamp when the data was processed"
   }
   ```
3. Run Terraform plan before destroy to identify schema discrepancies

## Authentication Issues

### Issue: Databricks API Connection Failures

**Symptoms:**
- "401 Unauthorized" errors when running API calls
- Terraform fails with authentication errors
- Jobs fail to start or stop SQL warehouses

**Cause:**
Common causes include expired tokens, incorrect host URLs, or misconfigured permissions.

**Solution:**
1. Verify token validity in the Databricks UI
2. Regenerate and update the token in `terraform.tfvars`
3. Ensure the token has the correct permissions for the operations
4. Use the `configure_databricks_cli.sh` script to update local CLI configuration
5. Check that the Databricks host URL is correct and accessible

## Terraform Apply/Destroy Problems

### Issue: Resource Dependency Errors

**Symptoms:**
- Terraform fails with dependency errors
- Resources fail to create or destroy in the correct order

**Solution:**
1. Ensure proper dependencies using `depends_on` attributes
2. For SQL warehouse operations, add explicit dependencies on warehouse resources
3. Use `-refresh=true` flag with Terraform commands when state might be out of sync

## SQL Warehouse Connectivity

### Issue: SQL Warehouse Fails to Start

**Symptoms:**
- Error starting SQL warehouse
- Notebook execution fails with connectivity errors
- API calls to start warehouse fail

**Solution:**
1. Verify warehouse ID in configuration
2. Check warehouse permissions for the token user
3. Ensure API calls include proper headers:
   ```bash
   curl -X POST "${DATABRICKS_HOST}/api/2.0/sql/warehouses/${WAREHOUSE_ID}/start" \
     -H "Authorization: Bearer ${DATABRICKS_TOKEN}" \
     -H "Content-Type: application/json"
   ```
4. Allow sufficient time for warehouse startup before executing queries

## Python Compatibility Issues

### Issue: PySpark Deprecation Warnings with Python 3.12

**Symptoms:**
- Deprecation warnings about `typing.io` during test execution
- Potential failures when upgrading to Python 3.12

**Solution:**
- For detailed information and solutions, see [Python Compatibility Guide](PYTHON_COMPATIBILITY.md)
- Use `-W ignore::DeprecationWarning` flag when running Python tests (implemented in `run_tests.sh`)
- Consider pinning Python version to 3.11 until PySpark is updated

## Cross-Platform Issues

### Issue: Terraform Execution Fails on Unsupported OS

**Symptoms:**
- Job not triggering automatically after deployment
- Error messages in Terraform logs about shell commands failing
- `local-exec` provisioner failures with messages like "command not found"

**Cause:**
Shell script incompatibilities between Windows and Linux operating systems. Scripts may use commands or syntax that are specific to one platform.

**Solution:**
1. Run the dependency checker before deployment:
   ```bash
   bash scripts/check_dependencies.sh
   ```

2. Ensure you're running the latest version of the code that includes OS detection in scripts

3. For Windows users:
   - Make sure PowerShell Core (pwsh) is installed, not just Windows PowerShell
   - Add PowerShell Core to your PATH
   - Run Terraform from Git Bash or WSL for better compatibility

4. For Linux users:
   - Ensure curl, grep, and sed are installed
   - Make all scripts executable: `chmod +x scripts/*.sh`

### Issue: PowerShell Security Restrictions

**Symptoms:**
- Scripts fail with execution policy errors
- PowerShell refuses to run scripts

**Solution:**
1. Run PowerShell as administrator
2. Set execution policy to allow scripts:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. If using pwsh for the first time, confirm you want to run scripts

### Issue: Missing Dependencies on Linux

**Symptoms:**
- Commands like `curl` not found
- Script failures on fresh Linux installations

**Solution:**
Install required dependencies:
```bash
# On Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y curl jq grep sed

# On Red Hat/CentOS
sudo yum install -y curl jq grep sed

# On macOS (using Homebrew)
brew install curl jq grep
```
