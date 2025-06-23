# Terraform Output Definitions
#
# This file defines outputs that provide useful information about the deployed
# infrastructure. The outputs include resource IDs, URLs, and configuration
# details that can be used by other systems or for reference.
#
# All outputs are organized in a single summary object for easy consumption.

# Output values for the Databricks Unity Catalog infrastructure
output "Databricks_deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    databricks_host   = var.databricks_host
    warehouse_id      = var.databricks_warehouse_id
    etl_job_id        = databricks_job.load_data_job.id
    etl_notebook_path = databricks_notebook.load_data_notebook.path
    catalog           = var.catalog_name
    schema            = var.schema_name
    volume            = var.volume_name
    table             = var.table_name
    full_table        = "${var.catalog_name}.${var.schema_name}.${var.table_name}"
    environment       = var.environment
    project           = var.project_name
  }
}

# Create a JSON file with connection parameters for the Streamlit app
# This file allows users to easily load deployment configuration into the app
# instead of manually entering all connection details. The token is excluded
# for security and must be provided separately by the user.
resource "local_file" "databricks_connection_config" {
  content = jsonencode({
    databricks_host = var.databricks_host
    # Note: Token is intentionally excluded for security reasons
    # Users should provide the token manually or via environment variables
    catalog_name            = var.catalog_name
    schema_name             = var.schema_name
    table_name              = var.table_name
    databricks_warehouse_id = var.databricks_warehouse_id
    environment             = var.environment
    project_name            = var.project_name
    deployment_info = {
      etl_job_id        = databricks_job.load_data_job.id
      etl_notebook_path = databricks_notebook.load_data_notebook.path
      full_table_path   = "${var.catalog_name}.${var.schema_name}.${var.table_name}"
      created_at        = timestamp()
    }
    security_note = "Token not included for security. Provide manually or via environment variables."
  })
  filename = "${path.root}/../../../streamlit/databricks_connection.json"

  # Ensure the file is created with appropriate permissions
  file_permission = "0644"
}
