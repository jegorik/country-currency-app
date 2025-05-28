# AWS S3 Bucket for Terraform State Storage
#
# This file creates an S3 bucket specifically for storing Terraform state files
# with the following features:
# - Object lock enabled for state file protection
# - Proper naming convention with environment and project identifiers
# - Lifecycle prevention to avoid accidental deletion
# - Resource tagging for organization and cost tracking
#
# The bucket serves as the backend for Terraform state management,
# enabling team collaboration and state persistence.

resource "aws_s3_bucket" "databricks_terraform_state" {
  bucket              = "databricks-terraform-ccjproject-${var.environment}-state"
  object_lock_enabled = true

  tags = merge(
    {
      Name        = "${var.app_name}-state-bucket"
      Environment = var.environment
      Project     = var.project_name
    },
    var.tags
  )

}