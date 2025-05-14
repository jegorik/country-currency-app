#############################################
# Databricks Country-Currency Application
#############################################

#----------------------------------------------
# Reference and start existing SQL warehouse
#----------------------------------------------

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

# Create schema to organize data objects
resource "databricks_schema" "schema" {
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

# Create volume to store uploaded CSV data files
resource "databricks_volume" "volume" {
  catalog_name = var.catalog_name
  schema_name  = databricks_schema.schema.name
  name         = var.volume_name
  volume_type  = "MANAGED"
  comment      = "Volume for storing country-currency CSV data files"
}

#----------------------------------------------
# Data Structure: Target Table Definition
#----------------------------------------------

# Create Delta table with schema for country-currency mapping data
resource "databricks_sql_table" "table" {
  catalog_name       = var.catalog_name
  schema_name        = databricks_schema.schema.name
  name               = var.table_name
  table_type         = "MANAGED"
  data_source_format = "DELTA"
  warehouse_id       = var.skip_validation ? var.databricks_warehouse_id : data.databricks_sql_warehouse.existing_warehouse[0].id
  comment            = "Table containing country and currency code mappings"

  # Column definitions based on CSV structure
  column {
    name    = "country_code"
    type    = "STRING"
    comment = "ISO 3166-1 alpha-3 country code"
  }
  column {
    name    = "country_number"
    type    = "INT"
    comment = "ISO 3166-1 numeric country code"
  }
  column {
    name    = "country"
    type    = "STRING"
    comment = "Country name"
  }
  column {
    name    = "currency_name"
    type    = "STRING"
    comment = "Currency name"
  }
  column {
    name    = "currency_code"
    type    = "STRING"
    comment = "ISO 4217 currency code"
  }
  column {
    name    = "currency_number"
    type    = "INT"
    comment = "ISO 4217 numeric currency code"
  }

  depends_on = [
    databricks_schema.schema, 
    null_resource.start_warehouse_windows,
    null_resource.start_warehouse_linux
  ]
}

#----------------------------------------------
# Data Upload: Source Files and Processing Logic
#----------------------------------------------

# Upload CSV file containing country-currency data to the Databricks volume
resource "databricks_file" "csv_data" {
  source = "${path.module}/../data/csv_data/country_code_to_currency_code.csv"
  path   = "/Volumes/${var.catalog_name}/${databricks_schema.schema.name}/${databricks_volume.volume.name}/data.csv"

  depends_on = [databricks_volume.volume]
}

# Create and deploy the data processing notebook to Databricks workspace
resource "databricks_notebook" "load_data_notebook" {
  source   = "${path.module}/../notebooks/load_data_notebook_jupyter.ipynb"
  path     = "/Shared/${var.app_name}/load_data_notebook"
  format   = "JUPYTER"
  language = "PYTHON"
}

#----------------------------------------------
# Data Processing: Job Setup and Execution
#----------------------------------------------

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
        schema_name    = databricks_schema.schema.name
        table_name     = databricks_sql_table.table.name
        csv_path       = databricks_file.csv_data.path
        warehouse_name = var.skip_validation ? "Mock Warehouse" : data.databricks_sql_warehouse.existing_warehouse[0].name
        warehouse_id   = var.databricks_warehouse_id
      }
    }

    # Set retry policy for job task
    retry_on_timeout = true
    max_retries      = 2
  }

  depends_on = [
    databricks_sql_table.table,
    databricks_file.csv_data,
    databricks_notebook.load_data_notebook,
    null_resource.start_warehouse_windows,
    null_resource.start_warehouse_linux
  ]
}

# Save the job ID to a file for reference
resource "local_file" "job_id_file" {
  content  = databricks_job.load_data_job.id
  filename = "${path.module}/job_id.txt"
}

#----------------------------------------------
# Job Execution: Initial Data Load Trigger
#----------------------------------------------

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
