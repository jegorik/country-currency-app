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

# Global variable for found vars file
$VarsFile = ""

# Function to find terraform vars file (universal logic)
function Find-VarsFile {
    $BackendDir = Join-Path $TerraformDir "$Environment-env\backend"
    $DatabricksDir = Join-Path $TerraformDir "$Environment-env\databricks-ifra"
    $EnvRootDir = Join-Path $TerraformDir "$Environment-env"
    
    # Initialize VarsFile as empty
    $script:VarsFile = ""
    
    # Case 1: User provided a path (contains "\" or "/")
    if ($TerraformVarsFile -match "[\\\/]") {
        $UserProvidedPath = Join-Path $ScriptDir $TerraformVarsFile
        if (Test-Path $UserProvidedPath) {
            $script:VarsFile = $UserProvidedPath
            Write-ColorOutput "📁 Using user-provided vars file: $($script:VarsFile)" "Cyan"
        } else {
            Write-ColorOutput "❌ User-provided vars file not found: $UserProvidedPath" "Red"
            exit 1
        }
    }
    # Case 2: User provided filename only (e.g., terraform.tfvars or terraform-prod.tfvars)
    elseif ($TerraformVarsFile -ne "terraform.tfvars") {
        # User provided a specific filename, look for it in standard locations
        $BackendVarsFile = Join-Path $BackendDir $TerraformVarsFile
        $DatabricksVarsFile = Join-Path $DatabricksDir $TerraformVarsFile
        $EnvRootVarsFile = Join-Path $EnvRootDir $TerraformVarsFile
        
        if (Test-Path $BackendVarsFile) {
            $script:VarsFile = $BackendVarsFile
        } elseif (Test-Path $DatabricksVarsFile) {
            $script:VarsFile = $DatabricksVarsFile
        } elseif (Test-Path $EnvRootVarsFile) {
            $script:VarsFile = $EnvRootVarsFile
        } else {
            Write-ColorOutput "❌ Specified vars file '$TerraformVarsFile' not found in any standard location" "Red"
            exit 1
        }
        Write-ColorOutput "📁 Using specified vars file: $($script:VarsFile)" "Cyan"
    }
    # Case 3: Default behavior (no specific file provided)
    else {
        # Look for terraform.tfvars in multiple locations and collect all valid files
        $FoundFiles = @()
        
        # Check backend directory
        $BackendVarsPath = Join-Path $BackendDir $TerraformVarsFile
        if (Test-Path $BackendVarsPath) {
            $FoundFiles += $BackendVarsPath
        }
        
        # Check databricks directory
        $DatabricksVarsPath = Join-Path $DatabricksDir $TerraformVarsFile
        if (Test-Path $DatabricksVarsPath) {
            $FoundFiles += $DatabricksVarsPath
        }
        
        # Check environment root directory
        $EnvRootVarsPath = Join-Path $EnvRootDir $TerraformVarsFile
        if (Test-Path $EnvRootVarsPath) {
            $FoundFiles += $EnvRootVarsPath
        }
        
        if ($FoundFiles.Count -eq 0) {
            # No files found, set to first preference for error reporting
            $script:VarsFile = Join-Path $BackendDir $TerraformVarsFile
            Write-ColorOutput "⚠️  No terraform.tfvars files found in standard locations" "Yellow"
        } else {
            # Files found - we'll use all of them for configuration validation
            $script:VarsFile = $FoundFiles[0]  # Set primary file for prerequisites check
            Write-ColorOutput "📁 Found terraform.tfvars files: $($FoundFiles.Count)" "Cyan"
            foreach ($file in $FoundFiles) {
                Write-ColorOutput "   - $file" "Gray"
            }
        }
    }
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
    
    $AllGood = $true
    
    # Check if Terraform is installed
    try {
        $terraformVersion = terraform version | Select-Object -First 1
        Write-ColorOutput "✅ Terraform found: $terraformVersion" "Green"
    }
    catch {
        Write-ColorOutput "❌ Terraform not found. Please install Terraform >= 1.0" "Red"
        $AllGood = $false
    }
    
    # Check if AWS CLI is installed
    try {
        $awsVersion = aws --version
        $awsVersionShort = ($awsVersion -split ' ')[0]
        Write-ColorOutput "✅ AWS CLI found: $awsVersionShort" "Green"
        
        # Check AWS credentials
        try {
            $awsAccount = aws sts get-caller-identity --query Account --output text 2>$null
            $awsRegion = aws configure get region 2>$null
            if (-not $awsRegion) { $awsRegion = "not-set" }
            Write-ColorOutput "✅ AWS credentials configured (Account: $awsAccount, Region: $awsRegion)" "Green"
        }
        catch {
            Write-ColorOutput "❌ AWS credentials not configured" "Red"
            $AllGood = $false
        }
    }
    catch {
        Write-ColorOutput "❌ AWS CLI not found. Please install and configure AWS CLI" "Red"
        $AllGood = $false
    }
    
    # Check if Databricks CLI is installed (optional)
    try {
        $databricksVersion = databricks --version 2>$null
        Write-ColorOutput "✅ Databricks CLI found: $databricksVersion" "Green"
    }
    catch {
        Write-ColorOutput "⚠️  Databricks CLI not found" "Yellow"
        Write-ColorOutput "   Install with: pip install databricks-cli" "Gray"
        Write-ColorOutput "   This is optional but recommended for full validation" "Gray"
    }
    
    # Check if terraform.tfvars exists
    if (-not (Test-Path $VarsFile)) {
        Write-ColorOutput "❌ Terraform variables file not found: $VarsFile" "Red"
        Write-ColorOutput "Please copy terraform.tfvars.example to terraform.tfvars and configure it" "Yellow"
        $AllGood = $false
    } else {
        Write-ColorOutput "✅ Variables file found: $VarsFile" "Green"
    }
    
    if (-not $AllGood) {
        Write-ColorOutput "❌ Prerequisites check failed" "Red"
        exit 1
    }
    
    Write-ColorOutput "✅ All prerequisites met" "Green"
}

