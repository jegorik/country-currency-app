#!/usr/bin/env python3
"""
Mock Plan Generator for Terraform Compliance Testing

This script generates a mock Terraform plan in JSON format that can be used
with terraform-compliance testing, without requiring the actual Terraform
provider to run. This avoids issues with the Databricks provider in CI environments.

Usage:
  python mock_plan_generator.py --output terraform-plan.json
"""

import json
import argparse
import uuid
from datetime import datetime

def generate_mock_terraform_plan():
    """Generate a mock Terraform plan for compliance testing."""
    
    # Basic plan structure
    plan = {
        "format_version": "0.2",
        "terraform_version": "1.11",
        "planned_values": {
            "root_module": {
                "resources": []
            }
        },
        "resource_changes": [],
        "configuration": {
            "root_module": {
                "resources": [],
                "variables": {
                    "environment": {
                        "default": "dev",
                        "description": "Deployment environment (e.g., dev, test, prod)",
                        "validation": {
                            "condition": "contains([\"dev\", \"test\", \"prod\"], var.environment)",
                            "error_message": "Environment must be one of: dev, test, or prod."
                        }
                    },
                    "databricks_token": {
                        "description": "Databricks API token",
                        "sensitive": True,
                        "type": "string"
                    }
                }
            }
        },
        "variables": {
            "databricks_token": {
                "value": "mock-token-value",
                "sensitive": True
            },
            "environment": {
                "value": "dev"
            }
        }
    }
    
    # Define the resources to include - use simpler structures to avoid JSON issues
    resources = [
        {
            "type": "databricks_catalog",
            "name": "this",
            "provider_name": "registry.terraform.io/databricks/databricks",
            "values": {
                "name": "test_catalog",
                "comment": "Catalog for Test Project data",
                "owner": "test_user",
                "tags": {
                    "environment": "dev",
                    "project": "Test Project"
                },
                "properties": {},  # Empty for simplicity
                "force_destroy": False
            }
        },
        {
            "type": "databricks_schema",
            "name": "schema",
            "provider_name": "registry.terraform.io/databricks/databricks",
            "values": {
                "name": "test_schema",
                "catalog_name": "test_catalog",
                "comment": "Schema for Test Project data",
                "owner": "test_user",
                "tags": {
                    "environment": "dev",
                    "project": "Test Project"
                }
            }
        },
        {
            "type": "databricks_file",
            "name": "csv_data",
            "provider_name": "registry.terraform.io/databricks/databricks",
            "values": {
                "path": "/tmp/data.csv",
                "source": "data/csv_data/country_code_to_currency_code.csv",
                "tags": {
                    "environment": "dev",
                    "project": "Test Project"
                }
            }
        },
        {
            "type": "databricks_job",
            "name": "load_data_job",
            "provider_name": "registry.terraform.io/databricks/databricks",
            "values": {
                "name": "Load Country Currency Data",
                "tags": {
                    "environment": "dev", 
                    "project": "Test Project"
                }
            }
        }
    ]
    
    # Add resources to the plan
    for resource in resources:
        resource_id = f"{resource['type']}.{resource['name']}"
        
        # Add to planned_values
        plan["planned_values"]["root_module"]["resources"].append({
            "address": resource_id,
            "mode": "managed",
            "type": resource["type"],
            "name": resource["name"],
            "provider_name": resource["provider_name"],
            "values": resource["values"],
        })
        
        # Add to resource_changes
        plan["resource_changes"].append({
            "address": resource_id,
            "mode": "managed",
            "type": resource["type"],
            "name": resource["name"],
            "provider_name": resource["provider_name"],
            "change": {
                "actions": ["create"],
                "before": None,
                "after": resource["values"],
                "after_unknown": {},
                "before_sensitive": False,
                "after_sensitive": {}
            }
        })
        
        # Add to configuration - create expressions safely
        expressions = {}
        for k, v in resource["values"].items():
            # Handle nested dictionaries and complex structures
            if isinstance(v, dict):
                expressions[k] = {"constant_value": v}
            elif isinstance(v, list):
                expressions[k] = {"constant_value": v}
            elif v is None:
                continue  # Skip null values
            else:
                expressions[k] = {"constant_value": v}
            
        resource_config = {
            "address": resource_id,
            "mode": "managed",
            "type": resource["type"],
            "name": resource["name"],
            "provider_config_key": "databricks",
            "expressions": expressions,
            "schema_version": 0
        }
            
        plan["configuration"]["root_module"]["resources"].append(resource_config)
    
    return plan

def main():
    parser = argparse.ArgumentParser(description="Generate mock Terraform plan for compliance testing")
    parser.add_argument("--output", default="terraform-plan.json", help="Output file path")
    args = parser.parse_args()
    
    plan = generate_mock_terraform_plan()
    
    try:
        # Validate the generated JSON first
        json_string = json.dumps(plan, indent=2)
        # Verify the json is valid by parsing it back
        json.loads(json_string)
        
        # Write to file
        with open(args.output, "w") as f:
            f.write(json_string)
        
        print(f"Mock Terraform plan written to {args.output}")
    except Exception as e:
        print(f"Error generating JSON: {str(e)}")
        raise

if __name__ == "__main__":
    main()
