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

# Check if job_id.txt file exists
$JobIdFile = "..\terraform\job_id.txt"
if (!(Test-Path $JobIdFile)) {
    Write-Host "Job ID file not found. The app may not be able to check job status." @Yellow
    $JobId = ""
}
else {
    $JobId = Get-Content $JobIdFile
    Write-Host "Found Job ID: $JobId" @Green
}

# Source variables from terraform.tfvars if it exists
$TfvarsFile = "..\terraform\terraform.tfvars"
if (!(Test-Path $TfvarsFile)) {
    Write-Host "terraform.tfvars file not found. Cannot start Streamlit app." @Red
    Write-Host "Please ensure you have run Terraform to create the infrastructure first."
    exit 1
}

# Extract variables from terraform.tfvars using regex
$TfvarsContent = Get-Content $TfvarsFile -Raw
$DatabricksHost = if ($TfvarsContent -match 'databricks_host\s*=\s*"([^"]+)"') { $Matches[1] } else { "" }
$CatalogName = if ($TfvarsContent -match 'catalog_name\s*=\s*"([^"]+)"') { $Matches[1] } else { "" }
$SchemaName = if ($TfvarsContent -match 'schema_name\s*=\s*"([^"]+)"') { $Matches[1] } else { "" }
$TableName = if ($TfvarsContent -match 'table_name\s*=\s*"([^"]+)"') { $Matches[1] } else { "" }

Write-Host "Using the following configuration:" @Green
Write-Host "Databricks Host: $DatabricksHost"
Write-Host "Catalog: $CatalogName"
Write-Host "Schema: $SchemaName"
Write-Host "Table: $TableName"

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
try {
    python -c "import streamlit" > $null 2>&1
    $StreamlitInstalled = $true
} catch {
    $StreamlitInstalled = $false
}

if (!$StreamlitInstalled) {
    Write-Host "Streamlit is not installed. Installing requirements..." @Yellow
    pip install -r requirements.txt
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install requirements." @Red
        exit 1
    }
}

Write-Host "Starting Streamlit app..." @Blue
Write-Host "The app will be available at http://localhost:8501" @Green
Write-Host "Press Ctrl+C to stop the app" @Yellow

# Start Streamlit app
streamlit run app.py

# Handle exit
Write-Host "Streamlit app has stopped." @Blue
