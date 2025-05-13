# Component Architecture Diagram

## Overview

This document provides a visual representation of the Country Currency App's components and their relationships.

## System Components

```
┌───────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                   │     │                 │     │                 │
│   CSV Data File   │───> │  Databricks     │────>│  Delta Table    │
│                   │     │  Notebook       │     │                 │
└───────────────────┘     └─────────────────┘     └─────────────────┘
                               │                           │
                               │                           │
                               ▼                           ▼
┌───────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                   │     │                 │     │                 │
│   GitHub Actions  │────>│  Terraform      │────>│  Databricks     │
│   CI/CD Pipeline  │     │  Configuration  │     │  Resources      │
│                   │     │                 │     │                 │
└───────────────────┘     └─────────────────┘     └─────────────────┘
```

## Data Flow

1. **Data Source**: CSV files containing country-to-currency mappings are stored in the `csv_data` directory
2. **Processing**: Databricks notebook (`load_data_notebook_jupyter.ipynb`) processes the data
3. **Storage**: Data is stored in a Delta table in the specified Databricks catalog/schema
4. **Access**: Data can be queried via Databricks SQL or notebooks

## Infrastructure Components

### CI/CD Pipeline

The GitHub Actions workflow manages the following steps:
- Validates notebook structure and syntax
- Runs Python tests
- Deploys to development, testing, and production environments based on branch

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│    Validate     │────>│      Test       │────>│     Deploy      │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Terraform Resources

The Terraform files provision:
- Databricks catalog
- Databricks schema
- Delta table
- Volumes for data storage
- Databricks job for automated data loading

## Environment Setup

```
┌───────────────────────────────────────────────┐
│                                               │
│                 Terraform                     │
│                                               │
├───────────────┬───────────────┬───────────────┤
│               │               │               │
│      Dev      │     Test      │     Prod      │
│               │               │               │
└───────────────┴───────────────┴───────────────┘
```

Each environment has its own configuration stored in the `environments` directory.
