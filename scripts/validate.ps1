#
# Validation script for the Country Currency Mapping Data Pipeline
#
# This PowerShell script validates the deployment and configuration of the
# Databricks infrastructure and data pipeline. It checks resource status,
# data integrity, and configuration correctness.
#
# Usage:
#   .\validate.ps1 [OPTIONS]
#
# Options:
#   -Environment ENV         The target environment (dev, staging, prod). Default is "dev"
#   -TerraformVarsFile FILE  Name of the terraform.tfvars file. Default is "terraform.tfvars"
#   -CheckData               Whether to perform data validation checks. Default is true
#   -NoCheckData             Skip data validation checks
#   -Help                    Show this help message
#
# Examples:
#   .\validate.ps1 -Environment dev -CheckData
#   .\validate.ps1 -Environment prod -TerraformVarsFile terraform-prod.tfvars
#   .\validate.ps1 -NoCheckData
#
# Author: Data Engineering Team
# Last Updated: June 20, 2025
# Requires: Terraform >= 1.0, AWS CLI, Databricks CLI (optional)

param(
    [Parameter(Position=0)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment = "dev",
    
    [Parameter(Position=1)]
    [string]$TerraformVarsFile = "terraform.tfvars",
    
    [switch]$CheckData = $true,
    [switch]$NoCheckData,
    [switch]$Help
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Script directory and paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Join-Path $ScriptDir "..\terraform"
$DataFile = Join-Path $ScriptDir "..\etl_data\country_code_to_currency_code.csv"

# Global variables
$VarsFile = ""
$ValidationResults = @{
    "Prerequisites" = $false
    "BackendState" = $false
    "DatabricksState" = $false
    "DataFile" = $false
    "Configuration" = $false
}

# Function to display usage
function Show-Usage {
    @"
Usage: .\validate.ps1 [OPTIONS]

Validation script for the Country Currency Mapping Data Pipeline

OPTIONS:
    -Environment ENV         The target environment (dev, staging, prod). Default is "dev"
    -TerraformVarsFile FILE  Name of the terraform.tfvars file. Default is "terraform.tfvars"
    -CheckData               Whether to perform data validation checks. Default is true
    -NoCheckData             Skip data validation checks
    -Help                    Show this help message

EXAMPLES:
    .\validate.ps1 -Environment dev -CheckData
    .\validate.ps1 -Environment prod -TerraformVarsFile terraform-prod.tfvars
    .\validate.ps1 -NoCheckData
"@
}

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to parse and validate parameters
function Initialize-Parameters {
    if ($Help) {
        Show-Usage
        exit 0
    }
    
    if ($NoCheckData) {
        $script:CheckData = $false
    }
    
    # Validate environment
    if ($Environment -notin @("dev", "staging", "prod")) {
        Write-ColorOutput "Error: Invalid environment '$Environment'" "Red"
        Show-Usage
        exit 1
    }
}

# Function to find terraform vars file (universal logic)
function Find-VarsFile {
    $BackendDir = Join-Path $TerraformDir "$Environment-env\backend"
    $DatabricksDir = Join-Path $TerraformDir "$Environment-env\databricks-ifra"
    $EnvRootDir = Join-Path $TerraformDir "$Environment-env"
    
    # Initialize VarsFile as empty
    $script:VarsFile = ""
    
    # Case 1: User provided a path (contains "\" or "/")
    if ($TerraformVarsFile.Contains("\") -or $TerraformVarsFile.Contains("/")) {
        $UserProvidedPath = Join-Path $ScriptDir $TerraformVarsFile
        if (Test-Path $UserProvidedPath) {
            $script:VarsFile = $UserProvidedPath
            Write-ColorOutput "Using user-provided vars file: $($script:VarsFile)" "Cyan"
        } else {
            Write-ColorOutput "User-provided vars file not found: $UserProvidedPath" "Red"
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
            Write-ColorOutput "Specified vars file '$TerraformVarsFile' not found in any standard location" "Red"
            exit 1
        }
        Write-ColorOutput "Using specified vars file: $($script:VarsFile)" "Cyan"
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
            Write-ColorOutput "No terraform.tfvars files found in standard locations" "Yellow"
        } else {
            # Files found - we'll use all of them for configuration validation
            $script:VarsFile = $FoundFiles[0]  # Set primary file for prerequisites check
            Write-ColorOutput "Found terraform.tfvars files: $($FoundFiles.Count)" "Cyan"
            foreach ($file in $FoundFiles) {
                Write-ColorOutput "   - $file" "Gray"
            }
        }
    }
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-ColorOutput "Validating prerequisites..." "Yellow"
    
    $AllGood = $true
    
    # Check Terraform
    try {
        $terraformVersion = terraform version 2>$null | Select-Object -First 1
        if ($terraformVersion) {
            Write-ColorOutput "Terraform: $terraformVersion" "Green"
        } else {
            throw "Terraform not found"
        }
    } catch {
        Write-ColorOutput "Terraform not found or not working" "Red"
        $AllGood = $false
    }
    
    # Check AWS CLI
    try {
        $awsVersion = aws --version 2>$null
        if ($awsVersion) {
            $awsVersionShort = ($awsVersion -split ' ')[0]
            Write-ColorOutput "AWS CLI: $awsVersionShort" "Green"
            
            # Check AWS credentials
            try {
                $awsAccount = aws sts get-caller-identity --query Account --output text 2>$null
                $awsRegion = aws configure get region 2>$null
                if (-not $awsRegion) { $awsRegion = "not-set" }
                Write-ColorOutput "AWS credentials configured (Account: $awsAccount, Region: $awsRegion)" "Green"
            } catch {
                Write-ColorOutput "AWS credentials not configured" "Red"
                $AllGood = $false
            }
        } else {
            throw "AWS CLI not found"
        }
    } catch {
        Write-ColorOutput "AWS CLI not found or not configured" "Red"
        $AllGood = $false
    }
    
    # Check Databricks CLI
    try {
        $databricksVersion = databricks --version 2>$null
        if ($databricksVersion) {
            Write-ColorOutput "Databricks CLI: $databricksVersion" "Green"
        } else {
            throw "Databricks CLI not found"
        }
    } catch {
        Write-ColorOutput "Databricks CLI not found" "Yellow"
        Write-ColorOutput "   Install with: pip install databricks-cli" "Gray"
        Write-ColorOutput "   This is optional but recommended for full validation" "Gray"
    }
    
    # Check for jq equivalent (not available on Windows by default)
    try {
        $jqTest = Get-Command jq -ErrorAction Stop
        Write-ColorOutput "jq JSON processor available" "Green"
    } catch {
        Write-ColorOutput "jq not found - JSON parsing will be limited" "Yellow"
        Write-ColorOutput "   PowerShell will use ConvertFrom-Json as fallback" "Gray"
    }
    
    # Check variables file
    if (Test-Path $script:VarsFile) {
        Write-ColorOutput "Variables file found: $($script:VarsFile)" "Green"
    } else {
        Write-ColorOutput "Variables file not found: $($script:VarsFile)" "Red"
        $AllGood = $false
    }
    
    if ($AllGood) {
        $script:ValidationResults["Prerequisites"] = $true
    }
}

# Function to validate backend state using AWS CLI
function Test-BackendState {
    Write-ColorOutput "Validating backend infrastructure..." "Yellow"
    
    $BackendDir = Join-Path $TerraformDir "$Environment-env\backend"
    
    if (-not (Test-Path $BackendDir)) {
        Write-ColorOutput "Backend directory not found" "Yellow"
        return $false
    }
    
    # Read backend configuration to get S3 bucket name
    $BackendConfigFile = Join-Path $TerraformDir "$Environment-env\databricks-ifra\backend-config.tf"
    $BucketName = ""
    
    if (Test-Path $BackendConfigFile) {
        $configContent = Get-Content $BackendConfigFile -Raw
        if ($configContent -match 'bucket\s*=\s*"([^"]*)"') {
            $BucketName = $matches[1]
            Write-ColorOutput "   Found S3 backend bucket: $BucketName" "Gray"
        }
    }
    
    # If bucket name not found in backend-config.tf, try to construct it from s3-bucket.tf
    if (-not $BucketName) {
        $S3BucketFile = Join-Path $BackendDir "s3-bucket.tf"
        if (Test-Path $S3BucketFile) {
            $s3Content = Get-Content $S3BucketFile -Raw
            if ($s3Content -match 'bucket\s*=\s*"([^"]*)"') {
                $BucketPattern = $matches[1]
                if ($BucketPattern -match '\$\{var\.environment\}') {
                    $BucketName = $BucketPattern -replace '\$\{var\.environment\}', $Environment
                    Write-ColorOutput "   Constructed bucket name: $BucketName" "Gray"
                }
            }
        }
    }
    
    if (-not $BucketName) {
        Write-ColorOutput "Could not determine S3 bucket name" "Red"
        return $false
    }
    
    # Check if S3 bucket exists using AWS CLI
    try {
        aws s3api head-bucket --bucket $BucketName 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "S3 backend bucket exists: $BucketName" "Green"
            
            # Check if bucket has versioning enabled
            try {
                $versioningStatus = aws s3api get-bucket-versioning --bucket $BucketName --query Status --output text 2>$null
                if ($versioningStatus -eq "Enabled") {
                    Write-ColorOutput "S3 bucket versioning enabled" "Green"
                } else {
                    Write-ColorOutput "S3 bucket versioning not enabled" "Yellow"
                }
            } catch {
                Write-ColorOutput "Could not check bucket versioning" "Yellow"
            }
            
            # Check if bucket has encryption
            try {
                aws s3api get-bucket-encryption --bucket $BucketName 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-ColorOutput "S3 bucket encryption enabled" "Green"
                } else {
                    Write-ColorOutput "S3 bucket encryption not configured" "Yellow"
                }
            } catch {
                Write-ColorOutput "Could not check bucket encryption" "Yellow"
            }
            
            # Check if terraform state file exists in bucket
            try {
                aws s3api head-object --bucket $BucketName --key "terraform.tfstate" 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-ColorOutput "Terraform state file exists in S3" "Green"
                    
                    # Get state file info
                    try {
                        $lastModified = aws s3api head-object --bucket $BucketName --key "terraform.tfstate" --query LastModified --output text 2>$null
                        $fileSize = aws s3api head-object --bucket $BucketName --key "terraform.tfstate" --query ContentLength --output text 2>$null
                        Write-ColorOutput "   Last modified: $lastModified" "Gray"
                        Write-ColorOutput "   Size: $fileSize bytes" "Gray"
                    } catch {
                        # Continue without metadata
                    }
                } else {
                    Write-ColorOutput "Terraform state file not found in S3" "Yellow"
                    Write-ColorOutput "   Resources may not have been deployed yet" "Gray"
                }
            } catch {
                Write-ColorOutput "Could not check state file" "Yellow"
            }
            
            $script:ValidationResults["BackendState"] = $true
        } else {
            Write-ColorOutput "S3 backend bucket not found: $BucketName" "Red"
            Write-ColorOutput "   Backend infrastructure may not be deployed" "Gray"
            return $false
        }
    } catch {
        Write-ColorOutput "Error checking S3 bucket: $($_.Exception.Message)" "Red"
        return $false
    }
    
    return $true
}

