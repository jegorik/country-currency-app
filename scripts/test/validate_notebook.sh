#!/bin/bash

# Script to validate notebook format and syntax locally
# This script can be run before committing changes to ensure CI pipeline won't fail

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "===== Databricks Notebook Validator ====="
echo "Validating notebooks in: $SCRIPT_DIR/../notebooks"

# Make sure Python requirements are installed
echo "Checking for required Python packages..."
pip3 install --quiet jupyter nbformat || {
  echo "Failed to install required Python packages. Please install them manually:"
  echo "pip3 install jupyter nbformat"
  exit 1
}

# Run the validation script
echo "Running validation script..."
python3 "$SCRIPT_DIR/../ci/validate_notebooks.py"

# If we have Databricks credentials, we can also check the notebook on Databricks
if [ ! -z "$DATABRICKS_HOST" ] && [ ! -z "$DATABRICKS_TOKEN" ]; then
  echo "Databricks credentials found, checking notebook on Databricks..."
  
  # Get the notebook path and job ID from terraform output
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
  TERRAFORM_DIR="$PROJECT_ROOT/terraform"
  NOTEBOOK_PATH=$(cd "$TERRAFORM_DIR" && terraform output -raw notebook_path 2>/dev/null || echo "/Shared/country-currency-app/load_data_notebook")
  JOB_ID=$(cd "$TERRAFORM_DIR" && terraform output -raw job_id 2>/dev/null)
  
  if [ -z "$JOB_ID" ]; then
    echo "Note: Could not retrieve job ID from terraform output"
    echo "Will check notebook status only"
  fi

# Check if the notebook exists in Databricks
echo "Checking notebook existence at path: $NOTEBOOK_PATH"
NOTEBOOK_STATUS=$(curl -s -X GET "${DATABRICKS_HOST}/api/2.0/workspace/get-status" \
  -H "Authorization: Bearer ${DATABRICKS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"path\": \"$NOTEBOOK_PATH\"}")

if echo "$NOTEBOOK_STATUS" | grep -q "error"; then
  echo "Error: Notebook not found or access denied"
  echo "$NOTEBOOK_STATUS"
  exit 1
else
  echo "Notebook found successfully"
  echo "$NOTEBOOK_STATUS"
fi

# If we have a job ID, run the job to test notebook execution
if [ ! -z "$JOB_ID" ]; then
  echo "Triggering job $JOB_ID to validate notebook execution..."
  
  RESPONSE=$(curl -s -w "\n%%{http_code}" -X POST "${DATABRICKS_HOST}/api/2.1/jobs/run-now" \
    -H "Authorization: Bearer ${DATABRICKS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"job_id\": $JOB_ID}")
  
  STATUS_CODE=$(echo "$RESPONSE" | tail -n1)
  RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')
  
  if [ $STATUS_CODE -eq 200 ]; then
    RUN_ID=$(echo $RESPONSE_BODY | grep -o '"run_id":[0-9]*' | cut -d':' -f2)
    echo "Job triggered successfully! Run ID: $RUN_ID"
    echo "Check job status at: ${DATABRICKS_HOST}/#job/$JOB_ID/run/$RUN_ID"
    
    # Wait a bit then check job status
    echo "Waiting 30 seconds for job to start running..."
    sleep 30
    
    JOB_STATUS=$(curl -s -X GET "${DATABRICKS_HOST}/api/2.1/jobs/runs/get" \
      -H "Authorization: Bearer ${DATABRICKS_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"run_id\": $RUN_ID}")
    
    echo "Current job status:"
    echo "$JOB_STATUS" | grep -o '"state":{[^}]*}'
    
    echo "Validation complete. Please check the Databricks console for detailed results."
  else
    echo "Failed to trigger job. Status code: $STATUS_CODE"
    echo "Response: $RESPONSE_BODY"
    exit 1
  fi
else
  echo "No job ID available for testing, skipping job execution test"
fi

echo "Databricks notebook validation complete."
else
  echo "Databricks credentials not found, skipping remote validation."
fi

echo "✅ All notebooks validated successfully!"
echo "You can now commit and push your changes."
