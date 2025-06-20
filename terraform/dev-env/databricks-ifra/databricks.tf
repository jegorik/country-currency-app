# Terraform Configuration for Databricks Infrastructure
#
# This file creates the complete Databricks infrastructure needed for the
# country-currency mapping data pipeline including:
# - Data storage (schema, volume, table)
# - Data processing (notebook, job)
# - Cross-platform automation (Windows/Linux support)
#
# The configuration is designed to be flexible and handle existing resources
# through conditional creation flags and validation skipping options.

# Local variables for platform detection
locals {
  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
}

# Reference existing SQL warehouse to be used for data loading operations
# Use count to conditionally create this resource based on skip_validation
data "databricks_sql_warehouse" "existing_warehouse" {
  count = var.skip_validation ? 0 : 1
  id    = var.databricks_warehouse_id
}

# Windows specific resource for SQL warehouse start
resource "null_resource" "start_warehouse_windows" {
  count = (!var.skip_validation && local.is_windows) ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["powershell", "-Command"]
    command     = <<-EOT
      Write-Host "Starting SQL warehouse ${var.databricks_warehouse_id}..."
      
      $Headers = @{
        "Authorization" = "Bearer ${var.databricks_token}"
        "Content-Type" = "application/json" 
      }
      
      try {
        $Response = Invoke-RestMethod -Uri "${var.databricks_host}/api/2.0/sql/warehouses/${var.databricks_warehouse_id}/start" -Method Post -Headers $Headers
        Write-Host "SQL warehouse start request successful"
      }
      catch {
        Write-Host "Failed to start SQL warehouse. Error: $_"
        exit 1
      }
    EOT
  }
}

# Linux/Unix specific resource for SQL warehouse start
resource "null_resource" "start_warehouse_linux" {
  count = (!var.skip_validation && !local.is_windows) ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "Starting SQL warehouse ${var.databricks_warehouse_id}..."
      
      status_code=$(curl -s -o /dev/null -w "%%{http_code}" \
        -X POST "${var.databricks_host}/api/2.0/sql/warehouses/${var.databricks_warehouse_id}/start" \
        -H "Authorization: Bearer ${var.databricks_token}" \
        -H "Content-Type: application/json")
        
      if [ $status_code -eq 200 ] || [ $status_code -eq 202 ]; then
        echo "SQL warehouse start request successful"
      else
        echo "Failed to start SQL warehouse. HTTP Status: $status_code"
        exit 1
      fi
    EOT
  }
}

#----------------------------------------------
# Data Storage: Schema and Volume Creation
#----------------------------------------------

# Create schema to organize data objects (only if it doesn't already exist)
resource "databricks_schema" "schema" {
  count = var.create_schema ? 1 : 0

  catalog_name  = var.catalog_name
  name          = var.schema_name
  comment       = "Schema for country-currency mapping data in ${var.environment} environment"
  force_destroy = true

  # Optional: Add tags for better resource organization
  properties = merge(
    {
      environment = var.environment
      project     = var.project_name
    },
    var.tags
  )
}

# Create volume to store uploaded CSV data files (only if it doesn't already exist)
resource "databricks_volume" "volume" {
  count = var.create_volume ? 1 : 0

  catalog_name = var.catalog_name
  schema_name  = var.schema_name # Use the variable directly since schema might already exist
  name         = var.volume_name
  volume_type  = "MANAGED"
  comment      = "Volume for storing country-currency CSV data files"

  # Add explicit dependency on schema to ensure proper creation order
  depends_on = [
    databricks_schema.schema
  ]
}

#----------------------------------------------
# Data Structure: Target Table Definition
#----------------------------------------------

# Create Delta table with schema for country-currency mapping data (only if it doesn't already exist)
resource "databricks_sql_table" "table" {
  count = var.create_table ? 1 : 0

  catalog_name       = var.catalog_name
  schema_name        = var.schema_name # Use the variable directly instead of the resource reference
  name               = var.table_name
  table_type         = "MANAGED"
  data_source_format = "DELTA"
  warehouse_id       = var.skip_validation ? var.databricks_warehouse_id : data.databricks_sql_warehouse.existing_warehouse[0].id
  comment            = "Table containing country and currency code mappings"

  # Column definitions based on CSV structure
  column {
    name     = "country_code"
    type     = "STRING"
    comment  = "ISO 3166-1 alpha-3 country code"
    nullable = false
  }
  column {
    name     = "country_number"
    type     = "INT"
    comment  = "ISO 3166-1 numeric country code"
    nullable = false
  }
  column {
    name     = "country"
    type     = "STRING"
    comment  = "Country name"
    nullable = false
  }
  column {
    name     = "currency_name"
    type     = "STRING"
    comment  = "Currency name"
    nullable = false
  }
  column {
    name     = "currency_code"
    type     = "STRING"
    comment  = "ISO 4217 currency code"
    nullable = false
  }
  column {
    name     = "currency_number"
    type     = "INT"
    comment  = "ISO 4217 numeric currency code"
    nullable = false
  }

  depends_on = [
    # Explicit schema dependency to ensure proper creation order
    databricks_schema.schema,
    null_resource.start_warehouse_windows,
    null_resource.start_warehouse_linux
  ]
}


