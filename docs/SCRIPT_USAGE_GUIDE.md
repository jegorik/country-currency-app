# Script Usage Guide

This guide provides detailed information on how to use the scripts in the Country Currency App project, including examples of running scripts from various locations in the project.

## Script Organization

The project scripts are organized into the following directories:

- `/scripts/deploy/` - Deployment scripts for infrastructure and application
- `/scripts/setup/` - Environment and configuration setup scripts
- `/scripts/test/` - Testing utilities and validators
- `/scripts/streamlit/` - Streamlit application launch scripts
- `/scripts/utils/` - General utility scripts

## Running Scripts from Different Locations

All scripts in this project are designed to be path-independent, meaning they can be run from any directory. This is accomplished through a standardized path calculation pattern used in each script.

### Path Calculation Pattern

The scripts determine their own location and calculate paths to other resources using this pattern:

```bash
# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Calculate path to project root
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Calculate paths to specific directories
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
```

### Running Examples

#### From the Project Root

When in the project root directory:

```bash
# Deployment
bash scripts/deploy/unified_deploy.sh

# Start Streamlit application
bash scripts/streamlit/unified_start_app.sh

# Run tests
bash scripts/test/run_tests.sh
```

#### From Inside a Script Directory

When inside a script directory:

```bash
# From scripts/deploy/
bash unified_deploy.sh

# From scripts/streamlit/
bash unified_start_app.sh

# From scripts/test/
bash run_tests.sh
```

#### From Any Other Directory

When in any other directory (using absolute paths):

```bash
# Using absolute path
bash /path/to/country-currency-app/scripts/deploy/unified_deploy.sh

# Using relative path if you know the relation
bash ../../../scripts/deploy/unified_deploy.sh
```

## Script-Specific Usage Examples

### Deployment Scripts

#### Unified Deployment (Cross-Platform)

```bash
# Basic usage
bash scripts/deploy/unified_deploy.sh

# With environment specification
bash scripts/deploy/unified_deploy.sh -e dev

# Check dependencies only
bash scripts/deploy/unified_deploy.sh --check-only
```

#### Windows Deployment (PowerShell)

```powershell
# Basic usage
.\scripts\deploy\unified_deploy.ps1

# With environment specification
.\scripts\deploy\unified_deploy.ps1 -Environment dev

# Check dependencies only
.\scripts\deploy\unified_deploy.ps1 -CheckOnly
```

### Streamlit Application Scripts

```bash
# Launch Streamlit app
bash scripts/streamlit/unified_start_app.sh

# Wait for job completion and then start app
bash scripts/streamlit/wait_and_start.sh
```

### Test Scripts

```bash
# Run all tests
bash scripts/test/run_tests.sh

# Test Databricks connection
bash scripts/test/test_databricks_connection.sh --workspace-url your-workspace-url --token your-token

# Validate notebook
bash scripts/test/validate_notebook.sh path/to/notebook.ipynb
```

## Troubleshooting Script Execution

If you encounter issues running scripts:

1. **Ensure bash is available**: The scripts require bash to run properly
2. **Check execution permissions**: You may need to make scripts executable with `chmod +x script.sh`
3. **Verify paths**: If errors mention missing files, check the project structure
4. **Environment variables**: Some scripts may rely on environment variables being set

## Makefile Integration

For convenience, common script operations are also available through the Makefile:

```bash
# Deploy using unified script
make deploy

# Start the Streamlit application
make streamlit-app

# Complete deployment with Streamlit app
make deploy-with-ui
```

The Makefile targets automatically handle OS detection and call the appropriate scripts with correct parameters.
