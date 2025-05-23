#############################################
# Country Currency App - Provider Configuration
#############################################

terraform {
  # Specify minimum Terraform version required
  required_version = "~>1.11"

  # Define required providers
  required_providers {
    # Databricks provider for managing Databricks resources
    databricks = {
      source  = "databricks/databricks"
      version = "~>1.0"
    }
  }

  # Uncomment this block to enable remote state storage
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "terraformstatesa"
  #   container_name       = "terraform-state"
  #   key                  = "country-currency-app.tfstate"
  # }
}

# Configure Databricks provider authentication
provider "databricks" {
  host                 = var.databricks_host
  token                = var.databricks_token
  skip_verify          = var.skip_validation # Skip SSL verification if validation is disabled
  debug_truncate_bytes = 2048                # Increase debug output size
  debug_headers        = true                # Include headers in debug output

  # Uncomment for Azure Databricks authentication
  # azure_workspace_resource_id = var.azure_workspace_id
  # azure_client_id             = var.azure_client_id
  # azure_client_secret         = var.azure_client_secret
  # azure_tenant_id             = var.azure_tenant_id
}
