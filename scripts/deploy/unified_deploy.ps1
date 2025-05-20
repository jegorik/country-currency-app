# Enhanced Windows deployment script for Country Currency App
# This script handles the deployment process for Windows environments

# Display header
function Display-Header {
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "  Country Currency App - Windows Deployment" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
}

# Function to check if a command exists
function Test-CommandExists {
    param (
        [string]$Command
    )
    
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Check prerequisites for Windows
function Check-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Yellow
    $Prerequisites = @("terraform", "curl")
    $MissingPrerequisites = $false

    foreach ($Tool in $Prerequisites) {
        if (Test-CommandExists -Command $Tool) {
            Write-Host "✓ $Tool is installed" -ForegroundColor Green
        } else {
            Write-Host "✗ $Tool is not installed" -ForegroundColor Red
            $MissingPrerequisites = $true
        }
    }

    # Windows-specific checks - FIX: Separate function calls for OR condition
    $hasPwsh = Test-CommandExists -Command "pwsh"
    $hasPowerShell = Test-CommandExists -Command "powershell"
    
    if ($hasPwsh -or $hasPowerShell) {
        Write-Host "✓ PowerShell is installed" -ForegroundColor Green
    } else {
        Write-Host "✗ PowerShell is not installed" -ForegroundColor Red
        $MissingPrerequisites = $true
    }

    if ($MissingPrerequisites) {
        Write-Host "Please install missing prerequisites and try again." -ForegroundColor Red
        exit 1
    }
}

# Execute Terraform commands for Windows
function Execute-TerraformDeployment {
    # Navigate to Terraform directory - FIX: More robust path detection
    Write-Host "Navigating to Terraform directory..." -ForegroundColor Yellow
    
    # FIX: Get script directory with fallback to current location
    $ScriptDir = if ($MyInvocation.MyCommand.Path) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $PSScriptRoot
    }
    
    # Use fallback if $ScriptDir is still null or empty
    if ([string]::IsNullOrEmpty($ScriptDir)) {
        $ScriptDir = Get-Location
        Write-Host "Using current directory as script directory: $ScriptDir" -ForegroundColor Yellow
    }
    
    # Navigate up two levels from the script directory to find project root
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
    $TerraformDir = Join-Path -Path $ProjectRoot -ChildPath "terraform"
    
    Write-Host "Script directory: $ScriptDir" -ForegroundColor Yellow
    Write-Host "Project root: $ProjectRoot" -ForegroundColor Yellow
    Write-Host "Terraform directory: $TerraformDir" -ForegroundColor Yellow
    
    if (!(Test-Path -Path $TerraformDir)) {
        Write-Host "Terraform directory not found: $TerraformDir" -ForegroundColor Red
        exit 1
    }
    
    Push-Location -Path $TerraformDir

    try {
        # Initialize Terraform
        Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
        terraform init
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Terraform initialization failed." -ForegroundColor Red
            throw "Terraform init failed"
        }

        # Validate Terraform configuration
        Write-Host "`nValidating Terraform configuration..." -ForegroundColor Yellow
        terraform validate
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Terraform validation failed." -ForegroundColor Red
            throw "Terraform validate failed"
        }

        # Apply Terraform configuration
        Write-Host "`nApplying Terraform configuration..." -ForegroundColor Yellow
        terraform apply -auto-approve
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Terraform apply failed." -ForegroundColor Red
            throw "Terraform apply failed"
        }

        # Capture important output values
        Write-Host "`nExtracting and storing deployment information..." -ForegroundColor Yellow
        
        # Extract Workspace URL (if available)
        try {
            $WorkspaceUrl = terraform output -raw workspace_url 2>$null
            if ($WorkspaceUrl) {
                Set-Content -Path (Join-Path -Path $ProjectRoot -ChildPath "terraform\workspace_url.txt") -Value $WorkspaceUrl
                Write-Host "✓ Workspace URL saved to file" -ForegroundColor Green
            }
        } catch {
            Write-Host "! Could not extract workspace URL" -ForegroundColor Yellow
        }
        
        # Extract Job ID (if available)
        try {
            $JobId = terraform output -raw job_id 2>$null
            if ($JobId) {
                Set-Content -Path (Join-Path -Path $ProjectRoot -ChildPath "terraform\job_id.txt") -Value $JobId
                Write-Host "✓ Job ID saved to file" -ForegroundColor Green
            }
        } catch {
            Write-Host "! Could not extract job ID" -ForegroundColor Yellow
        }

        Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
        Write-Host "You can now access your Databricks resources." -ForegroundColor Green
    }
    catch {
        Write-Host "An error occurred during deployment: $_" -ForegroundColor Red
    }
    finally {
        # Always return to original directory
        Pop-Location
    }
}

# Main execution flow
Display-Header
Check-Prerequisites
Execute-TerraformDeployment