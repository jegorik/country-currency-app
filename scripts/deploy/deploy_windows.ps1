# Windows deployment script for Country Currency App
# This script handles the deployment process specifically for Windows environments

# Display header
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Country Currency App - Windows Deployment" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
$Prerequisites = @("terraform", "pwsh")
$MissingPrerequisites = $false

foreach ($Tool in $Prerequisites) {
    try {
        $null = Get-Command $Tool -ErrorAction Stop
        Write-Host "✓ $Tool is installed" -ForegroundColor Green
    } catch {
        Write-Host "✗ $Tool is not installed" -ForegroundColor Red
        $MissingPrerequisites = $true
    }
}

if ($MissingPrerequisites) {
    Write-Host "Please install missing prerequisites and try again." -ForegroundColor Red
    exit 1
}

# Initialize Terraform
Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
Push-Location -Path (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "terraform")
try {
    terraform init

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform initialization failed." -ForegroundColor Red
        exit 1
    }

    # Validate Terraform configuration
    Write-Host "`nValidating Terraform configuration..." -ForegroundColor Yellow
    terraform validate

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform validation failed." -ForegroundColor Red
        exit 1
    }

    # Apply Terraform configuration
    Write-Host "`nApplying Terraform configuration..." -ForegroundColor Yellow
    terraform apply -auto-approve

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Terraform apply failed." -ForegroundColor Red
        exit 1
    }

    Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
    Write-Host "You can now access your Databricks resources." -ForegroundColor Green
} finally {
    Pop-Location
}
