"""
Main view component for the Streamlit application.
This module serves as the main dashboard with tabs for data exploration and analytics.
"""
import streamlit as st
import pandas as pd
from operations.data_operations import DataOperations
from templates.html_components import (
    section_header, 
    card_start, 
    card_end, 
    dataframe_container_start,
    dataframe_container_end,
    field_label,
    info_box,
    loader,
    app_header
)
from ui.data_display import render_data_display
from ui.filtering import render_filtering_controls
from ui.visualizations import render_visualizations

def render_main_view():
    """Render the main view of the application."""
    if not st.session_state.authenticated:
        return
    
    if st.session_state.current_view != "home":
        return
    
    # Display application header
    st.markdown(app_header(), unsafe_allow_html=True)
    
    # Display the data table if data is loaded
    if st.session_state.data_loaded:
        # Create a container for the data table
        with st.container():
            st.markdown(section_header("📊", "Country-Currency Mappings"), unsafe_allow_html=True)
            
            # Search card
            st.markdown(card_start(), unsafe_allow_html=True)
            
            # Add search/filter functionality
            col1, col2 = st.columns([3, 1])
            with col1:
                st.markdown(field_label("Filter by Country or Currency", 
                           "Type to search by country name, code, or currency code."), 
                           unsafe_allow_html=True)
                filter_value = st.text_input(
                    "",
                    value=st.session_state.filter_query,
                    placeholder="Type to filter..."
                )
                
                if filter_value != st.session_state.filter_query:
                    st.session_state.filter_query = filter_value
                    st.session_state.last_refresh = None  # Force refresh
            
            with col2:
                st.write("")  # Add some space
                st.write("")  # Add some space
                if st.button("Refresh Data"):
                    st.session_state.last_refresh = None  # Force refresh
            
            st.markdown(card_end(), unsafe_allow_html=True)
            
            # Data display card
            st.markdown(dataframe_container_start(), unsafe_allow_html=True)
            
            # Get data and display it
            try:
                operations = DataOperations(st.session_state.databricks_client)
                
                # Display a loading spinner while fetching data
                with st.spinner("Loading data..."):
                    data = operations.get_all_records(filter_query=st.session_state.filter_query)
                
                if not data:
                    st.markdown(info_box("No data found. Try a different filter or add new entries."), 
                               unsafe_allow_html=True)
                    return
                
                # Convert to pandas DataFrame for easier display
                df = pd.DataFrame(data)
                
                # Reorder and rename columns for better display
                columns = {
                    'country_code': 'Country Code',
                    'country_name': 'Country Name',
                    'country_number': 'Country Number',
                    'currency_code': 'Currency Code',
                    'currency_name': 'Currency Name',
                    'currency_number': 'Currency Number'
                }
                
                # Select only columns that exist in the DataFrame
                cols_to_use = [col for col in columns.keys() if col in df.columns]
                df_display = df[cols_to_use].copy()
                
                # Rename columns
                df_display.columns = [columns[col] for col in cols_to_use]
                
                # Display the data
                st.dataframe(df_display, use_container_width=True)
                
                # Show record count
                st.caption(f"Showing {len(df)} records")
                
            except Exception as e:
                st.error(f"Error loading data: {str(e)}")
            
            st.markdown(dataframe_container_end(), unsafe_allow_html=True)
    else:
        st.warning("Please connect to Databricks to load data.")
