#!/bin/bash

# Deployment automation script for the Country Currency Mapping Data Pipeline
#
# This shell script automates the deployment of the Databricks infrastructure
# and data pipeline. It provides options for deploying backend infrastructure,
# main Databricks resources, or both components together.
#
# Usage:
#   ./deploy.sh -a <action> [-e <environment>] [-v <vars_file>]
#
# Parameters:
#   -a, --action      The deployment action to perform:
#                     - "backend" - Deploy only the S3 backend infrastructure
#                     - "databricks" - Deploy only the Databricks infrastructure
#                     - "all" - Deploy both backend and Databricks infrastructure
#                     - "destroy" - Destroy all infrastructure (use with caution)
#   -e, --environment The target environment (dev, staging, prod). Default is "dev"
#   -v, --vars-file   Name of the terraform.tfvars file. Default is "terraform.tfvars"
#   -h, --help        Show this help message
#
# Examples:
#   ./deploy.sh -a all -e dev
#   ./deploy.sh -a backend -v terraform-prod.tfvars
#
# Author: Data Engineering Team
# Last Updated: June 19, 2025
# Requires: Terraform >= 1.0, AWS CLI configured, Databricks access

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Default values
ACTION=""
ENVIRONMENT="dev"
TERRAFORM_VARS_FILE="terraform.tfvars"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    cat << EOF
Usage: $0 -a <action> [-e <environment>] [-v <vars_file>]

Parameters:
  -a, --action      The deployment action to perform:
                    - "backend" - Deploy only the S3 backend infrastructure
                    - "databricks" - Deploy only the Databricks infrastructure
                    - "all" - Deploy both backend and Databricks infrastructure
                    - "destroy" - Destroy all infrastructure (use with caution)
  -e, --environment The target environment (dev, staging, prod). Default is "dev"
  -v, --vars-file   Name of the terraform.tfvars file. Default is "terraform.tfvars"
  -h, --help        Show this help message

Examples:
  $0 -a all -e dev
  $0 -a backend -v terraform-prod.tfvars
EOF
}

# Function to write colored output
write_color_output() {
    local message="$1"
    local color="${2:-$WHITE}"
    echo -e "${color}${message}${NC}"
}

# Function to parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--action)
                ACTION="$2"
                if [[ ! "$ACTION" =~ ^(backend|databricks|all|destroy)$ ]]; then
                    write_color_output "❌ Invalid action: $ACTION. Must be one of: backend, databricks, all, destroy" "$RED"
                    exit 1
                fi
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
                    write_color_output "❌ Invalid environment: $ENVIRONMENT. Must be one of: dev, staging, prod" "$RED"
                    exit 1
                fi
                shift 2
                ;;
            -v|--vars-file)
                TERRAFORM_VARS_FILE="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                write_color_output "❌ Unknown option: $1" "$RED"
                usage
                exit 1
                ;;
        esac
    done

    if [[ -z "$ACTION" ]]; then
        write_color_output "❌ Action parameter is required" "$RED"
        usage
        exit 1
    fi
}

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"
BACKEND_DIR="$TERRAFORM_DIR/$ENVIRONMENT-env/backend"
DATABRICKS_DIR="$TERRAFORM_DIR/$ENVIRONMENT-env/databricks-ifra"

# Function to find terraform vars file
find_vars_file() {
    # Check if the vars file has a path separator, if not, look for it in both directories
    if [[ "$TERRAFORM_VARS_FILE" != *"/"* ]]; then
        # Try to find the vars file in the backend directory first, then databricks directory
        local backend_vars_file="$BACKEND_DIR/$TERRAFORM_VARS_FILE"
        local databricks_vars_file="$DATABRICKS_DIR/$TERRAFORM_VARS_FILE"
        
        if [[ -f "$backend_vars_file" ]]; then
            VARS_FILE="$backend_vars_file"
        elif [[ -f "$databricks_vars_file" ]]; then
            VARS_FILE="$databricks_vars_file"
        else
            # Default to the old behavior for backwards compatibility
            VARS_FILE="$TERRAFORM_DIR/$TERRAFORM_VARS_FILE"
        fi
    else
        # User provided a path, use it as-is relative to script directory
        VARS_FILE="$SCRIPT_DIR/$TERRAFORM_VARS_FILE"
    fi
}

# Function to check prerequisites
check_prerequisites() {
    write_color_output "🔍 Checking prerequisites..." "$YELLOW"
    
    # Check if Terraform is installed
    if command -v terraform &> /dev/null; then
        local terraform_version=$(terraform version | head -n1)
        write_color_output "✅ Terraform found: $terraform_version" "$GREEN"
    else
        write_color_output "❌ Terraform not found. Please install Terraform >= 1.0" "$RED"
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if command -v aws &> /dev/null; then
        local aws_version=$(aws --version | cut -d' ' -f1)
        write_color_output "✅ AWS CLI found: $aws_version" "$GREEN"
    else
        write_color_output "❌ AWS CLI not found. Please install and configure AWS CLI" "$RED"
        exit 1
    fi
    
    # Check if terraform.tfvars exists
    if [[ ! -f "$VARS_FILE" ]]; then
        write_color_output "❌ Terraform variables file not found: $VARS_FILE" "$RED"
        write_color_output "Please copy terraform.tfvars.example to terraform.tfvars and configure it" "$YELLOW"
        exit 1
    fi
    
    write_color_output "✅ All prerequisites met" "$GREEN"
}

