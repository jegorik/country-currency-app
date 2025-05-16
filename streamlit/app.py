"""
Main Streamlit application for the Country Currency App.
This is a modern dark-themed interface for managing country-currency mappings.
"""
import streamlit as st
import os
import sys
import time
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

# Debug mode - set to False to disable debug messages
DEBUG_MODE = False

def debug_print(*args, **kwargs):
    """Print only when in debug mode or log at debug level."""
    if DEBUG_MODE:
        print(*args, **kwargs)
    logger.debug(" ".join(str(a) for a in args))

# Removed duplicate refresh_data function - using the one from utils.app_utils instead

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
from templates.html_components import app_header, footer
from utils.app_utils import refresh_data

# Set page configuration
st.set_page_config(
    page_title="Country-Currency App",
    page_icon="🌎",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Load custom CSS
css_path = os.path.join(os.path.dirname(__file__), "ui", "styles", "style.css")
with open(css_path, 'r') as f:
    st.markdown(f'<style>{f.read()}</style>', unsafe_allow_html=True)

# Initialize session state
if "authenticated" not in st.session_state:
    st.session_state.authenticated = False

if "current_view" not in st.session_state:
    st.session_state.current_view = "home"

if "filter_query" not in st.session_state:
    st.session_state.filter_query = ""

# Render the application components
render_sidebar()

# Render the main content based on the current view
if st.session_state.current_view == "home":
    render_main_view()
elif st.session_state.current_view in ["add", "edit", "delete"]:
    render_crud_views()
elif st.session_state.current_view == "batch_upload":
    try:
        from ui.batch_upload import render_batch_upload_view
        render_batch_upload_view()
    except Exception as e:
        st.error(f"Error loading batch upload view: {str(e)}")
        logger.error(f"Error loading batch upload view: {str(e)}", exc_info=True)
        if st.button("Back to Home"):
            st.session_state.current_view = "home"
            st.rerun()
elif st.session_state.current_view == "analytics":
    try:
        from ui.visualizations import render_visualizations
        render_visualizations()
    except Exception as e:
        st.error(f"Error loading analytics view: {str(e)}")
else:
    # Default to home view if the current view is invalid
    st.session_state.current_view = "home"
    render_main_view()

# Display version info in footer
st.markdown("""
<div style="text-align: center; margin-top: 50px; color: #666;">
Country Currency App v1.0.0 | Powered by Streamlit & Databricks
</div>
""", unsafe_allow_html=True)
