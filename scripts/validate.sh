#!/bin/bash
#
# Validation script for the Country Currency Mapping Data Pipeline
#
# This bash script validates the deployment and configuration of the
# Databricks infrastructure and data pipeline. It checks resource status,
# data integrity, and configuration correctness.
#
# Usage:
#   ./validate.sh [OPTIONS]
#
# Options:
#   -e, --environment ENV    The target environment (dev, staging, prod). Default is "dev"
#   -f, --tfvars-file FILE   Name of the terraform.tfvars file. Default is "terraform.tfvars"
#   -d, --check-data         Whether to perform data validation checks. Default is true
#   --no-check-data         Skip data validation checks
#   -h, --help              Show this help message
#
# Examples:
#   ./validate.sh --environment dev --check-data
#   ./validate.sh -e prod -f terraform-prod.tfvars
#   ./validate.sh --no-check-data
#
# Author: Data Engineering Team
# Last Updated: June 19, 2025
# Requires: Terraform >= 1.0, Databricks CLI (optional)

set -euo pipefail

# Default values
ENVIRONMENT="dev"
TERRAFORM_VARS_FILE="terraform.tfvars"
CHECK_DATA=true

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"
DATA_FILE="${SCRIPT_DIR}/../etl_data/country_code_to_currency_code.csv"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Validation results
declare -A VALIDATION_RESULTS=(
    ["Prerequisites"]="false"
    ["BackendState"]="false"
    ["DatabricksState"]="false"
    ["DataFile"]="false"
    ["Configuration"]="false"
)

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Validation script for the Country Currency Mapping Data Pipeline

OPTIONS:
    -e, --environment ENV    The target environment (dev, staging, prod). Default is "dev"
    -f, --tfvars-file FILE   Name of the terraform.tfvars file. Default is "terraform.tfvars"
    -d, --check-data         Whether to perform data validation checks. Default is true
    --no-check-data         Skip data validation checks
    -h, --help              Show this help message

EXAMPLES:
    $0 --environment dev --check-data
    $0 -e prod -f terraform-prod.tfvars
    $0 --no-check-data

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
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -f|--tfvars-file)
                TERRAFORM_VARS_FILE="$2"
                shift 2
                ;;
            -d|--check-data)
                CHECK_DATA=true
                shift
                ;;
            --no-check-data)
                CHECK_DATA=false
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Validate environment
    case "$ENVIRONMENT" in
        dev|staging|prod)
            ;;
        *)
            echo "Error: Invalid environment '$ENVIRONMENT'"
            usage
            exit 1
            ;;
    esac
}

# Function to find terraform vars file
find_vars_file() {
    local backend_dir="${TERRAFORM_DIR}/${ENVIRONMENT}-env/backend"
    local databricks_dir="${TERRAFORM_DIR}/${ENVIRONMENT}-env/databricks-ifra"
    
    # Check if the vars file has a path separator
    if [[ "$TERRAFORM_VARS_FILE" == *"/"* ]]; then
        # User provided a path, use it as-is relative to script directory
        VARS_FILE="${SCRIPT_DIR}/${TERRAFORM_VARS_FILE}"
    else
        # Try to find the vars file in the backend directory first, then databricks directory
        local backend_vars_file="${backend_dir}/${TERRAFORM_VARS_FILE}"
        local databricks_vars_file="${databricks_dir}/${TERRAFORM_VARS_FILE}"
        
        if [[ -f "$backend_vars_file" ]]; then
            VARS_FILE="$backend_vars_file"
        elif [[ -f "$databricks_vars_file" ]]; then
            VARS_FILE="$databricks_vars_file"
        else
            # Default to the old behavior for backwards compatibility
            VARS_FILE="${TERRAFORM_DIR}/${TERRAFORM_VARS_FILE}"
        fi
    fi
}

# Function to check prerequisites
check_prerequisites() {
    write_color_output "🔍 Validating prerequisites..." "$YELLOW"
    
    local all_good=true
    
    # Check Terraform
    if terraform version &>/dev/null; then
        local terraform_version=$(terraform version | head -n1)
        write_color_output "✅ Terraform: $terraform_version" "$GREEN"
    else
        write_color_output "❌ Terraform not found or not working" "$RED"
        all_good=false
    fi
    
    # Check AWS CLI
    if aws --version &>/dev/null; then
        local aws_version=$(aws --version | cut -d' ' -f1)
        write_color_output "✅ AWS CLI: $aws_version" "$GREEN"
    else
        write_color_output "❌ AWS CLI not found or not configured" "$RED"
        all_good=false
    fi
    
    # Check variables file
    if [[ -f "$VARS_FILE" ]]; then
        write_color_output "✅ Variables file found: $VARS_FILE" "$GREEN"
    else
        write_color_output "❌ Variables file not found: $VARS_FILE" "$RED"
        all_good=false
    fi
    
    if [[ "$all_good" == "true" ]]; then
        VALIDATION_RESULTS["Prerequisites"]="true"
    fi
}

