"""
CRUD view components for the Streamlit application.
"""
import streamlit as st
from operations.data_operations import DataOperations
from models.country_currency import CountryCurrency

def render_crud_views():
    """Render CRUD (Create, Read, Update, Delete) views."""
    if not st.session_state.authenticated:
        return
    
    if st.session_state.current_view == "add":
        _render_add_view()
    elif st.session_state.current_view == "edit":
        _render_edit_view()
    elif st.session_state.current_view == "delete":
        _render_delete_view()

def _render_add_view():
    """Render the add new entry view."""
    st.header("Add New Country-Currency Mapping")
    
    with st.form("add_form"):
        col1, col2 = st.columns(2)
        
        with col1:
            country_code = st.text_input("Country Code (3 letters, ISO 3166-1 alpha-3)", max_chars=3)
            country = st.text_input("Country Name")
            currency_name = st.text_input("Currency Name")
        
        with col2:
            country_number = st.number_input("Country Number (ISO 3166-1 numeric)", min_value=0, max_value=999, step=1)
            currency_code = st.text_input("Currency Code (3 letters, ISO 4217)", max_chars=3)
            currency_number = st.number_input("Currency Number (ISO 4217 numeric)", min_value=0, max_value=999, step=1)
        
        # Form submission
        submit_col, cancel_col = st.columns(2)
        with submit_col:
            submitted = st.form_submit_button("Add Entry")
        with cancel_col:
            if st.form_submit_button("Cancel"):
                st.session_state.current_view = "home"
                st.rerun()
        
        if submitted:
            # Validate form
            if not country_code or not country or not currency_code or not currency_name:
                st.error("Please fill in all required fields.")
                return
            
            # Create new record
            new_record = {
                'country_code': country_code.upper(),
                'country_number': country_number,
                'country': country,
                'currency_name': currency_name,
                'currency_code': currency_code.upper(),
                'currency_number': currency_number
            }
            
            try:
                # Add the record to the database
                operations = DataOperations(st.session_state.databricks_client)
                
                # Check if country code already exists
                existing = operations.get_record_by_id(country_code.upper())
                if existing:
                    st.error(f"A country with code {country_code.upper()} already exists.")
                    return
                
                with st.spinner("Adding new entry..."):
                    success = operations.create_record(new_record)
                
                if success:
                    st.success(f"Successfully added {country} ({country_code.upper()}).")
                    st.session_state.current_view = "home"
                    st.rerun()
                else:
                    st.error("Failed to add new entry.")
            except Exception as e:
                st.error(f"Error: {str(e)}")

def _render_edit_view():
    """Render the edit entry view."""
    st.header("Edit Country-Currency Mapping")
    
    if not st.session_state.edit_item:
        st.error("No item selected for editing.")
        if st.button("Back to List"):
            st.session_state.current_view = "home"
            st.rerun()
        return
    
    # Get existing record
    record = st.session_state.edit_item
    
    with st.form("edit_form"):
        col1, col2 = st.columns(2)
        
        with col1:
            country_code = st.text_input("Country Code (3 letters, ISO 3166-1 alpha-3)", 
                                       value=record['country_code'], 
                                       disabled=True)  # Country code is the primary key, can't change
            country = st.text_input("Country Name", value=record['country'])
            currency_name = st.text_input("Currency Name", value=record['currency_name'])
        
        with col2:
            country_number = st.number_input("Country Number (ISO 3166-1 numeric)", 
                                           min_value=0, 
                                           max_value=999, 
                                           step=1, 
                                           value=record['country_number'])
            currency_code = st.text_input("Currency Code (3 letters, ISO 4217)", 
                                        max_chars=3, 
                                        value=record['currency_code'])
            currency_number = st.number_input("Currency Number (ISO 4217 numeric)", 
                                            min_value=0, 
                                            max_value=999, 
                                            step=1, 
                                            value=record['currency_number'])
        
        # Form submission
        submit_col, cancel_col = st.columns(2)
        with submit_col:
            submitted = st.form_submit_button("Save Changes")
        with cancel_col:
            if st.form_submit_button("Cancel"):
                st.session_state.current_view = "home"
                st.session_state.edit_item = None
                st.rerun()
        
        if submitted:
            # Validate form
            if not country_code or not country or not currency_code or not currency_name:
                st.error("Please fill in all required fields.")
                return
            
            # Update record
            updated_record = {
                'country_code': country_code.upper(),  # Primary key, unchanged
                'country_number': country_number,
                'country': country,
                'currency_name': currency_name,
                'currency_code': currency_code.upper(),
                'currency_number': currency_number
            }
            
            try:
                # Update the record in the database
                operations = DataOperations(st.session_state.databricks_client)
                
                with st.spinner("Updating entry..."):
                    success = operations.update_record(updated_record)
                
                if success:
                    st.success(f"Successfully updated {country} ({country_code.upper()}).")
                    st.session_state.current_view = "home"
                    st.session_state.edit_item = None
                    st.rerun()
                else:
                    st.error("Failed to update entry.")
            except Exception as e:
                st.error(f"Error: {str(e)}")

def _render_delete_view():
    """Render the delete confirmation view."""
    st.header("Delete Country-Currency Mapping")
    
    if not st.session_state.edit_item:
        st.error("No item selected for deletion.")
        if st.button("Back to List"):
            st.session_state.current_view = "home"
            st.rerun()
        return
    
    # Get existing record
    record = st.session_state.edit_item
    
    st.warning("Are you sure you want to delete this entry? This action cannot be undone.")
    
    # Display the record details
    st.write(f"**Country Code:** {record['country_code']}")
    st.write(f"**Country:** {record['country']}")
    st.write(f"**Currency:** {record['currency_name']} ({record['currency_code']})")
    
    col1, col2 = st.columns(2)
    with col1:
        if st.button("Confirm Delete", key="confirm_delete"):
            try:
                # Delete the record from the database
                operations = DataOperations(st.session_state.databricks_client)
                
                with st.spinner("Deleting entry..."):
                    success = operations.delete_record(record['country_code'])
                
                if success:
                    st.success(f"Successfully deleted {record['country']} ({record['country_code']}).")
                    st.session_state.current_view = "home"
                    st.session_state.edit_item = None
                    st.rerun()
                else:
                    st.error("Failed to delete entry.")
            except Exception as e:
                st.error(f"Error: {str(e)}")
    
    with col2:
        if st.button("Cancel", key="cancel_delete"):
            st.session_state.current_view = "home"
            st.session_state.edit_item = None
            st.rerun()
