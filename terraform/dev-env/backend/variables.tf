# Backend Infrastructure Variable Definitions
#
# This file defines variables specific to the backend infrastructure
# (S3 bucket for Terraform state storage). Variables include:
# - Project and application naming
# - Environment configuration
# - AWS region settings
# - Resource tagging options
#
# These variables ensure consistent naming and organization across
# all backend resources.

variable "project_name" {
  description = "Project name for resource labeling"
  type        = string
}

variable "app_name" {
  description = "Application name for resource organization"
  type        = string
  default     = "country-currency-app"
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