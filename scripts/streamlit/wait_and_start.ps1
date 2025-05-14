# Wait for the Databricks job to complete and then start the Streamlit app

# Ensure we have the latest TLS protocols enabled
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Tls13

# Set up colors for output
$Green = @{ForegroundColor = 'Green'}
$Yellow = @{ForegroundColor = 'Yellow'}
$Blue = @{ForegroundColor = 'Blue'}
$Red = @{ForegroundColor = 'Red'}

# Print header
Write-Host "================================================" @Blue
Write-Host "   Waiting for Databricks Job to Complete   " @Blue
Write-Host "================================================" @Blue
Write-Host ""

# Check if job_id.txt file exists
$JobIdFile = "..\terraform\job_id.txt"
if (!(Test-Path $JobIdFile)) {
    Write-Host "Job ID file not found. Cannot check job status." @Red
    Write-Host "Please ensure you have run Terraform to create the infrastructure first."
    exit 1
}

$JobId = Get-Content $JobIdFile
Write-Host "Found Job ID: $JobId" @Green

# Source variables from terraform.tfvars if it exists
$TfvarsFile = "..\terraform\terraform.tfvars"
if (!(Test-Path $TfvarsFile)) {
    Write-Host "terraform.tfvars file not found. Cannot check job status." @Red
    exit 1
}

# Extract variables from terraform.tfvars using regex
$TfvarsContent = Get-Content $TfvarsFile -Raw
$DatabricksHost = if ($TfvarsContent -match 'databricks_host\s*=\s*"([^"]+)"') { $Matches[1] } else { "" }
$DatabricksToken = if ($TfvarsContent -match 'databricks_token\s*=\s*"([^"]+)"') { $Matches[1] } else { "" }

Write-Host "Using host: $DatabricksHost" @Green

# Test connection to Databricks
Write-Host "Testing connection to Databricks..." @Yellow
try {
    $TestHeaders = @{
        "Authorization" = "Bearer $DatabricksToken"
        "Content-Type" = "application/json"
    }
      $TestResponse = Invoke-RestMethod -Uri "$DatabricksHost/api/2.0/workspace/list" -Method Get `
        -Headers $TestHeaders -TimeoutSec 10
    
    # Check for error responses that might indicate auth issues
    if ($TestResponse.error -or $TestResponse.error_code) {
        Write-Host "Databricks API returned an error: $($TestResponse.error_code) - $($TestResponse.message)" @Red
        throw "Authentication or permission error"
    }
    
    Write-Host "Connection to Databricks successful." @Green
}
catch {
    Write-Host "Unable to connect to Databricks: $_" @Red
    Write-Host "Will start the Streamlit app without waiting for job completion." @Yellow
    
    # Start the Streamlit app
    Write-Host "Starting Streamlit app..." @Green
    & "$PSScriptRoot\start_app.ps1"
    exit 0
}

# Function to check job status
function Check-JobStatus {
    # Get the latest run information
    $Headers = @{
        "Authorization" = "Bearer $DatabricksToken"
        "Content-Type" = "application/json"
    }
    
    $Body = @{
        "job_id" = $JobId
        "limit" = 1
    } | ConvertTo-Json
    
    # Add retry logic for network issues
    $NetworkRetries = 3
    $NetworkRetryCount = 0
    $NetworkRetryDelay = 5
    
    while ($NetworkRetryCount -lt $NetworkRetries) {
        try {
            # Add timeout to prevent hanging on network issues
            $Response = Invoke-RestMethod -Uri "$DatabricksHost/api/2.1/jobs/runs/list" -Method Post `
                -Headers $Headers -Body $Body -TimeoutSec 30
            
            if ($null -eq $Response.runs -or $Response.runs.Count -eq 0) {
                Write-Host "Failed to get job runs or no runs found." @Red
                return 2 # Error
            }
            
            $LatestRun = $Response.runs[0]
            $RunId = $LatestRun.run_id
            $State = $LatestRun.state.life_cycle_state
            $ResultState = $LatestRun.state.result_state
            
            Write-Host "Run ID: $RunId, State: $State, Result: $ResultState" @Yellow
            
            # Return status code
            if ($State -eq "TERMINATED") {
                if ($ResultState -eq "SUCCESS") {
                    return 0 # Success
                } else {
                    return 1 # Failed
                }
            } else {
                return 3 # Still running
            }
        }
        catch [System.Net.WebException], [System.Net.Http.HttpRequestException] {
            $NetworkRetryCount++
            if ($NetworkRetryCount -lt $NetworkRetries) {
                Write-Host "Network error occurred: $_" @Yellow
                Write-Host "Retrying in $NetworkRetryDelay seconds... (Attempt $NetworkRetryCount of $NetworkRetries)" @Yellow
                Start-Sleep -Seconds $NetworkRetryDelay
                $NetworkRetryDelay *= 2  # Exponential backoff
            } else {
                Write-Host "Network connection failed after $NetworkRetries attempts: $_" @Red
                return 4 # Network error
            }
        }
        catch {
            Write-Host "Error checking job status: $_" @Red
            return 2 # Other error
        }
    }
}

# Wait for job completion
Write-Host "Checking job status..." @Yellow
$MaxAttempts = 30
$Attempt = 1

while ($Attempt -le $MaxAttempts) {
    Write-Host "Attempt $Attempt of $MaxAttempts" @Blue
    
    $Status = Check-JobStatus
    
    if ($Status -eq 0) {
        Write-Host "Job completed successfully!" @Green
        break
    }
    elseif ($Status -eq 1) {
        Write-Host "Job failed." @Red
        Write-Host "Check the Databricks console for details."
        exit 1
    }
    elseif ($Status -eq 2) {
        Write-Host "Error checking job status." @Red
        $Response = Read-Host "Do you want to continue and start the Streamlit app anyway? (y/N)"
        if ($Response -match "^[yY]([eE][sS])?$") {
            break
        }
        exit 1
    }
    elseif ($Status -eq 4) {
        Write-Host "Network connection issue with Databricks." @Red
        $Response = Read-Host "Do you want to continue and start the Streamlit app anyway? (y/N)"
        if ($Response -match "^[yY]([eE][sS])?$") {
            break
        }
        exit 1
    }
    else {
        Write-Host "Job is still running. Waiting 10 seconds before checking again..." @Yellow
        Start-Sleep -Seconds 10
    }
    
    $Attempt++
}

if ($Attempt -gt $MaxAttempts) {
    Write-Host "Maximum attempts reached. Job may still be running." @Yellow
    $Response = Read-Host "Do you want to start the Streamlit app anyway? (y/N)"
    if ($Response -notmatch "^[yY]([eE][sS])?$") {
        Write-Host "Exiting."
        exit 1
    }
}

# Start the Streamlit app
Write-Host "Starting Streamlit app..." @Green
& "$PSScriptRoot\start_app.ps1"