# Upload CSV file containing country-currency data to the Databricks volume (only if needed)
resource "databricks_file" "csv_data" {
  count = var.upload_csv ? 1 : 0

  source = "${path.module}/../../../etl_data/country_code_to_currency_code.csv"
  path   = "/Volumes/${var.catalog_name}/${var.schema_name}/${var.volume_name}/data.csv"

  # Since depends_on requires a static list, we always include the dependency but use count to control creation
  depends_on = [databricks_volume.volume]
}

# Create and deploy the data processing notebook to Databricks workspace
resource "databricks_notebook" "load_data_notebook" {
  source   = "${path.module}/../../../notebooks/load_notebook_jupyter.ipynb"
  path     = "/Shared/${var.app_name}/load_data_notebook"
  format   = "JUPYTER"
  language = "PYTHON"
}

# Create a job to load data from CSV to Delta table
resource "databricks_job" "load_data_job" {
  name = "Load Country Currency Data - ${var.environment}"

  # Add tags for filtering in Databricks UI
  tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      data        = "country-currency"
    },
    var.tags
  )

  task {
    task_key = "load_data"

    notebook_task {
      notebook_path = databricks_notebook.load_data_notebook.path
      base_parameters = {
        catalog_name   = var.catalog_name
        schema_name    = var.schema_name
        table_name     = var.table_name
        csv_path       = "/Volumes/${var.catalog_name}/${var.schema_name}/${var.volume_name}/data.csv"
        warehouse_name = var.skip_validation ? "Mock Warehouse" : data.databricks_sql_warehouse.existing_warehouse[0].name
        warehouse_id   = var.databricks_warehouse_id
      }
    }

    # Set retry policy for job task
    retry_on_timeout = true
    max_retries      = 2
  }

  depends_on = [
    # Ensure all required resources are created first
    databricks_notebook.load_data_notebook,
    databricks_schema.schema,
    databricks_volume.volume,
    databricks_sql_table.table,
    databricks_file.csv_data,
    null_resource.start_warehouse_windows,
    null_resource.start_warehouse_linux
  ]
}

# Save the job ID to a file for reference
resource "local_file" "job_id_file" {
  content  = databricks_job.load_data_job.id
  filename = "${path.module}/job_id.txt"
}

# Windows specific resource for job trigger
resource "null_resource" "trigger_job_windows" {
  count = (!var.skip_validation && local.is_windows) ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["powershell", "-Command"]
    command     = <<-EOT
      Write-Host "Waiting 5 seconds before triggering job..."
      Start-Sleep -Seconds 5
      Write-Host "Triggering job ${databricks_job.load_data_job.id} to load country-currency data..."
      
      $Headers = @{
        "Authorization" = "Bearer ${var.databricks_token}"
        "Content-Type" = "application/json"
      }
      
      $Body = @{
        "job_id" = ${databricks_job.load_data_job.id}
      } | ConvertTo-Json
      
      try {
        $Response = Invoke-RestMethod -Uri "${var.databricks_host}/api/2.1/jobs/run-now" -Method Post -Headers $Headers -Body $Body
        $RunId = $Response.run_id
        Write-Host "Job triggered successfully! Run ID: $RunId"
        Write-Host "Check job status at: ${var.databricks_host}/#job/${databricks_job.load_data_job.id}/run/$RunId"
      }
      catch {
        Write-Host "Failed to trigger job. Error: $_"
        exit 1
      }
    EOT
  }

  depends_on = [
    databricks_job.load_data_job
  ]
}

# Linux/Unix specific resource for job trigger
resource "null_resource" "trigger_job_linux" {
  count = (!var.skip_validation && !local.is_windows) ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "Waiting 5 seconds before triggering job..."
      sleep 5
      echo "Triggering job ${databricks_job.load_data_job.id} to load country-currency data..."
      
      # Create JSON payload
      payload="{\"job_id\": ${databricks_job.load_data_job.id}}"
      
      # Make API call using curl
      response=$(curl -s \
        -X POST "${var.databricks_host}/api/2.1/jobs/run-now" \
        -H "Authorization: Bearer ${var.databricks_token}" \
        -H "Content-Type: application/json" \
        -d "$payload")
        
      # Extract run_id using grep and cut (basic JSON parsing)
      run_id=$(echo $response | grep -o '"run_id":[0-9]*' | cut -d':' -f2)
      
      if [ -n "$run_id" ]; then
        echo "Job triggered successfully! Run ID: $run_id"
        echo "Check job status at: ${var.databricks_host}/#job/${databricks_job.load_data_job.id}/run/$run_id"
      else
        echo "Failed to trigger job. Response: $response"
        exit 1
      fi
    EOT
  }

  depends_on = [
    databricks_job.load_data_job
  ]
}