# Function to deploy backend infrastructure
function Deploy-Backend {
    Write-ColorOutput "🚀 Deploying backend infrastructure..." "Cyan"
    
    Push-Location $BackendDir
    
    try {
        # Use backend-specific vars file if it exists, otherwise use the discovered vars file
        $BackendVarsFile = Join-Path $BackendDir $TerraformVarsFile
        $ActualVarsFile = if (Test-Path $BackendVarsFile) { $BackendVarsFile } else { $VarsFile }
        
        Write-ColorOutput "Using variables file: $ActualVarsFile" "Gray"
        
        Write-ColorOutput "Initializing Terraform..." "Yellow"
        terraform init
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform init failed"
        }
        
        Write-ColorOutput "Planning deployment..." "Yellow"
        terraform plan -var-file="$ActualVarsFile"
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform plan failed"
        }
        
        Write-ColorOutput "Applying configuration..." "Yellow"
        terraform apply -var-file="$ActualVarsFile" -auto-approve
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform apply failed"
        }
        
        Write-ColorOutput "✅ Backend infrastructure deployed successfully" "Green"
    }
    catch {
        Write-ColorOutput "❌ Backend deployment failed: $($_.Exception.Message)" "Red"
        throw
    }
    finally {
        Pop-Location
    }
}

# Function to deploy Databricks infrastructure
function Deploy-Databricks {
    Write-ColorOutput "🚀 Deploying Databricks infrastructure..." "Cyan"
    
    Push-Location $DatabricksDir
    
    try {
        # Use databricks-specific vars file if it exists, otherwise use the discovered vars file
        $DatabricksVarsFile = Join-Path $DatabricksDir $TerraformVarsFile
        $ActualVarsFile = if (Test-Path $DatabricksVarsFile) { $DatabricksVarsFile } else { $VarsFile }
        
        Write-ColorOutput "Using variables file: $ActualVarsFile" "Gray"
        
        Write-ColorOutput "Initializing Terraform..." "Yellow"
        terraform init
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform init failed"
        }
        
        Write-ColorOutput "Planning deployment..." "Yellow"
        terraform plan -var-file="$ActualVarsFile"
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform plan failed"
        }
        
        Write-ColorOutput "Applying configuration..." "Yellow"
        terraform apply -var-file="$ActualVarsFile" -auto-approve
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform apply failed"
        }
        
        Write-ColorOutput "✅ Databricks infrastructure deployed successfully" "Green"
        
        # Display outputs
        Write-ColorOutput "📊 Deployment Summary:" "Cyan"
        terraform output
    }
    catch {
        Write-ColorOutput "❌ Databricks deployment failed: $($_.Exception.Message)" "Red"
        throw
    }
    finally {
        Pop-Location
    }
}

# Function to destroy infrastructure
function Destroy-Infrastructure {
    Write-ColorOutput "⚠️  DESTROYING INFRASTRUCTURE - This action cannot be undone!" "Red"
    $confirmation = Read-Host "Type 'DESTROY' to confirm destruction"
    
    if ($confirmation -ne "DESTROY") {
        Write-ColorOutput "❌ Destruction cancelled" "Yellow"
        return
    }
    
    try {
        # Destroy Databricks infrastructure first
        Write-ColorOutput "🗑️  Destroying Databricks infrastructure..." "Red"
        Push-Location $DatabricksDir
        
        try {
            $DatabricksVarsFile = Join-Path $DatabricksDir $TerraformVarsFile
            $ActualVarsFile = if (Test-Path $DatabricksVarsFile) { $DatabricksVarsFile } else { $VarsFile }
            terraform destroy -var-file="$ActualVarsFile" -auto-approve
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput "⚠️  Databricks destruction had issues but continuing..." "Yellow"
            }
        }
        finally {
            Pop-Location
        }
        
        # Destroy backend infrastructure
        Write-ColorOutput "🗑️  Destroying backend infrastructure..." "Red"
        Push-Location $BackendDir
        
        try {
            $BackendVarsFile = Join-Path $BackendDir $TerraformVarsFile
            $ActualVarsFile = if (Test-Path $BackendVarsFile) { $BackendVarsFile } else { $VarsFile }
            terraform destroy -var-file="$ActualVarsFile" -auto-approve
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput "⚠️  Backend destruction had issues" "Yellow"
            }
        }
        finally {
            Pop-Location
        }
        
        Write-ColorOutput "✅ Infrastructure destruction completed" "Green"
    }
    catch {
        Write-ColorOutput "❌ Destruction failed: $($_.Exception.Message)" "Red"
        throw
    }
}

# Main execution
try {
    # Find vars file using universal logic
    Find-VarsFile
    
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
    # Return to original directory (cleanup)
    Set-Location $ScriptDir
}