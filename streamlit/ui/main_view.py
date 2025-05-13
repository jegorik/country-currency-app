"""
Main view component for the Streamlit application.
"""
import streamlit as st
import pandas as pd
from operations.data_operations import DataOperations

def render_main_view():
    """Render the main view of the application."""
    if not st.session_state.authenticated:
        return
    
    if st.session_state.current_view != "home":
        return
    
    # Display the data table if data is loaded
    if st.session_state.data_loaded:
        # Create a container for the data table
        with st.container():
            st.header("Country-Currency Mappings")
            
            # Add search/filter functionality
            col1, col2 = st.columns([3, 1])
            with col1:
                filter_value = st.text_input(
                    "Filter by Country or Currency",
                    value=st.session_state.filter_query,
                    placeholder="Type to filter..."
                )
                
                if filter_value != st.session_state.filter_query:
                    st.session_state.filter_query = filter_value
                    st.session_state.last_refresh = None  # Force refresh
            
            with col2:
                if st.button("Refresh Data"):
                    st.session_state.last_refresh = None  # Force refresh
            
            # Get data and display it
            try:
                operations = DataOperations(st.session_state.databricks_client)
                
                # Display a loading spinner while fetching data
                with st.spinner("Loading data..."):
                    data = operations.get_all_records(filter_query=st.session_state.filter_query)
                
                if not data:
                    st.info("No data found. Try a different filter or add new entries.")
                    return
                
                # Convert to pandas DataFrame for easier display
                df = pd.DataFrame(data)
                
                # Add action buttons
                df['Actions'] = None  # Placeholder column for actions
                
                # Display the DataFrame
                with st.container():
                    st.dataframe(
                        df.drop(columns=['Actions']),  # Don't show the actions column in the dataframe
                        use_container_width=True,
                        column_config={
                            "country_code": st.column_config.TextColumn("Country Code", width="small"),
                            "country_number": st.column_config.NumberColumn("Country Number", width="small"),
                            "country": st.column_config.TextColumn("Country", width="medium"),
                            "currency_name": st.column_config.TextColumn("Currency Name", width="medium"),
                            "currency_code": st.column_config.TextColumn("Currency Code", width="small"),
                            "currency_number": st.column_config.NumberColumn("Currency Number", width="small"),
                        }
                    )
                    
                # Display totals
                col1, col2 = st.columns(2)
                with col1:
                    st.info(f"Total records: {len(data)}")
                
                # Row selection for edit/delete
                st.subheader("Actions")
                cols = st.columns(3)
                
                with cols[0]:
                    if st.button("Add New Entry", key="add_btn"):
                        st.session_state.current_view = "add"
                        st.rerun()
                
                country_codes = [record['country_code'] for record in data]
                selected_code = st.selectbox("Select a country to edit or delete:", country_codes)
                
                col1, col2 = st.columns(2)
                with col1:
                    if st.button("Edit Selected", key="edit_btn"):
                        for record in data:
                            if record['country_code'] == selected_code:
                                st.session_state.edit_item = record
                                st.session_state.current_view = "edit"
                                st.rerun()
                
                with col2:
                    if st.button("Delete Selected", key="delete_btn"):
                        for record in data:
                            if record['country_code'] == selected_code:
                                st.session_state.edit_item = record
                                st.session_state.current_view = "delete"
                                st.rerun()
            
            except Exception as e:
                st.error(f"Error loading data: {str(e)}")
    
    else:
        # Display a message if data is not yet loaded
        st.warning("Data is not yet available. The Databricks job to load data may still be running.")
        
        # Show job status if available
        if st.session_state.job_status:
            st.info(f"Job Status: {st.session_state.job_status}")
            if st.button("Check Again"):
                st.rerun()
