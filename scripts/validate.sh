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
# Last Updated: June 20, 2025
# Requires: Terraform >= 1.0, AWS CLI, Databricks CLI (optional)

set -euo pipefail

# Default values
ENVIRONMENT="dev"
TERRAFORM_VARS_FILE="terraform.tfvars"
CHECK_DATA=true

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform/"
DATA_FILE="${SCRIPT_DIR}/../etl_data/country_code_to_currency_code.csv"

# Global variable for found vars file
VARS_FILE=""

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
    local env_root_dir="${TERRAFORM_DIR}/${ENVIRONMENT}-env"
    
    # Initialize VARS_FILE as empty
    VARS_FILE=""
    
    # Case 1: User provided a path (contains "/")
    if [[ "$TERRAFORM_VARS_FILE" == *"/"* ]]; then
        local user_provided_path="${SCRIPT_DIR}/${TERRAFORM_VARS_FILE}"
        if [[ -f "$user_provided_path" ]]; then
            VARS_FILE="$user_provided_path"
            write_color_output "📁 Using user-provided vars file: $VARS_FILE" "$CYAN"
        else
            write_color_output "❌ User-provided vars file not found: $user_provided_path" "$RED"
            exit 1
        fi
    # Case 2: User provided filename only (e.g., terraform.tfvars or terraform-prod.tfvars)
    elif [[ "$TERRAFORM_VARS_FILE" != "terraform.tfvars" ]]; then
        # User provided a specific filename, look for it in standard locations
        local backend_vars_file="${backend_dir}/${TERRAFORM_VARS_FILE}"
        local databricks_vars_file="${databricks_dir}/${TERRAFORM_VARS_FILE}"
        local env_root_vars_file="${env_root_dir}/${TERRAFORM_VARS_FILE}"
        
        if [[ -f "$backend_vars_file" ]]; then
            VARS_FILE="$backend_vars_file"
        elif [[ -f "$databricks_vars_file" ]]; then
            VARS_FILE="$databricks_vars_file"
        elif [[ -f "$env_root_vars_file" ]]; then
            VARS_FILE="$env_root_vars_file"
        else
            write_color_output "❌ Specified vars file '$TERRAFORM_VARS_FILE' not found in any standard location" "$RED"
            exit 1
        fi
        write_color_output "📁 Using specified vars file: $VARS_FILE" "$CYAN"
    # Case 3: Default behavior (no specific file provided)
    else
        # Look for terraform.tfvars in multiple locations and collect all valid files
        local found_files=()
        
        # Check backend directory
        if [[ -f "${backend_dir}/${TERRAFORM_VARS_FILE}" ]]; then
            found_files+=("${backend_dir}/${TERRAFORM_VARS_FILE}")
        fi
        
        # Check databricks directory
        if [[ -f "${databricks_dir}/${TERRAFORM_VARS_FILE}" ]]; then
            found_files+=("${databricks_dir}/${TERRAFORM_VARS_FILE}")
        fi
        
        # Check environment root directory
        if [[ -f "${env_root_dir}/${TERRAFORM_VARS_FILE}" ]]; then
            found_files+=("${env_root_dir}/${TERRAFORM_VARS_FILE}")
        fi
        
        if [[ ${#found_files[@]} -eq 0 ]]; then
            # No files found, set to first preference for error reporting
            VARS_FILE="${backend_dir}/${TERRAFORM_VARS_FILE}"
            write_color_output "⚠️  No terraform.tfvars files found in standard locations" "$YELLOW"
        else
            # Files found - we'll use all of them for configuration validation
            VARS_FILE="${found_files[0]}"  # Set primary file for prerequisites check
            write_color_output "📁 Found terraform.tfvars files: ${#found_files[@]}" "$CYAN"
            for file in "${found_files[@]}"; do
                write_color_output "   - $file" "$GRAY"
            done
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
        
        # Check AWS credentials
        if aws sts get-caller-identity &>/dev/null; then
            local aws_account=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
            local aws_region=$(aws configure get region 2>/dev/null || echo "not-set")
            write_color_output "✅ AWS credentials configured (Account: $aws_account, Region: $aws_region)" "$GREEN"
        else
            write_color_output "❌ AWS credentials not configured" "$RED"
            all_good=false
        fi
    else
        write_color_output "❌ AWS CLI not found or not configured" "$RED"
        all_good=false
    fi
    
    # Check Databricks CLI
    if databricks --version &>/dev/null; then
        local databricks_version=$(databricks --version 2>/dev/null)
        write_color_output "✅ Databricks CLI: $databricks_version" "$GREEN"
    else
        write_color_output "⚠️  Databricks CLI not found" "$YELLOW"
        write_color_output "   Install with: pip install databricks-cli" "$GRAY"
        write_color_output "   This is optional but recommended for full validation" "$GRAY"
    fi
    
    # Check jq for JSON parsing
    if command -v jq &>/dev/null; then
        write_color_output "✅ jq JSON processor available" "$GREEN"
    else
        write_color_output "⚠️  jq not found - JSON parsing will be limited" "$YELLOW"
        write_color_output "   Install with: sudo apt-get install jq (Ubuntu) or brew install jq (macOS)" "$GRAY"
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

# Function to validate backend state using AWS CLI
validate_backend_state() {
    write_color_output "🔍 Validating backend infrastructure..." "$YELLOW"
    
    local backend_dir="${TERRAFORM_DIR}/${ENVIRONMENT}-env/backend"
    
    if [[ ! -d "$backend_dir" ]]; then
        write_color_output "⚠️  Backend directory not found" "$YELLOW"
        return 1
    fi
    
    # Read backend configuration to get S3 bucket name
    local backend_config_file="${TERRAFORM_DIR}/${ENVIRONMENT}-env/databricks-ifra/backend-config.tf"
    local bucket_name=""
    
    if [[ -f "$backend_config_file" ]]; then
        bucket_name=$(grep -o 'bucket[[:space:]]*=[[:space:]]*"[^"]*"' "$backend_config_file" | sed 's/.*"\([^"]*\)".*/\1/')
        write_color_output "   Found S3 backend bucket: $bucket_name" "$GRAY"
    fi
    
    # If bucket name not found in backend-config.tf, try to construct it from s3-bucket.tf
    if [[ -z "$bucket_name" ]]; then
        local s3_bucket_file="${backend_dir}/s3-bucket.tf"
        if [[ -f "$s3_bucket_file" ]]; then
            # Extract bucket name pattern from s3-bucket.tf
            local bucket_pattern=$(grep -o 'bucket[[:space:]]*=[[:space:]]*"[^"]*"' "$s3_bucket_file" | sed 's/.*"\([^"]*\)".*/\1/')
            if [[ "$bucket_pattern" == *'${var.environment}'* ]]; then
                bucket_name=$(echo "$bucket_pattern" | sed "s/\${var.environment}/$ENVIRONMENT/g")
                write_color_output "   Constructed bucket name: $bucket_name" "$GRAY"
            fi
        fi
    fi
    
    if [[ -z "$bucket_name" ]]; then
        write_color_output "❌ Could not determine S3 bucket name" "$RED"
        return 1
    fi
    
    # Check if S3 bucket exists using AWS CLI
    if aws s3api head-bucket --bucket "$bucket_name" &>/dev/null; then
        write_color_output "✅ S3 backend bucket exists: $bucket_name" "$GREEN"
        
        # Check if bucket has versioning enabled
        local versioning_status=$(aws s3api get-bucket-versioning --bucket "$bucket_name" --query Status --output text 2>/dev/null)
        if [[ "$versioning_status" == "Enabled" ]]; then
            write_color_output "✅ S3 bucket versioning enabled" "$GREEN"
        else
            write_color_output "⚠️  S3 bucket versioning not enabled" "$YELLOW"
        fi
        
        # Check if bucket has encryption
        if aws s3api get-bucket-encryption --bucket "$bucket_name" &>/dev/null; then
            write_color_output "✅ S3 bucket encryption enabled" "$GREEN"
        else
            write_color_output "⚠️  S3 bucket encryption not configured" "$YELLOW"
        fi
        
        # Check if terraform state file exists in bucket
        if aws s3api head-object --bucket "$bucket_name" --key "terraform.tfstate" &>/dev/null; then
            write_color_output "✅ Terraform state file exists in S3" "$GREEN"
            
            # Get state file info
            local last_modified=$(aws s3api head-object --bucket "$bucket_name" --key "terraform.tfstate" --query LastModified --output text 2>/dev/null)
            local file_size=$(aws s3api head-object --bucket "$bucket_name" --key "terraform.tfstate" --query ContentLength --output text 2>/dev/null)
            write_color_output "   Last modified: $last_modified" "$GRAY"
            write_color_output "   Size: $file_size bytes" "$GRAY"
        else
            write_color_output "⚠️  Terraform state file not found in S3" "$YELLOW"
            write_color_output "   Resources may not have been deployed yet" "$GRAY"
        fi
        
        VALIDATION_RESULTS["BackendState"]="true"
    else
        write_color_output "❌ S3 backend bucket not found: $bucket_name" "$RED"
        write_color_output "   Backend infrastructure may not be deployed" "$GRAY"
        return 1
    fi
}

# Function to validate Databricks infrastructure using Databricks CLI
validate_databricks_state() {
    write_color_output "🔍 Validating Databricks infrastructure..." "$YELLOW"
    
    local databricks_dir="${TERRAFORM_DIR}/${ENVIRONMENT}-env/databricks-ifra"
    
    if [[ ! -d "$databricks_dir" ]]; then
        write_color_output "⚠️  Databricks directory not found" "$YELLOW"
        return 1
    fi
    
    # Read Databricks configuration from terraform.tfvars
    local databricks_vars_file="${databricks_dir}/terraform.tfvars"
    local databricks_host=""
    local databricks_token=""
    local catalog_name=""
    local schema_name=""
    local table_name=""
    local volume_name=""
    
    if [[ -f "$databricks_vars_file" ]]; then
        databricks_host=$(grep "^[[:space:]]*databricks_host[[:space:]]*=" "$databricks_vars_file" | cut -d'=' -f2 | tr -d ' "' | head -n1)
        databricks_token=$(grep "^[[:space:]]*databricks_token[[:space:]]*=" "$databricks_vars_file" | cut -d'=' -f2 | tr -d ' "' | head -n1)
        catalog_name=$(grep "^[[:space:]]*catalog_name[[:space:]]*=" "$databricks_vars_file" | cut -d'=' -f2 | tr -d ' "' | head -n1)
        schema_name=$(grep "^[[:space:]]*schema_name[[:space:]]*=" "$databricks_vars_file" | cut -d'=' -f2 | tr -d ' "' | head -n1)
        table_name=$(grep "^[[:space:]]*table_name[[:space:]]*=" "$databricks_vars_file" | cut -d'=' -f2 | tr -d ' "' | head -n1)
        volume_name=$(grep "^[[:space:]]*volume_name[[:space:]]*=" "$databricks_vars_file" | cut -d'=' -f2 | tr -d ' "' | head -n1)
        
        # Clean up databricks_host - remove all control characters, quotes, spaces, and trailing slashes
        databricks_host=$(echo "$databricks_host" | tr -d '\r\n\t' | tr -d '"' | tr -d ' ' | sed 's:/*$::')
        databricks_token=$(echo "$databricks_token" | tr -d '\r\n\t' | tr -d '"' | tr -d ' ')
        
        # Ensure https:// prefix
        if [[ ! "$databricks_host" =~ ^https?:// ]]; then
            databricks_host="https://$databricks_host"
        fi
        
        # Remove any trailing slash that might have been added back
        databricks_host=$(echo "$databricks_host" | sed 's:/*$::')
        
        write_color_output "   Databricks host: $databricks_host" "$GRAY"
        write_color_output "   Catalog: $catalog_name" "$GRAY"
        write_color_output "   Schema: $schema_name" "$GRAY"
    else
        write_color_output "❌ Databricks variables file not found" "$RED"
        return 1
    fi
    
    if [[ -z "$databricks_host" || -z "$databricks_token" ]]; then
        write_color_output "❌ Databricks host or token not configured" "$RED"
        return 1
    fi
    
    # Check if Databricks CLI is available
    if ! command -v databricks &>/dev/null; then
        write_color_output "⚠️  Databricks CLI not available - skipping detailed checks" "$YELLOW"
        write_color_output "   Basic connectivity test only" "$GRAY"
        
        # Basic connectivity test with curl
        if curl -s --connect-timeout 10 "$databricks_host" &>/dev/null; then
            write_color_output "✅ Databricks host is reachable" "$GREEN"
            VALIDATION_RESULTS["DatabricksState"]="true"
        else
            write_color_output "⚠️  Databricks host connectivity check failed" "$YELLOW"
            write_color_output "   This might be normal if behind firewall/VPN" "$GRAY"
        fi
        return 0
    fi
    
    # Configure Databricks CLI temporarily
    export DATABRICKS_HOST="$databricks_host"
    export DATABRICKS_TOKEN="$databricks_token"
    
    # Debug: Show cleaned values
    write_color_output "   Debug - Cleaned host: '$databricks_host'" "$GRAY"
    write_color_output "   Debug - Token length: ${#databricks_token} chars" "$GRAY"
    
    # Test Databricks connectivity with more specific error handling
    write_color_output "   Testing Databricks connectivity..." "$GRAY"
    if databricks current-user me &>/dev/null; then
        write_color_output "✅ Databricks connectivity verified" "$GREEN"
        
        # Get current user info for additional validation
        local user_email=$(databricks current-user me --output json 2>/dev/null | jq -r '.emails[0].value // "unknown"' 2>/dev/null || echo "unknown")
        write_color_output "   Connected as: $user_email" "$GRAY"
    else
        write_color_output "❌ Cannot connect to Databricks workspace" "$RED"
        write_color_output "   Check databricks_host and databricks_token values" "$GRAY"
        
        # Additional debugging information
        write_color_output "   Debug info:" "$GRAY"
        write_color_output "   - Host: $databricks_host" "$GRAY"
        write_color_output "   - Token length: ${#databricks_token} characters" "$GRAY"
        write_color_output "   - Host hex dump: $(echo -n "$databricks_host" | hexdump -C | head -n1)" "$GRAY"
        
        # Try a simple API call to get more specific error
        local error_output=$(databricks current-user me 2>&1 | head -n1)
        write_color_output "   - Error: $error_output" "$GRAY"
        return 1
    fi
    
     # Check if catalog exists
    if [[ -n "$catalog_name" ]]; then
        # Clean up catalog name to remove any hidden characters
        catalog_name=$(echo "$catalog_name" | tr -d '\r\n\t' | tr -d '"' | tr -d ' ')
        
        if databricks catalogs get "$catalog_name" &>/dev/null; then
            write_color_output "✅ Catalog exists: $catalog_name" "$GREEN"
            
            # Check if schema exists
            if [[ -n "$schema_name" ]]; then
                # Clean up schema name
                schema_name=$(echo "$schema_name" | tr -d '\r\n\t' | tr -d '"' | tr -d ' ')
                
                if databricks schemas get "${catalog_name}.${schema_name}" &>/dev/null; then
                    write_color_output "✅ Schema exists: ${catalog_name}.${schema_name}" "$GREEN"
                    
                    # Check if table exists
                    if [[ -n "$table_name" ]]; then
                        table_name=$(echo "$table_name" | tr -d '\r\n\t' | tr -d '"' | tr -d ' ')
                        if databricks tables get "${catalog_name}.${schema_name}.${table_name}" &>/dev/null; then
                            write_color_output "✅ Table exists: ${catalog_name}.${schema_name}.${table_name}" "$GREEN"
                        else
                            write_color_output "⚠️  Table not found: ${catalog_name}.${schema_name}.${table_name}" "$YELLOW"
                        fi
                    fi
                else
                    write_color_output "⚠️  Schema not found: ${catalog_name}.${schema_name}" "$YELLOW"
                fi
            fi
            
            # Check if volume exists
            if [[ -n "$volume_name" ]]; then
                volume_name=$(echo "$volume_name" | tr -d '\r\n\t' | tr -d '"' | tr -d ' ')
                
                # Try to get volume info using the full three-part name
                if databricks volumes get "${catalog_name}.${schema_name}.${volume_name}" &>/dev/null; then
                    write_color_output "✅ Volume exists: ${catalog_name}.${schema_name}.${volume_name}" "$GREEN"
                else
                    # Fallback: check if volume exists in the schema's volume list
                    local volume_check=$(databricks volumes list "$catalog_name" "$schema_name" --output json 2>/dev/null | jq -r ".[].name" 2>/dev/null | grep "^${volume_name}$" || echo "")
                    if [[ -n "$volume_check" ]]; then
                        write_color_output "✅ Volume exists: ${catalog_name}.${schema_name}.${volume_name}" "$GREEN"
                    else
                        write_color_output "⚠️  Volume not found: ${catalog_name}.${schema_name}.${volume_name}" "$YELLOW"
                        
                        # Debug: Show available volumes
                        local available_volumes=$(databricks volumes list "$catalog_name" "$schema_name" --output json 2>/dev/null | jq -r '.[].name' 2>/dev/null | head -3 | tr '\n' ', ' | sed 's/,$//' || echo "unable to list")
                        if [[ "$available_volumes" != "unable to list" ]]; then
                            write_color_output "   Available volumes: $available_volumes" "$GRAY"
                        fi
                    fi
                fi
            fi
        else
            write_color_output "⚠️  Catalog not found: $catalog_name" "$YELLOW"
            write_color_output "   Databricks resources may not be deployed yet" "$GRAY"
            
            # Debug: Show what catalogs are available
            write_color_output "   Available catalogs:" "$GRAY"
            local available_catalogs=$(databricks catalogs list --output json 2>/dev/null | jq -r '.[].name' 2>/dev/null | head -5 | tr '\n' ', ' | sed 's/,$//' || echo "unable to list")
            write_color_output "   $available_catalogs" "$GRAY"
        fi
    fi
    
    # List some workspace resources to verify deployment
    local workspace_count=$(databricks workspace list / 2>/dev/null | wc -l || echo "0")
    write_color_output "   Workspace objects: $workspace_count" "$GRAY"
    
    VALIDATION_RESULTS["DatabricksState"]="true"
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
    local env_root_dir="${TERRAFORM_DIR}/${ENVIRONMENT}-env"
    
    local all_found_config=()
    
    # Case 1: User provided a specific path or filename
    if [[ "$TERRAFORM_VARS_FILE" == *"/"* ]] || [[ "$TERRAFORM_VARS_FILE" != "terraform.tfvars" ]]; then
        # Read from the single determined vars file
        if [[ -f "$VARS_FILE" ]]; then
            while IFS='' read -r line || [[ -n "$line" ]]; do
                # Skip comments and empty lines
                if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "${line// }" ]]; then
                    if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*= ]]; then
                        all_found_config+=("${BASH_REMATCH[1]}")
                    fi
                fi
            done < "$VARS_FILE"
        fi
    # Case 2: Default behavior - read from all available terraform.tfvars files
    else
        local vars_files_to_check=(
            "${backend_dir}/${TERRAFORM_VARS_FILE}"
            "${databricks_dir}/${TERRAFORM_VARS_FILE}"
            "${env_root_dir}/${TERRAFORM_VARS_FILE}"
        )
        
        for vars_file in "${vars_files_to_check[@]}"; do
            if [[ -f "$vars_file" ]]; then
                while IFS='' read -r line || [[ -n "$line" ]]; do
                    # Skip comments and empty lines
                    if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "${line// }" ]]; then
                        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*= ]]; then
                            all_found_config+=("${BASH_REMATCH[1]}")
                        fi
                    fi
                done < "$vars_file"
            fi
        done
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
        write_color_output "   Searched in configuration files based on provided parameters" "$GRAY"
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