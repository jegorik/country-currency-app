# Start the Streamlit application after Databricks infrastructure is created

# Set up colors for output
$Green = @{ForegroundColor = 'Green'}
$Yellow = @{ForegroundColor = 'Yellow'}
$Blue = @{ForegroundColor = 'Blue'}
$Red = @{ForegroundColor = 'Red'}

# Print header
Write-Host "================================================" @Blue
Write-Host "   Starting Country Currency Streamlit App   " @Blue
Write-Host "================================================" @Blue
Write-Host ""

# Get the current script directory for proper path resolution
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Check if job_id.txt file exists
$JobIdFile = Join-Path -Path $ScriptDir -ChildPath "..\..\terraform\job_id.txt"
if (!(Test-Path $JobIdFile)) {
    Write-Host "Job ID file not found. The app may not be able to check job status." @Yellow
    $JobId = ""
}
else {
    $JobId = Get-Content $JobIdFile
    Write-Host "Found Job ID: $JobId" @Green
}

# Check if workspace_url.txt file exists
$WorkspaceUrlFile = Join-Path -Path $ScriptDir -ChildPath "..\..\terraform\workspace_url.txt"
if (!(Test-Path $WorkspaceUrlFile)) {
    Write-Host "Workspace URL file not found. Using default configuration." @Yellow
    $WorkspaceUrl = "https://databricks.com"
}
else {
    $WorkspaceUrl = Get-Content $WorkspaceUrlFile
    Write-Host "Found workspace URL: $WorkspaceUrl" @Green
}

# Check if Python is installed
if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python is not installed or not in your PATH. Please install it first." @Red
    exit 1
}

# Check if pip is installed
if (!(Get-Command pip -ErrorAction SilentlyContinue)) {
    Write-Host "pip is not installed or not in your PATH. Please install it first." @Red
    exit 1
}

# Check if streamlit is installed
Write-Host "Checking for required Python packages..." @Yellow
try {
    python -c "import streamlit" > $null 2>&1
    $StreamlitInstalled = $true
} catch {
    $StreamlitInstalled = $false
}

if (!$StreamlitInstalled) {
    Write-Host "Installing required Python packages..." @Yellow
    $RequirementsFile = Join-Path -Path $ScriptDir -ChildPath "requirements.txt"
    
    if (Test-Path $RequirementsFile) {
        pip install -r $RequirementsFile
    } else {
        pip install streamlit pandas requests
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install requirements." @Red
        exit 1
    }
}

# Navigate to the streamlit directory
$StreamlitDir = Join-Path -Path $ScriptDir -ChildPath "..\..\streamlit"
Push-Location $StreamlitDir

# Check if the new UI app exists
$NewAppPath = Join-Path -Path $StreamlitDir -ChildPath "app_new.py"
if (Test-Path $NewAppPath) {
    Write-Host "Starting new UI version..." @Green
    $AppPath = "app.py"
} else {
    Write-Host "Starting standard UI version..." @Green
    $AppPath = "app.py"
}

Write-Host "Starting Streamlit app..." @Blue
Write-Host "The app will be available at http://localhost:8501" @Green
Write-Host "Press Ctrl+C to stop the app" @Yellow

# Start Streamlit app with parameters
streamlit run $AppPath -- --job_id="$JobId" --workspace_url="$WorkspaceUrl"

# Return to original directory when done
Pop-Location

# Handle exit
Write-Host "Streamlit app has stopped." @Blue