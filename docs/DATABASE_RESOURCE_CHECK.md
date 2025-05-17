# Database Resource Check Workflow

This document describes the GitHub Actions workflow that ensures proper database schema, volume, and table creation during deployment to Test and Prod environments.

## Overview

The `db-resource-check.yml` workflow is designed to check for the existence of required database resources (schema, volume, and tables) and create them if they don't exist. This workflow runs when merging to the main branch or can be triggered manually.

## Workflow Trigger

The workflow is triggered by:
- Push to the main branch
- Manual workflow dispatch (with environment selection)

## Workflow Jobs

The workflow consists of two main jobs:

1. **check-and-create-resources**: Checks for existing resources and creates them if they don't exist
2. **deploy**: Deploys the application to the environment after resources are checked/created

## Resource Check and Creation Process

The workflow follows this process for each environment (Test and Prod):

### 1. Check for Existing Schema

The workflow first checks if the required database schema exists:

```bash
databricks schemas list --catalog=$CATALOG_NAME
```

If the schema exists, the workflow proceeds to the next step. If not, it creates the schema using Terraform:

```terraform
create_schema = true
```

### 2. Check for Existing Volume

After ensuring the schema exists, the workflow checks if the necessary volume is present:

```bash
databricks volumes list --catalog=$CATALOG_NAME --schema=$SCHEMA_NAME
```

If the volume exists, the workflow continues. If it is missing, it creates the volume using Terraform:

```terraform
create_volume = true
```

### 3. Check for Existing Tables

Finally, the workflow assesses if the required tables within the schema exist:

```bash
databricks tables list --catalog=$CATALOG_NAME --schema=$SCHEMA_NAME
```

If the tables are found, the workflow completes without making any changes. If not, it creates the required tables using Terraform:

```terraform
create_table = true
```

## Error Handling

The workflow includes appropriate error handling to manage potential issues during the checks or creation processes:

- Each check command captures both stdout and stderr
- The exit code is checked to determine if the command was successful
- If a check command fails, the workflow logs the error but continues execution
- Terraform commands include proper error handling and reporting

## Deployment Steps

After the resource check and creation process, the workflow deploys the application to the environment:

1. **For Test Environment**:
   - Applies Terraform configuration
   - Triggers the data load job to populate the tables

2. **For Prod Environment**:
   - Applies Terraform configuration
   - Does not automatically trigger the data load job (manual trigger required)

## Usage

### Automatic Execution

The workflow automatically runs when code is merged to the main branch, ensuring that all required database resources exist in both Test and Prod environments.

### Manual Execution

You can also manually trigger the workflow:

1. Go to the "Actions" tab in GitHub
2. Select the "Database Resource Check and Creation" workflow
3. Click "Run workflow"
4. Select the target environment (Test or Prod)
5. Click "Run workflow"

## Benefits

This workflow provides several benefits:

1. **Automated Resource Management**: Automatically checks and creates database resources, reducing manual intervention
2. **Consistent Environments**: Ensures that Test and Prod environments have the same database structure
3. **Error Prevention**: Prevents deployment failures due to missing database resources
4. **Visibility**: Provides clear logs of resource status and creation activities
5. **Separation of Concerns**: Separates resource creation from application deployment

## Troubleshooting

If the workflow fails, check the following:

1. **Databricks CLI Configuration**: Ensure the Databricks CLI is properly configured with the correct host and token
2. **Catalog Permissions**: Verify that the Databricks token has the necessary permissions to list and create resources
3. **Terraform Configuration**: Check the Terraform configuration for any errors
4. **Resource Naming**: Ensure that the resource names match the expected values