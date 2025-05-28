"""
Utility functions for the Streamlit application.
"""
import os
import streamlit as st

def load_css(css_file_path):
    """Load CSS from a file and inject it into the Streamlit app"""
    if os.path.exists(css_file_path):
        with open(css_file_path, 'r') as f:
            st.markdown(f'<style>{f.read()}</style>', unsafe_allow_html=True)
    else:
        st.error(f"CSS file not found: {css_file_path}")
