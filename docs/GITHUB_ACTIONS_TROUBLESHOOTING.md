# Troubleshooting Guide

## GitHub Actions CI/CD Issues

### Catalog Does Not Exist Error

**Problem:**
When deploying to any environment, you might encounter an error like:
```
Error: cannot create schema: Catalog 'main' does not exist.

  with databricks_schema.schema,
  on main.tf line 44, in resource "databricks_schema" "schema":
  44: resource "databricks_schema" "schema" {
```

**Solution:**
This occurs when the hardcoded catalog name in the GitHub Actions workflow doesn't match an existing catalog in your Databricks workspace. To fix this:

1. **Use the catalog name from GitHub Secrets** instead of hardcoding values:
   ```yaml
   - name: Create terraform.tfvars
     run: |
       cat > terraform/terraform.tfvars <<EOF
       databricks_host         = "${{ secrets.DATABRICKS_HOST }}"
       databricks_token        = "${{ secrets.DATABRICKS_TOKEN }}"
       catalog_name            = "${{ secrets.DATABRICKS_CATALOG }}"  # Use secret instead of hardcoded value
       # Other properties...
       EOF
   ```

2. **Ensure the DATABRICKS_CATALOG secret is defined** in your GitHub repository settings with the correct catalog name for each environment.

3. **Verify the catalog exists** in your Databricks workspace before deploying.

### Duplicate Required Providers Configuration Error

**Problem:**
When running `terraform init` you might encounter the following error:
```
Error: Duplicate required providers configuration

  on versions.tf line 2, in terraform:
   2:   required_providers {

A module may have only one required providers configuration. The required
providers were previously configured at provider.tf:10,3-21.
```

**Solution:**
This error occurs when you have terraform provider configurations in multiple files. To fix:

1. **Remove the duplicate `versions.tf` file** entirely:
   ```bash
   rm terraform/versions.tf
   ```

2. **Keep provider configuration in one file** (in our case, `provider.tf`)

3. **Update the provider version** in the remaining file:
   ```terraform
   required_providers {
     databricks = {
       source  = "databricks/databricks"
       version = "1.77"  # Using the latest version
     }
   }
   ```

4. **Update the Terraform version** in GitHub Actions workflow to be compatible:
   ```yaml
   env:
     TF_VERSION: 1.5.7
     # Updated to Terraform 1.5.7 to ensure compatibility with Databricks provider 1.77
   ```

### Provider Produced Invalid Plan Error

**Problem:**
When deploying to test or production environments using GitHub Actions, you might encounter errors like:

```
Error: Provider produced invalid plan

Provider "registry.terraform.io/databricks/databricks" planned an invalid
value for databricks_sql_table.table.column[0].nullable: planned value
cty.True for a non-computed attribute.

This is a bug in the provider, which should be reported in the provider's own
issue tracker.
```

**Solution:**

This is a known issue with older versions of the Databricks Terraform provider. We implemented several fixes:

1. **Created a versions.tf file** to pin the Databricks provider to a newer version (1.6.5):
   ```terraform
   terraform {
     required_providers {
       databricks = {
         source  = "databricks/databricks"
         version = "1.6.5"
       }
     }
     required_version = ">= 1.0.0"
   }
   ```

2. **Updated Terraform version** from 1.0.0 to 1.5.7 to better support the provider.

3. **Added explicit nullable attribute** to all table column definitions in main.tf:
   ```terraform
   column {
     name     = "country_code"
     type     = "STRING"
     comment  = "ISO 3166-1 alpha-3 country code"
     nullable = false
   }
   ```

4. **Added skip_validation parameter** to avoid issues with provider validation in all environments:
   ```yaml
   databricks_host         = "${{ secrets.DATABRICKS_HOST }}"
   databricks_token        = "${{ secrets.DATABRICKS_TOKEN }}"
   # Other configuration...
   skip_validation         = true
   ```

5. **Used -upgrade flag** during `terraform init` to ensure the latest provider version is used:
   ```yaml
   - name: Terraform Init
     id: init
     run: |
       cd terraform
       terraform init -upgrade  # Force downloading the latest provider version
   ```

6. **Added debug logging** to provide more information when issues occur:
   ```yaml
   - name: Terraform Plan
     id: plan
     run: |
       cd terraform
       TF_LOG=DEBUG terraform plan -no-color -var-file=terraform.tfvars
   ```

7. **Updated provider configuration** with additional options to help with troubleshooting:
   ```terraform
   provider "databricks" {
     host                 = var.databricks_host
     token                = var.databricks_token
     skip_verify          = var.skip_validation
     debug_truncate_bytes = 2048
     debug_headers        = true
   }
   ```

If you continue to encounter issues with the provider, consider:
- Updating to the latest Terraform version
- Reporting the issue to the Databricks provider repository
- Using the mock plan generator for testing instead of the actual provider

## MD5 Attribute Issues

**Problem:**
Errors related to `md5` attributes in resources like `databricks_notebook` and `databricks_file`:

```
Error: Provider produced invalid plan

Provider "registry.terraform.io/databricks/databricks" planned an invalid
value for databricks_notebook.load_data_notebook.md5: planned value
cty.StringVal("different") for a non-computed attribute.
```

**Solution:**
This is another issue with older provider versions. The fix is to use a newer provider version through the versions.tf file as described above.
