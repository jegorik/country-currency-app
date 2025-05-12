#!/bin/bash

# Script to test Databricks connectivity
# Usage: ./test_databricks_connection.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Read values from terraform.tfvars
if [ -f ../terraform/terraform.tfvars ]; then
  echo -e "${YELLOW}Reading configuration from terraform.tfvars...${NC}"
  DATABRICKS_HOST=$(grep databricks_host ../terraform/terraform.tfvars | cut -d '=' -f2 | tr -d ' "' | tr -d "'")
  DATABRICKS_TOKEN=$(grep databricks_token ../terraform/terraform.tfvars | cut -d '=' -f2 | tr -d ' "' | tr -d "'")
  DATABRICKS_WAREHOUSE_ID=$(grep databricks_warehouse_id ../terraform/terraform.tfvars | cut -d '=' -f2 | tr -d ' "' | tr -d "'")
else
  echo -e "${RED}Error: terraform.tfvars not found${NC}"
  exit 1
fi

# Extract hostname from URL
DATABRICKS_URL=$(echo $DATABRICKS_HOST | sed 's/https:\/\///')

echo -e "${YELLOW}Testing connection to Databricks workspace...${NC}"
echo "Host URL: $DATABRICKS_HOST"
echo "Host: $DATABRICKS_URL"

# Check if databricks CLI is installed
if ! command -v databricks &> /dev/null; then
  echo -e "${RED}Databricks CLI is not installed.${NC}"
  echo "Please install it with: pip install databricks-cli"
  exit 1
else
  DATABRICKS_VERSION=$(databricks --version)
  echo -e "${GREEN}Databricks CLI version: $DATABRICKS_VERSION${NC}"
fi

# Test DNS resolution
echo -e "\n${YELLOW}Testing DNS resolution...${NC}"
host $DATABRICKS_URL || {
  echo -e "${RED}DNS resolution failed for $DATABRICKS_URL${NC}"
  echo "Trying with 'dig'..."
  dig $DATABRICKS_URL || {
    echo -e "${RED}DNS resolution failed with 'dig' as well${NC}"
    echo "Please check your network connection and DNS settings"
  }
}

# Test network connectivity
echo -e "\n${YELLOW}Testing network connectivity...${NC}"
curl -s --connect-timeout 5 $DATABRICKS_HOST > /dev/null
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Successfully connected to $DATABRICKS_HOST${NC}"
else
  echo -e "${RED}Failed to connect to $DATABRICKS_HOST${NC}"
  echo "Please check your network connection and firewall settings"
fi

# Test Databricks API with token
echo -e "\n${YELLOW}Testing Databricks API authentication...${NC}"
export DATABRICKS_HOST=$DATABRICKS_HOST
export DATABRICKS_TOKEN=$DATABRICKS_TOKEN

# Test with Databricks CLI
echo "Testing API with Databricks CLI..."
databricks workspace ls / > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Successfully authenticated with Databricks API${NC}"
else
  echo -e "${RED}Failed to authenticate with Databricks API${NC}"
  echo "Please check your token and host URL"
fi

# Test SQL warehouse status
echo -e "\n${YELLOW}Checking SQL warehouse status...${NC}"
databricks warehouses get $DATABRICKS_WAREHOUSE_ID > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Successfully retrieved warehouse information${NC}"
  echo "Warehouse status:"
  databricks warehouses get $DATABRICKS_WAREHOUSE_ID --output json | grep state
else
  echo -e "${RED}Failed to retrieve warehouse information${NC}"
  echo "Please check your warehouse ID and permissions"
fi

echo -e "\n${YELLOW}Connection test summary:${NC}"
echo "1. Check your network connection to Databricks"
echo "2. Verify the Databricks host URL in terraform.tfvars"
echo "3. Confirm your API token has the necessary permissions"
echo "4. Ensure the warehouse ID is correct and you have access to it"