# Function to validate Databricks infrastructure using Databricks CLI
function Test-DatabricksState {
    Write-ColorOutput "Validating Databricks infrastructure..." "Yellow"
    
    $DatabricksDir = Join-Path $TerraformDir "$Environment-env\databricks-ifra"
    
    if (-not (Test-Path $DatabricksDir)) {
        Write-ColorOutput "Databricks directory not found" "Yellow"
        return $false
    }
    
    # Read Databricks configuration from terraform.tfvars
    $DatabricksVarsFile = Join-Path $DatabricksDir "terraform.tfvars"
    $DatabricksHost = ""
    $DatabricksToken = ""
    $CatalogName = ""
    $SchemaName = ""
    $TableName = ""
    $VolumeName = ""
    
    if (Test-Path $DatabricksVarsFile) {
        $varsContent = Get-Content $DatabricksVarsFile
        
        foreach ($line in $varsContent) {
            if ($line -match 'databricks_host\s*=\s*"(.+?)"') {
                $DatabricksHost = $matches[1].Trim()
            }
            elseif ($line -match 'databricks_token\s*=\s*"(.+?)"') {
                $DatabricksToken = $matches[1].Trim()
            }
            elseif ($line -match 'catalog_name\s*=\s*"(.+?)"') {
                $CatalogName = $matches[1].Trim()
            }
            elseif ($line -match 'schema_name\s*=\s*"(.+?)"') {
                $SchemaName = $matches[1].Trim()
            }
            elseif ($line -match 'table_name\s*=\s*"(.+?)"') {
                $TableName = $matches[1].Trim()
            }
            elseif ($line -match 'volume_name\s*=\s*"(.+?)"') {
                $VolumeName = $matches[1].Trim()
            }
        }
        
        # Clean up databricks_host - remove trailing slashes and ensure https://
        $DatabricksHost = $DatabricksHost.TrimEnd('/')
        if ($DatabricksHost -and -not $DatabricksHost.StartsWith("http")) {
            $DatabricksHost = "https://$DatabricksHost"
        }
        
        Write-ColorOutput "   Databricks host: $DatabricksHost" "Gray"
        Write-ColorOutput "   Catalog: $CatalogName" "Gray"
        Write-ColorOutput "   Schema: $SchemaName" "Gray"
    } else {
        Write-ColorOutput "Databricks variables file not found" "Red"
        return $false
    }
    
    if (-not $DatabricksHost -or -not $DatabricksToken) {
        Write-ColorOutput "Databricks host or token not configured" "Red"
        return $false
    }
    
    # Check if Databricks CLI is available
    try {
        $databricksTest = Get-Command databricks -ErrorAction Stop
    } catch {
        Write-ColorOutput "Databricks CLI not available - skipping detailed checks" "Yellow"
        Write-ColorOutput "   Basic connectivity test only" "Gray"
        
        # Basic connectivity test with Invoke-WebRequest
        try {
            $response = Invoke-WebRequest -Uri $DatabricksHost -Method HEAD -TimeoutSec 10 -ErrorAction Stop
            Write-ColorOutput "Databricks host is reachable" "Green"
            $script:ValidationResults["DatabricksState"] = $true
        } catch {
            Write-ColorOutput "Databricks host connectivity check failed" "Yellow"
            Write-ColorOutput "   This might be normal if behind firewall/VPN" "Gray"
        }
        return $true
    }
    
    # Configure Databricks CLI temporarily
    $env:DATABRICKS_HOST = $DatabricksHost
    $env:DATABRICKS_TOKEN = $DatabricksToken
    
    Write-ColorOutput "   Debug - Cleaned host: '$DatabricksHost'" "Gray"
    Write-ColorOutput "   Debug - Token length: $($DatabricksToken.Length) chars" "Gray"
    
    # Test Databricks connectivity
    Write-ColorOutput "   Testing Databricks connectivity..." "Gray"
    try {
        $userResult = databricks current-user me 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Databricks connectivity verified" "Green"
            
            # Get current user info for additional validation
            try {
                $userJson = databricks current-user me --output json 2>$null | ConvertFrom-Json
                if ($userJson.emails -and $userJson.emails.Count -gt 0) {
                    $userEmail = $userJson.emails[0].value
                } else {
                    $userEmail = "unknown"
                }
                Write-ColorOutput "   Connected as: $userEmail" "Gray"
            } catch {
                Write-ColorOutput "   Connected as: unknown" "Gray"
            }
        } else {
            throw "Databricks connection failed"
        }
    } catch {
        Write-ColorOutput "Cannot connect to Databricks workspace" "Red"
        Write-ColorOutput "   Check databricks_host and databricks_token values" "Gray"
        Write-ColorOutput "   Debug info:" "Gray"
        Write-ColorOutput "   - Host: $DatabricksHost" "Gray"
        Write-ColorOutput "   - Token length: $($DatabricksToken.Length) characters" "Gray"
        
        # Additional debugging information - show hex representation of host for hidden characters
        $hostBytes = [System.Text.Encoding]::UTF8.GetBytes($DatabricksHost)
        $hexRepresentation = ($hostBytes | ForEach-Object { "{0:X2}" -f $_ }) -join " "
        Write-ColorOutput "   - Host hex dump: $hexRepresentation" "Gray"
        
        # Try to get more specific error from databricks command
        try {
            $errorOutput = databricks current-user me 2>&1 | Select-Object -First 1
            Write-ColorOutput "   - Error: $errorOutput" "Gray"
        } catch {
            # Ignore error retrieval failure
        }
        return $false
    }
    
    # Check if catalog exists
    if ($CatalogName) {
        try {
            databricks catalogs get $CatalogName 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "Catalog exists: $CatalogName" "Green"
                
                # Check if schema exists
                if ($SchemaName) {
                    try {
                        databricks schemas get "$CatalogName.$SchemaName" 2>$null
                        if ($LASTEXITCODE -eq 0) {
                            Write-ColorOutput "Schema exists: $CatalogName.$SchemaName" "Green"
                            
                            # Check if table exists
                            if ($TableName) {
                                try {
                                    databricks tables get "$CatalogName.$SchemaName.$TableName" 2>$null
                                    if ($LASTEXITCODE -eq 0) {
                                        Write-ColorOutput "Table exists: $CatalogName.$SchemaName.$TableName" "Green"
                                    } else {
                                        Write-ColorOutput "Table not found: $CatalogName.$SchemaName.$TableName" "Yellow"
                                    }
                                } catch {
                                    Write-ColorOutput "Could not check table: $CatalogName.$SchemaName.$TableName" "Yellow"
                                }
                            }
                        } else {
                            Write-ColorOutput "Schema not found: $CatalogName.$SchemaName" "Yellow"
                        }
                    } catch {
                        Write-ColorOutput "Could not check schema: $CatalogName.$SchemaName" "Yellow"
                    }
                }
                
                # Check if volume exists
                if ($VolumeName) {
                    try {
                        databricks volumes get "$CatalogName.$SchemaName.$VolumeName" 2>$null
                        if ($LASTEXITCODE -eq 0) {
                            Write-ColorOutput "Volume exists: $CatalogName.$SchemaName.$VolumeName" "Green"
                        } else {
                            # Fallback: check if volume exists in the schema's volume list
                            try {
                                $volumeList = databricks volumes list $CatalogName $SchemaName --output json 2>$null | ConvertFrom-Json
                                $volumeExists = $volumeList | Where-Object { $_.name -eq $VolumeName }
                                if ($volumeExists) {
                                    Write-ColorOutput "Volume exists: $CatalogName.$SchemaName.$VolumeName" "Green"
                                } else {
                                    Write-ColorOutput "Volume not found: $CatalogName.$SchemaName.$VolumeName" "Yellow"
                                    
                                    # Debug: Show available volumes
                                    $availableVolumes = ($volumeList | Select-Object -First 3 -ExpandProperty name) -join ', '
                                    if ($availableVolumes) {
                                        Write-ColorOutput "   Available volumes: $availableVolumes" "Gray"
                                    } else {
                                        Write-ColorOutput "   No volumes found in schema" "Gray"
                                    }
                                }
                            } catch {
                                Write-ColorOutput "Volume not found: $CatalogName.$SchemaName.$VolumeName" "Yellow"
                            }
                        }
                    } catch {
                        Write-ColorOutput "Could not check volume: $CatalogName.$SchemaName.$VolumeName" "Yellow"
                    }
                }
            } else {
                Write-ColorOutput "Catalog not found: $CatalogName" "Yellow"
                Write-ColorOutput "   Databricks resources may not be deployed yet" "Gray"
                
                # Debug: Show what catalogs are available
                try {
                    $catalogsJson = databricks catalogs list --output json 2>$null | ConvertFrom-Json
                    $availableCatalogs = ($catalogsJson | Select-Object -First 5 -ExpandProperty name) -join ', '
                    Write-ColorOutput "   Available catalogs:" "Gray"
                    Write-ColorOutput "   $availableCatalogs" "Gray"
                } catch {
                    Write-ColorOutput "   Unable to list available catalogs" "Gray"
                }
            }
        } catch {
            Write-ColorOutput "Could not check catalog: $CatalogName" "Yellow"
        }
    }
    
    # List some workspace resources to verify deployment
    try {
        $workspaceList = databricks workspace list / 2>$null
        if ($LASTEXITCODE -eq 0) {
            $workspaceCount = ($workspaceList | Measure-Object).Count
            if ($workspaceCount -gt 0) {
                Write-ColorOutput "   Workspace objects: $workspaceCount" "Gray"
            } else {
                Write-ColorOutput "   Workspace objects: 0" "Gray"
            }
        } else {
            Write-ColorOutput "   Workspace objects: unknown" "Gray"
        }
    } catch {
        Write-ColorOutput "   Workspace objects: unknown" "Gray"
    }
    
    $script:ValidationResults["DatabricksState"] = $true
    return $true
}

