# Troubleshooting Guide

## GitHub Actions CI/CD Issues

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
