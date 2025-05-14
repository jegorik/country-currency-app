#!/bin/bash
# Unified cross-platform launcher for the Streamlit application
# This script automatically detects the OS and launches the app appropriately

# Set up colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display header
display_header() {
  echo -e "${BLUE}================================================${NC}"
  echo -e "${BLUE}   Starting Country Currency Streamlit App   ${NC}"
  echo -e "${BLUE}================================================${NC}"
  echo ""
}

# Function to detect OS
detect_os() {
  OS_TYPE="unknown"
  
  # Try to detect OS using uname if available
  if command -v uname &> /dev/null; then
    case "$(uname -s)" in
      Linux*)     OS_TYPE="linux";;
      Darwin*)    OS_TYPE="macos";;
      CYGWIN*)    OS_TYPE="windows";;
      MINGW*)     OS_TYPE="windows";;
      MSYS*)      OS_TYPE="windows";;
      *)          OS_TYPE="unknown";;
    esac
  else
    # Fallback detection method
    if [ -f /proc/version ]; then
      OS_TYPE="linux"
    elif [ -d "/Applications" ] && [ -d "/System" ]; then
      OS_TYPE="macos"
    elif [ -d "/c/Windows" ] || [ -d "/mnt/c/Windows" ]; then
      OS_TYPE="windows"
    fi
  fi
  
  echo -e "${YELLOW}Detected operating system: ${OS_TYPE}${NC}"
  export OS_TYPE
}

# Function to run Windows-specific launcher
run_windows_launcher() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  
  echo -e "${YELLOW}Running Windows launcher using PowerShell...${NC}"
  
  # Choose between pwsh or powershell.exe
  if command -v pwsh &> /dev/null; then
    pwsh -ExecutionPolicy Bypass -File "$SCRIPT_DIR/start_app.ps1"
  elif command -v powershell.exe &> /dev/null; then
    powershell.exe -ExecutionPolicy Bypass -File "$SCRIPT_DIR/start_app.ps1"
  else
    echo -e "${RED}PowerShell not found. Cannot launch app on Windows.${NC}"
    exit 1
  fi
}

# Function to run Unix (Linux/macOS) launcher
run_unix_launcher() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  
  # Check if job_id.txt file exists
  JOB_ID_FILE="${SCRIPT_DIR}/../../terraform/job_id.txt"
  if [ ! -f "$JOB_ID_FILE" ]; then
    echo -e "${YELLOW}Job ID file not found. The app may not be able to check job status.${NC}"
    JOB_ID=""
  else
    JOB_ID=$(cat "$JOB_ID_FILE")
    echo -e "${GREEN}Found job ID: $JOB_ID${NC}"
  fi
  
  # Get workspace URL
  WORKSPACE_URL_FILE="${SCRIPT_DIR}/../../terraform/workspace_url.txt"
  if [ ! -f "$WORKSPACE_URL_FILE" ]; then
    echo -e "${YELLOW}Workspace URL file not found. Using default configuration.${NC}"
    WORKSPACE_URL="https://databricks.com"
  else
    WORKSPACE_URL=$(cat "$WORKSPACE_URL_FILE")
    echo -e "${GREEN}Found workspace URL: $WORKSPACE_URL${NC}"
  fi
  
  # Check for required Python packages
  echo -e "${YELLOW}Checking for required Python packages...${NC}"
  python -c "import streamlit" &> /dev/null
  if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Installing required Python packages...${NC}"
    REQUIREMENTS_FILE="${SCRIPT_DIR}/requirements.txt"
    if [ -f "$REQUIREMENTS_FILE" ]; then
      pip install -r "$REQUIREMENTS_FILE"
    else
      pip install streamlit pandas requests
    fi
  fi
  
  # Launch the Streamlit app
  echo -e "${GREEN}Launching Streamlit app...${NC}"
  cd "${SCRIPT_DIR}/../../streamlit"
  
  # Check if the new UI app exists
  if [ -f "${SCRIPT_DIR}/../../streamlit/app_new.py" ]; then
    echo -e "${GREEN}Starting new UI version...${NC}"
    streamlit run ../../streamlit/app_new.py -- --job_id="$JOB_ID" --workspace_url="$WORKSPACE_URL"
  else
    echo -e "${GREEN}Starting standard UI version...${NC}"
    streamlit run ../../streamlit/app.py -- --job_id="$JOB_ID" --workspace_url="$WORKSPACE_URL"
  fi
}

# Main execution flow
display_header
detect_os

# Execute OS-specific launcher
case "$OS_TYPE" in
  windows)
    run_windows_launcher
    ;;
  linux|macos)
    run_unix_launcher
    ;;
  *)
    echo -e "${RED}Unsupported operating system: $OS_TYPE${NC}"
    echo -e "${YELLOW}Please run the app launcher manually.${NC}"
    exit 1
    ;;
esac

exit 0
