#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deployment automation script for the Country Currency Mapping Data Pipeline

.DESCRIPTION
    This PowerShell script automates the deployment of the Databricks infrastructure
    and data pipeline. It provides options for deploying backend infrastructure,
    main Databricks resources, or both components together.

.PARAMETER Action
    The deployment action to perform:
    - "backend" - Deploy only the S3 backend infrastructure
    - "databricks" - Deploy only the Databricks infrastructure
    - "all" - Deploy both backend and Databricks infrastructure
    - "destroy" - Destroy all infrastructure (use with caution)

.PARAMETER Environment
    The target environment (dev, staging, prod). Default is "dev"

.PARAMETER TerraformVarsFile
    Name of the terraform.tfvars file (will be searched in environment directories). Default is "terraform.tfvars"

.EXAMPLE
    .\deploy.ps1 -Action "all" -Environment "dev"
    
.EXAMPLE
    .\deploy.ps1 -Action "backend" -TerraformVarsFile "terraform-prod.tfvars"

.NOTES
    Author: Data Engineering Team
    Last Updated: May 28, 2025
    Requires: Terraform >= 1.0, AWS CLI configured, Databricks access
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("backend", "databricks", "all", "destroy")]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment = "dev",
      [Parameter(Mandatory = $false)]
    [string]$TerraformVarsFile = "terraform.tfvars"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Define paths
$ScriptDir = $PSScriptRoot
$TerraformDir = Join-Path $ScriptDir "..\terraform"
$BackendDir = Join-Path $TerraformDir "$Environment-env\backend"
$DatabricksDir = Join-Path $TerraformDir "$Environment-env\databricks-ifra"

# Check if the vars file has a path separator, if not, look for it in both directories
if ($TerraformVarsFile -notmatch [regex]::Escape([IO.Path]::DirectorySeparatorChar)) {
    # Try to find the vars file in the backend directory first, then databricks directory
    $BackendVarsFile = Join-Path $BackendDir $TerraformVarsFile
    $DatabricksVarsFile = Join-Path $DatabricksDir $TerraformVarsFile
    
    if (Test-Path $BackendVarsFile) {
        $VarsFile = $BackendVarsFile
    } elseif (Test-Path $DatabricksVarsFile) {
        $VarsFile = $DatabricksVarsFile
    } else {
        # Default to the old behavior for backwards compatibility
        $VarsFile = Join-Path $TerraformDir $TerraformVarsFile
    }
} else {
    # User provided a path, use it as-is relative to script directory
    $VarsFile = Join-Path $ScriptDir $TerraformVarsFile
}

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-ColorOutput "🔍 Checking prerequisites..." "Yellow"
    
    # Check if Terraform is installed
    try {
        $terraformVersion = terraform version
        Write-ColorOutput "✅ Terraform found: $($terraformVersion[0])" "Green"
    }
    catch {
        Write-ColorOutput "❌ Terraform not found. Please install Terraform >= 1.0" "Red"
        exit 1
    }
    
    # Check if AWS CLI is installed
    try {
        $awsVersion = aws --version
        Write-ColorOutput "✅ AWS CLI found: $($awsVersion.Split()[0])" "Green"
    }
    catch {
        Write-ColorOutput "❌ AWS CLI not found. Please install and configure AWS CLI" "Red"
        exit 1
    }
    
    # Check if terraform.tfvars exists
    if (-not (Test-Path $VarsFile)) {
        Write-ColorOutput "❌ Terraform variables file not found: $VarsFile" "Red"
        Write-ColorOutput "Please copy terraform.tfvars.example to terraform.tfvars and configure it" "Yellow"
        exit 1
    }
    
    Write-ColorOutput "✅ All prerequisites met" "Green"
}

