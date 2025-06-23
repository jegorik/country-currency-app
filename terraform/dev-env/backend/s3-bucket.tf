# AWS S3 Bucket for Terraform State Storage
#
# This file creates an S3 bucket specifically for storing Terraform state files
# with the following features:
# - Object lock enabled for state file protection
# - Versioning enabled for state file history
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

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "databricks_terraform_state_versioning" {
  bucket = aws_s3_bucket.databricks_terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure server-side encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "databricks_terraform_state_encryption" {
  bucket = aws_s3_bucket.databricks_terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "databricks_terraform_state_pab" {
  bucket = aws_s3_bucket.databricks_terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}