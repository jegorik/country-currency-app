#!/bin/bash

# Consolidated test script for country-currency-app

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   Country Currency App - Test Runner   ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Show test options
echo -e "${YELLOW}Available Tests:${NC}"
echo "1. Test Databricks Connection"
echo "2. Validate Notebooks"
echo "3. Run Python Unit Tests"
echo "4. Exit"

# Get user choice
read -p "Select a test to run (1-4): " choice

# Execute selected test
case $choice in
  1)
    echo -e "${GREEN}Running Databricks Connection Test...${NC}"
    bash "$(dirname "$0")/test_databricks_connection.sh"
    ;;
  2)
    echo -e "${GREEN}Running Notebook Validation...${NC}"
    bash "$(dirname "$0")/validate_notebook.sh"
    ;;
  3)
    echo -e "${GREEN}Running Python Unit Tests...${NC}"
    
    # Explicitly use Python 3.11 which matches our pip3 installation
    PYTHON_CMD=python3.11
    
    # Check if pytest module is available for the Python interpreter
    if ! $PYTHON_CMD -c "import pytest" &> /dev/null; then
      echo -e "${YELLOW}pytest not found. Installing required packages...${NC}"
      pip3 install --user pytest pytest-mock pyspark==3.3.0 pyarrow
    fi
    
    # Run the tests
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    cd "$PROJECT_ROOT"
    echo -e "${YELLOW}Using Python interpreter: $PYTHON_CMD${NC}"
    $PYTHON_CMD -c "import sys; print(f'Python version: {sys.version}')"
    # Add -W ignore option to suppress deprecation warnings
    $PYTHON_CMD -W ignore::DeprecationWarning -m pytest tests/ -v
    ;;
  4)
    echo -e "${BLUE}Exiting test runner.${NC}"
    exit 0
    ;;
  *)
    echo -e "${RED}Invalid choice. Please select 1-4.${NC}"
    exit 1
    ;;
esac

echo ""
echo -e "${GREEN}Test execution complete.${NC}"
