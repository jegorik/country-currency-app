# Wait for the Databricks job to complete and then start the Streamlit app

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
    
    try {
        $Response = Invoke-RestMethod -Uri "$DatabricksHost/api/2.1/jobs/runs/list" -Method Post `
            -Headers $Headers -Body $Body
        
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
    catch {
        Write-Host "Error checking job status: $_" @Red
        return 2 # Error
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
