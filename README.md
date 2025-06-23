# Country Currency Mapping Project (CCP)

A comprehensive data engineering solution for managing country-to-currency mappings using Databricks, Streamlit, and Terraform. This project provides a complete ETL pipeline with a modern web interface for data visualization and CRUD operations.

## 🌟 Features

- **📊 Modern Streamlit Dashboard**: Interactive web interface for data visualization and management
- **🔄 Complete ETL Pipeline**: Automated data processing using Databricks notebooks
- **🏗️ Infrastructure as Code**: Terraform-based deployment for AWS and Databricks resources
- **🎯 CRUD Operations**: Full Create, Read, Update, Delete functionality
- **📈 Data Visualization**: Interactive charts and analytics using Plotly
- **📋 Batch Operations**: Upload and process data in batches
- **🔍 Advanced Filtering**: Search and filter capabilities
- **🌐 Cross-Platform Support**: Works on Windows and Linux environments
- **📱 Responsive Design**: Mobile-friendly dark theme interface
- **🚀 CI/CD Pipeline**: Automated testing and deployment with GitHub Actions

## 🏗️ Architecture

```text
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Streamlit     │    │    Databricks    │    │   Terraform     │
│   Frontend      │◄──►│    Backend       │◄──►│Infrastructure   │
│                 │    │                  │    │                 │
│ • Dashboard     │    │ • Delta Tables   │    │ • AWS S3        │
│ • CRUD Ops      │    │ • ETL Notebooks  │    │ • Databricks    │
│ • Visualizations│    │ • SQL Warehouse  │    │ • Resources     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 📁 Project Structure

```text
Updated_CCP/
├── 📊 streamlit/              # Streamlit web application
│   ├── app.py                 # Main application entry point
│   ├── requirements.txt       # Python dependencies
│   ├── config/                # Configuration management
│   ├── models/                # Data models
│   ├── operations/            # Data operations
│   ├── ui/                    # User interface components
│   ├── utils/                 # Utility functions
│   └── templates/             # HTML templates
├── 📓 notebooks/              # Databricks notebooks
│   └── load_notebook_jupyter.ipynb  # ETL pipeline notebook
├── 🗂️ etl_data/               # Source data files
│   └── country_code_to_currency_code.csv
├── 🏗️ terraform/              # Infrastructure as Code
│   ├── dev-env/               # Development environment
│   │   ├── backend/           # S3 backend configuration
│   │   └── databricks-ifra/   # Databricks infrastructure
│   └── terraform.tfvars.example
├── 🔧 scripts/                # Deployment scripts
│   ├── deploy.sh              # Automated deployment
│   └── validate.sh            # Infrastructure validation
├── 🚀 .github/workflows/      # GitHub Actions CI/CD
│   ├── ci.yml                 # Continuous Integration
│   ├── deploy.yml             # Deployment pipeline
│   └── terraform.yml          # Infrastructure validation
└── 📄 README.md               # Project documentation
```

## 🚀 Quick Start

### Prerequisites

- Python 3.8+
- Terraform >= 1.0
- AWS CLI configured
- Databricks workspace access
- Git

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Updated_CCP
```

### 2. Set Up Environment

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install Python dependencies
cd streamlit
pip install -r requirements.txt
```

### 3. Configure Databricks Connection

```bash
# Copy the example configuration
cp databricks_connection.json.example databricks_connection.json

# Edit with your Databricks details
nano databricks_connection.json
```

### 4. Deploy Infrastructure

```bash
# Copy Terraform variables
cd ../terraform
cp terraform.tfvars.example terraform.tfvars

# Edit with your AWS and Databricks configuration
nano terraform.tfvars

# Deploy infrastructure
chmod +x ../scripts/deploy.sh
../scripts/deploy.sh -a all -e dev
```

### 5. Run the Application

```bash
cd ../streamlit
streamlit run app.py
```

The application will be available at `http://localhost:8501`

## 📋 Configuration

### Databricks Configuration

Edit `streamlit/databricks_connection.json`:

```json
{
  "databricks_host": "https://your-workspace.cloud.databricks.com",
  "catalog_name": "main",
  "schema_name": "default",
  "table_name": "country_currency",
  "databricks_warehouse_id": "your-warehouse-id",
  "environment": "dev"
}
```

### Terraform Configuration

Edit `terraform/terraform.tfvars`:

```hcl
# Databricks connectivity
databricks_host  = "https://your-workspace.cloud.databricks.com"
databricks_token = "your-databricks-token-here"

# Resource configuration
catalog_name             = "country_currency_metastore"
schema_name              = "country_currency_schema"
table_name               = "country_currency_mapping"
volume_name              = "csv_data_volume"
databricks_warehouse_id  = "your-warehouse-id-here"
```

