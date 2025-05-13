"""
CRUD operations component for the Streamlit application.
This module handles creating, reading, updating, and deleting records.
"""
import streamlit as st
import pandas as pd
import time
import tempfile
import io
from operations.data_operations import DataOperations
from models.country_currency import CountryCurrency
from templates.html_components import (
    section_header, 
    card_start, 
    card_end, 
    field_label,
    tooltip_field,
    success_message,
    error_message,
    delete_warning,
    delete_confirmation
)

def render_add_record_form():
    """Render the form for adding a new record."""
    st.markdown(section_header("➕", "Add New Country-Currency Mapping"), unsafe_allow_html=True)
    st.markdown(card_start(), unsafe_allow_html=True)
    
    with st.form("add_form"):
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown(tooltip_field("Country Code", "3-letter ISO 3166-1 alpha-3 country code"), unsafe_allow_html=True)
            country_code = st.text_input("", max_chars=3, placeholder="e.g. USA")
            
            st.markdown(tooltip_field("Country Name", "Full official country name"), unsafe_allow_html=True)
            country = st.text_input("", placeholder="e.g. United States of America", key="country_name_input")
            
            st.markdown(tooltip_field("Currency Name", "Full currency name"), unsafe_allow_html=True)
            currency_name = st.text_input("", placeholder="e.g. US Dollar", key="currency_name_input")
        
        with col2:
            st.markdown(tooltip_field("Country Number", "ISO 3166-1 numeric code (0-999)"), unsafe_allow_html=True)
            country_number = st.number_input("", min_value=0, max_value=999, step=1, format="%d", key="country_number_input")
            
            st.markdown(tooltip_field("Currency Code", "3-letter ISO 4217 currency code"), unsafe_allow_html=True)
            currency_code = st.text_input("", max_chars=3, placeholder="e.g. USD", key="currency_code_input")
            
            st.markdown(tooltip_field("Currency Number", "ISO 4217 numeric code (0-999)"), unsafe_allow_html=True)
            currency_number = st.number_input("", min_value=0, max_value=999, step=1, format="%d", key="currency_number_input")
        
        # Form submission
        col1, col2 = st.columns(2)
        with col1:
            submitted = st.form_submit_button("Add Record")
        with col2:
            if st.form_submit_button("Cancel"):
                st.session_state.current_view = "home"
                st.rerun()
        
        if submitted:
            # Validate form
            if not country_code or not country or not currency_code or not currency_name:
                st.markdown(error_message("Please fill in all required fields."), unsafe_allow_html=True)
                return
            
            # Create a new CountryCurrency object
            new_record = CountryCurrency(
                country_code=country_code.upper(),
                country=country,
                country_number=country_number,
                currency_code=currency_code.upper(),
                currency_name=currency_name,
                currency_number=currency_number
            )
            
            # Save the new record
            try:
                operations = DataOperations(st.session_state.databricks_client)
                operations.add_record(new_record)
                st.markdown(success_message("Record added successfully."), unsafe_allow_html=True)
                # Clear the form (by returning to home view after a short delay)
                with st.spinner("Redirecting..."):
                    time.sleep(2)
                st.session_state.current_view = "home"
                st.rerun()
            except Exception as e:
                st.markdown(error_message(f"Error adding record: {str(e)}"), unsafe_allow_html=True)
    
    st.markdown(card_end(), unsafe_allow_html=True)

