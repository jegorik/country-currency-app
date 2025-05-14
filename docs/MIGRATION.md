# Migration to CI/CD Process

This document outlines the steps for migrating from manual deployments to the automated CI/CD process.

## Overview

The Country Currency App has been enhanced with a CI/CD pipeline using GitHub Actions. This transition requires some careful planning to ensure no disruption to existing environments and data.

## Script Relocation and Path Management

### Script Directory Reorganization

In May 2025, the project underwent a significant reorganization of script locations to improve maintainability and organization. Key changes included:

1. **Script Consolidation**: Scripts previously scattered throughout the project were consolidated into subdirectories under `/scripts/`:
   - `/scripts/deploy/` - Deployment scripts
   - `/scripts/setup/` - Environment setup scripts
   - `/scripts/test/` - Testing utilities
   - `/scripts/utils/` - General utility scripts
   - `/scripts/streamlit/` - Streamlit application launch scripts (relocated from `/streamlit/` directory)

2. **Path Independence**: All scripts were updated to use relative path calculations instead of hardcoded paths, making them runnable from any directory.

3. **Unified Interfaces**: Script interfaces were standardized to provide consistent command-line arguments and output formatting.

### Path Calculation Pattern

The scripts use the following pattern to determine their location and calculate paths to other project resources:

```bash
# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Calculate path to project root (2 levels up from scripts/subdirectory)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Calculate paths to specific directories
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
STREAMLIT_DIR="$PROJECT_ROOT/streamlit"
DATA_DIR="$PROJECT_ROOT/data"
```

This pattern ensures that scripts can:
- Be called from any directory
- Correctly locate other project resources
- Work consistently across different environments

### Running Relocated Scripts

When running scripts that were previously in a different location:

1. **Update your commands** to use the new path:
   ```bash
   # Old (deprecated)
   bash /streamlit/unified_start_app.sh
   
   # New
   bash /scripts/streamlit/unified_start_app.sh
   ```

2. **Update CI/CD configurations** to reference the new script locations.

3. **Check for new command-line options** as some scripts have enhanced functionality.

## Migration Steps

### 1. Preparation Phase

1. **Inventory Existing Resources**
   - Document all existing Databricks resources and their configurations
   - Export Terraform state if available: `terraform state pull > current-state.json`
   - Take screenshots of the Databricks workspace for reference

2. **Setup GitHub Repository**
   - Push existing code to GitHub
   - Configure required secrets in GitHub repository settings

3. **Test CI/CD in Isolation**
   - Create a temporary environment to validate the pipeline
   - Run a full CI/CD cycle to ensure all stages complete successfully

### 2. Development Environment Migration

1. **Import Current State (if available)**
   ```bash
   terraform init
   terraform import databricks_schema.schema "catalog_name.schema_name"
   terraform import databricks_volume.volume "catalog_name.schema_name.volume_name"
   terraform import databricks_sql_table.table "catalog_name.schema_name.table_name"
   ```

2. **Run Initial CI/CD Pipeline**
   - Trigger the GitHub Actions workflow for development environment
   - Monitor the process and validate results

3. **Verify Resources**
   - Confirm all resources match the pre-migration state
   - Run tests to ensure functionality is preserved

### 3. Test & Production Migration

1. **Test Environment Migration**
   - Schedule a maintenance window
   - Backup any critical data
   - Run the migration during low-traffic periods
   - Follow the same import steps as for development

2. **Production Migration**
   - Require explicit approval from stakeholders
   - Schedule a maintenance window with advance notification
   - Have a rollback plan prepared
   - Perform additional verification steps post-migration

### 4. Post-Migration Tasks

1. **Update Documentation**
   - Remove outdated manual deployment instructions
   - Train team members on the new CI/CD process

2. **Implement Monitoring**
   - Set up alerts for CI/CD pipeline failures
   - Configure monitoring for deployed resources

3. **Validate Security**
   - Audit access rights in GitHub and Databricks
   - Review secret management procedures

## Rollback Plan

In case the migration encounters critical issues:

1. **GitHub Actions Rollback**
   - For minor issues, fix and re-run the GitHub Actions workflow
   - For major issues, disable GitHub Actions temporarily

2. **Manual Restoration**
   - Use the documented pre-migration configuration to manually restore resources
   - Restore data from backups if needed

3. **Hybrid Approach**
   - Maintain the ability to deploy manually during the transition period
   - Keep documentation for both approaches until migration is complete

## Timeline

| Phase                | Estimated Duration | Recommended Timing        |
|----------------------|--------------------|---------------------------|
| Preparation          | 1-2 days           | Before sprint start       |
| Dev Migration        | 1 day              | Early in sprint           |
| Test Migration       | 1 day              | Mid-sprint                |
| Production Migration | 1 day              | During maintenance window |
| Post-Migration       | Ongoing            | Following sprint          |

## Success Criteria

The migration will be considered successful when:

1. All environments are successfully deployed via CI/CD
2. All functionality works as expected
3. No manual steps are required for deployment
4. Team members are comfortable with the new process
