"""
Sidebar component for the Streamlit application.
"""
import streamlit as st

def render_sidebar():
    """Render the application sidebar."""
    with st.sidebar:
        st.title("Navigation")
        
        if st.session_state.authenticated:
            # Display navigation options
            if st.button("Home", use_container_width=True):
                st.session_state.current_view = "home"
                st.rerun()
                
            if st.button("Add New Entry", use_container_width=True):
                st.session_state.current_view = "add"
                st.rerun()
            
            # Display connection info
            st.divider()
            st.subheader("Connection Info")
            st.write(f"**Host:** {st.session_state.config.host}")
            st.write(f"**Catalog:** {st.session_state.config.catalog}")
            st.write(f"**Schema:** {st.session_state.config.schema}")
            st.write(f"**Table:** {st.session_state.config.table}")
            
            # Add a disconnect button
            if st.button("Disconnect", use_container_width=True):
                st.session_state.authenticated = False
                st.session_state.databricks_client = None
                st.session_state.current_view = "home"
                st.rerun()
        
        # Display app information
        st.divider()
        st.caption("Country Currency App")
        st.caption("Version 1.0.0")
