#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validation script for the Country Currency Mapping Data Pipeline

.DESCRIPTION
    This PowerShell script validates the deployment and configuration of the
    Databricks infrastructure and data pipeline. It checks resource status,
    data integrity, and configuration correctness.

.PARAMETER Environment
    The target environment to validate (dev, staging, prod). Default is "dev"

.PARAMETER TerraformVarsFile
    Name of the terraform.tfvars file (will be searched in environment directories). Default is "terraform.tfvars"

.PARAMETER CheckData
    Whether to perform data validation checks. Default is $true

.EXAMPLE
    .\validate.ps1 -Environment "dev" -CheckData $true
    
.EXAMPLE
    .\validate.ps1 -TerraformVarsFile "terraform-prod.tfvars"

.NOTES
    Author: Data Engineering Team
    Last Updated: May 28, 2025
    Requires: Terraform >= 1.0, Databricks CLI (optional)
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment = "dev",
      [Parameter(Mandatory = $false)]
    [string]$TerraformVarsFile = "terraform.tfvars",
    
    [Parameter(Mandatory = $false)]
    [bool]$CheckData = $true
)

# Set error action preference
$ErrorActionPreference = "Continue"

# Define paths
$ScriptDir = $PSScriptRoot
$TerraformDir = Join-Path $ScriptDir "..\terraform"
$BackendDir = Join-Path $TerraformDir "$Environment-env\backend"
$DatabricksDir = Join-Path $TerraformDir "$Environment-env\databricks-ifra"
$DataFile = Join-Path $ScriptDir "..\etl_data\country_code_to_currency_code.csv"

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

# Validation results
$ValidationResults = @{
    "Prerequisites" = $false
    "BackendState" = $false
    "DatabricksState" = $false
    "DataFile" = $false
    "Configuration" = $false
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
    Write-ColorOutput "🔍 Validating prerequisites..." "Yellow"
    
    $allGood = $true
    
    # Check Terraform
    try {
        $terraformVersion = terraform version 2>$null
        Write-ColorOutput "✅ Terraform: $($terraformVersion[0])" "Green"
    }
    catch {
        Write-ColorOutput "❌ Terraform not found or not working" "Red"
        $allGood = $false
    }
    
    # Check AWS CLI
    try {
        $awsVersion = aws --version 2>$null
        Write-ColorOutput "✅ AWS CLI: $($awsVersion.Split()[0])" "Green"
    }
    catch {
        Write-ColorOutput "❌ AWS CLI not found or not configured" "Red"
        $allGood = $false
    }
    
    # Check variables file
    if (Test-Path $VarsFile) {
        Write-ColorOutput "✅ Variables file found: $VarsFile" "Green"
    } else {
        Write-ColorOutput "❌ Variables file not found: $VarsFile" "Red"
        $allGood = $false
    }
    
    $ValidationResults["Prerequisites"] = $allGood
    return $allGood
}

