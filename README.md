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
├── streamlit/               # Streamlit web application
│   ├── app.py               # Main Streamlit application
│   ├── requirements.txt     # Python dependencies
│   ├── README.md            # Streamlit app documentation
│   ├── config/              # App configuration
│   ├── models/              # Data models
│   ├── operations/          # Business logic
│   ├── ui/                  # User interface components
│   └── utils/               # Utility functions
├── scripts/                 # Utility scripts
│   ├── deploy/              # Deployment scripts
│   │   ├── deploy_windows.ps1      # Windows deployment
│   │   ├── unified_deploy.ps1      # Unified Windows deployment
│   │   └── unified_deploy.sh       # Unified Linux/macOS deployment
│   │
│   ├── setup/               # Setup scripts
│   │   ├── setup.sh                # Initial setup script 
│   │   └── configure_databricks_cli.sh # CLI configuration
│   │
│   ├── streamlit/           # Streamlit launch scripts
│   │   ├── unified_start_app.sh    # Cross-platform Streamlit launcher
│   │   ├── wait_and_start.sh       # Unix job wait and app start
│   │   ├── wait_and_start.ps1      # Windows job wait and app start
│   │   └── start_app.ps1           # Windows startup
│   │
│   ├── test/                # Testing scripts
│   │   ├── run_tests.sh            # Consolidated test runner script
│   │   ├── test_databricks_connection.sh # Connection testing
│   │   └── validate_notebook.sh    # Notebook validation
│   │
│   └── utils/               # Utility scripts
│       └── check_terraform_paths.sh # Script to validate terraform paths
├── docs/                    # Documentation
│   ├── ARCHITECTURE.md
│   ├── CONTRIBUTING.md
│   ├── MIGRATION.md
│   ├── TROUBLESHOOTING.md
│   ├── GITHUB_ACTIONS_TROUBLESHOOTING.md
│   ├── EXISTING_INFRASTRUCTURE.md # How to handle existing resources
│   ├── CI_CD.md
│   ├── STREAMLIT_APP.md     # Documentation for the Streamlit app
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
└── README.md                # Project documentation (this file)
```

## Getting Started

### Prerequisites
- Terraform (version 1.11.4 or later)
- Databricks account with appropriate permissions
- PowerShell (for Windows) or Bash (for Linux/macOS)
- Access to a Databricks workspace

### Quick Start Deployment

#### Simplified Cross-Platform Deployment
Our new unified deployment script automatically detects your operating system and runs the appropriate commands:

```bash
# Run the unified deployment script (works on Windows, Linux, and macOS)
bash scripts/unified_deploy.sh
```

This script will:
1. Automatically detect your operating system
2. Check for required dependencies
3. Run the appropriate deployment process for your platform
4. Set up all necessary Terraform resources

For advanced users who prefer direct control:

```powershell
# Windows users can directly use the PowerShell script
.\scripts\unified_deploy.ps1
```

## Cross-Platform Compatibility

This project supports deployment on both Windows and Linux operating systems. The Terraform scripts are designed to work correctly on your specific platform.

### Platform-Specific Dependencies

#### Windows Requirements:
- PowerShell Core (pwsh)
- Terraform 1.11.4+
- Databricks CLI
- Python 3.x

#### Linux/Unix Requirements:
- Bash
- curl
- grep
- sed
- Terraform 1.11.4+
- Databricks CLI
- Python 3.x

### Checking Dependencies

Dependency checking is now integrated into the unified deployment scripts:

```bash
# Run with the --check-only flag to verify dependencies without deployment
bash /scripts/deploy/unified_deploy.sh --check-only
```

This will verify that all required tools are installed on your system, including:
- Terraform
- Databricks CLI
- Python with required packages
- Platform-specific dependencies

## Deployment Instructions

### Cross-Platform Deployment

This project is designed to be OS-agnostic and can be deployed on both Windows and Linux/macOS. There are several ways to deploy the application:

1. **Using the Makefile (Recommended)**:

   ```bash
   # Deploy using the OS-agnostic Makefile target
   make deploy ENV=dev
   ```

   The Makefile automatically detects your operating system and runs the appropriate deployment script.

2. **Using the unified deployment script**:

   ```bash
   # Run the unified deployment script (works on Windows, Linux, and macOS)
   ./scripts/deploy/unified_deploy.sh
   ```

3. **Directly using OS-specific scripts**:

   - On Linux/macOS:
     ```bash
     ./scripts/deploy/unified_deploy.sh
     ```

   - On Windows (PowerShell):
     ```powershell
     .\scripts\deploy\unified_deploy.ps1
     ```

### Requirements

- **All Platforms**: Terraform 1.0+, Databricks CLI
- **Linux/macOS**: Bash 4.0+, curl, grep, sed
- **Windows**: PowerShell 5.0+

### Environment Variables

The following environment variables can be set to override defaults:

- `DATABRICKS_HOST`: Databricks workspace URL
- `DATABRICKS_TOKEN`: Personal access token for authentication

## Streamlit Web Application

The project includes a Streamlit web application that provides a user-friendly interface for managing the country-currency data. The app allows users to:

- View all country-currency mappings in an interactive table
- Add new country-currency mappings
- Edit existing mappings
- Delete mappings
- Search and filter data

### Running the Streamlit App

After deploying the Databricks infrastructure, you can start the Streamlit app using one of the following methods:

1. **Without waiting for job completion:**
   ```bash
   make streamlit-app
   ```

2. **Wait for the Databricks job to complete first:**
   ```bash
   make wait-and-start-ui
   ```

3. **Deploy infrastructure and start app in one command:**
   ```bash
   make deploy-and-wait
   ```

For more detailed information on running scripts from various locations, see the [Script Usage Guide](docs/SCRIPT_USAGE_GUIDE.md).

### Streamlit App Architecture

The Streamlit app is structured following a clean architecture pattern:

- **UI Layer** - Streamlit components for user interaction
- **Operations Layer** - Business logic for CRUD operations
- **Data Access Layer** - Connection and queries to Databricks
- **Configuration** - App settings and parameters

For more details on the Streamlit application, see [STREAMLIT_APP.md](docs/STREAMLIT_APP.md).

## Project Documentation

This project includes several documentation files to help users understand, use, and contribute to the project:

- [User Guide](docs/USER_GUIDE.md) - How to use the Country Currency App
- [Architecture](docs/ARCHITECTURE.md) - Detailed system architecture
- [Component Diagram](docs/COMPONENT_DIAGRAM.md) - Visual representation of system components
- [Notebook Validation](docs/NOTEBOOK_VALIDATION.md) - How notebook validation works in CI/CD
- [CI/CD Process](docs/CI_CD.md) - CI/CD pipeline documentation
- [Terraform Compliance](docs/TERRAFORM_COMPLIANCE.md) - Policy-as-code testing for infrastructure
- [Contributing Guidelines](docs/CONTRIBUTING.md) - How to contribute to this project
- [Migration Guide](docs/MIGRATION.md) - Instructions for migrating between versions
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Streamlit App](docs/STREAMLIT_APP.md) - Documentation for the Streamlit application

## Troubleshooting

For common issues and their solutions, please refer to the [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) document. Common issues include:

1. **Notebook Format Issues** - Problems with notebook execution format in Databricks
2. **Table Schema Conflicts** - Issues with table schema discrepancies between Terraform and Databricks
3. **Authentication Issues** - Problems with Databricks API tokens and authentication
4. **Terraform Apply/Destroy Problems** - Common Terraform operational issues
5. **SQL Warehouse Connectivity** - Issues connecting to SQL warehouses

For specific GitHub Actions CI/CD issues, see [GITHUB_ACTIONS_TROUBLESHOOTING.md](./docs/GITHUB_ACTIONS_TROUBLESHOOTING.md).

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
- [VIEW_COMPLIANCE_RESULTS.md](docs/VIEW_COMPLIANCE_RESULTS.md) - How to view Terraform compliance check results
- [TERRAFORM_COMPLIANCE.md](docs/TERRAFORM_COMPLIANCE.md) - Information about Terraform compliance checks

## Contributing
Please follow the standard Git workflow:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request
4. Ensure CI/CD pipeline passes all checks

## License
[Specify your license here]
