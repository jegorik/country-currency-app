# app.py - Main Streamlit Application
import streamlit as st
import os
import sys
import time
from pathlib import Path

# Add the project to the Python path
sys.path.insert(0, str(Path(__file__).parent))

# Import application modules
from utils.databricks_client import DatabricksClient
from operations.data_operations import DataOperations
from ui.sidebar import render_sidebar
from ui.main_view import render_main_view
from ui.crud_views import render_crud_views
from config.app_config import AppConfig
from utils.status_checker import check_databricks_job_status

# Set page configuration
st.set_page_config(
    page_title="Country-Currency App",
    page_icon="🌎",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Initialize session state for storing application state
if "authenticated" not in st.session_state:
    st.session_state.authenticated = False
    st.session_state.databricks_client = None
    st.session_state.current_view = "home"
    st.session_state.job_status = None
    st.session_state.last_refresh = None
    st.session_state.data_loaded = False
    st.session_state.filter_query = ""
    st.session_state.edit_mode = False
    st.session_state.edit_item = None

def main():
    """Main application entry point."""
    # Custom styling
    with open(Path(__file__).parent / "ui" / "style.css") as f:
        st.markdown(f"<style>{f.read()}</style>", unsafe_allow_html=True)

    # Render the application header
    st.title("Country-Currency Management")
    st.markdown("---")

    # Render sidebar with navigation and authentication
    render_sidebar()

    # If not authenticated, show the login form
    if not st.session_state.authenticated:
        with st.container():
            st.header("Connect to Databricks")
            with st.form("login_form"):
                host = st.text_input("Databricks Host", placeholder="https://your-databricks-instance.cloud.databricks.com")
                token = st.text_input("Databricks Token", type="password")
                catalog = st.text_input("Catalog Name", placeholder="country-currency-app", value="country-currency-app")
                schema = st.text_input("Schema Name", placeholder="country_currency", value="country_currency")
                table = st.text_input("Table Name", placeholder="country_to_currency", value="country_to_currency")
                job_id = st.text_input("Job ID (optional)", placeholder="12345678")
                
                submitted = st.form_submit_button("Connect")
                if submitted:
                    try:
                        with st.spinner("Connecting to Databricks..."):
                            # Create config and client
                            config = AppConfig(host=host, token=token, catalog=catalog, schema=schema, table=table, job_id=job_id)
                            client = DatabricksClient(config)
                            
                            # Test connection
                            if client.test_connection():
                                st.session_state.authenticated = True
                                st.session_state.databricks_client = client
                                st.session_state.config = config
                                st.success("Connected to Databricks successfully!")
                                time.sleep(1)
                                st.rerun()
                            else:
                                st.error("Failed to connect to Databricks. Please check your credentials.")
                    except Exception as e:
                        st.error(f"Error connecting to Databricks: {str(e)}")
        
        # Show project information
        with st.expander("About This Project", expanded=False):
            st.markdown("""
            ## Country-Currency App
            
            This application provides a user-friendly interface to manage country and currency mappings stored in Databricks.
            
            ### Features:
            
            - View country-currency mappings
            - Add new mappings
            - Edit existing mappings
            - Delete mappings
            - Search and filter capabilities
            
            ### Prerequisites:
            
            - Databricks workspace with access to the country-currency table
            - Personal access token with appropriate permissions
            """)
    else:
        # If authenticated, check if the data is ready
        if not st.session_state.data_loaded:
            with st.spinner("Checking if data is available..."):
                # Check if job_id is provided and check the job status
                if st.session_state.config.job_id:
                    job_status = check_databricks_job_status(
                        st.session_state.databricks_client,
                        st.session_state.config.job_id
                    )
                    st.session_state.job_status = job_status
                    
                    if job_status == "SUCCESS":
                        st.session_state.data_loaded = True
                    elif job_status == "RUNNING":
                        st.warning("Data loading job is still running. Please wait or proceed with caution.")
                        st.session_state.data_loaded = False
                    else:
                        # Check if the table exists and has data regardless of job status
                        try:
                            operations = DataOperations(st.session_state.databricks_client)
                            count = operations.count_records()
                            if count > 0:
                                st.session_state.data_loaded = True
                            else:
                                st.error("No data found in the table. Please verify that data has been loaded.")
                                st.session_state.data_loaded = False
                        except Exception as e:
                            st.error(f"Error checking table: {str(e)}")
                            st.session_state.data_loaded = False
                else:
                    # If no job_id, just check if the table has data
                    try:
                        operations = DataOperations(st.session_state.databricks_client)
                        count = operations.count_records()
                        if count > 0:
                            st.session_state.data_loaded = True
                        else:
                            st.warning("No data found in the table. Some features may be limited.")
                            st.session_state.data_loaded = True  # Still allow access to the app
                    except Exception as e:
                        st.error(f"Error checking table: {str(e)}")
                        st.session_state.data_loaded = False

        # Render the main content based on the current view
        render_main_view()
        render_crud_views()

if __name__ == "__main__":
    main()