# Function to validate backend state
validate_backend_state() {
    write_color_output "🔍 Validating backend infrastructure..." "$YELLOW"
    
    local backend_dir="${TERRAFORM_DIR}/${ENVIRONMENT}-env/backend"
    
    if [[ ! -d "$backend_dir" ]]; then
        write_color_output "⚠️  Backend directory not found" "$YELLOW"
        return 1
    fi
    
    cd "$backend_dir"
    
    # Check if Terraform is initialized
    if [[ ! -d ".terraform" ]]; then
        write_color_output "⚠️  Backend Terraform not initialized" "$YELLOW"
        return 1
    fi
    
    # Check Terraform state
    if terraform show -json &>/dev/null; then
        local resource_count=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources | length' 2>/dev/null || echo "0")
        
        if [[ "$resource_count" -gt 0 ]]; then
            write_color_output "✅ Backend state valid - Resources deployed" "$GREEN"
            
            # Show backend resources
            local resources=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[].type' 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//' || echo "unknown")
            write_color_output "   Resources: $resources" "$GRAY"
            
            VALIDATION_RESULTS["BackendState"]="true"
        else
            write_color_output "❌ Backend state shows no resources" "$RED"
            return 1
        fi
    else
        write_color_output "❌ Backend validation failed: Cannot read Terraform state" "$RED"
        return 1
    fi
}

# Function to validate Databricks infrastructure
validate_databricks_state() {
    write_color_output "🔍 Validating Databricks infrastructure..." "$YELLOW"
    
    local databricks_dir="${TERRAFORM_DIR}/${ENVIRONMENT}-env/databricks-ifra"
    
    if [[ ! -d "$databricks_dir" ]]; then
        write_color_output "⚠️  Databricks directory not found" "$YELLOW"
        return 1
    fi
    
    cd "$databricks_dir"
    
    # Check if Terraform is initialized
    if [[ ! -d ".terraform" ]]; then
        write_color_output "⚠️  Databricks Terraform not initialized" "$YELLOW"
        return 1
    fi
    
    # Check Terraform state
    if terraform show -json &>/dev/null; then
        local resource_count=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.resources | length' 2>/dev/null || echo "0")
        
        if [[ "$resource_count" -gt 0 ]]; then
            write_color_output "✅ Databricks state valid - Resources deployed" "$GREEN"
            
            # Count different resource types
            if command -v jq &>/dev/null; then
                terraform show -json 2>/dev/null | jq -r '.values.root_module.resources | group_by(.type) | .[] | "\(.[0].type): \(length)"' 2>/dev/null | while read line; do
                    write_color_output "   $line" "$GRAY"
                done
            else
                write_color_output "   Resources: $resource_count" "$GRAY"
            fi
            
            VALIDATION_RESULTS["DatabricksState"]="true"
        else
            write_color_output "❌ Databricks state shows no resources" "$RED"
            return 1
        fi
    else
        write_color_output "❌ Databricks validation failed: Cannot read Terraform state" "$RED"
        return 1
    fi
}

