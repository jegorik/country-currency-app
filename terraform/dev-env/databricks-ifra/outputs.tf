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
