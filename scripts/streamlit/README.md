# Streamlit Application Launch Scripts

This directory contains scripts for starting the Streamlit application. These scripts were relocated from the `/streamlit` directory to improve project organization.

## Available Scripts

### Cross-Platform Launchers

- `unified_start_app.sh`: Unified cross-platform launcher that detects OS and launches the app appropriately
  - Automatically identifies whether you're on Windows or Unix
  - Sets up required environment
  - Checks for Databricks job completion
  - Launches the Streamlit application

### Windows-Specific Scripts

- `start_app.ps1`: PowerShell script to start the Streamlit application on Windows
- `wait_and_start.ps1`: PowerShell script that waits for Databricks job completion before starting the app

### Unix-Specific Scripts

- `wait_and_start.sh`: Shell script that waits for Databricks job completion before starting the app

## Usage

### From this directory

```bash
# On Unix systems
./unified_start_app.sh

# On Windows systems
pwsh -ExecutionPolicy Bypass -File ".\start_app.ps1"
```

### From project root

```bash
# On Unix systems
./scripts/streamlit/unified_start_app.sh

# On Windows systems 
pwsh -ExecutionPolicy Bypass -File ".\scripts\streamlit\start_app.ps1"
```

## Notes

- These scripts reference files in the `/terraform` directory for configuration
- The scripts will run the Streamlit application from the `/streamlit` directory
- Original duplicate scripts in `/streamlit/startup` should be removed after testing