# Function to validate data file
function Test-DataFile {
    Write-ColorOutput "Validating data file..." "Yellow"
    
    if (-not (Test-Path $DataFile)) {
        Write-ColorOutput "Data file not found: $DataFile" "Red"
        return $false
    }
    
    # Basic file validation
    $content = Get-Content $DataFile
    $recordCount = $content.Count - 1  # Subtract header
    $headerLine = $content[0]
    
    Write-ColorOutput "Data file found: $DataFile" "Green"
    Write-ColorOutput "   Records: $recordCount" "Gray"
    Write-ColorOutput "   Columns: $headerLine" "Gray"
    
    # Validate required columns
    $requiredColumns = @("country_code", "country_number", "country", "currency_name", "currency_code", "currency_number")
    $missingColumns = @()
    
    foreach ($col in $requiredColumns) {
        if ($headerLine -notmatch $col) {
            $missingColumns += $col
        }
    }
    
    if ($missingColumns.Count -eq 0) {
        Write-ColorOutput "All required columns present" "Green"
        
        # Basic data quality checks (check for empty required fields)
        $dataRows = $content | Select-Object -Skip 1
        $nullCountryCode = 0
        $nullCurrencyCode = 0
        
        foreach ($row in $dataRows) {
            $fields = $row -split ','
            if ([string]::IsNullOrWhiteSpace($fields[0]) -or $fields[0] -in @("NULL", "null")) {
                $nullCountryCode++
            }
            if ($fields.Count -gt 4 -and ([string]::IsNullOrWhiteSpace($fields[4]) -or $fields[4] -in @("NULL", "null"))) {
                $nullCurrencyCode++
            }
        }
        
        if ($nullCountryCode -eq 0 -and $nullCurrencyCode -eq 0) {
            Write-ColorOutput "No null values in key columns" "Green"
            $script:ValidationResults["DataFile"] = $true
        } else {
            Write-ColorOutput "Found null values - Country: $nullCountryCode, Currency: $nullCurrencyCode" "Yellow"
            return $false
        }
    } else {
        $missingStr = $missingColumns -join ','
        Write-ColorOutput "Missing required columns: $missingStr" "Red"
        return $false
    }
    
    return $true
}

