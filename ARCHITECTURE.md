# Country Currency App - Technical Architecture

## Overview
This document outlines the technical architecture of the Country Currency Application, which is designed to process, store, and provide access to country-to-currency mapping data in a Databricks environment.

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

## Monitoring and Maintenance
* Job run logs provide visibility into execution status
* Delta table history tracks changes to the data
* Infrastructure is version controlled and reproducible

## Development Workflow
1. Make changes to infrastructure code or notebooks locally
2. Test in development environment
3. Promote to test/prod environments using CI/CD pipelines
