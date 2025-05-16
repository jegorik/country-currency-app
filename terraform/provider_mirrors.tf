# Provider Mirror Configuration
# This file configures alternative sources for Terraform providers
# to handle network connectivity issues with the primary source.

terraform {
  # Provider installation method configuration
  provider_installation {
    # Try the direct/default installation method first
    direct {
      exclude = []
    }

    # If direct installation fails, try the network mirror
    network_mirror {
      url = "https://terraform-mirror.yevster.com"
      include = ["databricks/databricks"]
    }

    # Fallback to another mirror if needed
    network_mirror {
      url = "https://terraform-mirror.devops-services.io"
      include = ["databricks/databricks"]
    }
  }
}