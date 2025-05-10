# Reference existing SQL warehouse
data "databricks_sql_warehouse" "existing_warehouse" {
  id = var.databricks_warehouse_id
}

# Start SQL warehouse using Databricks CLI
resource "null_resource" "start_warehouse" {
  provisioner "local-exec" {
    command = "databricks warehouses start ${var.databricks_warehouse_id}"
  }
}

# Create schema
resource "databricks_schema" "schema" {
  catalog_name  = var.catalog_name
  name          = var.schema_name
  comment       = "Schema for country-currency data in ${var.environment}"
  force_destroy = true
}

# Create volume
resource "databricks_volume" "volume" {
  catalog_name = var.catalog_name
  schema_name  = databricks_schema.schema.name
  name         = var.volume_name
  volume_type  = "MANAGED"
  comment      = "Volume for storing CSV data"
}

# Create table
resource "databricks_sql_table" "table" {
  catalog_name       = var.catalog_name
  schema_name        = databricks_schema.schema.name
  name               = var.table_name
  table_type         = "MANAGED"
  data_source_format = "DELTA"
  warehouse_id       = data.databricks_sql_warehouse.existing_warehouse.id

  column {
    name = "country_code"
    type = "STRING"
  }
  column {
    name = "country_number"
    type = "INT"
  }
  column {
    name = "country"
    type = "STRING"
  }
  column {
    name = "currency_name"
    type = "STRING"
  }
  column {
    name = "currency_code"
    type = "STRING"
  }
  column {
    name = "currency_number"
    type = "INT"
  }

  depends_on = [databricks_schema.schema, null_resource.start_warehouse]
}

# Upload CSV file to volume
resource "databricks_file" "csv_data" {
  source = "${path.module}/csv_data/country_code_to_currency_code.csv"
  path   = "/Volumes/${var.catalog_name}/${databricks_schema.schema.name}/${databricks_volume.volume.name}/data.csv"

  depends_on = [databricks_volume.volume]
}

# Create notebook in workspace
resource "databricks_notebook" "load_data_notebook" {
  source = "${path.module}/notebooks/load_data_notebook.py"
  path   = "/Shared/load_data_notebook"
}

# Run notebook to load data
resource "databricks_job" "load_data_job" {
  name = "Load Country Currency Data"

  task {
    task_key = "load_data"

    notebook_task {
      notebook_path = databricks_notebook.load_data_notebook.path
      base_parameters = {
        catalog_name   = var.catalog_name
        schema_name    = databricks_schema.schema.name
        table_name     = databricks_sql_table.table.name
        csv_path       = databricks_file.csv_data.path
        warehouse_name = data.databricks_sql_warehouse.existing_warehouse.name
        warehouse_id   = data.databricks_sql_warehouse.existing_warehouse.id
      }
    }
  }

  depends_on = [
    databricks_sql_table.table,
    databricks_file.csv_data,
    databricks_notebook.load_data_notebook,
    null_resource.start_warehouse
  ]
}

# Auto execute write data to the table script in databricks workflows jobs
resource "null_resource" "trigger_job" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "${var.databricks_host}/api/2.1/jobs/run-now" \
        -H "Authorization: Bearer ${var.databricks_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "job_id": ${databricks_job.load_data_job.id}
        }'
    EOT
  }

  depends_on = [
    databricks_job.load_data_job
  ]
}
