# Country Currency App User Guide

## Overview

The Country Currency App provides mapping between countries and their corresponding currencies. It loads data from a CSV file into a Databricks Delta table and provides a query interface to retrieve currency information by country code.

## Prerequisites

Before using the application, ensure you have:

1. Access to a Databricks workspace with appropriate permissions
2. SQL warehouse access for querying data
3. The country-to-currency CSV data in the specified volume location

## Setup and Configuration

### Initial Setup

1. Clone the repository
   ```bash
   git clone [repository-url]
   cd country-currency-app
   ```

2. Configure your Databricks CLI credentials
   ```bash
   ./setup.sh
   ```

3. Deploy the infrastructure with Terraform
   ```bash
   terraform init
   terraform apply -var-file=environments/dev.tfvars
   ```

### Environment Configuration

The application supports multiple environments (dev, test, prod) with different configurations:

- **Development**: `environments/dev.tfvars`
- **Testing**: `environments/test.tfvars`
- **Production**: `environments/prod.tfvars`

## Using the Application

### Loading Data

Data is loaded into Databricks using the `load_data_notebook_jupyter.ipynb` notebook. This notebook:

1. Reads country-to-currency mappings from a CSV file
2. Performs data validation and quality checks
3. Loads the data into a Delta table for querying

#### Notebook Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| catalog_name | The Databricks catalog name | main |
| schema_name | The schema for the table | country_currency |
| table_name | The name of the table | country_code_to_currency_code |
| csv_path | Path to the CSV file | /Volumes/country_currency_data/csv_data/country_code_to_currency_code.csv |
| warehouse_id | SQL warehouse ID (optional) | 123456789abcdef |

### Querying Data

After data is loaded, you can query it using SQL:

```sql
SELECT * FROM main.country_currency.country_code_to_currency_code
WHERE country_code = 'US';
```

Common queries:

1. Get currency for a specific country:
   ```sql
   SELECT currency_code FROM main.country_currency.country_code_to_currency_code
   WHERE country_code = '[country_code]';
   ```

2. Get all countries using a specific currency:
   ```sql
   SELECT country_code, country_name FROM main.country_currency.country_code_to_currency_code
   WHERE currency_code = '[currency_code]';
   ```

## Troubleshooting

For common issues and their solutions, refer to `TROUBLESHOOTING.md`.

If you encounter data loading issues:

1. Check CSV file format (column names, delimiters)
2. Verify access permissions to the volume
3. Run data validation checks manually

For infrastructure issues, see `terraform.tfstate` for the current state of resources.

## Contributing

For guidelines on contributing to this project, please refer to `CONTRIBUTING.md`.

When making changes to the notebooks, ensure they pass validation:
```bash
./validate_notebook.sh
```
