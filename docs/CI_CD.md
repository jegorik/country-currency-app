# CI/CD Implementation Guide

This document provides details on the Continuous Integration and Continuous Deployment (CI/CD) implementation for the Country Currency App.

## Overview

The CI/CD pipeline automates the process of testing, building, and deploying the Country Currency App across multiple environments (development, test, production). It uses GitHub Actions to orchestrate the workflow.

## CI/CD Pipeline Architecture

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐      ┌────────────────┐
│              │      │              │      │              │      │                │
│   Validate   ├─────►│     Test     ├─────►│    Build     ├─────►│    Deploy      │
│              │      │              │      │              │      │                │
└──────────────┘      └──────────────┘      └──────────────┘      └────────────────┘
     │                      │                     │                      │
     ▼                      ▼                     ▼                      ▼
┌──────────────┐      ┌──────────────┐      ┌──────────────┐      ┌────────────────┐
│- Lint code   │      │- Run tests   │      │- Package     │      │- Dev           │
│- Terraform   │      │- Terraform   │      │  artifacts   │      │- Test (manual) │
│  validation  │      │  plan        │      │- Generate    │      │- Prod (manual) │
│- Syntax check│      │              │      │  docs        │      │  approval      │
└──────────────┘      └──────────────┘      └──────────────┘      └────────────────┘
```

## Environment Strategy

1. **Development (dev)**: 
   - Automatic deployment on pushes to the `develop` branch
   - Used for ongoing development and testing
   - Less restrictive permissions

2. **Test (test)**:
   - Manual trigger required
   - Used for integration testing and feature validation
   - Mimics production with similar data volumes

3. **Production (prod)**:
   - Manual trigger with approval required
   - Strict access controls
   - Automatic rollback on failure

## GitHub Actions Workflow

The project uses multiple GitHub Actions workflows:

### Main CI/CD Pipeline

The main CI/CD pipeline is defined in `.github/workflows/ci-cd.yml` and consists of the following jobs:

1. **Validate**:
   - Checks code syntax and style
   - Validates Terraform configurations
   - Ensures code meets quality standards

### Terraform Compliance Workflow

A separate workflow for infrastructure policy checking is defined in `.github/workflows/terraform-compliance.yml`. This workflow:

- Runs on pull requests that modify Terraform files
- Uses a custom mock plan generator to avoid provider authentication issues
- Validates infrastructure against policy rules defined in `compliance/` directory
- Posts results to pull requests when issues are found

For detailed information about the terraform-compliance workflow, see [TERRAFORM_COMPLIANCE.md](./TERRAFORM_COMPLIANCE.md).

2. **Test**:
   - Runs automated tests on the codebase
   - Performs Terraform plan to validate infrastructure changes
   - Verifies notebook functionality (mock tests)

3. **Build**:
   - Creates deployment artifacts
   - Packages code and resources together
   - Prepares for deployment to target environments

4. **Deploy-Dev/Test/Prod**:
   - Environment-specific deployment jobs
   - Uses appropriate configuration for each environment
   - Includes necessary approvals for higher environments

## Environment Variables and Secrets

The following secrets need to be configured in GitHub:

- `DATABRICKS_HOST`: The Databricks workspace URL
- `DATABRICKS_TOKEN`: Authentication token for Databricks API
- `DATABRICKS_WAREHOUSE_ID`: ID of the SQL warehouse to use

Environment-specific variables are stored in the `environments/` directory as `.tfvars` files.

## Infrastructure as Code

All infrastructure is defined as code using Terraform:
- Resources are defined in `main.tf` and related files
- Environment-specific configurations are in `environments/*.tfvars`
- Terraform state is stored remotely as configured in `backend.tf`

## Monitoring and Logging

- Job logs are available in the Databricks workspace
- GitHub Actions workflow logs provide CI/CD execution details
- Deployment status is visible in the GitHub interface

## Rollback Procedures

If a deployment fails or causes issues:

1. **Automated Rollback**:
   - Failed deployments in production automatically trigger a rollback to the previous known-good state

2. **Manual Rollback**:
   - Re-run the GitHub Action workflow with the previous commit
   - Use Terraform to restore from a previous state snapshot

## Local Development vs CI/CD

- Local development uses `setup.sh` for initial configuration
- CI/CD uses GitHub Actions for automated, reproducible builds
- Both use the same underlying Terraform code for consistent environments
