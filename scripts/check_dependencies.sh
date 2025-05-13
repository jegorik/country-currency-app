#!/bin/bash
# Script to check for required dependencies across platforms
# This script works on both Linux/Unix and Windows with Git Bash

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check Windows-specific dependencies
check_windows_deps() {
  echo -e "${YELLOW}Checking Windows dependencies...${NC}"
  
  # Check for PowerShell
  if command_exists pwsh; then
    echo -e "${GREEN}✓ PowerShell Core (pwsh) is installed${NC}"
  else
    echo -e "${RED}✗ PowerShell Core (pwsh) is not installed. Please install it from: https://github.com/PowerShell/PowerShell${NC}"
    missing_deps=true
  fi
  
  # Check if Invoke-RestMethod is available in PowerShell
  if pwsh -Command "Get-Command Invoke-RestMethod" &>/dev/null; then
    echo -e "${GREEN}✓ PowerShell Invoke-RestMethod cmdlet is available${NC}"
  else
    echo -e "${RED}✗ PowerShell Invoke-RestMethod cmdlet is not available${NC}"
    missing_deps=true
  fi
}

# Function to check Linux-specific dependencies
check_linux_deps() {
  echo -e "${YELLOW}Checking Linux dependencies...${NC}"
  
  # Check for curl
  if command_exists curl; then
    echo -e "${GREEN}✓ curl is installed${NC}"
  else
    echo -e "${RED}✗ curl is not installed. Install it using your package manager (e.g., apt-get install curl)${NC}"
    missing_deps=true
  fi
  
  # Check for sed
  if command_exists sed; then
    echo -e "${GREEN}✓ sed is installed${NC}"
  else
    echo -e "${RED}✗ sed is not installed. Install it using your package manager${NC}"
    missing_deps=true
  fi
  
  # Check for grep
  if command_exists grep; then
    echo -e "${GREEN}✓ grep is installed${NC}"
  else
    echo -e "${RED}✗ grep is not installed. Install it using your package manager${NC}"
    missing_deps=true
  fi
}

# Function to check common dependencies
check_common_deps() {
  echo -e "${YELLOW}Checking common dependencies...${NC}"
  
  # Check for Terraform
  if command_exists terraform; then
    tf_version=$(terraform version | head -n 1)
    echo -e "${GREEN}✓ Terraform is installed: $tf_version${NC}"
  else
    echo -e "${RED}✗ Terraform is not installed. Please install it from: https://www.terraform.io/downloads.html${NC}"
    missing_deps=true
  fi
  
  # Check for Databricks CLI
  if command_exists databricks; then
    db_version=$(databricks version)
    echo -e "${GREEN}✓ Databricks CLI is installed: $db_version${NC}"
  else
    echo -e "${RED}✗ Databricks CLI is not installed. Please install it: pip install databricks-cli${NC}"
    missing_deps=true
  fi
  
  # Check for Python
  if command_exists python || command_exists python3; then
    python_cmd="python"
    if ! command_exists python && command_exists python3; then
      python_cmd="python3"
    fi
    py_version=$($python_cmd --version 2>&1)
    echo -e "${GREEN}✓ Python is installed: $py_version${NC}"
  else
    echo -e "${RED}✗ Python is not installed. Please install it from: https://www.python.org/downloads/${NC}"
    missing_deps=true
  fi
}

# Main execution
echo "Country Currency App - Dependency Checker"
echo "----------------------------------------"

missing_deps=false

# Check common dependencies for all platforms
check_common_deps

# Detect OS and run appropriate checks
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win"* || "$OSTYPE" == "cygwin" ]]; then
  check_windows_deps
else
  check_linux_deps
fi

echo "----------------------------------------"
if [ "$missing_deps" = true ]; then
  echo -e "${RED}One or more required dependencies are missing.${NC}"
  echo -e "Please install the missing dependencies and try again."
  exit 1
else
  echo -e "${GREEN}All required dependencies are installed!${NC}"
  echo -e "You're ready to deploy the Country Currency App."
  exit 0
fi
