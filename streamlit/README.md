# Country Currency App - Streamlit Interface

This directory contains the Streamlit web application for the Country Currency App. The application provides a user-friendly interface for managing the country-currency mapping data stored in Databricks.

## Features

- View, add, edit, and delete country-currency mappings
- Search and filter capabilities
- Real-time connection to Databricks
- Monitors job status to ensure data availability

## Project Structure

```
streamlit/
│
├── app.py              # Main application file
├── config/             # Configuration files
│   └── app_config.py   # Application configuration
│
├── models/             # Data models
│   └── country_currency.py
│
├── operations/         # Business logic and data operations
│   └── data_operations.py
│
├── ui/                 # User interface components
│   ├── crud_views.py   # Create, Read, Update, Delete views
│   ├── main_view.py    # Main data table view
│   ├── sidebar.py      # Application sidebar
│   └── style.css       # Custom styling
│
└── utils/              # Utility functions
    ├── databricks_client.py  # Databricks API client
    └── status_checker.py     # Job status checker
```

## Prerequisites

- Python 3.8 or higher
- Databricks workspace with the country-currency table deployed
- Databricks personal access token with appropriate permissions

## Installation

1. Install the required Python packages:

```bash
pip install -r requirements.txt
```

2. Set up the Databricks connection:
   - Databricks workspace URL
   - Personal access token
   - Catalog, schema, and table information

## Usage

Run the Streamlit application:

```bash
cd streamlit
streamlit run app.py
```

The application will be available at http://localhost:8501.

## Cross-Platform Compatibility

This Streamlit application is designed to work on both Windows and Linux/macOS environments. We provide platform-specific launch scripts as well as a cross-platform launcher:

### Running the App

1. **Cross-platform launcher (Recommended)**:

   ```bash
   # Automatically detects your OS and runs the appropriate script
   ./start_app_cross_platform.sh
   ```

2. **Platform-specific launchers**:

   - On Linux/macOS:
     ```bash
     ./start_app_new.sh
     # or for legacy UI
     ./start_app.sh
     ```

   - On Windows:
     ```powershell
     .\start_app.ps1
     ```

### Platform-Specific Notes:

- **Windows**: Requires PowerShell 5.0+ for the PowerShell scripts
- **Linux/macOS**: Requires Bash 4.0+ for the shell scripts
- **All platforms**: Python 3.8+ and Streamlit 1.18+ are required

## Development

### Adding New Features

To add new features to the application:

1. Create new UI components in the `ui` directory
2. Implement business logic in the `operations` directory
3. Add new data models in the `models` directory
4. Update the main `app.py` file to incorporate your changes

### Testing

Run tests using pytest:

```bash
pytest tests/
```
