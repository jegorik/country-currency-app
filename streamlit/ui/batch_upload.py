"""
Batch upload component for the Streamlit application.
This module provides functionality to upload multiple country-currency mappings at once.
"""
import streamlit as st
import pandas as pd
import io
import logging
import time
from operations.data_operations import DataOperations
from models.country_currency import CountryCurrency
from templates.html_components import (
    section_header, 
    card_start, 
    card_end, 
    field_label,
    success_message,
    error_message,
    info_box
)
from utils.app_utils import refresh_data

# Configure logger
logger = logging.getLogger(__name__)

def render_batch_upload_view():
    """Render the batch upload view."""
    if not st.session_state.authenticated:
        return
    
    st.markdown(section_header("📤", "Batch Upload Country-Currency Mappings"), unsafe_allow_html=True)
    st.markdown(card_start(), unsafe_allow_html=True)
    
    # Instructions
    st.markdown("""
    ### Upload Instructions
    
    Upload a CSV file containing multiple country-currency mappings. The file should have the following columns:
    
    - `country_code` (required): 3-letter ISO 3166-1 alpha-3 country code
    - `country` (required): Full country name
    - `country_number` (optional): ISO 3166-1 numeric country code
    - `currency_code` (required): 3-letter ISO 4217 currency code
    - `currency_name` (required): Full currency name
    - `currency_number` (optional): ISO 4217 numeric currency code
    
    **Example CSV format:**
    ```
    country_code,country,country_number,currency_code,currency_name,currency_number
    USA,United States,840,USD,US Dollar,840
    CAN,Canada,124,CAD,Canadian Dollar,124
    ```
    """)
    
    # File upload
    uploaded_file = st.file_uploader("Choose a CSV file", type="csv")
    
    if uploaded_file is not None:
        try:
            # Read the CSV file
            df = pd.read_csv(uploaded_file)
            
            # Display the uploaded data
            st.subheader("Preview of uploaded data")
            st.dataframe(df.head(10), use_container_width=True)
            
            # Validate the data
            validation_errors = validate_upload_data(df)
            
            if validation_errors:
                # Display validation errors
                st.markdown(error_message("Validation errors found in the uploaded file:"), unsafe_allow_html=True)
                for error in validation_errors:
                    st.markdown(f"- {error}")
            else:
                # Process the data
                if st.button("Process Upload"):
                    with st.spinner("Processing upload..."):
                        success_count, error_count, errors = process_upload(df)
                        
                        if error_count > 0:
                            st.markdown(error_message(f"Upload completed with {error_count} errors. {success_count} records were successfully processed."), unsafe_allow_html=True)
                            st.subheader("Error Details")
                            for i, error in enumerate(errors):
                                st.markdown(f"**Row {error['row']}**: {error['message']}")
                        else:
                            st.markdown(success_message(f"Successfully uploaded {success_count} records."), unsafe_allow_html=True)
                            # Refresh data
                            refresh_data(reset_page=True, show_message=False)
                            
                            # Return to home view after a short delay
                            time_placeholder = st.empty()
                            time_placeholder.text("Redirecting to home view in 3 seconds...")
                            time.sleep(3)
                            st.session_state.current_view = "home"
                            st.rerun()
        
        except Exception as e:
            st.markdown(error_message(f"Error processing file: {str(e)}"), unsafe_allow_html=True)
            logger.error(f"Error processing batch upload: {str(e)}", exc_info=True)
    
    # Cancel button
    if st.button("Cancel"):
        st.session_state.current_view = "home"
        st.rerun()
    
    st.markdown(card_end(), unsafe_allow_html=True)

