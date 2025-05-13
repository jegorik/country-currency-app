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
    
    # Try to load configuration from terraform.tfvars
    # Use absolute paths to ensure we find the files correctly
    base_dir = Path(__file__).resolve().parent.parent
    tfvars_path = base_dir / "terraform" / "terraform.tfvars"
    job_id_path = base_dir / "terraform" / "job_id.txt"
      # Debug: Print paths to check if they're correct
    print(f"Base directory: {base_dir}")
    print(f"terraform.tfvars path: {tfvars_path}")
    print(f"job_id.txt path: {job_id_path}")
    print(f"terraform.tfvars exists: {tfvars_path.exists()}")
    
    host_value = ""
    token_value = ""
    catalog_value = "country-currency-app"  # Default value
    schema_value = "country_currency"       # Default value
    table_value = "country_to_currency"     # Default value
    job_id_value = ""
    warehouse_id_value = ""
      # Check if the terraform.tfvars file exists and is readable
    if tfvars_path.exists():
        print(f"terraform.tfvars exists: {tfvars_path}")
        try:
            # Try a completely different approach - direct file loading
            try:
                # Try with absolute path
                abs_path = os.path.abspath(tfvars_path)
                print(f"Trying absolute path: {abs_path}")
                
                # Try to load with direct open
                with open(abs_path, 'r') as f:
                    tfvars_content = f.read()
                    print(f"Successfully read {len(tfvars_content)} characters from terraform.tfvars with absolute path")
            except Exception as e:
                print(f"Failed with absolute path: {e}")
                # Try with relative path from current working directory
                relative_path = "../terraform/terraform.tfvars"
                print(f"Trying relative path: {relative_path}")
                with open(relative_path, 'r') as f:
                    tfvars_content = f.read()
                    print(f"Successfully read {len(tfvars_content)} characters from terraform.tfvars with relative path")
            
            # Print part of the content for debugging (without sensitive content)
            print(f"Read {len(tfvars_content)} characters from terraform.tfvars")
            lines = tfvars_content.splitlines()
            print(f"Sample lines (filtered):")
            for line in lines[:3]:
                if not "token" in line.lower():
                    print(f"  {line}")
              # Very simple direct extraction of key values using regex patterns
            import re
            
            # Extract values directly with regex patterns
            host_match = re.search(r'databricks_host\s*=\s*"([^"]+)"', tfvars_content)
            token_match = re.search(r'databricks_token\s*=\s*"([^"]+)"', tfvars_content)
            catalog_match = re.search(r'catalog_name\s*=\s*"([^"]+)"', tfvars_content)
            schema_match = re.search(r'schema_name\s*=\s*"([^"]+)"', tfvars_content)
            table_match = re.search(r'table_name\s*=\s*"([^"]+)"', tfvars_content)
            warehouse_match = re.search(r'databricks_warehouse_id\s*=\s*"([^"]+)"', tfvars_content)
            
            # Direct line by line parsing for terraform.tfvars
            tfvars_dict = {}
            for line in tfvars_content.splitlines():
                line = line.strip()
                if not line or line.startswith('//') or line.startswith('#'):
                    continue
                if '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    # Remove quotes if present
                    if value.startswith('"') and value.endswith('"'):
                        value = value[1:-1]
                    tfvars_dict[key] = value
            
            # Debug the keys that are available
            print("Keys in tfvars_dict:", list(tfvars_dict.keys()))
              # Set values from regex matches (most reliable)
            if host_match:
                host_value = host_match.group(1)
            if token_match:
                token_value = token_match.group(1)
            if catalog_match:
                catalog_value = catalog_match.group(1)
            if schema_match:
                schema_value = schema_match.group(1)
            if table_match:
                table_value = table_match.group(1)
            if warehouse_match:
                warehouse_id_value = warehouse_match.group(1)
              # Fallback to dictionary parsing if regex didn't work
            if not host_value and 'databricks_host' in tfvars_dict:
                host_value = tfvars_dict['databricks_host']
            if not token_value and 'databricks_token' in tfvars_dict:
                token_value = tfvars_dict['databricks_token']
            if not catalog_value and 'catalog_name' in tfvars_dict:
                catalog_value = tfvars_dict['catalog_name']
            if not schema_value and 'schema_name' in tfvars_dict:
                schema_value = tfvars_dict['schema_name']
            if not table_value and 'table_name' in tfvars_dict:
                table_value = tfvars_dict['table_name']
            if not warehouse_id_value and 'databricks_warehouse_id' in tfvars_dict:
                warehouse_id_value = tfvars_dict['databricks_warehouse_id']
              # Debug: Print what was found 
            print(f"Found host match: {bool(host_value)}")
            print(f"Found token match: {bool(token_value)}")
            print(f"Found catalog match: {bool(catalog_value)}")
            print(f"Found schema match: {bool(schema_value)}")
            print(f"Found table match: {bool(table_value)}")
            print(f"Found warehouse match: {bool(warehouse_id_value)}")
            
            # Debug: Print the values (omit token for security)
            print(f"Host value: {host_value}")
            print(f"Catalog value: {catalog_value}")
            print(f"Schema value: {schema_value}")
            print(f"Table value: {table_value}")
            print(f"Warehouse ID: {warehouse_id_value}")
        except Exception as e:
            st.warning(f"Could not load configuration: {str(e)}")
            print(f"Error loading config: {str(e)}")
    
    # Try to load job ID from job_id.txt
    if job_id_path.exists():
        try:
            with open(job_id_path, 'r') as f:
                job_id_value = f.read().strip()
        except Exception:
            pass
      # If not authenticated, show the login form
    if not st.session_state.authenticated:
        with st.container():
            st.header("Connect to Databricks")
            with st.form("login_form"):
                host = st.text_input("Databricks Host", placeholder="https://your-databricks-instance.cloud.databricks.com", value=host_value)
                token = st.text_input("Databricks Token", type="password", value=token_value)
                catalog = st.text_input("Catalog Name", placeholder="country-currency-app", value=catalog_value)
                schema = st.text_input("Schema Name", placeholder="country_currency", value=schema_value)                
                table = st.text_input("Table Name", placeholder="country_to_currency", value=table_value)
                job_id = st.text_input("Job ID (optional)", placeholder="12345678", value=job_id_value)
                submitted = st.form_submit_button("Connect")
                if submitted:
                    try:
                        st.info("Connecting to Databricks... This may take a few moments.")
                        progress_placeholder = st.empty()
                        progress_placeholder.progress(0)
                        
                        # Create config
                        progress_placeholder.progress(10)
                        config = AppConfig(
                            host=host, 
                            token=token, 
                            catalog=catalog, 
                            schema=schema, 
                            table=table, 
                            job_id=job_id,
                            warehouse_id=warehouse_id_value
                        )
                        progress_placeholder.progress(20)
                        
                        # Create client
                        client = DatabricksClient(config)
                        progress_placeholder.progress(40)
                          # Test connection with a timeout approach that works on Windows
                        import threading
                        import time
                        
                        class TimeoutException(Exception):
                            pass
                        
                        def test_connection_with_timeout(client, timeout=15):
                            """Test connection with timeout that works on Windows"""
                            result = {"success": False, "error": None}
                            
                            def _test_connection():
                                try:
                                    result["success"] = client.test_connection()
                                except Exception as e:
                                    result["error"] = e
                            
                            # Create and start the thread
                            thread = threading.Thread(target=_test_connection)
                            thread.daemon = True
                            thread.start()
                            
                            # Wait for the thread to finish or timeout
                            thread.join(timeout)
                            
                            if thread.is_alive():
                                # Thread is still running after timeout
                                raise TimeoutException("Connection test timed out")
                            
                            # Thread completed, check result
                            if result["error"]:
                                raise result["error"]
                            
                            return result["success"]
                        
                        try:
                            # Test connection
                            progress_placeholder.progress(60)
                            connection_successful = test_connection_with_timeout(client, timeout=15)
                            progress_placeholder.progress(90)
                            
                            if connection_successful:
                                st.session_state.authenticated = True
                                st.session_state.databricks_client = client
                                st.session_state.config = config
                                progress_placeholder.progress(100)
                                st.success("Connected to Databricks successfully!")
                                time.sleep(1)
                                st.rerun()
                            else:
                                st.error("Failed to connect to Databricks. Please check your credentials and network connectivity.")
                                st.info("Make sure your Databricks token has the correct permissions and that you can access the workspace.")
                        except TimeoutException:
                            st.error("Connection timed out. The Databricks server is taking too long to respond.")
                            st.info("This could be due to network issues or incorrect host/credentials.")
                        except Exception as e:
                            st.error(f"Error connecting to Databricks: {type(e).__name__}: {str(e)}")
                            st.info("Check the terminal for more detailed error information.")
                    except Exception as e:
                        st.error(f"Error connecting to Databricks: {type(e).__name__}: {str(e)}")
                        st.info("Check the terminal for more detailed error information.")
        
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
