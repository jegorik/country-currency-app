
# Output values provide useful information about resources that were created

output "schema_id" {
  description = "ID of the created Databricks schema"
  value       = var.create_schema ? databricks_schema.schema[0].id : "${var.catalog_name}.${var.schema_name}"
}

output "table_id" {
  description = "ID of the created country-currency table"
  value       = var.create_table ? databricks_sql_table.table[0].id : "${var.catalog_name}.${var.schema_name}.${var.table_name}"
}

output "job_id" {
  description = "ID of the data loading job"
  value       = databricks_job.load_data_job.id
}

output "job_url" {
  description = "URL to access the data loading job in Databricks UI"
  value       = "${var.databricks_host}/#job/${databricks_job.load_data_job.id}"
}

output "table_full_name" {
  description = "Fully qualified name of the created table"
  value       = "${var.catalog_name}.${var.schema_name}.${var.table_name}"
}

output "volume_path" {
  description = "Path to the volume where CSV data is stored"
  value       = var.upload_csv ? databricks_file.csv_data[0].path : "/Volumes/${var.catalog_name}/${var.schema_name}/${var.volume_name}/data.csv"
}

output "notebook_path" {
  description = "Path to the deployed notebook in Databricks workspace"
  value       = databricks_notebook.load_data_notebook.path
}
