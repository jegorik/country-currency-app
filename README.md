# Country Currency App

## Overview
This project provisions a Databricks environment to load, store, and analyze country and currency data. It uses Terraform to create and manage all necessary Databricks resources including schemas, volumes, tables, and jobs that process CSV data containing country-to-currency mappings.

## Architecture
The application follows this workflow:
1. Sets up Databricks environment (schema, volume, table)
2. Uploads CSV data to a Databricks volume
3. Creates and runs a notebook to load data from CSV to a Delta table
4. Automates the entire process using a scheduled job

## Project Structure

The project has been reorganized according to best practices for maintainability and clarity:

```
country-currency-app/
├── terraform/               # All Terraform infrastructure code
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Variable declarations
│   ├── outputs.tf           # Output definitions
│   ├── provider.tf          # Provider configuration
│   ├── backend.tf           # Backend configuration
│   └── terraform.tfvars     # Variable values (credentials)
├── notebooks/               # Databricks notebooks
│   └── load_data_notebook_jupyter.ipynb
├── data/                    # Data files
│   └── csv_data/            # CSV data files
│       └── country_code_to_currency_code.csv
├── scripts/                 # Shell scripts for setup and testing
│   ├── setup.sh             # Initial setup script 
│   ├── configure_databricks_cli.sh # CLI configuration
│   ├── test_databricks_connection.sh # Connection testing
│   ├── validate_notebook.sh # Notebook validation
│   └── run_tests.sh         # Consolidated test runner script
├── docs/                    # Documentation
│   ├── ARCHITECTURE.md
│   ├── CONTRIBUTING.md
│   ├── MIGRATION.md
│   ├── TROUBLESHOOTING.md
│   ├── CI_CD.md
│   └── Other documentation files
├── Makefile               # Automation for common tasks
├── setup.sh               # Initial setup script
├── validate_notebook.sh   # Script to validate notebook execution
├── .github/               # GitHub Actions configuration
│   └── workflows/       
│       └── ci-cd.yml      # CI/CD pipeline definition
├── environments/          # Environment-specific configurations 
│   ├── dev.tfvars         # Development environment variables
│   ├── test.tfvars        # Test environment variables
│   └── prod.tfvars        # Production environment variables
├── compliance/            # Terraform compliance tests
│   └── basic_checks.feature  # Policy-as-code tests
├── csv_data/              # Source data
│   └── country_code_to_currency_code.csv
├── notebooks/             # Databricks notebooks
│   └── load_data_notebook_jupyter.ipynb  # Data processing notebook in Jupyter format
├── tests/                 # Test files for application code
│   └── test_load_data_notebook.py
├── environments/            # Environment-specific configuration
├── ci/                      # CI/CD configuration files
├── tests/                   # Test files
└── README.md                # Project documentation (this file)
```

## Project Documentation

This project includes several documentation files to help users understand, use, and contribute to the project:

- [User Guide](docs/USER_GUIDE.md) - How to use the Country Currency App
- [Architecture](docs/ARCHITECTURE.md) - Detailed system architecture
- [Component Diagram](docs/COMPONENT_DIAGRAM.md) - Visual representation of system components
- [Notebook Validation](docs/NOTEBOOK_VALIDATION.md) - How notebook validation works in CI/CD
- [CI/CD Process](docs/CI_CD.md) - CI/CD pipeline documentation
- [Contributing Guidelines](docs/CONTRIBUTING.md) - How to contribute to this project
- [Migration Guide](docs/MIGRATION.md) - Instructions for migrating between versions
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## Troubleshooting

For common issues and their solutions, please refer to the [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) document. Common issues include:

1. **Notebook Format Issues** - Problems with notebook execution format in Databricks
2. **Table Schema Conflicts** - Issues with table schema discrepancies between Terraform and Databricks
3. **Authentication Issues** - Problems with Databricks API tokens and authentication
4. **Terraform Apply/Destroy Problems** - Common Terraform operational issues
5. **SQL Warehouse Connectivity** - Issues connecting to SQL warehouses

## Prerequisites
- Terraform v1.0.0+
- Databricks workspace and access token
- Existing SQL warehouse in Databricks

## Setup Instructions

### Local Development Setup
1. Configure your Databricks credentials in `terraform.tfvars` or use environment variables
2. Run the setup script to prepare your environment:
   ```bash
   ./scripts/setup.sh
   ```
   
3. Or use the Makefile for common operations:
   ```bash
   # Initialize Terraform
   make init
   
   # Plan changes for development environment
   make ENV=dev plan
   
   # Apply changes
   make ENV=dev apply
   ```
   
4. Run tests with the consolidated test script:
   ```bash
   ./scripts/run_tests.sh
   ```
   
   This script offers options for:
   - Testing Databricks connection
   - Validating notebooks
   - Running Python unit tests

### CI/CD Setup
1. Fork this repository in GitHub
2. Configure the following secrets in your GitHub repository:
   - `DATABRICKS_HOST`: Your Databricks workspace URL
   - `DATABRICKS_TOKEN`: Your Databricks API token
   - `DATABRICKS_WAREHOUSE_ID`: ID of your SQL warehouse
   
3. The CI/CD pipeline will automatically run on pull requests and pushes to main branches
4. To manually trigger a deployment:
   - Go to the "Actions" tab in GitHub
   - Select the "Country Currency App CI/CD" workflow
   - Click "Run workflow"
   - Select the target environment
   - Click "Run workflow"

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

## CI/CD Pipeline

This project uses GitHub Actions to automate testing, building, and deployment processes. The CI/CD pipeline ensures consistent, reliable deployments across multiple environments.

### Pipeline Stages

1. **Validate**: Code linting and Terraform validation
2. **Test**: Run automated tests and verify infrastructure plans
3. **Build**: Package resources for deployment
4. **Deploy**: Environment-specific deployments (dev, test, prod)

### Deployment Environments

- **Development**: Automatic deployment on pushes to the `develop` branch
- **Test**: Manual trigger with validation checks
- **Production**: Manual trigger with approval requirements

For complete details on the CI/CD implementation, see:
- [CI_CD.md](docs/CI_CD.md) - General CI/CD configuration
- [CI_CD_TESTING.md](docs/CI_CD_TESTING.md) - CI/CD testing configuration and troubleshooting

## Contributing
Please follow the standard Git workflow:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request
4. Ensure CI/CD pipeline passes all checks

## License
[Specify your license here]
