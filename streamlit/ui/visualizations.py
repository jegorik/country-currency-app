"""
Visualization component for the Streamlit application.
This module handles data visualization and analytics.
"""
import streamlit as st
import pandas as pd
import altair as alt
import plotly.express as px
import plotly.graph_objects as go
from operations.data_operations import DataOperations
from templates.html_components import (
    section_header, 
    card_start, 
    card_end, 
    field_label,
    info_box,
    analytics_card
)

def render_visualizations():
    """Render data visualizations and analytics."""
    if not st.session_state.get("authenticated", False):
        return
    
    st.markdown(section_header("📈", "Data Analytics & Visualizations"), unsafe_allow_html=True)
    
    try:
        operations = DataOperations(st.session_state.databricks_client)
        
        # Get full dataset for analytics
        query = f"SELECT * FROM {operations.table_name}"
        data = operations.client.execute_query(query)
        
        if not data:
            st.markdown(info_box("No data available for visualization."), unsafe_allow_html=True)
            return
        
        # Convert to pandas DataFrame
        df = pd.DataFrame(data)
        
        # Analytics Cards
        col1, col2, col3 = st.columns(3)
        
        with col1:
            st.markdown(card_start(), unsafe_allow_html=True)
            unique_countries = len(df['country_code'].unique())
            st.markdown(analytics_card("Unique Countries", unique_countries), unsafe_allow_html=True)
            st.markdown(card_end(), unsafe_allow_html=True)
        
        with col2:
            st.markdown(card_start(), unsafe_allow_html=True)
            unique_currencies = len(df['currency_code'].unique())
            st.markdown(analytics_card("Unique Currencies", unique_currencies), unsafe_allow_html=True)
            st.markdown(card_end(), unsafe_allow_html=True)
        
        with col3:
            st.markdown(card_start(), unsafe_allow_html=True)
            countries_per_currency = df.groupby('currency_code').size().mean()
            st.markdown(analytics_card("Avg Countries per Currency", f"{countries_per_currency:.2f}"), unsafe_allow_html=True)
            st.markdown(card_end(), unsafe_allow_html=True)
        
        # Visualization Controls
        st.markdown(card_start(), unsafe_allow_html=True)
        
        viz_type = st.selectbox(
            "Visualization Type",
            options=["Currency Distribution", "Country Number Distribution", "Currency Number Distribution", "Country-Currency Map"]
        )
        
        chart_type = st.radio(
            "Chart Type",
            options=["Bar Chart", "Pie Chart", "Histogram", "Box Plot"],
            horizontal=True
        )
        
        # Custom chart options based on visualization type
        if viz_type == "Currency Distribution":
            currency_counts = df['currency_code'].value_counts().reset_index()
            currency_counts.columns = ['Currency', 'Count']
            
            if chart_type == "Bar Chart":
                fig = px.bar(
                    currency_counts, 
                    x='Currency', 
                    y='Count',
                    title='Number of Countries per Currency',
                    color='Count',
                    color_continuous_scale='Viridis'
                )
                st.plotly_chart(fig, use_container_width=True)
            
            elif chart_type == "Pie Chart":
                fig = px.pie(
                    currency_counts, 
                    values='Count', 
                    names='Currency',
                    title='Currency Distribution'
                )
                st.plotly_chart(fig, use_container_width=True)
                
        elif viz_type == "Country Number Distribution":
            if chart_type == "Histogram":
                fig = px.histogram(
                    df, 
                    x='country_number',
                    nbins=20,
                    title='Distribution of Country Numbers'
                )
                st.plotly_chart(fig, use_container_width=True)
            
            elif chart_type == "Box Plot":
                fig = px.box(
                    df, 
                    y='country_number',
                    title='Country Number Statistics'
                )
                st.plotly_chart(fig, use_container_width=True)
                
        elif viz_type == "Currency Number Distribution":
            if chart_type == "Histogram":
                fig = px.histogram(
                    df, 
                    x='currency_number',
                    nbins=20,
                    title='Distribution of Currency Numbers'
                )
                st.plotly_chart(fig, use_container_width=True)
            
            elif chart_type == "Box Plot":
                fig = px.box(
                    df, 
                    y='currency_number',
                    title='Currency Number Statistics'
                )
                st.plotly_chart(fig, use_container_width=True)
                
        elif viz_type == "Country-Currency Map":
            # Create a scatter plot of country number vs currency number
            fig = px.scatter(
                df, 
                x='country_number', 
                y='currency_number',
                hover_name='country',
                hover_data=['currency_name'],
                color='currency_code',
                title='Country vs Currency Numbers'
            )
            st.plotly_chart(fig, use_container_width=True)
        
        st.markdown(card_end(), unsafe_allow_html=True)
        
        # Statistical Analysis Section
        st.subheader("Statistical Analysis")
        
        # Choose columns for analysis
        numeric_cols = [col for col in df.columns if df[col].dtype in ['int64', 'float64']]
        
        if numeric_cols:
            selected_col = st.selectbox("Select column for analysis", numeric_cols)
            
            st.markdown(card_start(), unsafe_allow_html=True)
            
            # Basic stats
            stats = df[selected_col].describe()
            
            col1, col2, col3 = st.columns(3)
            
            with col1:
                st.metric("Mean", f"{stats['mean']:.2f}")
                st.metric("Min", f"{stats['min']:.2f}")
            
            with col2:
                st.metric("Median", f"{stats['50%']:.2f}")
                st.metric("Max", f"{stats['max']:.2f}")
                
            with col3:
                st.metric("Std Dev", f"{stats['std']:.2f}")
                st.metric("Count", int(stats['count']))
            
            st.markdown(card_end(), unsafe_allow_html=True)
            
            # Histogram with normal distribution curve
            fig = go.Figure()
            
            fig.add_trace(go.Histogram(
                x=df[selected_col],
                histnorm='probability density',
                name='Histogram',
                marker_color='#4da6ff',
                opacity=0.7
            ))
            
            fig.update_layout(
                title=f"Distribution of {selected_col}",
                xaxis_title=selected_col,
                yaxis_title="Frequency",
                template="plotly_dark"
            )
            
            st.plotly_chart(fig, use_container_width=True)
            
        else:
            st.info("No numeric columns available for statistical analysis.")
        
    except Exception as e:
        st.error(f"Error generating visualizations: {str(e)}")
        st.exception(e)
