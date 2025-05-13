#!/bin/bash
# Start the Streamlit application after Databricks infrastructure is created

# Set up colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   Starting Country Currency Streamlit App   ${NC}"
echo -e "${BLUE}================================================${NC}"

# Check if job_id.txt file exists
JOB_ID_FILE="../terraform/job_id.txt"
if [ ! -f "$JOB_ID_FILE" ]; then
    echo -e "${YELLOW}Job ID file not found. The app may not be able to check job status.${NC}"
    JOB_ID=""
else
    JOB_ID=$(cat "$JOB_ID_FILE")
    echo -e "${GREEN}Found Job ID: $JOB_ID${NC}"
fi

# Source variables from terraform.tfvars if it exists
TFVARS_FILE="../terraform/terraform.tfvars"
if [ ! -f "$TFVARS_FILE" ]; then
    echo -e "${RED}terraform.tfvars file not found. Cannot start Streamlit app.${NC}"
    echo "Please ensure you have run Terraform to create the infrastructure first."
    exit 1
fi

# Extract variables from terraform.tfvars
DATABRICKS_HOST=$(grep "databricks_host" "$TFVARS_FILE" | cut -d '=' -f2 | tr -d ' "')
CATALOG_NAME=$(grep "catalog_name" "$TFVARS_FILE" | cut -d '=' -f2 | tr -d ' "')
SCHEMA_NAME=$(grep "schema_name" "$TFVARS_FILE" | cut -d '=' -f2 | tr -d ' "')
TABLE_NAME=$(grep "table_name" "$TFVARS_FILE" | cut -d '=' -f2 | tr -d ' "')

echo -e "${GREEN}Using the following configuration:${NC}"
echo "Databricks Host: $DATABRICKS_HOST"
echo "Catalog: $CATALOG_NAME"
echo "Schema: $SCHEMA_NAME"
echo "Table: $TABLE_NAME"

# Check if Python and required packages are installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python 3 is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if pip is installed
if ! command -v pip &> /dev/null; then
    echo -e "${RED}pip is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if streamlit is installed
if ! python3 -c "import streamlit" &> /dev/null; then
    echo -e "${YELLOW}Streamlit is not installed. Installing requirements...${NC}"
    pip install -r requirements.txt
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install requirements.${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}Starting Streamlit app...${NC}"
echo -e "${GREEN}The app will be available at http://localhost:8501${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop the app${NC}"

# Start Streamlit app
streamlit run app.py

# Handle exit
echo -e "${BLUE}Streamlit app has stopped.${NC}"
