#!/bin/bash

# Script to configure Databricks CLI from terraform.tfvars
# Usage: ./configure_databricks_cli.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Configuring Databricks CLI from terraform.tfvars...${NC}"

# Read values from terraform.tfvars
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

# Change to terraform directory
echo -e "${YELLOW}Accessing terraform.tfvars in $TERRAFORM_DIR...${NC}"
cd "$TERRAFORM_DIR" || {
    echo -e "${RED}Error: Could not change to terraform directory${NC}"
    exit 1
}

if [ -f "terraform.tfvars" ]; then
  echo -e "${YELLOW}Reading Databricks configuration from terraform.tfvars...${NC}"
  
  # Debug: Show the line containing the host
  echo "Host line from terraform.tfvars:"
  grep databricks_host terraform.tfvars
  
  # Debug: Show the line containing the token (but mask most of it)
  echo "Token line from terraform.tfvars (masked):"
  grep databricks_token terraform.tfvars | sed 's/\(databricks_token[^"]*"[^"]\{5\}\).*\([^"]\{5\}"\)/\1...\2/'
  
  # Extract values, keeping any quotes that may be needed
  DATABRICKS_HOST=$(grep databricks_host terraform.tfvars | cut -d '=' -f2 | sed 's/^[ \t]*//')
  DATABRICKS_TOKEN=$(grep databricks_token terraform.tfvars | cut -d '=' -f2 | sed 's/^[ \t]*//')
  
  # Remove surrounding quotes if present (but keep content intact)
  DATABRICKS_HOST=$(echo "$DATABRICKS_HOST" | sed 's/^"\(.*\)"$/\1/')
  DATABRICKS_TOKEN=$(echo "$DATABRICKS_TOKEN" | sed 's/^"\(.*\)"$/\1/')
else
  echo -e "${RED}Error: terraform.tfvars not found${NC}"
  exit 1
fi

# Return to original directory
cd "$SCRIPT_DIR" || true

# Create or update ~/.databrickscfg file
echo -e "# Databricks CLI configuration - $(date)" > ~/.databrickscfg
echo -e "[DEFAULT]" >> ~/.databrickscfg
echo -e "host = $DATABRICKS_HOST" >> ~/.databrickscfg
echo -e "token = $DATABRICKS_TOKEN" >> ~/.databrickscfg
chmod 600 ~/.databrickscfg

# Show the actual configuration file content (with token masked)
echo -e "${YELLOW}Databricks CLI config file content:${NC}"
cat ~/.databrickscfg | sed 's/\(token = [^.]\{5\}\).*$/\1.../'

echo -e "${GREEN}Databricks CLI configuration updated successfully!${NC}"
echo "Configuration:"
echo -e "Host: ${DATABRICKS_HOST}"
echo -e "Token: ${DATABRICKS_TOKEN:0:5}...${DATABRICKS_TOKEN: -5}"

# Test the connection with detailed error output
echo -e "\n${YELLOW}Testing Databricks connection...${NC}"
echo "Executing: databricks workspace list /"

# Capture both stdout and stderr
OUTPUT=$(databricks workspace list / 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}Successfully authenticated with Databricks API${NC}"
  echo "Connected to workspace:"
  echo "$OUTPUT" | head -5
  
  # Add the configuration to the project's check script
  echo -e "\n${YELLOW}Updating test_databricks_connection.sh with successful configuration...${NC}"
  sed -i 's/databricks workspace ls/databricks workspace list/g' "$SCRIPT_DIR/test_databricks_connection.sh" 2>/dev/null || echo "Note: Could not update test_databricks_connection.sh"
else
  echo -e "${RED}Failed to authenticate with Databricks API${NC}"
  echo -e "${RED}Error details:${NC}"
  echo "$OUTPUT"
  
  # Check for common issues
  if echo "$OUTPUT" | grep -q "401"; then
    echo -e "\n${YELLOW}This appears to be an authentication error (401). Possible solutions:${NC}"
    echo "1. The token might be expired. Generate a new token in the Databricks UI."
    echo "2. The token might be incorrectly formatted in terraform.tfvars."
    echo "3. The host URL might be incorrect."
  elif echo "$OUTPUT" | grep -q "Connection refused"; then
    echo -e "\n${YELLOW}This appears to be a connection issue. Possible solutions:${NC}"
    echo "1. Check your internet connection."
    echo "2. Verify that the Databricks host URL is correct."
    echo "3. Ensure there are no firewalls blocking the connection."
  fi
  
  echo -e "\n${YELLOW}For troubleshooting:${NC}"
  echo "1. Verify your token in Databricks UI"
  echo "2. Check terraform.tfvars for correct formatting"
  echo "3. Try using a personal access token temporarily"
fi
