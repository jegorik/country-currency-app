"""
CRUD view components for the Streamlit application.
"""
import streamlit as st
import time
import logging
import re
from operations.data_operations import DataOperations
from models.country_currency import CountryCurrency
from templates.html_components import (
    section_header, 
    card_start, 
    card_end, 
    field_label,
    success_message,
    error_message,
    delete_warning,
    delete_confirmation
)

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
    st.markdown(section_header("➕", "Add New Country-Currency Mapping"), unsafe_allow_html=True)
    st.markdown(card_start(), unsafe_allow_html=True)

    with st.form("add_form"):
        col1, col2 = st.columns(2)

        with col1:
            st.markdown(field_label("Country Code", "3 letters, ISO 3166-1 alpha-3"), unsafe_allow_html=True)
            country_code = st.text_input("", max_chars=3, placeholder="e.g. USA", key="add_country_code")

            st.markdown(field_label("Country Name", "Full country name"), unsafe_allow_html=True)
            country = st.text_input("", placeholder="e.g. United States of America", key="add_country_name")

            st.markdown(field_label("Currency Name", "Full currency name"), unsafe_allow_html=True)
            currency_name = st.text_input("", placeholder="e.g. US Dollar", key="add_currency_name")

        with col2:
            st.markdown(field_label("Country Number", "ISO 3166-1 numeric code"), unsafe_allow_html=True)
            country_number = st.number_input("", min_value=0, max_value=999, step=1, format="%d", key="add_country_number")

            st.markdown(field_label("Currency Code", "3 letters, ISO 4217"), unsafe_allow_html=True)
            currency_code = st.text_input("", max_chars=3, placeholder="e.g. USD", key="add_currency_code")

            st.markdown(field_label("Currency Number", "ISO 4217 numeric code"), unsafe_allow_html=True)
            currency_number = st.number_input("", min_value=0, max_value=999, step=1, format="%d", key="add_currency_number")

        # Form submission
        col1, col2 = st.columns(2)
        with col1:
            submitted = st.form_submit_button("Add Entry")
        with col2:
            if st.form_submit_button("Cancel"):
                st.session_state.current_view = "home"
                st.rerun()

        if submitted:
            # Validate form - check required fields
            if not country_code or not country or not currency_code or not currency_name:
                st.markdown(error_message("Please fill in all required fields."), unsafe_allow_html=True)
                return

            # Validate country_code format (3 uppercase letters)
            if not re.match(r'^[A-Z]{3}$', country_code.upper()):
                st.markdown(error_message("Country Code must be exactly 3 letters (A-Z)."), unsafe_allow_html=True)
                return

            # Validate currency_code format (3 uppercase letters)
            if not re.match(r'^[A-Z]{3}$', currency_code.upper()):
                st.markdown(error_message("Currency Code must be exactly 3 letters (A-Z)."), unsafe_allow_html=True)
                return

            # Validate country name (not empty and reasonable length)
            if len(country.strip()) < 2 or len(country.strip()) > 100:
                st.markdown(error_message("Country name must be between 2 and 100 characters."), unsafe_allow_html=True)
                return

            # Validate currency name (not empty and reasonable length)
            if len(currency_name.strip()) < 2 or len(currency_name.strip()) > 100:
                st.markdown(error_message("Currency name must be between 2 and 100 characters."), unsafe_allow_html=True)
                return

            # Check if country_code already exists
            operations = DataOperations(st.session_state.databricks_client)
            existing_record = operations.get_record_by_id(country_code.upper())
            if existing_record:
                st.markdown(error_message(f"A record with Country Code '{country_code.upper()}' already exists."), unsafe_allow_html=True)
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
                time_placeholder = st.empty()
                time_placeholder.text("Redirecting to home view in 3 seconds...")
                time.sleep(3)
                # Refresh data using the utility function
                from utils.app_utils import refresh_data
                refresh_data()
                st.session_state.current_view = "home"
                st.rerun()
            except Exception as e:
                st.markdown(error_message(f"Error adding record: {str(e)}"), unsafe_allow_html=True)

    st.markdown(card_end(), unsafe_allow_html=True)

