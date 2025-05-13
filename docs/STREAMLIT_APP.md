# Streamlit Application Documentation

## Overview
The Streamlit application provides a user-friendly interface for performing CRUD operations on the country-currency mapping data stored in Databricks. 

## Architecture
The application follows a layered architecture:

1. **Presentation Layer**: Streamlit UI components
2. **Business Logic Layer**: Data validation and processing
3. **Data Access Layer**: Databricks connectivity using PyDatabricks client

## Features
- View, add, edit, and delete country-currency mappings
- Search and filtering capabilities
- Data validation to ensure integrity
- Authentication integration with Databricks

## Setup and Installation
See the `streamlit/README.md` file for setup instructions.

## Usage
1. Start the application with `streamlit run app.py`
2. Authenticate with your Databricks credentials
3. Interact with the country-currency data through the provided interface

## Development
- Add new UI components in the `ui` module
- Implement new data operations in the `operations` module
- Extend the data models in the `models` module
