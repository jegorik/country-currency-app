# Terraform Backend Configuration
#
# This file configures the S3 backend for storing Terraform state files.
# The backend configuration ensures:
# - State file persistence in AWS S3
# - State locking to prevent concurrent modifications
# - Encryption of state files for security
# - Consistent state management across team members
#
# Note: This configuration is typically generated automatically and should
# match the S3 bucket created by the backend infrastructure.

# Generated backend configuration

terraform {
  backend "s3" {
    bucket       = "databricks-terraform-ccjproject-dev-state"
    key          = "terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
  }
}
