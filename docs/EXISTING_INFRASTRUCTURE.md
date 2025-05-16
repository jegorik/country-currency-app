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

To handle existing infrastructure, the Terraform configuration has been updated to make schema creation conditional:

1. A new variable `create_schema` has been added to control whether the schema should be created
2. This variable defaults to `true` but can be set to `false` in environments where the schema already exists
3. All references to the schema have been updated to handle the conditional creation

## How to Use

### In CI/CD Workflows

The GitHub Actions workflows have been updated to set `create_schema = false` for all environments,
assuming that schemas have been created in previous deployments.

### For Local Development

When running Terraform locally, you can control schema creation with:

```bash
# To skip schema creation because it already exists
terraform apply -var="create_schema=false"

# To create the schema (default behavior)
terraform apply
```

## Importing Existing Resources

If you want Terraform to manage existing resources, you can import them into the Terraform state:

```bash
# Import an existing schema
terraform import databricks_schema.schema "catalog_name.schema_name"

# Import other resources as needed
terraform import databricks_table.table "catalog_name.schema_name.table_name"
```

After importing, Terraform will manage these resources without trying to recreate them.

## Troubleshooting

If you encounter other "already exists" errors:

1. Check if the resource already exists in your Databricks workspace
2. Add a conditional creation pattern similar to the schema resource
3. Update all references to handle the conditional creation
4. Set the appropriate variable in your CI/CD workflow or local deployment
