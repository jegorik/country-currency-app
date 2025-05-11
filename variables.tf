#############################################
# Country Currency App - Variable Definitions
#############################################

#----------------------------------------------
# Environment Configuration
#----------------------------------------------

variable "environment" {
  description = "Deployment environment (e.g., dev, test, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "project_name" {
  description = "Name of the project for resource labeling"
  type        = string
}

#----------------------------------------------
# Databricks Connection Parameters
#----------------------------------------------

variable "databricks_host" {
  description = "Databricks workspace URL (e.g., https://adb-123456789.0.azuredatabricks.net)"
  type        = string
  validation {
    condition     = can(regex("^https://", var.databricks_host))
    error_message = "Databricks host must start with https://"
  }
}

variable "databricks_token" {
  description = "Databricks personal access token for authentication"
  type        = string
  sensitive   = true
}

#----------------------------------------------
# Databricks Resources
#----------------------------------------------

variable "databricks_warehouse_id" {
  description = "ID of the existing Databricks SQL warehouse to use for data processing"
  type        = string
}

variable "catalog_name" {
  description = "Name of the Unity Catalog catalog to create resources in"
  type        = string
}

variable "schema_name" {
  description = "Name of the schema to create for country-currency data"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.schema_name))
    error_message = "Schema name must contain only alphanumeric characters and underscores."
  }
}

variable "table_name" {
  description = "Name of the table to store country-currency mapping data"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.table_name))
    error_message = "Table name must contain only alphanumeric characters and underscores."
  }
}

variable "volume_name" {
  description = "Name of the volume to store CSV data files"
  type        = string
}

variable "app_name" {
  description = "Name of the Databricks application for resource organization"
  type        = string
}

#----------------------------------------------
# Resource Tagging
#----------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources for management and organization"
  type        = map(string)
  default = {
    owner       = "data_engineering"
    application = "country_currency_app"
    managed_by  = "terraform"
  }
}