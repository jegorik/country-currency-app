# Streamlit App - Startup Scripts

This directory contains scripts for starting and managing the Streamlit application.

## Files

- `start_app.ps1` - Windows PowerShell script to start the Streamlit app
- `unified_start_app.sh` - Cross-platform shell script to start the Streamlit app
- `wait_and_start.ps1` - Windows PowerShell script that waits for dependencies and then starts the app
- `wait_and_start.sh` - Shell script that waits for dependencies and then starts the app

## Usage

### Windows

```powershell
# Basic startup
./start_app.ps1

# Wait for resources and then start
./wait_and_start.ps1 -waitForResources $true
```

### Linux/macOS

```bash
# Basic startup
./unified_start_app.sh

# Wait for resources and then start
./wait_and_start.sh --wait-for-resources
```

## Configuration

These scripts read environment variables and configuration files from the `../config` directory. Make sure your configuration is properly set up before running the startup scripts.
