variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "databricks_host" {
  description = "Databricks workspace URL"
  type        = string
}

variable "databricks_token" {
  description = "Databricks API token"
  type        = string
  sensitive   = true
}

variable "databricks_warehouse_id" {
  description = "ID of the Databricks SQL warehouse"
  type        = string
}

variable "catalog_name" {
  description = "Name of the catalog"
  type        = string
}

variable "schema_name" {
  description = "Name of the schema"
  type        = string
}

variable "table_name" {
  description = "Name of the table"
  type        = string
}

variable "volume_name" {
  description = "Name of the volume"
  type        = string
}

variable "app_name" {
  description = "Name of the Databricks app"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}