# Function to validate configuration
function Test-Configuration {
    Write-ColorOutput "Validating configuration..." "Yellow"
    
    $BackendDir = Join-Path $TerraformDir "$Environment-env\backend"
    $DatabricksDir = Join-Path $TerraformDir "$Environment-env\databricks-ifra"
    $EnvRootDir = Join-Path $TerraformDir "$Environment-env"
    
    $AllFoundConfig = @()
    
    # Case 1: User provided a specific path or filename
    if ($TerraformVarsFile.Contains("\") -or $TerraformVarsFile.Contains("/") -or $TerraformVarsFile -ne "terraform.tfvars") {
        # Read from the single determined vars file
        if (Test-Path $script:VarsFile) {
            $content = Get-Content $script:VarsFile
            foreach ($line in $content) {
                # Skip comments and empty lines
                if ($line -notmatch '^\s*#' -and ![string]::IsNullOrWhiteSpace($line)) {
                    if ($line -match '^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=') {
                        $AllFoundConfig += $matches[1]
                    }
                }
            }
        }
    }
    # Case 2: Default behavior - read from all available terraform.tfvars files
    else {
        $VarsFilesToCheck = @(
            (Join-Path $BackendDir $TerraformVarsFile),
            (Join-Path $DatabricksDir $TerraformVarsFile),
            (Join-Path $EnvRootDir $TerraformVarsFile)
        )
        
        foreach ($varsFile in $VarsFilesToCheck) {
            if (Test-Path $varsFile) {
                $content = Get-Content $varsFile
                foreach ($line in $content) {
                    # Skip comments and empty lines
                    if ($line -notmatch '^\s*#' -and ![string]::IsNullOrWhiteSpace($line)) {
                        if ($line -match '^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=') {
                            $AllFoundConfig += $matches[1]
                        }
                    }
                }
            }
        }
    }
    
    # Remove duplicates
    $UniqueConfig = $AllFoundConfig | Sort-Object -Unique
    
    # Check for key configuration items
    $RequiredConfig = @(
        "databricks_host",
        "databricks_token",
        "databricks_warehouse_id",
        "catalog_name",
        "schema_name",
        "table_name",
        "volume_name",
        "aws_region"
    )
    
    $MissingConfig = @()
    foreach ($reqConfig in $RequiredConfig) {
        if ($reqConfig -notin $UniqueConfig) {
            $MissingConfig += $reqConfig
        }
    }
    
    if ($MissingConfig.Count -eq 0) {
        Write-ColorOutput "All required configuration parameters found" "Green"
        Write-ColorOutput "   Configured parameters: $($UniqueConfig.Count)" "Gray"
        $script:ValidationResults["Configuration"] = $true
    } else {
        $missingStr = $MissingConfig -join ','
        Write-ColorOutput "Missing configuration parameters: $missingStr" "Red"
        Write-ColorOutput "   Searched in configuration files based on provided parameters" "Gray"
        return $false
    }
    
    return $true
}

# Function to display validation summary
function Show-ValidationSummary {
    Write-ColorOutput "`nValidation Summary" "Cyan"
    Write-ColorOutput "=====================" "Cyan"
    
    $PassedCount = 0
    $TotalCount = $script:ValidationResults.Count
    
    foreach ($test in $script:ValidationResults.Keys) {
        if ($script:ValidationResults[$test]) {
            $status = "PASS"
            $color = "Green"
            $PassedCount++
        } else {
            $status = "FAIL" 
            $color = "Red"
        }
        
        Write-ColorOutput "$test`: $status" $color
    }
    
    Write-ColorOutput "`nOverall Result: $PassedCount/$TotalCount tests passed" "White"
    
    if ($PassedCount -eq $TotalCount) {
        Write-ColorOutput "All validations passed! The pipeline is ready." "Green"
        return $true
    } else {
        Write-ColorOutput "Some validations failed. Please review and fix issues." "Yellow"
        return $false
    }
}

# Main execution
function Main {
    try {
        Initialize-Parameters
        Find-VarsFile
        
        Write-ColorOutput "Starting validation process..." "Cyan"
        Write-ColorOutput "Environment: $Environment" "White"
        Write-ColorOutput "Backend config: $(Join-Path $TerraformDir "$Environment-env\backend\$TerraformVarsFile")" "White"
        Write-ColorOutput "Databricks config: $(Join-Path $TerraformDir "$Environment-env\databricks-ifra\$TerraformVarsFile")" "White"
        Write-ColorOutput "Data validation: $CheckData" "White"
        Write-ColorOutput "========================================" "White"
        
        # Run validations
        Test-Prerequisites
        Test-Configuration
        
        $BackendDir = Join-Path $TerraformDir "$Environment-env\backend"
        if (Test-Path $BackendDir) {
            Test-BackendState | Out-Null
        } else {
            Write-ColorOutput "Backend directory not found, skipping backend validation" "Yellow"
        }
        
        $DatabricksDir = Join-Path $TerraformDir "$Environment-env\databricks-ifra"
        if (Test-Path $DatabricksDir) {
            Test-DatabricksState | Out-Null
        } else {
            Write-ColorOutput "Databricks directory not found, skipping Databricks validation" "Yellow"
        }
        
        if ($CheckData) {
            Test-DataFile | Out-Null
        }
        
        # Show summary and exit with appropriate code
        if (Show-ValidationSummary) {
            exit 0
        } else {
            exit 1
        }
    } catch {
        Write-ColorOutput ('Script execution failed: ' + $_.Exception.Message) "Red"
        exit 1
    }
}

# Execute main function
Main
