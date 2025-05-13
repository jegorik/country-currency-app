#!/bin/bash
# filepath: /home/gangmaster/Documents/Databricks/country-currency-app/streamlit/start_app_new.sh

# Start the Streamlit application with the new UI
cd "$(dirname "$0")"

echo "Starting Country Currency App with new UI..."
echo "Press Ctrl+C to stop the application"

# Check if streamlit is installed
if ! command -v streamlit &> /dev/null
then
    echo "Error: streamlit is not installed."
    echo "Please install it using: pip install streamlit"
    exit 1
fi

# Start the application
streamlit run app_new.py