def render_edit_record_form(record_id):
    """
    Render the form for editing an existing record.
    
    Args:
        record_id: ID of the record to edit
    """
    if not record_id:
        st.warning("No record selected for editing.")
        if st.button("Return to Home"):
            st.session_state.current_view = "home"
            st.rerun()
        return
    
    operations = DataOperations(st.session_state.databricks_client)
    record = operations.get_record_by_id(record_id)
    
    if not record:
        st.error(f"Record with ID {record_id} not found.")
        if st.button("Return to Home"):
            st.session_state.current_view = "home"
            st.rerun()
        return
    
    # Convert dictionary to model
    record = CountryCurrency.from_dict(record)
    
    st.markdown(section_header("✏️", f"Edit Record: {record.country_code}"), unsafe_allow_html=True)
    st.markdown(card_start(), unsafe_allow_html=True)
    
    with st.form("edit_form"):
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown(field_label("Country Code", "3-letter ISO 3166-1 alpha-3"), unsafe_allow_html=True)
            country_code = st.text_input("", value=record.country_code, max_chars=3)
            
            st.markdown(field_label("Country Name", "Full country name"), unsafe_allow_html=True)
            country = st.text_input("", value=record.country)
            
            st.markdown(field_label("Currency Name", "Full currency name"), unsafe_allow_html=True)
            currency_name = st.text_input("", value=record.currency_name, key="edit_currency_name")
        
        with col2:
            st.markdown(field_label("Country Number", "ISO 3166-1 numeric code"), unsafe_allow_html=True)
            country_number = st.number_input("", value=record.country_number, min_value=0, max_value=999, step=1)
            
            st.markdown(field_label("Currency Code", "3-letter ISO 4217"), unsafe_allow_html=True)
            currency_code = st.text_input("", value=record.currency_code, max_chars=3)
            
            st.markdown(field_label("Currency Number", "ISO 4217 numeric code"), unsafe_allow_html=True)
            currency_number = st.number_input("", value=record.currency_number, min_value=0, max_value=999, step=1)
        
        # Form submission
        col1, col2 = st.columns(2)
        with col1:
            submitted = st.form_submit_button("Update Record")
        with col2:
            if st.form_submit_button("Cancel"):
                st.session_state.current_view = "home"
                st.session_state.edit_record_id = None
                st.rerun()
        
        if submitted:
            # Validate form
            if not country_code or not country or not currency_code or not currency_name:
                st.markdown(error_message("Please fill in all required fields."), unsafe_allow_html=True)
                return
            
            # Update the record
            updated_record = CountryCurrency(
                country_code=country_code.upper(),
                country=country,
                country_number=country_number,
                currency_code=currency_code.upper(),
                currency_name=currency_name,
                currency_number=currency_number
            )
            
            try:
                operations.update_record(updated_record)
                st.markdown(success_message("Record updated successfully."), unsafe_allow_html=True)
                # Return to home view after a short delay
                with st.spinner("Redirecting..."):
                    time.sleep(2)
                st.session_state.current_view = "home"
                st.session_state.edit_record_id = None
                st.rerun()
            except Exception as e:
                st.markdown(error_message(f"Error updating record: {str(e)}"), unsafe_allow_html=True)
    
    st.markdown(card_end(), unsafe_allow_html=True)

def render_delete_record_form(record_id):
    """
    Render the form for deleting a record.
    
    Args:
        record_id: ID of the record to delete
    """
    if not record_id:
        st.warning("No record selected for deletion.")
        if st.button("Return to Home"):
            st.session_state.current_view = "home"
            st.rerun()
        return
    
    operations = DataOperations(st.session_state.databricks_client)
    record = operations.get_record_by_id(record_id)
    
    if not record:
        st.error(f"Record with ID {record_id} not found.")
        if st.button("Return to Home"):
            st.session_state.current_view = "home"
            st.rerun()
        return
    
    # Convert dictionary to model
    record = CountryCurrency.from_dict(record)
    
    st.markdown(section_header("🗑️", f"Delete Record: {record.country_code}"), unsafe_allow_html=True)
    st.markdown(card_start(), unsafe_allow_html=True)
    
    # Display record information
    st.markdown(f"""
    <div style="margin-bottom: 20px;">
        <div><strong>Country:</strong> {record.country} ({record.country_code})</div>
        <div><strong>Country Number:</strong> {record.country_number}</div>
        <div><strong>Currency:</strong> {record.currency_name} ({record.currency_code})</div>
        <div><strong>Currency Number:</strong> {record.currency_number}</div>
    </div>
    """, unsafe_allow_html=True)
    
    # Warning message
    st.markdown(delete_warning(), unsafe_allow_html=True)
    st.markdown(delete_confirmation(), unsafe_allow_html=True)
    
    col1, col2 = st.columns(2)
    
    with col1:
        if st.button("Confirm Delete", key="confirm_delete_btn"):
            try:
                operations.delete_record(record.country_code)
                st.markdown(success_message("Record deleted successfully."), unsafe_allow_html=True)
                # Return to home view after a short delay
                with st.spinner("Redirecting..."):
                    time.sleep(2)
                st.session_state.current_view = "home"
                st.session_state.delete_record_id = None
                st.rerun()
            except Exception as e:
                st.markdown(error_message(f"Error deleting record: {str(e)}"), unsafe_allow_html=True)
    
    with col2:
        if st.button("Cancel", key="cancel_delete_btn"):
            st.session_state.current_view = "home"
            st.session_state.delete_record_id = None
            st.rerun()
    
    st.markdown(card_end(), unsafe_allow_html=True)

