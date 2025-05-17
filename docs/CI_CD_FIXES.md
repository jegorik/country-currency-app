# CI/CD Workflow Fixes

## Problem

The CI/CD workflow for the Country Currency App was broken due to several issues:

1. When merging from the development branch to the main branch, the CI/CD workflow attempted to deploy to test and production environments but failed because the necessary resources (schemas, volumes, and tables) didn't exist in those environments.
2. The CI/CD workflow was setting all resource creation flags to `false`, preventing the creation of required resources.
3. The release workflow was running in parallel with the CI/CD workflow, causing coordination issues.
4. Error handling was insufficient, especially when resources didn't exist.

## Solutions Implemented

### 1. Dynamic Resource Creation

We've updated the test and production deployment steps to dynamically check if resources exist and create them if they don't:

```yaml
- name: Check Resource Existence
  id: check_resources
  run: |
    echo "Checking if resources exist in test/prod environment..."
    
    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
      -X GET "${{ secrets.DATABRICKS_HOST }}/api/2.1/unity-catalog/schemas/${{ secrets.DATABRICKS_CATALOG_TEST/PROD }}.country_currency" \
      -H "Authorization: Bearer ${{ secrets.DATABRICKS_TOKEN }}")
      
    if [ "$STATUS_CODE" -eq 200 ]; then
      echo "Schema exists, using existing resources"
      echo "CREATE_SCHEMA=false" >> $GITHUB_OUTPUT
      echo "CREATE_VOLUME=false" >> $GITHUB_OUTPUT
      echo "CREATE_TABLE=false" >> $GITHUB_OUTPUT
      echo "UPLOAD_CSV=false" >> $GITHUB_OUTPUT
    else
      echo "Schema does not exist, will create resources"
      echo "CREATE_SCHEMA=true" >> $GITHUB_OUTPUT
      echo "CREATE_VOLUME=true" >> $GITHUB_OUTPUT
      echo "CREATE_TABLE=true" >> $GITHUB_OUTPUT
      echo "UPLOAD_CSV=true" >> $GITHUB_OUTPUT
    fi
```

### 2. Workflow Coordination

We've created a new release workflow (`release-fixed.yml`) that waits for the CI/CD workflow to complete before creating a release:

```yaml
wait_for_deployment:
  name: Wait for CI/CD Deployment
  runs-on: ubuntu-latest
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  steps:
    - name: Wait for CI/CD workflow
      uses: lewagon/wait-on-check-action@v1.3.1
      with:
        ref: ${{ github.ref }}
        check-name: 'deploy-prod'
        repo-token: ${{ secrets.GITHUB_TOKEN }}
        wait-interval: 20

release:
  name: Create Release
  runs-on: ubuntu-latest
  needs: [wait_for_deployment]
  # Rest of release job...
```

### 3. Improved Error Handling

We've enhanced error handling in job triggering to provide better feedback:

```yaml
- name: Trigger Data Load Job
  run: |
    # Extract job ID and trigger with proper error handling
    # ...
    if [ "$status_code" -eq 200 ]; then
      # Success handling with job status checking
    else
      # Detailed error reporting
    fi
```

### 4. Fixed Version File Handling

We've improved the handling of version extraction in the release workflow to avoid shell expansion issues.

## How to Use These Changes

1. First, replace your existing CI/CD workflow file with the updated version.
2. Replace your release workflow with the `release-fixed.yml` file.
3. When triggering a merge from development to main:
   - The CI/CD workflow will run first, checking if resources exist in each environment.
   - If resources don't exist, they'll be created automatically.
   - The workflow will trigger any necessary jobs after creating resources.
   - The release workflow will wait for the CI/CD workflow to complete before creating a release.

## Monitoring and Troubleshooting

If you continue to experience issues, check:

1. GitHub Actions logs for any error messages
2. Databricks workspace for job execution status
3. Ensure all required secrets are properly configured in GitHub
4. Verify permissions in Databricks for schema and table creation

## Security Considerations

- The workflow uses GitHub secrets for sensitive information.
- API tokens should be rotated regularly for security.
- Consider using Databricks service principals instead of personal access tokens in production.
