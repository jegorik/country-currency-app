#!/bin/bash
# Linux deployment script for Country Currency App
# This script handles the deployment process specifically for Linux environments

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Display header
echo -e "${CYAN}=============================================="
echo -e "Country Currency App - Linux Deployment"
echo -e "==============================================${NC}"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
PREREQUISITES=("terraform" "curl" "grep" "sed")
MISSING_PREREQUISITES=false

for TOOL in "${PREREQUISITES[@]}"; do
    if ! command -v "$TOOL" &> /dev/null; then
        echo -e "${RED}✗ $TOOL is not installed${NC}"
        MISSING_PREREQUISITES=true
    else
        echo -e "${GREEN}✓ $TOOL is installed${NC}"
    fi
done

if [ "$MISSING_PREREQUISITES" = true ]; then
    echo -e "${RED}Please install missing prerequisites and try again.${NC}"
    exit 1
fi

# Navigate to Terraform directory
cd "$(dirname "$0")/../terraform" || { echo -e "${RED}Failed to navigate to terraform directory${NC}"; exit 1; }

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