## 🎯 Usage

### Dashboard Features

1. **📊 Data Overview**: View summary statistics and data health metrics
2. **🔍 Data Explorer**: Browse and filter country-currency mappings
3. **📈 Visualizations**: Interactive charts and analytics
4. **✏️ CRUD Operations**: Add, edit, and delete records
5. **📤 Batch Upload**: Upload CSV files for bulk data processing
6. **🔄 Data Refresh**: Real-time data synchronization

### ETL Pipeline

The ETL pipeline processes country-currency mapping data:

1. **Extract**: Reads CSV data from Databricks volume
2. **Transform**: Validates and cleans data
3. **Load**: Stores data in Delta table format

Run the ETL pipeline:

```bash
# Via Databricks job (automated)
# Or run the notebook manually in Databricks workspace
```

### API Operations

The application supports programmatic access through the Databricks SQL connector:

```python
from utils.databricks_client import DatabricksClient

client = DatabricksClient(config)
data = client.query("SELECT * FROM country_currency_mapping")
```

## 🛠️ Development

### Local Development Setup

```bash
# Install development dependencies
pip install -r requirements.txt

# Run in development mode
streamlit run app.py --server.runOnSave true
```

### GitHub Actions CI/CD

This project includes automated workflows for continuous integration and deployment:

#### Workflow Files

- `.github/workflows/ci.yml` - Continuous Integration pipeline
- `.github/workflows/deploy.yml` - Deployment pipeline
- `.github/workflows/terraform.yml` - Infrastructure validation

#### CI Pipeline Features

- **Code Quality**: Automated linting and formatting checks
- **Security Scanning**: Dependency vulnerability scanning
- **Testing**: Unit tests and integration tests
- **Build Validation**: Streamlit application build verification
- **Terraform Validation**: Infrastructure code validation

#### Deployment Pipeline

- **Environment-based Deployment**: Separate workflows for dev/staging/prod
- **Infrastructure Deployment**: Automated Terraform apply
- **Application Deployment**: Streamlit app deployment
- **Rollback Capabilities**: Automatic rollback on deployment failures

#### Setting Up GitHub Actions

1. **Repository Secrets**: Configure the following secrets in your GitHub repository:

   ```text
   DATABRICKS_HOST           # Your Databricks workspace URL
   DATABRICKS_TOKEN          # Databricks personal access token
   AWS_ACCESS_KEY_ID         # AWS access key for Terraform
   AWS_SECRET_ACCESS_KEY     # AWS secret key for Terraform
   TERRAFORM_CLOUD_TOKEN     # Terraform Cloud API token (if using)
   ```

2. **Environment Variables**: Set up environment-specific variables:

   ```yaml
   # In .github/workflows/deploy.yml
   env:
     TF_VAR_environment: ${{ github.ref_name }}
     TF_VAR_databricks_host: ${{ secrets.DATABRICKS_HOST }}
     TF_VAR_databricks_token: ${{ secrets.DATABRICKS_TOKEN }}
   ```

3. **Branch Protection**: Configure branch protection rules:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date

#### Workflow Triggers

- **Pull Requests**: Run CI checks on all PRs
- **Main Branch**: Deploy to staging environment
- **Release Tags**: Deploy to production environment
- **Manual Trigger**: Allow manual deployments with environment selection

#### Example Workflow Structure

```yaml
# .github/workflows/ci.yml
name: CI Pipeline
on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop]

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      - name: Install dependencies
        run: |
          pip install -r streamlit/requirements.txt
          pip install flake8 black pytest
      - name: Lint code
        run: |
          flake8 streamlit/
          black --check streamlit/
      - name: Run tests
        run: pytest tests/

  terraform-validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      - name: Terraform Format Check
        run: terraform fmt -check -recursive terraform/
      - name: Terraform Validate
        run: |
          cd terraform/dev-env/databricks-ifra
          terraform init -backend=false
          terraform validate
```

### Adding New Features

1. **UI Components**: Add to `streamlit/ui/`
2. **Data Operations**: Extend `streamlit/operations/data_operations.py`
3. **Utilities**: Add to `streamlit/utils/`
4. **Configuration**: Update `streamlit/config/app_config.py`

### Testing

```bash
# Validate infrastructure
./scripts/validate.sh

# Run application tests
python -m pytest tests/  # (if tests directory exists)
```

## 🚀 Deployment

### Development Environment

```bash
./scripts/deploy.sh -a all -e dev
```

### Production Environment

```bash
./scripts/deploy.sh -a all -e prod -v terraform-prod.tfvars
```

