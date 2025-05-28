# Terraform Variable Definitions for Databricks Infrastructure
#
# This file defines all input variables used by the Databricks infrastructure
# configuration. Variables are organized into logical groups:
# - Databricks connectivity (host, token, warehouse)
# - Resource configuration (catalog, schema, table, volume names)
# - Environment and project settings
# - AWS configuration
# - Feature flags for conditional resource creation
#
# All variables include validation rules and helpful descriptions to ensure
# proper configuration and reduce deployment errors.

# Databricks connectivity variables
variable "databricks_host" {
  description = "Databricks workspace URL"
  type        = string

  validation {
    condition     = can(regex("^https://", var.databricks_host))
    error_message = "Databricks host must start with https://."
  }
}

variable "databricks_token" {
  description = "Databricks personal access token"
  type        = string
  sensitive   = true
}

# Resource configuration variables
variable "catalog_name" {
  description = "Name of the Unity Catalog to use (use 'hive_metastore' for trial accounts)"
  type        = string
  default     = "hive_metastore"
}

variable "schema_name" {
  description = "Name of the schema to create"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name for resource labeling"
  type        = string
}

variable "table_name" {
  description = "Name of the table to create"
  type        = string
}

variable "volume_name" {
  description = "Name of the volume for CSV files"
  type        = string
}

variable "databricks_warehouse_id" {
  description = "ID of the existing SQL warehouse"
  type        = string
}

variable "app_name" {
  description = "Application name for resource organization"
  type        = string
  default     = "country-currency-app"
}

variable "skip_validation" {
  description = "Skip resource validation (useful for existing resources)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources for management and organization"
  type        = map(string)
  default     = {}
}

# AWS Configuration variables
variable "aws_region" {
  description = "AWS region for resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1)."
  }
}

variable "aws_profile" {
  description = "AWS CLI profile to use (optional)"
  type        = string
  default     = null
}

# Variables to control creation of resources that might already exist

variable "create_schema" {
  description = "Whether to create the schema - set to false if schema already exists"
  type        = bool
  default     = true
}

variable "create_volume" {
  description = "Whether to create the volume - set to false if volume already exists"
  type        = bool
  default     = true
}

variable "create_table" {
  description = "Whether to create the table - set to false if table already exists"
  type        = bool
  default     = true
}

variable "upload_csv" {
  description = "Whether to upload the CSV file - set to false if data already exists"
  type        = bool
  default     = true
}