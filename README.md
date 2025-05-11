# Country Currency App

## Overview
This project provisions a Databricks environment to load, store, and analyze country and currency data. It uses Terraform to create and manage all necessary Databricks resources including schemas, volumes, tables, and jobs that process CSV data containing country-to-currency mappings.

## Architecture
The application follows this workflow:
1. Sets up Databricks environment (schema, volume, table)
2. Uploads CSV data to a Databricks volume
3. Creates and runs a notebook to load data from CSV to a Delta table
4. Automates the entire process using a scheduled job

## Directory Structure
```
country-currency-app/
├── main.tf              # Main Terraform configuration file
├── provider.tf          # Terraform provider configuration
├── variables.tf         # Variable declarations
├── terraform.tfvars     # Variable values (credentials & configuration)
├── outputs.tf           # Outputs (newly created)
├── csv_data/            # Source data
│   └── country_code_to_currency_code.csv
├── notebooks/           # Databricks notebooks
│   └── load_data_notebook.py
└── README.md            # Project documentation
```

## Prerequisites
- Terraform v1.0.0+
- Databricks workspace and access token
- Existing SQL warehouse in Databricks

## Setup Instructions
1. Configure your Databricks credentials in `terraform.tfvars` or use environment variables
2. Initialize Terraform:
   ```
   terraform init
   ```
3. Review the execution plan:
   ```
   terraform plan
   ```
4. Apply the configuration:
   ```
   terraform apply
   ```

## Resources Created
- Databricks schema for organizing data
- Databricks volume for storing CSV data
- Delta table for country-currency data
- Databricks notebook for data processing
- Automated job to load data from CSV to the table

## Security Considerations
- API tokens are marked as sensitive in the Terraform configuration
- Don't commit the `terraform.tfvars` file to version control systems

## Troubleshooting
If the job fails to load data:
1. Check if the SQL warehouse is running
2. Verify the CSV file format is correct
3. Review the job run logs in the Databricks UI

## Contributing
Please follow the standard Git workflow:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License
[Specify your license here]
