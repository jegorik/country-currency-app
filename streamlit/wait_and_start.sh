#!/bin/bash
# Wait for the Databricks job to complete and then start the Streamlit app

# Set up colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   Waiting for Databricks Job to Complete   ${NC}"
echo -e "${BLUE}================================================${NC}"

# Check if job_id.txt file exists
JOB_ID_FILE="../terraform/job_id.txt"
if [ ! -f "$JOB_ID_FILE" ]; then
    echo -e "${RED}Job ID file not found. Cannot check job status.${NC}"
    echo "Please ensure you have run Terraform to create the infrastructure first."
    exit 1
fi

JOB_ID=$(cat "$JOB_ID_FILE")
echo -e "${GREEN}Found Job ID: $JOB_ID${NC}"

# Source variables from terraform.tfvars if it exists
TFVARS_FILE="../terraform/terraform.tfvars"
if [ ! -f "$TFVARS_FILE" ]; then
    echo -e "${RED}terraform.tfvars file not found. Cannot check job status.${NC}"
    exit 1
fi

# Extract variables from terraform.tfvars
DATABRICKS_HOST=$(grep "databricks_host" "$TFVARS_FILE" | cut -d '=' -f2 | tr -d ' "')
DATABRICKS_TOKEN=$(grep "databricks_token" "$TFVARS_FILE" | cut -d '=' -f2 | tr -d ' "')

echo -e "${GREEN}Using host: $DATABRICKS_HOST${NC}"

# Function to check job status
check_job_status() {
    # Get the latest run information
    response=$(curl -s -X GET \
        "$DATABRICKS_HOST/api/2.1/jobs/runs/list" \
        -H "Authorization: Bearer $DATABRICKS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"job_id\": $JOB_ID, \"limit\": 1}")
    
    # Extract run status
    if ! echo "$response" | grep -q "runs"; then
        echo -e "${RED}Failed to get job runs. API response:${NC}"
        echo "$response"
        return 2 # Error
    fi
    
    # Get the latest run state
    run_id=$(echo "$response" | grep -o '"run_id":[0-9]*' | head -1 | cut -d':' -f2)
    state=$(echo "$response" | grep -o '"state":{[^}]*}' | grep -o '"life_cycle_state":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    result_state=$(echo "$response" | grep -o '"state":{[^}]*}' | grep -o '"result_state":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    
    echo -e "${YELLOW}Run ID: $run_id, State: $state, Result: $result_state${NC}"
    
    # Return status code
    if [ "$state" == "TERMINATED" ]; then
        if [ "$result_state" == "SUCCESS" ]; then
            return 0 # Success
        else
            return 1 # Failed
        fi
    else
        return 3 # Still running
    fi
}

# Wait for job completion
echo -e "${YELLOW}Checking job status...${NC}"
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    echo -e "${BLUE}Attempt $attempt of $max_attempts${NC}"
    
    check_job_status
    status=$?
    
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}Job completed successfully!${NC}"
        break
    elif [ $status -eq 1 ]; then
        echo -e "${RED}Job failed.${NC}"
        echo "Check the Databricks console for details."
        exit 1
    elif [ $status -eq 2 ]; then
        echo -e "${RED}Error checking job status.${NC}"
        exit 1
    else
        echo -e "${YELLOW}Job is still running. Waiting 10 seconds before checking again...${NC}"
        sleep 10
    fi
    
    attempt=$((attempt+1))
done

if [ $attempt -gt $max_attempts ]; then
    echo -e "${YELLOW}Maximum attempts reached. Job may still be running.${NC}"
    echo "Do you want to start the Streamlit app anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Exiting."
        exit 1
    fi
fi

# Start the Streamlit app
echo -e "${GREEN}Starting Streamlit app...${NC}"
bash ./start_app.sh
