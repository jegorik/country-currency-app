#!/bin/bash
# Unified cross-platform deployment script for Country Currency App
# This script works on Linux, macOS and Windows (via Git Bash or WSL)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display header
display_header() {
  echo -e "${CYAN}=================================================="
  echo -e "  Country Currency App - Cross-Platform Deployment"
  echo -e "==================================================${NC}"
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

# Function to check if command exists
check_command() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check dependencies
check_dependencies() {
  echo -e "${YELLOW}Checking required dependencies...${NC}"
  local missing_deps=false
  
  # Common dependencies for all platforms
  common_deps=("terraform" "curl")
  
  for dep in "${common_deps[@]}"; do
    if check_command "$dep"; then
      echo -e "✅ ${GREEN}${dep} is installed${NC}"
    else
      echo -e "❌ ${RED}${dep} is not installed${NC}"
      missing_deps=true
    fi
  done
  
  # OS-specific dependencies
  if [ "$OS_TYPE" = "windows" ]; then
    if check_command "pwsh" || check_command "powershell.exe"; then
      echo -e "✅ ${GREEN}PowerShell is installed${NC}"
    else
      echo -e "❌ ${RED}PowerShell is not installed${NC}"
      missing_deps=true
    fi
  elif [ "$OS_TYPE" = "linux" ] || [ "$OS_TYPE" = "macos" ]; then
    for dep in "grep" "sed"; do
      if check_command "$dep"; then
        echo -e "✅ ${GREEN}${dep} is installed${NC}"
      else
        echo -e "❌ ${RED}${dep} is not installed${NC}"
        missing_deps=true
      fi
    done
  fi
  
  if [ "$missing_deps" = true ]; then
    echo -e "${RED}Please install missing dependencies and try again.${NC}"
    exit 1
  fi
}

# Function to run Terraform commands (for Linux and macOS)
run_terraform_deployment() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
  
  echo -e "${YELLOW}Navigating to Terraform directory...${NC}"
  cd "$PROJECT_ROOT/terraform" || { 
    echo -e "${RED}Failed to navigate to terraform directory.${NC}"
    exit 1
  }
  
  # Initialize Terraform
  echo -e "\n${YELLOW}Initializing Terraform...${NC}"
  terraform init
  if [ $? -ne 0 ]; then
    echo -e "${RED}Terraform initialization failed.${NC}"
    exit 1
  fi
  
  # Validate Terraform configuration
  echo -e "\n${YELLOW}Validating Terraform configuration...${NC}"
  terraform validate
  if [ $? -ne 0 ]; then
    echo -e "${RED}Terraform validation failed.${NC}"
    exit 1
  fi
  
  # Apply Terraform configuration
  echo -e "\n${YELLOW}Applying Terraform configuration...${NC}"
  terraform apply -auto-approve
  if [ $? -ne 0 ]; then
    echo -e "${RED}Terraform apply failed.${NC}"
    exit 1
  fi
  
  echo -e "\n${GREEN}Deployment completed successfully!${NC}"
  echo -e "${GREEN}You can now access your Databricks resources.${NC}"
}

# Function to run PowerShell deployment on Windows
run_windows_deployment() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  
  echo -e "${YELLOW}Running Windows deployment using PowerShell...${NC}"
  
  # Support both pwsh and powershell.exe
  if check_command "pwsh"; then
    pwsh -ExecutionPolicy Bypass -File "$SCRIPT_DIR/deploy_windows.ps1"
  elif check_command "powershell.exe"; then
    powershell.exe -ExecutionPolicy Bypass -File "$SCRIPT_DIR/deploy_windows.ps1"
  else
    echo -e "${RED}PowerShell not found. Cannot proceed with Windows deployment.${NC}"
    exit 1
  fi
}

# Main execution flow
display_header
detect_os
check_dependencies

# Execute OS-specific deployment
case "$OS_TYPE" in
  windows)
    run_windows_deployment
    ;;
  linux|macos)
    run_terraform_deployment
    ;;
  *)
    echo -e "${RED}Unsupported operating system: $OS_TYPE${NC}"
    echo -e "${YELLOW}Please run deployment manually using appropriate scripts.${NC}"
    exit 1
    ;;
esac

exit 0
