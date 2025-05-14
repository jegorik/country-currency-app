#!/bin/bash

# Country Currency App Setup Script
# This script helps set up and deploy the Country Currency Application

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   Country Currency App - Setup Script   ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}[ERROR] Terraform is not installed. Please install Terraform first.${NC}"
    echo "Visit https://developer.hashicorp.com/terraform/install for installation instructions."
    exit 1
else
    TERRAFORM_VERSION=$(terraform --version | head -n 1)
    echo -e "${GREEN}✓ $TERRAFORM_VERSION${NC}"
fi

# Check Databricks CLI
if ! command -v databricks &> /dev/null; then
    echo -e "${YELLOW}[WARNING] Databricks CLI is not installed. Some features might not work.${NC}"
    echo "Visit https://docs.databricks.com/dev-tools/cli/index.html for installation instructions."
else
    DATABRICKS_VERSION=$(databricks --version)
    echo -e "${GREEN}✓ Databricks CLI: $DATABRICKS_VERSION${NC}"
fi

echo ""
echo -e "${YELLOW}Checking configuration files...${NC}"

# Check terraform.tfvars
if [ ! -f "../terraform/terraform.tfvars" ]; then
    echo -e "${RED}[ERROR] terraform.tfvars file not found!${NC}"
    echo "Please copy terraform.tfvars.example to terraform.tfvars and fill in your values."
    exit 1
else
    echo -e "${GREEN}✓ terraform.tfvars exists${NC}"
    
    # Basic validation of terraform.tfvars
    if ! grep -q "databricks_host" ../terraform/terraform.tfvars || ! grep -q "databricks_token" ../terraform/terraform.tfvars; then
        echo -e "${RED}[ERROR] terraform.tfvars is missing required variables.${NC}"
        echo "Please make sure databricks_host and databricks_token are defined."
        exit 1
    fi
fi

echo ""
echo -e "${YELLOW}Initializing Terraform...${NC}"

# Change to the terraform directory
cd ../terraform || {
    echo -e "${RED}[ERROR] Cannot find terraform directory!${NC}"
    exit 1
}

# Initialize Terraform in the terraform directory
terraform init

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Terraform initialization failed!${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Terraform initialized successfully${NC}"
fi

echo ""
echo -e "${YELLOW}Validating Terraform configuration...${NC}"
terraform validate

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Terraform validation failed!${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Terraform configuration is valid${NC}"
fi

echo ""
echo -e "${YELLOW}Generating Terraform plan...${NC}"
terraform plan -out=country_currency_app.tfplan

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Terraform plan generation failed!${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Terraform plan generated successfully${NC}"
fi

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review the Terraform plan above"
echo "2. Apply the Terraform configuration with:"
echo "   terraform apply country_currency_app.tfplan"
echo ""
echo -e "${BLUE}================================================${NC}"
