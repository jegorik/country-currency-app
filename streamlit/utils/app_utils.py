"""
Utility functions for the Streamlit application.

This module contains common utilities that are used across the application,
including functions for data management, UI helpers, and state management.
"""

import streamlit as st
import logging

logger = logging.getLogger(__name__)

def refresh_data(reset_page=True, show_message=False):
    """
    Refresh data by clearing any cached state.
    Call this function after any data modification operation.
    
    Args:
        reset_page (bool): Whether to reset pagination to page 1
        show_message (bool): Whether to display a success message
    """
    # Clear any cached data
    if "last_refresh" in st.session_state:
        st.session_state.pop("last_refresh", None)
    
    # Reset to first page of results if requested
    if reset_page and "current_page" in st.session_state:
        st.session_state.current_page = 1
    
    # Optionally show a success message
    if show_message:
        st.success("Data refreshed successfully.")
    
    # Log the refresh action
    logger.info("Data refresh triggered")
    
    # Note: We keep data_loaded=True since we're just refreshing, not disconnecting
