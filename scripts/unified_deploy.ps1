# Enhanced Windows deployment script for Country Currency App
# This script handles the deployment process for Windows environments

# Display header
function Display-Header {
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "  Country Currency App - Windows Deployment" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
}

# Check prerequisites for Windows
function Check-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Yellow
    $Prerequisites = @("terraform", "curl")
    $MissingPrerequisites = $false

    foreach ($Tool in $Prerequisites) {
        try {
            $null = Get-Command $Tool -ErrorAction Stop
            Write-Host "✓ $Tool is installed" -ForegroundColor Green
        } 
        catch {
            Write-Host "✗ $Tool is not installed" -ForegroundColor Red
            $MissingPrerequisites = $true
        }
    }

    if ($MissingPrerequisites) {
        Write-Host "Please install missing prerequisites and try again." -ForegroundColor Red
        exit 1
    }
}

# Execute Terraform commands for Windows
function Execute-TerraformDeployment {
    # Navigate to Terraform directory
    Write-Host "Navigating to Terraform directory..." -ForegroundColor Yellow
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $TerraformDir = Join-Path -Path (Split-Path -Parent $ScriptDir) -ChildPath "terraform"
    Push-Location -Path $TerraformDir

    # Initialize Terraform
    Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
    terraform init
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform initialization failed." -ForegroundColor Red
        Pop-Location
        exit 1
    }

    # Validate Terraform configuration
    Write-Host "`nValidating Terraform configuration..." -ForegroundColor Yellow
    terraform validate
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform validation failed." -ForegroundColor Red
        Pop-Location
        exit 1
    }

    # Apply Terraform configuration
    Write-Host "`nApplying Terraform configuration..." -ForegroundColor Yellow
    terraform apply -auto-approve
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform apply failed." -ForegroundColor Red
        Pop-Location
        exit 1
    }

    # Return to original directory
    Pop-Location
    
    Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
    Write-Host "You can now access your Databricks resources." -ForegroundColor Green
}

# Main execution flow
Display-Header
Check-Prerequisites
Execute-TerraformDeployment