# Function to validate backend state
function Test-BackendState {
    Write-ColorOutput "🔍 Validating backend infrastructure..." "Yellow"
    
    try {
        Set-Location $BackendDir
        
        # Check if Terraform is initialized
        if (-not (Test-Path ".terraform")) {
            Write-ColorOutput "⚠️  Backend Terraform not initialized" "Yellow"
            return $false
        }
        
        # Check Terraform state
        $stateOutput = terraform show -json 2>$null | ConvertFrom-Json
        
        if ($stateOutput.values.root_module.resources.Count -gt 0) {
            Write-ColorOutput "✅ Backend state valid - Resources deployed" "Green"
            
            # Show backend resources
            $resources = $stateOutput.values.root_module.resources | ForEach-Object { $_.type }
            Write-ColorOutput "   Resources: $($resources -join ', ')" "Gray"
            
            $ValidationResults["BackendState"] = $true
            return $true
        } else {
            Write-ColorOutput "❌ Backend state shows no resources" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "❌ Backend validation failed: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to validate Databricks infrastructure
function Test-DatabricksState {
    Write-ColorOutput "🔍 Validating Databricks infrastructure..." "Yellow"
    
    try {
        Set-Location $DatabricksDir
        
        # Check if Terraform is initialized
        if (-not (Test-Path ".terraform")) {
            Write-ColorOutput "⚠️  Databricks Terraform not initialized" "Yellow"
            return $false
        }
        
        # Check Terraform state
        $stateOutput = terraform show -json 2>$null | ConvertFrom-Json
        
        if ($stateOutput.values.root_module.resources.Count -gt 0) {
            Write-ColorOutput "✅ Databricks state valid - Resources deployed" "Green"
            
            # Count different resource types
            $resourceTypes = $stateOutput.values.root_module.resources | Group-Object -Property type
            foreach ($group in $resourceTypes) {
                Write-ColorOutput "   $($group.Name): $($group.Count)" "Gray"
            }
            
            $ValidationResults["DatabricksState"] = $true
            return $true
        } else {
            Write-ColorOutput "❌ Databricks state shows no resources" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "❌ Databricks validation failed: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to validate data file
function Test-DataFile {
    Write-ColorOutput "🔍 Validating data file..." "Yellow"
    
    try {
        if (Test-Path $DataFile) {
            $csvData = Import-Csv $DataFile
            $recordCount = $csvData.Count
            $columns = $csvData[0].PSObject.Properties.Name
            
            Write-ColorOutput "✅ Data file found: $DataFile" "Green"
            Write-ColorOutput "   Records: $recordCount" "Gray"
            Write-ColorOutput "   Columns: $($columns -join ', ')" "Gray"
            
            # Validate required columns
            $requiredColumns = @("country_code", "country_number", "country", "currency_name", "currency_code", "currency_number")
            $missingColumns = $requiredColumns | Where-Object { $_ -notin $columns }
            
            if ($missingColumns.Count -eq 0) {
                Write-ColorOutput "✅ All required columns present" "Green"
                
                # Basic data quality checks
                $nullCountryCode = ($csvData | Where-Object { -not $_.country_code }).Count
                $nullCurrencyCode = ($csvData | Where-Object { -not $_.currency_code }).Count
                
                if ($nullCountryCode -eq 0 -and $nullCurrencyCode -eq 0) {
                    Write-ColorOutput "✅ No null values in key columns" "Green"
                    $ValidationResults["DataFile"] = $true
                    return $true
                } else {
                    Write-ColorOutput "⚠️  Found null values - Country: $nullCountryCode, Currency: $nullCurrencyCode" "Yellow"
                    return $false
                }
            } else {
                Write-ColorOutput "❌ Missing required columns: $($missingColumns -join ', ')" "Red"
                return $false
            }
        } else {
            Write-ColorOutput "❌ Data file not found: $DataFile" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "❌ Data validation failed: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to validate configuration
function Test-Configuration {
    Write-ColorOutput "🔍 Validating configuration..." "Yellow"
    
    try {
        # Check both backend and databricks configuration files
        $BackendVarsFile = Join-Path $BackendDir $TerraformVarsFile
        $DatabricksVarsFile = Join-Path $DatabricksDir $TerraformVarsFile
        
        $allFoundConfig = @()
        
        # Read backend configuration
        if (Test-Path $BackendVarsFile) {
            $backendConfig = Get-Content $BackendVarsFile | Where-Object { $_ -notmatch "^\s*#" -and $_ -notmatch "^\s*$" }
            foreach ($line in $backendConfig) {
                if ($line -match "^\s*(\w+)\s*=") {
                    $allFoundConfig += $matches[1]
                }
            }
        }
        
        # Read databricks configuration
        if (Test-Path $DatabricksVarsFile) {
            $databricksConfig = Get-Content $DatabricksVarsFile | Where-Object { $_ -notmatch "^\s*#" -and $_ -notmatch "^\s*$" }
            foreach ($line in $databricksConfig) {
                if ($line -match "^\s*(\w+)\s*=") {
                    $allFoundConfig += $matches[1]
                }
            }
        }
        
        # Check for key configuration items across both files
        $requiredConfig = @(
            "databricks_host",
            "databricks_token",
            "databricks_warehouse_id",
            "catalog_name",
            "schema_name",
            "table_name",
            "volume_name",
            "aws_region"
        )
        
        # Remove duplicates from found config
        $allFoundConfig = $allFoundConfig | Sort-Object -Unique
        
        $missingConfig = $requiredConfig | Where-Object { $_ -notin $allFoundConfig }
        
        if ($missingConfig.Count -eq 0) {
            Write-ColorOutput "✅ All required configuration parameters found" "Green"
            Write-ColorOutput "   Configured parameters: $($allFoundConfig.Count)" "Gray"
            $ValidationResults["Configuration"] = $true
            return $true
        } else {
            Write-ColorOutput "❌ Missing configuration parameters: $($missingConfig -join ', ')" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "❌ Configuration validation failed: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to display validation summary
function Show-ValidationSummary {
    Write-ColorOutput "`n📊 Validation Summary" "Cyan"
    Write-ColorOutput "=====================" "Cyan"
    
    $passedCount = 0
    $totalCount = $ValidationResults.Count
    
    foreach ($test in $ValidationResults.GetEnumerator()) {
        $status = if ($test.Value) { "✅ PASS" } else { "❌ FAIL" }
        $color = if ($test.Value) { "Green" } else { "Red" }
        
        Write-ColorOutput "$($test.Key): $status" $color
        
        if ($test.Value) {
            $passedCount++
        }
    }
    
    Write-ColorOutput "`nOverall Result: $passedCount/$totalCount tests passed" "White"
    
    if ($passedCount -eq $totalCount) {
        Write-ColorOutput "🎉 All validations passed! The pipeline is ready." "Green"
        return $true
    } else {
        Write-ColorOutput "⚠️  Some validations failed. Please review and fix issues." "Yellow"
        return $false
    }
}

# Main execution
try {
    Write-ColorOutput "🎯 Starting validation process..." "Cyan"
    Write-ColorOutput "Environment: $Environment" "White"
    Write-ColorOutput "Backend config: $BackendDir\$TerraformVarsFile" "White"
    Write-ColorOutput "Databricks config: $DatabricksDir\$TerraformVarsFile" "White"
    Write-ColorOutput "Data validation: $CheckData" "White"
    Write-ColorOutput "========================================" "White"
    
    # Run validations
    Test-Prerequisites
    Test-Configuration
    
    if (Test-Path $BackendDir) {
        Test-BackendState
    } else {
        Write-ColorOutput "⚠️  Backend directory not found, skipping backend validation" "Yellow"
    }
    
    if (Test-Path $DatabricksDir) {
        Test-DatabricksState
    } else {
        Write-ColorOutput "⚠️  Databricks directory not found, skipping Databricks validation" "Yellow"
    }
    
    if ($CheckData) {
        Test-DataFile
    }
    
    # Show summary
    $success = Show-ValidationSummary
    
    if ($success) {
        exit 0
    } else {
        exit 1
    }
    
} catch {
    Write-ColorOutput "❌ Validation process failed: $($_.Exception.Message)" "Red"
    exit 1
} finally {
    # Return to original directory
    Set-Location $ScriptDir
}
