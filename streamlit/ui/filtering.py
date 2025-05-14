"""
Filtering and sorting component for the Streamlit application.
This module handles all data filtering, searching, and sorting functionality.
"""
import streamlit as st
import pandas as pd
from operations.data_operations import DataOperations
from templates.html_components import (
    section_header, 
    card_start, 
    card_end, 
    field_label,
    tooltip_field
)

def render_filtering_controls():
    """
    Render the filtering and sorting controls.
    
    Returns:
        tuple: filter_query, sort_by, sort_ascending
    """
    st.markdown(card_start(), unsafe_allow_html=True)
    
    # Use standard Streamlit components but adjust the layout
    col1, col2 = st.columns([3, 1])
    
    with col1:
        # Add search label and text input
        st.markdown(field_label("Search", "Filter by country, currency, or codes"), unsafe_allow_html=True)
        filter_query = st.text_input(
            "",
            value=st.session_state.get("filter_query", ""),
            placeholder="Type to search..."
        )
        
        if "filter_query" not in st.session_state or filter_query != st.session_state.filter_query:
            st.session_state.filter_query = filter_query
            # Reset to first page when filter changes
            st.session_state.current_page = 1
    
    # Space between columns
    st.write("")
    
    # Create a new row of columns for the button with proper alignment
    col1, col2, col3 = st.columns([2.5, 0.5, 1])
    
    # Put the button in the third column, which aligns it to the right
    with col3:
        if st.button("🔄 Refresh"):
            # Force refresh by clearing caches using the central function
            from utils.app_utils import refresh_data
            refresh_data(reset_page=True, show_message=True)
            st.rerun()
    
    # Advanced filtering (expandable)
    with st.expander("Advanced Filtering"):
        col1, col2 = st.columns(2)
        
        with col1:
            # Numeric Range filters
            st.markdown(field_label("Country Number Range"), unsafe_allow_html=True)
            country_num_min, country_num_max = st.slider(
                "Country Number", 
                min_value=0, 
                max_value=999, 
                value=(0, 999)
            )
            
            st.markdown(field_label("Currency Number Range"), unsafe_allow_html=True)
            currency_num_min, currency_num_max = st.slider(
                "Currency Number", 
                min_value=0, 
                max_value=999, 
                value=(0, 999)
            )
        
        with col2:
            # Categorical filters
            try:
                operations = DataOperations(st.session_state.databricks_client)
                
                # Get unique regions for filtering (if available in dataset)
                regions = operations.get_unique_values("region") if hasattr(operations, "get_unique_values") else []
                if regions:
                    st.markdown(field_label("Filter by Region"), unsafe_allow_html=True)
                    selected_regions = st.multiselect("", regions)
                
                # Get unique continents for filtering (if available in dataset)
                continents = operations.get_unique_values("continent") if hasattr(operations, "get_unique_values") else []
                if continents:
                    st.markdown(field_label("Filter by Continent"), unsafe_allow_html=True)
                    selected_continents = st.multiselect("", continents)
            except Exception as e:
                st.warning(f"Could not load categorical filters: {str(e)}")
    
    # Sorting controls
    col1, col2 = st.columns(2)
    
    with col1:
        sort_options = [
            "country", 
            "country_code", 
            "country_number", 
            "currency_name", 
            "currency_code", 
            "currency_number"
        ]
        
        st.markdown(field_label("Sort by"), unsafe_allow_html=True)
        sort_by = st.selectbox(
            "",
            options=sort_options,
            index=sort_options.index(st.session_state.get("sort_by", "country_code"))
        )
        
        if "sort_by" not in st.session_state or sort_by != st.session_state.sort_by:
            st.session_state.sort_by = sort_by
    
    with col2:
        st.markdown(field_label("Sort direction"), unsafe_allow_html=True)
        sort_ascending = st.radio(
            "",
            options=["Ascending", "Descending"],
            index=0 if st.session_state.get("sort_ascending", True) else 1,
            horizontal=True
        )
        
        sort_ascending = (sort_ascending == "Ascending")
        if "sort_ascending" not in st.session_state or sort_ascending != st.session_state.sort_ascending:
            st.session_state.sort_ascending = sort_ascending
    
    st.markdown(card_end(), unsafe_allow_html=True)
    
    # Construct the advanced filter query if needed
    advanced_filter = ""
    if "country_num_min" in locals() and "country_num_max" in locals():
        if country_num_min > 0 or country_num_max < 999:
            advanced_filter += f" AND country_number BETWEEN {country_num_min} AND {country_num_max}"
    
    if "currency_num_min" in locals() and "currency_num_max" in locals():
        if currency_num_min > 0 or currency_num_max < 999:
            advanced_filter += f" AND currency_number BETWEEN {currency_num_min} AND {currency_num_max}"
    
    if "selected_regions" in locals() and selected_regions:
        regions_str = ", ".join([f"'{region}'" for region in selected_regions])
        advanced_filter += f" AND region IN ({regions_str})"
    
    if "selected_continents" in locals() and selected_continents:
        continents_str = ", ".join([f"'{continent}'" for continent in selected_continents])
        advanced_filter += f" AND continent IN ({continents_str})"
    
    # Combine basic filter and advanced filter
    combined_filter = filter_query
    if advanced_filter and filter_query:
        combined_filter = f"({filter_query}){advanced_filter}"
    elif advanced_filter:
        combined_filter = advanced_filter.strip(" AND ")
    
    return combined_filter, sort_by, sort_ascending