# Function to validate data file
validate_data_file() {
    write_color_output "🔍 Validating data file..." "$YELLOW"
    
    if [[ ! -f "$DATA_FILE" ]]; then
        write_color_output "❌ Data file not found: $DATA_FILE" "$RED"
        return 1
    fi
    
    # Basic file validation
    local record_count=$(tail -n +2 "$DATA_FILE" | wc -l)
    local header_line=$(head -n 1 "$DATA_FILE")
    
    write_color_output "✅ Data file found: $DATA_FILE" "$GREEN"
    write_color_output "   Records: $record_count" "$GRAY"
    write_color_output "   Columns: $header_line" "$GRAY"
    
    # Validate required columns
    local required_columns=("country_code" "country_number" "country" "currency_name" "currency_code" "currency_number")
    local missing_columns=()
    
    for col in "${required_columns[@]}"; do
        if ! echo "$header_line" | grep -q "$col"; then
            missing_columns+=("$col")
        fi
    done
    
    if [[ ${#missing_columns[@]} -eq 0 ]]; then
        write_color_output "✅ All required columns present" "$GREEN"
        
        # Basic data quality checks (check for empty required fields)
        local null_country_code=$(awk -F',' 'NR>1 && ($1=="" || $1=="NULL" || $1=="null") {count++} END {print count+0}' "$DATA_FILE")
        local null_currency_code=$(awk -F',' 'NR>1 && ($5=="" || $5=="NULL" || $5=="null") {count++} END {print count+0}' "$DATA_FILE")
        
        if [[ "$null_country_code" -eq 0 && "$null_currency_code" -eq 0 ]]; then
            write_color_output "✅ No null values in key columns" "$GREEN"
            VALIDATION_RESULTS["DataFile"]="true"
        else
            write_color_output "⚠️  Found null values - Country: $null_country_code, Currency: $null_currency_code" "$YELLOW"
            return 1
        fi
    else
        local missing_str=$(IFS=,; echo "${missing_columns[*]}")
        write_color_output "❌ Missing required columns: $missing_str" "$RED"
        return 1
    fi
}

# Function to validate configuration
validate_configuration() {
    write_color_output "🔍 Validating configuration..." "$YELLOW"
    
    local backend_dir="${TERRAFORM_DIR}/${ENVIRONMENT}-env/backend"
    local databricks_dir="${TERRAFORM_DIR}/${ENVIRONMENT}-env/databricks-ifra"
    local backend_vars_file="${backend_dir}/${TERRAFORM_VARS_FILE}"
    local databricks_vars_file="${databricks_dir}/${TERRAFORM_VARS_FILE}"
    
    local all_found_config=()
    
    # Read backend configuration
    if [[ -f "$backend_vars_file" ]]; then
        while IFS='' read -r line || [[ -n "$line" ]]; do
            # Skip comments and empty lines
            if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "${line// }" ]]; then
                if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*= ]]; then
                    all_found_config+=("${BASH_REMATCH[1]}")
                fi
            fi
        done < "$backend_vars_file"
    fi
    
    # Read databricks configuration
    if [[ -f "$databricks_vars_file" ]]; then
        while IFS='' read -r line || [[ -n "$line" ]]; do
            # Skip comments and empty lines
            if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "${line// }" ]]; then
                if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*= ]]; then
                    all_found_config+=("${BASH_REMATCH[1]}")
                fi
            fi
        done < "$databricks_vars_file"
    fi
    
    # Remove duplicates
    local unique_config=($(printf '%s\n' "${all_found_config[@]}" | sort -u))
    
    # Check for key configuration items
    local required_config=(
        "databricks_host"
        "databricks_token"
        "databricks_warehouse_id"
        "catalog_name"
        "schema_name"
        "table_name"
        "volume_name"
        "aws_region"
    )
    
    local missing_config=()
    for req_config in "${required_config[@]}"; do
        local found=false
        for found_config in "${unique_config[@]}"; do
            if [[ "$found_config" == "$req_config" ]]; then
                found=true
                break
            fi
        done
        if [[ "$found" == "false" ]]; then
            missing_config+=("$req_config")
        fi
    done
    
    if [[ ${#missing_config[@]} -eq 0 ]]; then
        write_color_output "✅ All required configuration parameters found" "$GREEN"
        write_color_output "   Configured parameters: ${#unique_config[@]}" "$GRAY"
        VALIDATION_RESULTS["Configuration"]="true"
    else
        local missing_str=$(IFS=,; echo "${missing_config[*]}")
        write_color_output "❌ Missing configuration parameters: $missing_str" "$RED"
        return 1
    fi
}

# Function to display validation summary
show_validation_summary() {
    write_color_output "\n📊 Validation Summary" "$CYAN"
    write_color_output "=====================" "$CYAN"
    
    local passed_count=0
    local total_count=${#VALIDATION_RESULTS[@]}
    
    for test in "${!VALIDATION_RESULTS[@]}"; do
        local status
        local color
        if [[ "${VALIDATION_RESULTS[$test]}" == "true" ]]; then
            status="✅ PASS"
            color="$GREEN"
            ((passed_count++))
        else
            status="❌ FAIL"
            color="$RED"
        fi
        
        write_color_output "$test: $status" "$color"
    done
    
    write_color_output "\nOverall Result: $passed_count/$total_count tests passed" "$WHITE"
    
    if [[ $passed_count -eq $total_count ]]; then
        write_color_output "🎉 All validations passed! The pipeline is ready." "$GREEN"
        return 0
    else
        write_color_output "⚠️  Some validations failed. Please review and fix issues." "$YELLOW"
        return 1
    fi
}

# Main execution
main() {
    parse_args "$@"
    find_vars_file
    
    write_color_output "🎯 Starting validation process..." "$CYAN"
    write_color_output "Environment: $ENVIRONMENT" "$WHITE"
    write_color_output "Backend config: ${TERRAFORM_DIR}/${ENVIRONMENT}-env/backend/${TERRAFORM_VARS_FILE}" "$WHITE"
    write_color_output "Databricks config: ${TERRAFORM_DIR}/${ENVIRONMENT}-env/databricks-ifra/${TERRAFORM_VARS_FILE}" "$WHITE"
    write_color_output "Data validation: $CHECK_DATA" "$WHITE"
    write_color_output "========================================" "$WHITE"
    
    # Run validations
    check_prerequisites
    validate_configuration
    
    local backend_dir="${TERRAFORM_DIR}/${ENVIRONMENT}-env/backend"
    if [[ -d "$backend_dir" ]]; then
        validate_backend_state || true
    else
        write_color_output "⚠️  Backend directory not found, skipping backend validation" "$YELLOW"
    fi
    
    local databricks_dir="${TERRAFORM_DIR}/${ENVIRONMENT}-env/databricks-ifra"
    if [[ -d "$databricks_dir" ]]; then
        validate_databricks_state || true
    else
        write_color_output "⚠️  Databricks directory not found, skipping Databricks validation" "$YELLOW"
    fi
    
    if [[ "$CHECK_DATA" == "true" ]]; then
        validate_data_file || true
    fi
    
    # Show summary and exit with appropriate code
    if show_validation_summary; then
        exit 0
    else
        exit 1
    fi
}

# Trap to ensure we return to the original directory
trap 'cd "$SCRIPT_DIR"' EXIT

# Run main function with all arguments
main "$@"
