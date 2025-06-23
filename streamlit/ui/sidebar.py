"""
Sidebar component for the Streamlit application.
This module handles the sidebar navigation and Databricks connection.
"""
import streamlit as st
import pandas as pd
import time
import os
import re
import json
from config.app_config import AppConfig
from utils.databricks_client import DatabricksClient
from utils.status_checker import check_databricks_job_status
from templates.html_components import section_header, card_start, card_end, success_message, error_message
from pathlib import Path

def load_terraform_vars():
    """Load Databricks configuration from terraform.tfvars file"""
    config_values = {
        'databricks_host': '',
        'databricks_token': '',
        'catalog_name': 'main',
        'schema_name': 'default',
        'table_name': 'country_currency',
        'databricks_warehouse_id': ''
    }

    try:
        # Get the path to terraform.tfvars
        base_dir = Path(__file__).parent.parent.parent
        tfvars_path = base_dir / 'terraform' / 'terraform.tfvars'

        if tfvars_path.exists():
            with open(tfvars_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('//'):
                        # Parse key-value pairs
                        match = re.match(r'(\w+)\s*=\s*"([^"]*)"', line)
                        if match:
                            key, value = match.groups()
                            if key in config_values:
                                config_values[key] = value
        return config_values
    except Exception as e:
        print(f"Error loading terraform.tfvars: {str(e)}")
        return config_values

def load_connection_config_from_json():
    """Load Databricks connection configuration from the deployment JSON file"""
    config_values = {
        'databricks_host': '',
        'databricks_token': '',
        'catalog_name': 'main',
        'schema_name': 'default',
        'table_name': 'country_currency',
        'databricks_warehouse_id': ''
    }

    try:
        # Get the path to the databricks_connection.json file
        base_dir = Path(__file__).parent.parent
        json_path = base_dir / 'databricks_connection.json'

        if json_path.exists():
            with open(json_path, 'r') as f:
                data = json.load(f)
                config_values.update({
                    'databricks_host': data.get('databricks_host', ''),
                    'databricks_token': data.get('databricks_token', ''),
                    'catalog_name': data.get('catalog_name', 'main'),
                    'schema_name': data.get('schema_name', 'default'),
                    'table_name': data.get('table_name', 'country_currency'),
                    'databricks_warehouse_id': data.get('databricks_warehouse_id', '')
                })
            return config_values, json_path.exists()
        return config_values, False
    except Exception as e:
        print(f"Error loading databricks_connection.json: {str(e)}")
        return config_values, False

def render_sidebar():
    """Render the sidebar component."""
    # Load config values from terraform.tfvars
    config_values = load_terraform_vars()

    with st.sidebar:
        st.image("https://databricks.com/wp-content/uploads/2021/10/DB-logo-clear-background-1.svg", width=200)
        st.title("Country Currency App")

        # Connection Status
        if "databricks_client" in st.session_state and st.session_state.databricks_client:
            st.sidebar.success("✅ Connected to Databricks")
            # Show connection info
            with st.sidebar.expander("Connection Info"):
                st.write(f"**Host:** {st.session_state.databricks_client.config.host}")
                st.write(f"**Catalog:** {st.session_state.databricks_client.config.catalog}")
                st.write(f"**Schema:** {st.session_state.databricks_client.config.schema}")
                st.write(f"**Table:** {st.session_state.databricks_client.config.table}")
        else:
            st.sidebar.warning("⚠️ Not connected to Databricks")

        # Connect to Databricks Section
        st.sidebar.subheader("Databricks Connection")

        if not st.session_state.authenticated:
            # Check if deployment config file exists
            deployment_config, config_file_exists = load_connection_config_from_json()
            
            # Show option to load from deployment file if it exists
            if config_file_exists:
                st.sidebar.info("🎯 Deployment configuration file found!")
                
                col1, col2 = st.sidebar.columns(2)
                with col1:
                    if st.button("📁 Load from File", help="Load connection details from deployment", use_container_width=True):
                        st.session_state.load_from_file = True
                        st.rerun()
                
                with col2:
                    if st.button("✏️ Manual Entry", help="Enter connection details manually", use_container_width=True):
                        st.session_state.load_from_file = False
                        st.rerun()
                        
                st.sidebar.divider()
            
            # Determine which config to use
            if config_file_exists and st.session_state.get("load_from_file", True):
                # Use deployment config
                active_config = deployment_config
                config_source = "deployment file"
                st.sidebar.success("📁 Using configuration from deployment file")
                if not deployment_config.get('databricks_token'):
                    st.sidebar.warning("🔑 Please provide your Databricks token below")
            else:
                # Use terraform.tfvars config
                active_config = config_values
                config_source = "manual entry"
                if not config_file_exists:
                    st.sidebar.info("💡 Enter your Databricks connection details below")

            # Create connection form
            with st.sidebar.form("databricks_connection_form"):
                # Get default values from active config or environment variables
                default_host = active_config.get('databricks_host') or os.environ.get("DATABRICKS_HOST", "")
                default_token = active_config.get('databricks_token') or os.environ.get("DATABRICKS_TOKEN", "")
                default_catalog = active_config.get('catalog_name') or os.environ.get("DATABRICKS_CATALOG", "main")
                default_schema = active_config.get('schema_name') or os.environ.get("DATABRICKS_SCHEMA", "default")
                default_table = active_config.get('table_name') or os.environ.get("DATABRICKS_TABLE", "country_currency")
                default_warehouse_id = active_config.get('databricks_warehouse_id') or os.environ.get("DATABRICKS_WAREHOUSE_ID", "")

                # Connection form fields
                if config_file_exists and st.session_state.get("load_from_file", True):
                    st.caption("🔒 Most fields are pre-filled from deployment. Please provide your token.")
                
                host = st.text_input("Databricks Host", value=default_host, 
                                    placeholder="e.g. https://your-workspace.cloud.databricks.com")
                token = st.text_input("Databricks Token", value=default_token, 
                                    placeholder="Enter your access token", type="password",
                                    help="Required for authentication. Not stored in deployment file for security.")
                catalog = st.text_input("Catalog Name", value=default_catalog, 
                                        placeholder="e.g. main")
                schema = st.text_input("Schema Name", value=default_schema, 
                                        placeholder="e.g. default")
                table = st.text_input("Table Name", value=default_table, 
                                    placeholder="e.g. country_currency")
                warehouse_id = st.text_input("Warehouse ID", value=default_warehouse_id,
                                          placeholder="SQL Warehouse ID (optional)")

                connect_submitted = st.form_submit_button("Connect")

            if connect_submitted:
                if not host or not token or not catalog or not schema or not table:
                    st.sidebar.error("Please fill in all required fields")
                else:
                    # Show spinner while connecting
                    status_placeholder = st.sidebar.empty()
                    if config_file_exists and st.session_state.get("load_from_file", True):
                        status_placeholder.info("Connecting to Databricks using deployment configuration...")
                    else:
                        status_placeholder.info("Connecting to Databricks...")

                    try:
                        # Create configuration
                        config = AppConfig(
                            host=host,
                            token=token,
                            catalog=catalog,
                            schema=schema,
                            table=table,
                            warehouse_id=warehouse_id if warehouse_id else None
                        )

                        # Save config to session state
                        st.session_state.config = config

                        # Create and test client
                        client = DatabricksClient(config)
                        connection_ok = client.test_connection()

                        if connection_ok:
                            st.session_state.databricks_client = client
                            st.session_state.authenticated = True
                            st.session_state.data_loaded = True
                            # Track if configuration was loaded from deployment file
                            st.session_state.loaded_from_file = config_file_exists and st.session_state.get("load_from_file", True)
                            if config_file_exists and st.session_state.get("load_from_file", True):
                                status_placeholder.success("✅ Connected using deployment configuration!")
                            else:
                                status_placeholder.success("✅ Connected to Databricks!")
                            st.rerun()
                        else:
                            status_placeholder.error("Connection test failed")
                    except Exception as e:
                        status_placeholder.error(f"Connection error: {str(e)}")

        elif st.session_state.authenticated:
            # Display navigation options in card
            st.markdown(card_start(), unsafe_allow_html=True)

            col1, col2 = st.columns(2)
            with col1:
                if st.button("🏠 Home", use_container_width=True):
                    st.session_state.current_view = "home"
                    st.rerun()

            with col2:
                if st.button("➕ Add New", use_container_width=True):
                    st.session_state.current_view = "add"
                    st.rerun()

            st.markdown(card_end(), unsafe_allow_html=True)

            # Display connection info in card
            st.markdown(section_header("🔌", "Connection Info"), unsafe_allow_html=True)
            st.markdown(card_start(), unsafe_allow_html=True)

            st.markdown(f"""
            <div style="font-size: 0.9rem;">
                <div style="display: flex; margin-bottom: 8px;">
                    <div style="width: 80px; color: #4da6ff;">Host:</div>
                    <div>{st.session_state.config.host}</div>
                </div>
                <div style="display: flex; margin-bottom: 8px;">
                    <div style="width: 80px; color: #4da6ff;">Catalog:</div>
                    <div>{st.session_state.config.catalog}</div>
                </div>
                <div style="display: flex; margin-bottom: 8px;">
                    <div style="width: 80px; color: #4da6ff;">Schema:</div>
                    <div>{st.session_state.config.schema}</div>
                </div>
                <div style="display: flex; margin-bottom: 8px;">
                    <div style="width: 80px; color: #4da6ff;">Table:</div>
                    <div>{st.session_state.config.table}</div>
                </div>
                <div style="display: flex; margin-bottom: 8px;">
                    <div style="width: 80px; color: #4da6ff;">Warehouse:</div>
                    <div>{st.session_state.config.warehouse_id if st.session_state.config.warehouse_id else "Auto"}</div>
                </div>
                <div style="display: flex; margin-bottom: 8px;">
                    <div style="width: 80px; color: #4da6ff;">Source:</div>
                    <div>{"Deployment File" if st.session_state.get("loaded_from_file", False) else "Manual Entry"}</div>
                </div>
            </div>
            """, unsafe_allow_html=True)

            st.markdown(card_end(), unsafe_allow_html=True)

            # Add a disconnect button
            if st.button("🔓 Disconnect", use_container_width=True):
                st.session_state.authenticated = False
                st.session_state.databricks_client = None
                st.session_state.current_view = "home"
                st.rerun()

        # Display app information
        st.divider()
        st.markdown("""
        <div style="text-align: center; margin-top: 20px;">
            <div style="color: #4da6ff; font-weight: bold;">Country Currency App</div>
            <div style="color: #7f8c8d; font-size: 0.8rem;">Version 1.0.0</div>
        </div>
        """, unsafe_allow_html=True)
