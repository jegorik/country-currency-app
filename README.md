# Country Currency Mapping Data Pipeline

A comprehensive data pipeline for loading and managing country-to-currency mapping data using Databricks and Terraform. This project provides infrastructure-as-code deployment and automated data processing capabilities.

## 🚀 Project Overview

This project implements an end-to-end data pipeline that:
- **Extracts** country-currency mapping data from CSV files
- **Transforms** and validates the data with quality checks
- **Loads** the data into Databricks Delta tables
- **Manages** infrastructure using Terraform automation

### Key Features

- ✅ **Infrastructure as Code**: Complete Terraform automation for Databricks resources
- ✅ **Cross-Platform Support**: Works on Windows and Linux environments
- ✅ **Data Quality Validation**: Built-in data quality checks and validation
- ✅ **Modular Design**: Reusable components and functions
- ✅ **Error Handling**: Comprehensive error handling and logging
- ✅ **State Management**: S3 backend for Terraform state storage
- ✅ **Parameterized Execution**: Flexible configuration through widgets

## 📁 Project Structure

```
New_app_databriks/
├── etl_data/                          # Source data files
│   └── country_code_to_currency_code.csv
├── notebooks/                         # Databricks notebooks
│   └── load_notebook_jupyter.ipynb    # Main ETL notebook
├── scripts/                           # Utility scripts (currently empty)
├── terraform/                         # Infrastructure as Code
│   ├── terraform.tfvars.example       # Configuration template
│   └── dev-env/
│       ├── backend/                   # S3 backend infrastructure
│       │   ├── s3-bucket.tf          # S3 bucket for state storage
│       │   ├── variables.tf          # Backend variables
│       │   ├── providers.tf          # AWS provider config
│       │   └── outputs.tf            # Backend outputs
│       └── databricks-ifra/           # Main Databricks infrastructure
│           ├── databricks.tf         # Core Databricks resources
│           ├── variables.tf          # Input variables
│           ├── providers.tf          # Provider configurations
│           ├── outputs.tf            # Resource outputs
│           └── backend-config.tf     # S3 backend configuration
└── README.md                         # This file
```

## 🛠️ Prerequisites