def validate_upload_data(df):
    """
    Validate the uploaded data.
    
    Args:
        df (pandas.DataFrame): The dataframe containing the uploaded data
        
    Returns:
        list: A list of validation error messages
    """
    errors = []
    
    # Check required columns
    required_columns = ['country_code', 'country', 'currency_code', 'currency_name']
    for col in required_columns:
        if col not in df.columns:
            errors.append(f"Missing required column: {col}")
    
    # If missing required columns, return early
    if errors:
        return errors
    
    # Check for empty values in required columns
    for col in required_columns:
        if df[col].isnull().any():
            errors.append(f"Column {col} contains empty values")
    
    # Validate country_code format (3 uppercase letters)
    invalid_country_codes = df[~df['country_code'].str.match(r'^[A-Z]{3}$', na=False)]
    if not invalid_country_codes.empty:
        errors.append(f"Invalid country codes found. Country codes must be exactly 3 uppercase letters.")
        
    # Validate currency_code format (3 uppercase letters)
    invalid_currency_codes = df[~df['currency_code'].str.match(r'^[A-Z]{3}$', na=False)]
    if not invalid_currency_codes.empty:
        errors.append(f"Invalid currency codes found. Currency codes must be exactly 3 uppercase letters.")
    
    # Validate country name length
    invalid_country_names = df[(df['country'].str.len() < 2) | (df['country'].str.len() > 100)]
    if not invalid_country_names.empty:
        errors.append(f"Invalid country names found. Country names must be between 2 and 100 characters.")
    
    # Validate currency name length
    invalid_currency_names = df[(df['currency_name'].str.len() < 2) | (df['currency_name'].str.len() > 100)]
    if not invalid_currency_names.empty:
        errors.append(f"Invalid currency names found. Currency names must be between 2 and 100 characters.")
    
    # Validate numeric fields if present
    if 'country_number' in df.columns:
        if not pd.to_numeric(df['country_number'], errors='coerce').notnull().all():
            errors.append("Invalid country numbers found. Country numbers must be numeric.")
    
    if 'currency_number' in df.columns:
        if not pd.to_numeric(df['currency_number'], errors='coerce').notnull().all():
            errors.append("Invalid currency numbers found. Currency numbers must be numeric.")
    
    return errors

def process_upload(df):
    """
    Process the uploaded data and insert/update records.
    
    Args:
        df (pandas.DataFrame): The dataframe containing the validated data
        
    Returns:
        tuple: (success_count, error_count, errors)
    """
    operations = DataOperations(st.session_state.databricks_client)
    success_count = 0
    error_count = 0
    errors = []
    
    # Ensure numeric columns are properly formatted
    if 'country_number' not in df.columns:
        df['country_number'] = 0
    else:
        df['country_number'] = pd.to_numeric(df['country_number'], errors='coerce').fillna(0).astype(int)
    
    if 'currency_number' not in df.columns:
        df['currency_number'] = 0
    else:
        df['currency_number'] = pd.to_numeric(df['currency_number'], errors='coerce').fillna(0).astype(int)
    
    # Process each row
    for index, row in df.iterrows():
        try:
            # Create a CountryCurrency object
            record = CountryCurrency(
                country_code=row['country_code'],
                country=row['country'],
                country_number=row['country_number'],
                currency_code=row['currency_code'],
                currency_name=row['currency_name'],
                currency_number=row['currency_number']
            )
            
            # Check if record already exists
            existing_record = operations.get_record_by_id(row['country_code'])
            
            if existing_record:
                # Update existing record
                if operations.update_record(record):
                    success_count += 1
                    logger.info(f"Updated record for country_code: {row['country_code']}")
                else:
                    error_count += 1
                    errors.append({
                        'row': index + 2,  # +2 for 1-based indexing and header row
                        'message': f"Failed to update record for {row['country_code']}"
                    })
            else:
                # Create new record
                if operations.add_record(record):
                    success_count += 1
                    logger.info(f"Created record for country_code: {row['country_code']}")
                else:
                    error_count += 1
                    errors.append({
                        'row': index + 2,
                        'message': f"Failed to create record for {row['country_code']}"
                    })
        
        except Exception as e:
            error_count += 1
            errors.append({
                'row': index + 2,
                'message': f"Error processing row: {str(e)}"
            })
            logger.error(f"Error processing row {index + 2}: {str(e)}")
    
    return success_count, error_count, errors