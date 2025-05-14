#!/bin/bash
# Wait for the Databricks job to complete and then start the Streamlit app

# Ensure we use the latest SSL/TLS settings for curl
export CURL_SSL_VERSION=TLSv1.2

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

# Test connection to Databricks
echo -e "${YELLOW}Testing connection to Databricks...${NC}"
test_response=$(curl -s -o /dev/null -w "%{http_code}" \
    "$DATABRICKS_HOST/api/2.0/workspace/list" \
    -H "Authorization: Bearer $DATABRICKS_TOKEN" \
    -H "Content-Type: application/json" \
    --connect-timeout 10)

if [ "$test_response" == "200" ]; then
    echo -e "${GREEN}Connection to Databricks successful.${NC}"
else
    echo -e "${RED}Unable to connect to Databricks. HTTP status: $test_response${NC}"
    echo -e "${YELLOW}Will start the Streamlit app without waiting for job completion.${NC}"
    
    # Start the Streamlit app
    echo -e "${GREEN}Starting Streamlit app...${NC}"
    bash "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/start_app.sh"
    exit 0
fi

# Function to check job status
check_job_status() {
    # Add retry logic for network issues
    network_retries=3
    network_retry_count=0
    network_retry_delay=5
    
    while [ $network_retry_count -lt $network_retries ]; do
        # Get the latest run information with timeout
        response=$(curl -s -X GET \
            "$DATABRICKS_HOST/api/2.1/jobs/runs/list" \
            -H "Authorization: Bearer $DATABRICKS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"job_id\": $JOB_ID, \"limit\": 1}" \
            --connect-timeout 15 \
            --max-time 30)
        
        curl_exit_code=$?
        
        # Check for curl errors (network issues)
        if [ $curl_exit_code -ne 0 ]; then
            network_retry_count=$((network_retry_count+1))
            if [ $network_retry_count -lt $network_retries ]; then
                echo -e "${YELLOW}Network error occurred: curl exit code $curl_exit_code${NC}"
                echo -e "${YELLOW}Retrying in $network_retry_delay seconds... (Attempt $network_retry_count of $network_retries)${NC}"
                sleep $network_retry_delay
                network_retry_delay=$((network_retry_delay*2))  # Exponential backoff
            else
                echo -e "${RED}Network connection failed after $network_retries attempts${NC}"
                return 4 # Network error
            fi
            continue
        fi
        
        # Extract run status
        if ! echo "$response" | grep -q "runs"; then
            # Check if it's an auth error
            if echo "$response" | grep -q "error_code"; then
                error_code=$(echo "$response" | grep -o '"error_code":"[^"]*"' | cut -d':' -f2 | tr -d '"')
                error_message=$(echo "$response" | grep -o '"message":"[^"]*"' | cut -d':' -f2 | tr -d '"')
                echo -e "${RED}API Error: $error_code - $error_message${NC}"
            else 
                echo -e "${RED}Failed to get job runs. API response:${NC}"
                echo "$response"
            fi
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
        
        # If we reach here, we had a successful API call, so exit the retry loop
        break
    done
}

# Wait for job completion
echo -e "${YELLOW}Checking job status...${NC}"
max_attempts=30
attempt=1
retry_delay=10

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
        echo -e "${YELLOW}Do you want to start the Streamlit app anyway? (y/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo "Exiting."
            exit 1
        else
            break  # Continue to start the app
        fi
    elif [ $status -eq 2 ]; then
        echo -e "${RED}Error checking job status.${NC}"
        echo -e "${YELLOW}Do you want to retry? (Y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^([nN][oO]|[nN])$ ]]; then
            echo "Starting app without waiting for job completion."
            break
        else
            echo -e "${YELLOW}Retrying...${NC}"
            continue
        fi
    elif [ $status -eq 4 ]; then
        echo -e "${RED}Network error connecting to Databricks.${NC}"
        echo -e "${YELLOW}Do you want to retry? (Y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^([nN][oO]|[nN])$ ]]; then
            echo "Starting app without waiting for job completion."
            break
        else
            echo -e "${YELLOW}Retrying in $retry_delay seconds...${NC}"
            sleep $retry_delay
            retry_delay=$((retry_delay*2))  # Exponential backoff (max 80 seconds)
            if [ $retry_delay -gt 80 ]; then
                retry_delay=80
            fi
        fi
    else
        echo -e "${YELLOW}Job is still running. Waiting 10 seconds before checking again...${NC}"
        sleep 10
    fi
    
    attempt=$((attempt+1))
done

if [ $attempt -gt $max_attempts ]; then
    echo -e "${YELLOW}Maximum attempts reached. Job may still be running.${NC}"
    echo -e "${YELLOW}This could be because:${NC}"
    echo -e " - The Databricks job is taking longer than expected"
    echo -e " - The job is stuck or queued"
    echo -e " - There might be connectivity issues with the Databricks workspace"
    echo -e "\n${YELLOW}Do you want to start the Streamlit app anyway? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Exiting."
        exit 1
    fi
fi

# Start the Streamlit app
echo -e "${GREEN}Starting Streamlit app...${NC}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
START_APP_PATH="$SCRIPT_DIR/start_app.sh"

if [ ! -f "$START_APP_PATH" ]; then
    echo -e "${RED}Error: start_app.sh not found at $START_APP_PATH${NC}"
    echo -e "${YELLOW}Attempting to run streamlit directly...${NC}"
    cd "$SCRIPT_DIR" && python -m streamlit run app.py
    exit $?
fi

echo -e "${GREEN}Running: $START_APP_PATH${NC}"
bash "$START_APP_PATH"
