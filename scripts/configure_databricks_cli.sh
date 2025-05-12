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
if [ -f terraform.tfvars ]; then
  DATABRICKS_HOST=$(grep databricks_host terraform.tfvars | cut -d '=' -f2 | tr -d ' "' | tr -d "'")
  DATABRICKS_TOKEN=$(grep databricks_token terraform.tfvars | cut -d '=' -f2 | tr -d ' "' | tr -d "'")
else
  echo -e "${RED}Error: terraform.tfvars not found${NC}"
  exit 1
fi

# Create or update ~/.databrickscfg file
echo -e "[DEFAULT]\nhost = $DATABRICKS_HOST\ntoken = $DATABRICKS_TOKEN" > ~/.databrickscfg
chmod 600 ~/.databrickscfg

echo -e "${GREEN}Databricks CLI configuration updated successfully!${NC}"
echo "Configuration:"
echo -e "Host: ${DATABRICKS_HOST}"
echo -e "Token: ${DATABRICKS_TOKEN:0:5}...${DATABRICKS_TOKEN: -5}"

# Test the connection
echo -e "\n${YELLOW}Testing Databricks connection...${NC}"
databricks workspace ls / > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Successfully authenticated with Databricks API${NC}"
  echo "Connected to workspace:"
  databricks workspace ls / | head -5
else
  echo -e "${RED}Failed to authenticate with Databricks API${NC}"
  echo "Please check your token and host URL"
fi
