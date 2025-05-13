"""
Data display component for the Streamlit application.
This module handles fetching, displaying, and pagination of data from Unity Catalog.
"""
import streamlit as st
import pandas as pd
import math
from operations.data_operations import DataOperations
from utils.databricks_client import DatabricksClient
from templates.html_components import (
    section_header, 
    card_start, 
    card_end, 
    dataframe_container_start,
    dataframe_container_end,
    info_box,
    loader
)

def render_data_display(filter_query=None, sort_by=None, sort_ascending=True, page=1, rows_per_page=10):
    """
    Render the data display component with pagination, sorting, and filtering.
    
    Args:
        filter_query: Optional filter query to apply
        sort_by: Column to sort by
        sort_ascending: Sort direction (True for ascending, False for descending)
        page: Current page number
        rows_per_page: Number of rows to display per page
    """
    if not st.session_state.get("authenticated", False):
        return
    
    st.markdown(section_header("📊", "Data Explorer"), unsafe_allow_html=True)
    
    # Get data operations
    try:
        operations = DataOperations(st.session_state.databricks_client)
        
        # Stats Card
        st.markdown(card_start(), unsafe_allow_html=True)
        col1, col2, col3 = st.columns(3)
        
        with col1:
            try:
                total_records = operations.count_records()
                st.metric("Total Records", f"{total_records:,}")
            except Exception as e:
                st.error(f"Error getting record count: {str(e)}")
        
        with col2:
            st.metric("Table Schema", st.session_state.databricks_client.config.schema)
        
        with col3:
            st.metric("Table Name", st.session_state.databricks_client.config.table)
        
        st.markdown(card_end(), unsafe_allow_html=True)
        
        # Data Card
        st.markdown(dataframe_container_start(), unsafe_allow_html=True)
        
        # Set up pagination controls
        total_records = operations.count_records()
        total_pages = math.ceil(total_records / rows_per_page)
        
        # Pagination controls
        col1, col2, col3, col4 = st.columns([1, 1, 1, 1])
        
        with col1:
            if st.button("⏮️ First", disabled=page <= 1):
                st.session_state.current_page = 1
                st.rerun()
        
        with col2:
            if st.button("◀️ Previous", disabled=page <= 1):
                st.session_state.current_page = max(1, page - 1)
                st.rerun()
        
        with col3:
            if st.button("Next ▶️", disabled=page >= total_pages):
                st.session_state.current_page = min(total_pages, page + 1)
                st.rerun()
        
        with col4:
            if st.button("Last ⏭️", disabled=page >= total_pages):
                st.session_state.current_page = total_pages
                st.rerun()
                
        # Page indicator
        st.caption(f"Page {page} of {total_pages}")
        
        # Get data with pagination
        with st.spinner("Loading data..."):
            offset = (page - 1) * rows_per_page
            query = f"SELECT * FROM {operations.table_name}"
            
            # Add filtering with case-insensitive search
            if filter_query:
                query += f" WHERE LOWER(country) LIKE LOWER('%{filter_query}%') OR LOWER(country_code) LIKE LOWER('%{filter_query}%') " \
                         f"OR LOWER(currency_name) LIKE LOWER('%{filter_query}%') OR LOWER(currency_code) LIKE LOWER('%{filter_query}%')"
            
            # Add sorting
            if sort_by:
                query += f" ORDER BY {sort_by} {'ASC' if sort_ascending else 'DESC'}"
            else:
                query += " ORDER BY country_code"
                
            # Add pagination
            query += f" LIMIT {rows_per_page} OFFSET {offset}"
            
            data = operations.client.execute_query(query)
            
            if not data:
                st.markdown(info_box("No data found. Try a different filter or add new entries."), unsafe_allow_html=True)
                st.markdown(dataframe_container_end(), unsafe_allow_html=True)
                return
            
            # Convert to pandas DataFrame for display
            df = pd.DataFrame(data)
            
            # Display the data as an interactive table
            st.dataframe(df, use_container_width=True, height=400)
            
            # Show record count
            st.caption(f"Showing {len(df)} of {total_records:,} records")
            
        st.markdown(dataframe_container_end(), unsafe_allow_html=True)
        
        # Table Schema Information
        with st.expander("Table Schema Information"):
            # Get column information
            table_schema = operations.get_table_schema()
            if table_schema:
                schema_df = pd.DataFrame(table_schema)
                st.dataframe(schema_df, use_container_width=True)
            else:
                st.info("Schema information not available")
                
    except Exception as e:
        st.error(f"Error loading data: {str(e)}")