### Required Tools
- [Terraform](https://terraform.io/) >= 1.0
- [Databricks CLI](https://docs.databricks.com/dev-tools/cli/index.html) (optional)
- AWS CLI configured with appropriate permissions
- PowerShell (Windows) or Bash (Linux/macOS)

### Required Access
- **Databricks Workspace**: Access to a Databricks workspace
- **Databricks Token**: Personal access token for API authentication
- **SQL Warehouse**: An existing SQL warehouse in your Databricks workspace
- **AWS Account**: Access to create S3 buckets for state storage

## 🚀 Quick Start

### 1. Configure Terraform Variables

```bash
# Copy the example configuration
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit the configuration file with your specific values
# Update the following key parameters:
# - databricks_host: Your Databricks workspace URL
# - databricks_token: Your personal access token
# - databricks_warehouse_id: Your SQL warehouse ID
# - aws_region: Your preferred AWS region
```

### 2. Deploy Backend Infrastructure

```bash
# Navigate to backend directory
cd terraform/dev-env/backend

# Initialize and apply backend infrastructure
terraform init
terraform plan
terraform apply
```

### 3. Deploy Databricks Infrastructure

```bash
# Navigate to Databricks infrastructure directory
cd ../databricks-ifra

# Initialize and apply Databricks resources
terraform init
terraform plan
terraform apply
```

### 4. Verify Deployment

After successful deployment, check your Databricks workspace for:
- Created schema and volume
- Uploaded CSV data file
- Deployed notebook
- Configured and executed job

## 📋 Configuration Reference

### Core Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `databricks_host` | Databricks workspace URL | - | ✅ |
| `databricks_token` | Personal access token | - | ✅ |
| `databricks_warehouse_id` | SQL warehouse ID | - | ✅ |
| `catalog_name` | Unity Catalog name | `hive_metastore` | ✅ |
| `schema_name` | Schema name | - | ✅ |
| `table_name` | Target table name | - | ✅ |
| `volume_name` | Volume name for CSV files | - | ✅ |
| `aws_region` | AWS region | - | ✅ |

### Optional Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `environment` | Environment name (dev/staging/prod) | `dev` |
| `project_name` | Project identifier | - |
| `app_name` | Application name | `country-currency-app` |
| `skip_validation` | Skip resource validation | `false` |
| `create_schema` | Create new schema | `true` |
| `create_volume` | Create new volume | `true` |
| `create_table` | Create new table | `true` |
| `upload_csv` | Upload CSV file | `true` |

## 📊 Data Schema

The pipeline processes CSV data with the following structure:

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `country_code` | STRING | ISO 3166-1 alpha-3 country code | `USA` |
| `country_number` | INT | ISO 3166-1 numeric country code | `840` |
| `country` | STRING | Full country name | `UNITED STATES` |
| `currency_name` | STRING | Official currency name | `US Dollar` |
| `currency_code` | STRING | ISO 4217 currency code | `USD` |
| `currency_number` | INT | ISO 4217 numeric currency code | `840` |

## 🔧 Advanced Usage

### Working with Existing Resources

If you have existing Databricks resources, you can configure the pipeline to use them:

```hcl
# In terraform.tfvars
create_schema = false  # Use existing schema
create_volume = false  # Use existing volume
create_table = false   # Use existing table
upload_csv = false     # Skip CSV upload

skip_validation = true # Skip warehouse validation
```

### Custom Data Sources

To use your own CSV data:

1. Replace the CSV file in `etl_data/country_code_to_currency_code.csv`
2. Update the notebook if your data has a different schema
3. Redeploy the infrastructure

### Environment-Specific Deployments

Create environment-specific configurations:

```bash
# Create environment-specific tfvars files
cp terraform.tfvars terraform-dev.tfvars
cp terraform.tfvars terraform-prod.tfvars

# Deploy to specific environment
terraform apply -var-file="terraform-dev.tfvars"
```

## 🧪 Testing and Validation

### Data Quality Checks

The notebook includes automated data quality checks:
- **Null Value Detection**: Identifies null values in key columns
- **Record Count Validation**: Ensures all records are loaded successfully
- **Schema Validation**: Verifies data types and structure

### Manual Verification

After deployment, verify the pipeline by:

1. **Check Databricks Workspace**: Confirm resources are created
2. **Review Job Execution**: Check job run status and logs
3. **Query the Data**: Validate data in the Delta table

```sql
-- Sample query to verify data
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT country_code) as unique_countries,
    COUNT(DISTINCT currency_code) as unique_currencies
FROM your_catalog.your_schema.your_table;
```

## 🔍 Troubleshooting

### Common Issues

**Issue**: Terraform fails with authentication error
- **Solution**: Verify `databricks_token` and `databricks_host` are correct

**Issue**: SQL warehouse not found
- **Solution**: Check `databricks_warehouse_id` exists and is accessible

**Issue**: CSV upload fails
- **Solution**: Ensure the volume exists and has proper permissions

**Issue**: Job execution fails
- **Solution**: Check notebook parameters and SQL warehouse status

### Debug Commands

```bash
# Check Terraform state
terraform show

# Validate configuration
terraform validate

# Plan without applying
terraform plan

# Check Databricks CLI connectivity
databricks workspace list
```

## 📈 Monitoring and Maintenance

### Resource Monitoring

Monitor your deployment through:
- **Databricks Workspace**: Job runs, cluster usage, storage metrics
- **AWS Console**: S3 bucket usage, costs
- **Terraform State**: Resource drift detection

### Regular Maintenance

- **Update Dependencies**: Keep Terraform providers updated
- **Review Costs**: Monitor AWS and Databricks usage costs
- **Backup State**: Ensure Terraform state is backed up
- **Security Review**: Rotate tokens and review permissions regularly

## 🤝 Contributing

To contribute to this project:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Guidelines

- Add comments to all Terraform resources
- Include validation rules for variables
- Test changes in a development environment
- Update documentation for new features

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support and questions:

- **Issues**: Use GitHub Issues for bug reports and feature requests
- **Documentation**: Check this README and inline code comments
- **Databricks Docs**: [Official Databricks Documentation](https://docs.databricks.com/)
- **Terraform Docs**: [Terraform Databricks Provider](https://registry.terraform.io/providers/databricks/databricks/latest/docs)

## 🏷️ Tags

`databricks` `terraform` `etl` `data-pipeline` `infrastructure-as-code` `aws` `delta-lake` `data-engineering` `automation` `csv-processing`

---

**Last Updated**: May 28, 2025  
**Version**: 1.0.0  
**Terraform Version**: >= 1.0  
**Databricks Provider**: ~> 1.81.0
