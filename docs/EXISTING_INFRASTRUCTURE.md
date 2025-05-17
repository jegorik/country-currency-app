# Working with Existing Infrastructure

This document describes how to handle existing Databricks resources in the CI/CD pipeline.

## Background

When working with existing Databricks resources that were created outside of Terraform or in a previous deployment, 
you might encounter errors like:

```
Error: cannot create schema: Schema 'country_currency' already exists
```

This happens because Terraform tries to create resources that already exist in your Databricks environment.

## Solution: Conditional Resource Creation

To handle existing infrastructure, the Terraform configuration has been updated to make resource creation conditional:

1. New variables have been added to control whether each resource should be created:
   - `create_schema`: Controls schema creation
   - `create_volume`: Controls volume creation
   - `create_table`: Controls table creation
   - `upload_csv`: Controls CSV file upload

2. These variables default to `true` but can be set to `false` in environments where resources already exist

3. All references to these resources have been updated to handle conditional creation

## How to Use

### In CI/CD Workflows

The GitHub Actions workflows have been updated to set all resource creation flags to `false` for all environments:

```yaml
create_schema = false
create_volume = false
create_table = false
upload_csv = false
```

This configuration prevents CI/CD pipelines from trying to recreate resources that already exist, which would cause errors and pipeline failures.

### Using the Makefile

For easier management, specialized Makefile commands have been added:

```bash
# Update existing environment (plan and apply with skip flags)
make update-existing ENV=dev

# Apply changes skipping resources that might already exist
make apply-existing ENV=test
```

These commands automatically set the appropriate flags to skip creation of resources that might already exist.

### In terraform.tfvars file

You can also set these variables directly in your `terraform.tfvars` file:

```terraform
# Skip creation of resources that already exist
create_schema = false
create_volume = false
create_table = false
upload_csv = false
```

### For Local Development

When running Terraform locally, you can control resource creation with:

```bash
# To skip creation of resources that already exist
terraform apply -var="create_schema=false" -var="create_volume=false" -var="create_table=false" -var="upload_csv=false"

# To skip only specific resources
terraform apply -var="create_schema=false" -var="create_volume=false"

# To create all resources (default behavior)
terraform apply
```

## Importing Existing Resources

If you want Terraform to manage existing resources, you can import them into the Terraform state:

```bash
# Import an existing schema
terraform import databricks_schema.schema[0] "catalog_name.schema_name"

# Import an existing volume
terraform import databricks_volume.volume[0] "catalog_name.schema_name.volume_name"

# Import an existing table
terraform import databricks_sql_table.table[0] "catalog_name.schema_name.table_name"

# Import an existing file
terraform import databricks_file.csv_data[0] "/Volumes/catalog_name/schema_name/volume_name/data.csv"
```

Note: When importing resources that use the count parameter in Terraform, you need to specify the index (e.g., `[0]`) in the import command.

After importing, Terraform will manage these resources without trying to recreate them.

## Checking Existing Resources

Before deploying, you may want to check which resources already exist in your Databricks workspace. You can do this using the Databricks CLI:

```bash
# List catalogs
databricks catalogs list

# List schemas in a catalog
databricks schemas list --catalog=your_catalog_name

# List volumes in a schema
databricks volumes list --catalog=your_catalog_name --schema=your_schema_name

# List tables in a schema
databricks tables list --catalog=your_catalog_name --schema=your_schema_name
```

Alternatively, you can use the Databricks UI to explore your workspace and check existing resources.

## Handling Changes to Existing Resources

When you need to modify existing resources that Terraform is aware of:

1. If the resource was imported into Terraform state:
   - Make changes to the Terraform configuration
   - Run `terraform plan` to see the changes that will be applied
   - Run `terraform apply` to apply the changes

2. If the resource is being skipped with `create_*=false` variables:
   - Make changes manually in the Databricks workspace
   - Or consider importing the resource into Terraform state for better management

## Troubleshooting

If you encounter other "already exists" errors:

1. Check if the resource already exists in your Databricks workspace
2. Add a conditional creation pattern similar to the schema resource
3. Update all references to handle the conditional creation
4. Set the appropriate variable in your CI/CD workflow or local deployment
