terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.6.5"  # Using a more recent version to avoid the provider bugs
    }
  }
  required_version = ">= 1.0.0"
}
