# Backend Infrastructure Output Definitions
#
# This file defines outputs for the backend infrastructure components,
# specifically the S3 bucket used for Terraform state storage.
# These outputs provide key information about the deployed backend
# resources that may be needed for configuration or reference.

output "Backend_deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    aws_region     = var.aws_region
    s3_bucket_name = aws_s3_bucket.databricks_terraform_state.bucket
    project_name   = var.project_name
    environment    = var.environment
  }
}