def _render_edit_view():
    """Render the edit entry view."""
    if "edit_record_id" not in st.session_state:
        st.warning("No record selected for editing.")
        return

    st.markdown(section_header("✏️", "Edit Country-Currency Mapping"), unsafe_allow_html=True)
    st.markdown(card_start(), unsafe_allow_html=True)

    try:
        operations = DataOperations(st.session_state.databricks_client)
        record = operations.get_record_by_id(st.session_state.edit_record_id)

        if not record:
            st.markdown(error_message("Record not found."), unsafe_allow_html=True)
            return

        # Convert dictionary to model
        record_model = CountryCurrency.from_dict(record)

        with st.form("edit_form"):
            col1, col2 = st.columns(2)

            with col1:
                st.markdown(field_label("Country Code", "3 letters, ISO 3166-1 alpha-3 (cannot be changed)"), unsafe_allow_html=True)
                country_code = st.text_input("", value=record['country_code'], max_chars=3, disabled=True, key="edit_country_code")

                st.markdown(field_label("Country Name", "Full country name"), unsafe_allow_html=True)
                country = st.text_input("", value=record['country'], key="edit_country_name")

                st.markdown(field_label("Currency Name", "Full currency name"), unsafe_allow_html=True)
                currency_name = st.text_input("", value=record['currency_name'], key="edit_currency_name")

            with col2:
                st.markdown(field_label("Country Number", "ISO 3166-1 numeric code"), unsafe_allow_html=True)
                country_number = st.number_input("", value=record['country_number'], min_value=0, max_value=999, step=1, key="edit_country_number")

                st.markdown(field_label("Currency Code", "3 letters, ISO 4217"), unsafe_allow_html=True)
                currency_code = st.text_input("", value=record['currency_code'], max_chars=3, key="edit_currency_code")

                st.markdown(field_label("Currency Number", "ISO 4217 numeric code"), unsafe_allow_html=True)
                currency_number = st.number_input("", value=record['currency_number'], min_value=0, max_value=999, step=1, key="edit_currency_number")

            # Form submission
            col1, col2 = st.columns(2)
            with col1:
                submitted = st.form_submit_button("Update")
            with col2:
                if st.form_submit_button("Cancel"):
                    st.session_state.current_view = "home"
                    st.session_state.edit_record_id = None
                    # No need to refresh data on cancel since no changes were made
                    st.rerun()

            if submitted:
                # Validate form - check required fields
                if not country_code or not country or not currency_code or not currency_name:
                    st.markdown(error_message("Please fill in all required fields."), unsafe_allow_html=True)
                    return

                # Validate currency_code format (3 uppercase letters)
                if not re.match(r'^[A-Z]{3}$', currency_code.upper()):
                    st.markdown(error_message("Currency Code must be exactly 3 letters (A-Z)."), unsafe_allow_html=True)
                    return

                # Validate country name (not empty and reasonable length)
                if len(country.strip()) < 2 or len(country.strip()) > 100:
                    st.markdown(error_message("Country name must be between 2 and 100 characters."), unsafe_allow_html=True)
                    return

                # Validate currency name (not empty and reasonable length)
                if len(currency_name.strip()) < 2 or len(currency_name.strip()) > 100:
                    st.markdown(error_message("Currency name must be between 2 and 100 characters."), unsafe_allow_html=True)
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
                    # Explicitly set country_code from the selected record
                    updated_record.country_code = st.session_state.edit_record_id

                    # Log record information for debugging
                    logger = logging.getLogger(__name__)
                    logger.debug(f"Updating record: {updated_record.country_code}, {updated_record.country}, {updated_record.currency_code}")

                    success = operations.update_record(updated_record)

                    if success:
                        st.markdown(success_message("Record updated successfully."), unsafe_allow_html=True)
                        # Return to home view after a short delay
                        time_placeholder = st.empty()
                        time_placeholder.text("Redirecting to home view in 3 seconds...")
                        time.sleep(3)
                        # Refresh data using the utility function
                        from utils.app_utils import refresh_data
                        refresh_data()
                        st.session_state.current_view = "home"
                        st.session_state.edit_record_id = None
                        # Force data refresh
                        st.rerun()
                    else:
                        st.markdown(error_message("Failed to update record. Please check the database connection."), unsafe_allow_html=True)
                except Exception as e:
                    import traceback
                    error_details = traceback.format_exc()
                    st.markdown(error_message(f"Error updating record: {str(e)}"), unsafe_allow_html=True)
                    # Add detailed error information
                    with st.expander("Error Details"):
                        st.code(error_details)
    except Exception as e:
        st.markdown(error_message(f"Error loading record: {str(e)}"), unsafe_allow_html=True)

    st.markdown(card_end(), unsafe_allow_html=True)

def _render_delete_view():
    """Render the delete entry view."""
    if "delete_record_id" not in st.session_state:
        st.warning("No record selected for deletion.")
        return

    st.markdown(section_header("🗑️", "Delete Country-Currency Mapping"), unsafe_allow_html=True)
    st.markdown(card_start(), unsafe_allow_html=True)

    try:
        operations = DataOperations(st.session_state.databricks_client)
        record = operations.get_record_by_id(st.session_state.delete_record_id)

        if not record:
            st.markdown(error_message("Record not found."), unsafe_allow_html=True)
            return

        # Show delete warning
        st.markdown(delete_warning(), unsafe_allow_html=True)

        # Display record information
        st.markdown(f"""
        <div style="background-color: #2d2d2d; padding: 15px; border-radius: 5px; margin-bottom: 20px;">
            <div style="display: flex; justify-content: space-between; margin-bottom: 10px;">
                <div><strong>Country:</strong> {record['country']} ({record['country_code']})</div>
                <div><strong>Country Number:</strong> {record['country_number']}</div>
            </div>
            <div style="display: flex; justify-content: space-between;">
                <div><strong>Currency:</strong> {record['currency_name']} ({record['currency_code']})</div>
                <div><strong>Currency Number:</strong> {record['currency_number']}</div>
            </div>
        </div>
        """, unsafe_allow_html=True)

        # Delete confirmation
        st.markdown(delete_confirmation(), unsafe_allow_html=True)

        col1, col2 = st.columns(2)

        with col1:
            if st.button("Confirm Delete", use_container_width=True, key="delete_confirm_btn"):
                try:
                    operations.delete_record(st.session_state.delete_record_id)
                    st.markdown(success_message("Record deleted successfully."), unsafe_allow_html=True)
                    # Return to home view after a short delay
                    time_placeholder = st.empty()
                    time_placeholder.text("Redirecting to home view in 3 seconds...")
                    time.sleep(3)
                    # Refresh data using the utility function
                    from utils.app_utils import refresh_data
                    refresh_data()
                    st.session_state.current_view = "home"
                    st.session_state.delete_record_id = None
                    st.rerun()
                except Exception as e:
                    st.markdown(error_message(f"Error deleting record: {str(e)}"), unsafe_allow_html=True)

        with col2:
            if st.button("Cancel", use_container_width=True, key="delete_cancel_btn"):
                st.session_state.current_view = "home"
                st.session_state.delete_record_id = None
                # No need to refresh data on cancel since no changes were made
                st.rerun()
    except Exception as e:
        st.markdown(error_message(f"Error loading record: {str(e)}"), unsafe_allow_html=True)

    st.markdown(card_end(), unsafe_allow_html=True)
