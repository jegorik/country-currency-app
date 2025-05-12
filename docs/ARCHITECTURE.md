# Country Currency App - Technical Architecture

## Overview
This document outlines the technical architecture of the Country Currency Application, which is designed to process, store, and provide access to country-to-currency mapping data in a Databricks environment. The architecture leverages Databricks' capabilities for data processing and storage, with infrastructure managed through Terraform.

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────┐
│                     Terraform                            │
└──────────┬─────────────────────────────────┬─────────────┘
           │                                 │
           ▼                                 ▼
┌──────────────────────┐       ┌──────────────────────────┐
│ Infrastructure Code  │       │   Deployment Process     │
│                      │       │                          │
│ - main.tf            │       │ 1. terraform init        │
│ - variables.tf       │       │ 2. terraform plan        │
│ - provider.tf        │       │ 3. terraform apply       │
│ - outputs.tf         │       │                          │
└──────────┬───────────┘       └──────────────┬───────────┘
           │                                  │
           └──────────────┬──────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                 Databricks Workspace                    │
│                                                         │
│  ┌─────────────────┐      ┌───────────────────────┐    │
│  │  Unity Catalog  │      │     SQL Warehouse     │    │
│  │                 │      │                       │    │
│  │  Catalog        │      │  Query Engine for     │    │
│  │  └── Schema     │◄────►│  Data Processing      │    │
│  │      └── Table  │      │                       │    │
│  └────────┬────────┘      └───────────────────────┘    │
│           │                                            │
│  ┌────────▼────────┐      ┌───────────────────────┐    │
│  │    Volume       │      │      Notebook         │    │
│  │                 │      │                       │    │
│  │  CSV Storage    │─────►│  Data Processing      │    │
│  │                 │      │  Logic               │    │
│  └─────────────────┘      └───────────────────────┘    │
│                                      │                 │
│                           ┌──────────▼─────────┐       │
│                           │        Job         │       │
│                           │                    │       │
│                           │  Scheduled         │       │
│                           │  Execution         │       │
│                           └────────────────────┘       │
└─────────────────────────────────────────────────────────┘
```

## Component Description

### 1. Infrastructure as Code (Terraform)
* **Provider Configuration**: Sets up authentication with Databricks API
* **Resource Definitions**: Defines all required Databricks resources
* **Variables**: Parameterizes the deployment for different environments

### 2. Databricks Components
* **Unity Catalog**: Hierarchical organization of data assets
  * **Catalog**: Top-level container for data objects
  * **Schema**: Organizes tables within a catalog
  * **Table**: Delta table storing the country-currency mapping data
* **Volume**: Storage location for the CSV data files
* **SQL Warehouse**: Compute resource for running SQL queries and data processing
* **Notebook**: Python code for ETL operations
* **Job**: Scheduled execution of the data loading notebook

### 3. Data Flow
1. CSV data is stored in the local project repository
2. Terraform uploads the CSV to a Databricks volume
3. Notebook reads the CSV data and processes it
4. Data is written to a Delta table in the configured schema
5. Job orchestrates and schedules the data loading process

### 4. Security Considerations
* API tokens are stored securely and marked as sensitive in Terraform
* Unity Catalog provides fine-grained access control to data assets
* Source data integrity is validated during processing

## Performance Optimizations
* Delta Lake format for efficient storage and querying
* SQL warehouse sizing based on data volume
* Data validation to ensure quality

## Notebook Execution Model

### 1. Notebook Structure
The data processing notebook (`load_data_notebook_jupyter.ipynb`) follows a specific cell-based execution model:

1. **Import and Function Definition Cells** - Contains library imports and function definitions
2. **Parameter Widget Definition Cell** - Creates notebook widgets for parameterized execution
3. **Parameter Validation Cell** - Validates all required parameters are present
4. **Data Processing Cells** - Executes the data loading workflow:
   - CSV data reading
   - Data quality checks
   - Delta table writing
   - Data load validation

### 2. Notebook-Table Interaction
Notebooks interact with tables through the following mechanisms:
* Reading from volumes using the Spark CSV reader
* Writing to tables using Delta Lake format
* Data transformation using Spark DataFrame operations
* Schema inference with manual overrides for type safety

### 3. Execution Context
The notebook runs in the context of:
* The assigned SQL warehouse for compute resources
* The authenticated user or service principal
* The Unity Catalog security model

## Data Schema Design

### 1. Table Schema
The country-currency mapping table includes the following columns:

| Column Name      | Data Type | Description                        | Nullable | 
|------------------|----------|------------------------------------|----------|
| country_code     | STRING   | ISO 3166-1 alpha-3 country code    | Yes      |
| country_number   | INT      | ISO 3166-1 numeric country code    | Yes      |
| country          | STRING   | Country name                       | Yes      |
| currency_name    | STRING   | Currency name                      | Yes      |
| currency_code    | STRING   | ISO 4217 currency code             | Yes      |
| currency_number  | INT      | ISO 4217 numeric currency code     | Yes      |
| processing_time  | TIMESTAMP| Timestamp when the data was loaded | Yes      |

### 2. Schema Considerations
* The `processing_time` column is automatically added by the notebook during data processing
* All columns are defined in both the Terraform configuration and the notebook
* Schema evolution is handled through Delta Lake features like `mergeSchema` and `overwriteSchema`

## Monitoring and Maintenance
* Job run logs provide visibility into execution status
* Delta table history tracks changes to the data
* Infrastructure is version controlled and reproducible

## Development Workflow
1. Make changes to infrastructure code or notebooks locally
2. Test in development environment
3. Promote to test/prod environments using CI/CD pipelines