def render_batch_upload():
    """Render the interface for batch uploading records from a CSV or Excel file."""
    st.markdown(section_header("📤", "Batch Upload"), unsafe_allow_html=True)
    st.markdown(card_start(), unsafe_allow_html=True)
    
    st.markdown("""
    Upload multiple records at once using a CSV or Excel file.
    The file should have the following columns:
    - country_code (required)
    - country (required)
    - country_number
    - currency_name (required)
    - currency_code (required)
    - currency_number
    """)
    
    uploaded_file = st.file_uploader("Choose a file", type=["csv", "xlsx"])
    
    if uploaded_file is not None:
        try:
            # Determine file type
            if uploaded_file.name.endswith('.csv'):
                df = pd.read_csv(uploaded_file)
            else:
                df = pd.read_excel(uploaded_file)
            
            # Display preview
            st.subheader("Preview")
            st.dataframe(df.head(5), use_container_width=True)
            
            # Validate data
            required_columns = ['country_code', 'country', 'currency_name', 'currency_code']
            missing_columns = [col for col in required_columns if col not in df.columns]
            
            if missing_columns:
                st.markdown(error_message(f"Missing required columns: {', '.join(missing_columns)}"), unsafe_allow_html=True)
            else:
                # Convert NaN values to appropriate defaults
                df['country_number'].fillna(0, inplace=True)
                df['currency_number'].fillna(0, inplace=True)
                
                # Process upload
                if st.button("Upload Records"):
                    with st.spinner("Uploading records..."):
                        operations = DataOperations(st.session_state.databricks_client)
                        
                        # Process each record
                        success_count = 0
                        error_count = 0
                        errors = []
                        
                        for _, row in df.iterrows():
                            try:
                                # Create record
                                record = CountryCurrency(
                                    country_code=str(row['country_code']).upper(),
                                    country=str(row['country']),
                                    country_number=int(row['country_number']) if 'country_number' in row and not pd.isna(row['country_number']) else 0,
                                    currency_code=str(row['currency_code']).upper(),
                                    currency_name=str(row['currency_name']),
                                    currency_number=int(row['currency_number']) if 'currency_number' in row and not pd.isna(row['currency_number']) else 0
                                )
                                
                                # Add record to database
                                operations.add_record(record)
                                success_count += 1
                            except Exception as e:
                                error_count += 1
                                errors.append(f"Error on row {_+2}: {str(e)}")
                        
                        # Show results
                        st.markdown(f"""
                        <div style="margin-top: 20px;">
                            <div><strong>Upload Summary:</strong></div>
                            <div>Successful uploads: {success_count}</div>
                            <div>Failed uploads: {error_count}</div>
                        </div>
                        """, unsafe_allow_html=True)
                        
                        if errors:
                            with st.expander("Show Errors"):
                                for error in errors:
                                    st.error(error)
                        
                        if success_count > 0:
                            st.markdown(success_message(f"Successfully uploaded {success_count} records."), unsafe_allow_html=True)
        
        except Exception as e:
            st.markdown(error_message(f"Error processing file: {str(e)}"), unsafe_allow_html=True)
    
    # Template download
    st.markdown("### Download Template")
    st.markdown("Download a template file to see the required format:")
    
    col1, col2 = st.columns(2)
    
    with col1:
        if st.button("Download CSV Template"):
            template_data = {
                "country_code": ["USA", "GBR", "JPN"],
                "country": ["United States of America", "United Kingdom", "Japan"],
                "country_number": [840, 826, 392],
                "currency_name": ["US Dollar", "Pound Sterling", "Japanese Yen"],
                "currency_code": ["USD", "GBP", "JPY"],
                "currency_number": [840, 826, 392]
            }
            df = pd.DataFrame(template_data)
            csv = df.to_csv(index=False)
            st.download_button(
                label="Click to download",
                data=csv,
                file_name="country_currency_template.csv",
                mime="text/csv"
            )
    
    with col2:
        if st.button("Download Excel Template"):
            template_data = {
                "country_code": ["USA", "GBR", "JPN"],
                "country": ["United States of America", "United Kingdom", "Japan"],
                "country_number": [840, 826, 392],
                "currency_name": ["US Dollar", "Pound Sterling", "Japanese Yen"],
                "currency_code": ["USD", "GBP", "JPY"],
                "currency_number": [840, 826, 392]
            }
            df = pd.DataFrame(template_data)
            
            # Create Excel in memory
            output = io.BytesIO()
            with pd.ExcelWriter(output, engine='openpyxl') as writer:
                df.to_excel(writer, index=False, sheet_name="Template")
            excel_data = output.getvalue()
            
            st.download_button(
                label="Click to download",
                data=excel_data,
                file_name="country_currency_template.xlsx",
                mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            )
    
    st.markdown(card_end(), unsafe_allow_html=True)