# Function to deploy backend infrastructure
deploy_backend() {
    write_color_output "🚀 Deploying backend infrastructure..." "$CYAN"
    
    cd "$BACKEND_DIR"
    
    # Use backend-specific vars file if it exists, otherwise use the discovered vars file
    local backend_vars_file="$BACKEND_DIR/$TERRAFORM_VARS_FILE"
    local actual_vars_file
    if [[ -f "$backend_vars_file" ]]; then
        actual_vars_file="$backend_vars_file"
    else
        actual_vars_file="$VARS_FILE"
    fi
    
    write_color_output "Using variables file: $actual_vars_file" "$GRAY"
    
    write_color_output "Initializing Terraform..." "$YELLOW"
    terraform init
    
    write_color_output "Planning deployment..." "$YELLOW"
    terraform plan -var-file="$actual_vars_file"
    
    write_color_output "Applying configuration..." "$YELLOW"
    terraform apply -var-file="$actual_vars_file" -auto-approve
    
    if [[ $? -eq 0 ]]; then
        write_color_output "✅ Backend infrastructure deployed successfully" "$GREEN"
    else
        write_color_output "❌ Backend deployment failed" "$RED"
        exit 1
    fi
}

# Function to deploy Databricks infrastructure
deploy_databricks() {
    write_color_output "🚀 Deploying Databricks infrastructure..." "$CYAN"
    
    cd "$DATABRICKS_DIR"
    
    # Use databricks-specific vars file if it exists, otherwise use the discovered vars file
    local databricks_vars_file="$DATABRICKS_DIR/$TERRAFORM_VARS_FILE"
    local actual_vars_file
    if [[ -f "$databricks_vars_file" ]]; then
        actual_vars_file="$databricks_vars_file"
    else
        actual_vars_file="$VARS_FILE"
    fi
    
    write_color_output "Using variables file: $actual_vars_file" "$GRAY"
    
    write_color_output "Initializing Terraform..." "$YELLOW"
    terraform init
    
    write_color_output "Planning deployment..." "$YELLOW"
    terraform plan -var-file="$actual_vars_file"
    
    write_color_output "Applying configuration..." "$YELLOW"
    terraform apply -var-file="$actual_vars_file" -auto-approve
    
    if [[ $? -eq 0 ]]; then
        write_color_output "✅ Databricks infrastructure deployed successfully" "$GREEN"
        
        # Display outputs
        write_color_output "📊 Deployment Summary:" "$CYAN"
        terraform output
    else
        write_color_output "❌ Databricks deployment failed" "$RED"
        exit 1
    fi
}

# Function to destroy infrastructure
destroy_infrastructure() {
    write_color_output "⚠️  DESTROYING INFRASTRUCTURE - This action cannot be undone!" "$RED"
    read -p "Type 'DESTROY' to confirm destruction: " confirmation
    
    if [[ "$confirmation" != "DESTROY" ]]; then
        write_color_output "❌ Destruction cancelled" "$YELLOW"
        exit 0
    fi
    
    # Destroy Databricks infrastructure first
    write_color_output "🗑️  Destroying Databricks infrastructure..." "$RED"
    cd "$DATABRICKS_DIR"
    local databricks_vars_file="$DATABRICKS_DIR/$TERRAFORM_VARS_FILE"
    local actual_vars_file
    if [[ -f "$databricks_vars_file" ]]; then
        actual_vars_file="$databricks_vars_file"
    else
        actual_vars_file="$VARS_FILE"
    fi
    terraform destroy -var-file="$actual_vars_file" -auto-approve
    
    # Destroy backend infrastructure
    write_color_output "🗑️  Destroying backend infrastructure..." "$RED"
    cd "$BACKEND_DIR"
    local backend_vars_file="$BACKEND_DIR/$TERRAFORM_VARS_FILE"
    if [[ -f "$backend_vars_file" ]]; then
        actual_vars_file="$backend_vars_file"
    else
        actual_vars_file="$VARS_FILE"
    fi
    terraform destroy -var-file="$actual_vars_file" -auto-approve
    
    write_color_output "✅ Infrastructure destroyed" "$GREEN"
}

# Function to cleanup on exit
cleanup() {
    # Return to original directory
    cd "$SCRIPT_DIR"
}

# Set trap for cleanup
trap cleanup EXIT

# Main execution
main() {
    parse_args "$@"
    find_vars_file
    
    write_color_output "🎯 Starting deployment process..." "$CYAN"
    write_color_output "Action: $ACTION" "$WHITE"
    write_color_output "Environment: $ENVIRONMENT" "$WHITE"
    write_color_output "Variables file: $VARS_FILE" "$WHITE"
    write_color_output "----------------------------------------" "$WHITE"
    
    # Check prerequisites
    check_prerequisites
    
    # Execute requested action
    case "$ACTION" in
        "backend")
            deploy_backend
            ;;
        "databricks")
            deploy_databricks
            ;;
        "all")
            deploy_backend
            deploy_databricks
            ;;
        "destroy")
            destroy_infrastructure
            ;;
    esac
    
    write_color_output "🎉 Deployment process completed successfully!" "$GREEN"
}

# Run main function with all arguments
main "$@"
