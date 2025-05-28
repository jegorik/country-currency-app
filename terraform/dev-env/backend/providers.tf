# Backend Infrastructure Provider Configuration
#
# This file configures the AWS provider specifically for backend infrastructure
# (S3 bucket for Terraform state storage). It includes:
# - Required provider specifications with version constraints
# - AWS provider configuration with region settings
#
# This configuration is separate from the main Databricks infrastructure
# to allow independent management of state storage resources.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.98.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}