### Destroy Infrastructure

```bash
./scripts/deploy.sh -a destroy -e dev
```

## 📊 Data Schema

The application manages the following data structure:

| Column | Type | Description |
|--------|------|-------------|
| `country_code` | STRING | ISO 3166-1 alpha-3 country code |
| `country_number` | INT | ISO 3166-1 numeric country code |
| `country` | STRING | Full country name |
| `currency_name` | STRING | Official currency name |
| `currency_code` | STRING | ISO 4217 currency code |
| `currency_number` | INT | ISO 4217 numeric currency code |

## 🔒 Security & Data Protection

### Sensitive Information Masking

The project implements comprehensive **data leak prevention** in CI/CD pipelines and validation scripts to protect sensitive information in public repositories.

#### 🛡️ What Gets Masked

| Information Type | Example | Masked Output | Protection Level |
|------------------|---------|---------------|------------------|
| AWS Account ID | `123456789012` | `123******012` | High |
| Databricks URLs | `https://dbc-12345678-abcd.cloud.databricks.com` | `https://***.databricks.com` | High |
| S3 Bucket Names | `databricks-terraform-myproject-dev-state` | `databricks***state` | Medium |
| File Paths | `/home/runner/work/project/...` | `/***` | Medium |

#### 🔧 Masking Implementation

The validation script includes automatic masking functions:

```bash
# Built-in masking for different data types
mask_sensitive_info "$aws_account" "aws_account"    # AWS Account IDs
mask_sensitive_info "$databricks_host" "url"        # URLs and hostnames
mask_sensitive_info "$bucket_name" "bucket"         # S3 bucket names
mask_sensitive_info "$file_path" "path"             # File system paths
```

#### ✅ Security Best Practices Applied

1. **Repository Secrets**: All sensitive values stored in GitHub secrets

   ```yaml
   AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}          # Hidden from logs
   DATABRICKS_HOST: ${{ secrets.DATABRICKS_HOST }}    # Masked in output
   ```

2. **OIDC Authentication**: Temporary credentials with restricted scope

   ```yaml
   permissions:
     id-token: write    # Required for OIDC
     contents: read     # Minimal permissions
   ```

3. **Environment Isolation**: Separate secrets per environment

   ```text
   AWS_ROLE_ARN_DEV       # Development environment
   AWS_ROLE_ARN_PROD      # Production environment
   DATABRICKS_HOST_DEV    # Dev workspace
   DATABRICKS_HOST_PROD   # Prod workspace
   ```

#### 🔍 Log Security Examples

**Before (Data Leak):**

```bash
✅ AWS credentials configured (Account: 123456789012, Region: us-east-1)
✅ S3 backend bucket exists: databricks-terraform-myproject-dev-state
   Databricks host: https://dbc-12345678-abcd.cloud.databricks.com
```

**After (Protected):**

```bash
✅ AWS credentials configured (Account: 123******012, Region: us-east-1)
✅ S3 backend bucket exists: databricks***state
   Databricks host: https://***.databricks.com
```

#### 🚨 Security Monitoring

The project includes monitoring for:

- **Failed Authentication Attempts**: AWS/Databricks access failures
- **Unusual Access Patterns**: Geographic or time-based anomalies
- **Resource Access**: CloudTrail logging for all AWS operations
- **Pipeline Failures**: Automated alerts for security-related failures

### Infrastructure Security

#### IAM Role Configuration

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:ORG/REPO:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

#### Network Security

- **VPC Isolation**: Databricks workspaces in private subnets
- **Security Groups**: Restrictive inbound/outbound rules
- **Encryption**: Data encrypted at rest and in transit
- **Access Controls**: Multi-factor authentication required

#### Data Protection

- **Delta Lake**: Built-in versioning and ACID transactions
- **Access Logging**: Comprehensive audit trails
- **Data Masking**: Automatic PII detection and masking
- **Backup Strategy**: Automated backups with retention policies

### Compliance & Governance

- **GDPR Compliance**: Data residency and right to deletion
- **SOX Controls**: Audit trails and change management
- **ISO 27001**: Information security management
- **Data Classification**: Automatic tagging and protection

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/new-feature`
5. Submit a Pull Request

## 📄 License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

## 🆘 Support

For support and questions:

1. Check the troubleshooting section above
2. Review Databricks documentation
3. Open an issue in the repository
4. Contact the development team

## 🎉 Acknowledgments

- Databricks for the data platform
- Streamlit for the web framework
- Terraform for infrastructure automation
- The open-source community for various libraries and tools

---

### Credits

Built with ❤️ by the Data Engineering Team

Last Updated: June 23, 2025