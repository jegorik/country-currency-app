# Terraform Provider Configuration
#
# This file configures the required providers for the Databricks infrastructure:
# - Databricks provider: For creating and managing Databricks resources
# - AWS provider: For any AWS-specific resources or configurations
#
# Provider versions are pinned to ensure consistent behavior across deployments.

terraform {
  required_version = ">= 1.0"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.81.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.98.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "databricks" {
  host  = var.databricks_host
  token = var.databricks_token
}