# Function to deploy backend infrastructure
function Deploy-Backend {
    Write-ColorOutput "🚀 Deploying backend infrastructure..." "Cyan"
    
    Set-Location $BackendDir
    
    # Use backend-specific vars file if it exists, otherwise use the discovered vars file
    $BackendVarsFile = Join-Path $BackendDir $TerraformVarsFile
    $ActualVarsFile = if (Test-Path $BackendVarsFile) { $BackendVarsFile } else { $VarsFile }
    
    Write-ColorOutput "Using variables file: $ActualVarsFile" "Gray"
    
    Write-ColorOutput "Initializing Terraform..." "Yellow"
    terraform init
    
    Write-ColorOutput "Planning deployment..." "Yellow"
    terraform plan -var-file="$ActualVarsFile"
    
    Write-ColorOutput "Applying configuration..." "Yellow"
    terraform apply -var-file="$ActualVarsFile" -auto-approve
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Backend infrastructure deployed successfully" "Green"
    } else {
        Write-ColorOutput "❌ Backend deployment failed" "Red"
        exit 1
    }
}

# Function to deploy Databricks infrastructure
function Deploy-Databricks {
    Write-ColorOutput "🚀 Deploying Databricks infrastructure..." "Cyan"
    
    Set-Location $DatabricksDir
    
    # Use databricks-specific vars file if it exists, otherwise use the discovered vars file
    $DatabricksVarsFile = Join-Path $DatabricksDir $TerraformVarsFile
    $ActualVarsFile = if (Test-Path $DatabricksVarsFile) { $DatabricksVarsFile } else { $VarsFile }
    
    Write-ColorOutput "Using variables file: $ActualVarsFile" "Gray"
    
    Write-ColorOutput "Initializing Terraform..." "Yellow"
    terraform init
    
    Write-ColorOutput "Planning deployment..." "Yellow"
    terraform plan -var-file="$ActualVarsFile"
    
    Write-ColorOutput "Applying configuration..." "Yellow"
    terraform apply -var-file="$ActualVarsFile" -auto-approve
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✅ Databricks infrastructure deployed successfully" "Green"
        
        # Display outputs
        Write-ColorOutput "📊 Deployment Summary:" "Cyan"
        terraform output
    } else {
        Write-ColorOutput "❌ Databricks deployment failed" "Red"
        exit 1
    }
}

# Function to destroy infrastructure
function Destroy-Infrastructure {
    Write-ColorOutput "⚠️  DESTROYING INFRASTRUCTURE - This action cannot be undone!" "Red"
    $confirmation = Read-Host "Type 'DESTROY' to confirm destruction"
    
    if ($confirmation -ne "DESTROY") {
        Write-ColorOutput "❌ Destruction cancelled" "Yellow"
        exit 0
    }
    
    # Destroy Databricks infrastructure first
    Write-ColorOutput "🗑️  Destroying Databricks infrastructure..." "Red"
    Set-Location $DatabricksDir
    $DatabricksVarsFile = Join-Path $DatabricksDir $TerraformVarsFile
    $ActualVarsFile = if (Test-Path $DatabricksVarsFile) { $DatabricksVarsFile } else { $VarsFile }
    terraform destroy -var-file="$ActualVarsFile" -auto-approve
    
    # Destroy backend infrastructure
    Write-ColorOutput "🗑️  Destroying backend infrastructure..." "Red"
    Set-Location $BackendDir
    $BackendVarsFile = Join-Path $BackendDir $TerraformVarsFile
    $ActualVarsFile = if (Test-Path $BackendVarsFile) { $BackendVarsFile } else { $VarsFile }
    terraform destroy -var-file="$ActualVarsFile" -auto-approve
    
    Write-ColorOutput "✅ Infrastructure destroyed" "Green"
}

# Main execution
try {
    Write-ColorOutput "🎯 Starting deployment process..." "Cyan"
    Write-ColorOutput "Action: $Action" "White"
    Write-ColorOutput "Environment: $Environment" "White"
    Write-ColorOutput "Variables file: $VarsFile" "White"
    Write-ColorOutput "----------------------------------------" "White"
    
    # Check prerequisites
    Test-Prerequisites
    
    # Execute requested action
    switch ($Action) {
        "backend" {
            Deploy-Backend
        }
        "databricks" {
            Deploy-Databricks
        }
        "all" {
            Deploy-Backend
            Deploy-Databricks
        }
        "destroy" {
            Destroy-Infrastructure
        }
    }
    
    Write-ColorOutput "🎉 Deployment process completed successfully!" "Green"
    
} catch {
    Write-ColorOutput "❌ Deployment failed: $($_.Exception.Message)" "Red"
    exit 1
} finally {
    # Return to original directory
    Set-Location $ScriptDir
}