"""
Main view component for the Streamlit application.
This module serves as the main dashboard with tabs for data exploration and analytics.
"""
import streamlit as st
import pandas as pd
import time
import io
import plotly.express as px
from operations.data_operations import DataOperations
from templates.html_components import (
    section_header, 
    card_start, 
    card_end, 
    dataframe_container_start,
    dataframe_container_end,
    field_label,
    info_box,
    loader,
    app_header,
    footer
)

def render_main_view():
    """Render the main view of the application."""
    if not st.session_state.authenticated:
        return

    if st.session_state.current_view != "home":
        return

    # Display application header
    st.markdown(app_header(), unsafe_allow_html=True)

    # Create tabs for data view and analytics
    tab1, tab2 = st.tabs(["📊 Data Explorer", "📈 Analytics"])

    with tab1:
        render_data_explorer()

    with tab2:
        render_analytics()

    # Display footer
    st.markdown(footer(version="v1.0.0"), unsafe_allow_html=True)

def render_data_explorer():
    """Render the data explorer tab with filtering and pagination."""
    if st.session_state.data_loaded:
        # Initialize session state variables
        if "current_page" not in st.session_state:
            st.session_state.current_page = 1

        if "rows_per_page" not in st.session_state:
            st.session_state.rows_per_page = 10

        if "filter_query" not in st.session_state:
            st.session_state.filter_query = ""

        if "sort_by" not in st.session_state:
            st.session_state.sort_by = "country_code"

        if "sort_ascending" not in st.session_state:
            st.session_state.sort_ascending = True

        # Filter and Search Card
        st.markdown(section_header("🔍", "Search and Filter"), unsafe_allow_html=True)
        st.markdown(card_start(), unsafe_allow_html=True)

        col1, col2 = st.columns([3, 1])

        with col1:
            st.markdown(field_label("Search", "Filter by country, currency, or codes"), unsafe_allow_html=True)

            # Add search type selector
            if "search_type" not in st.session_state:
                st.session_state.search_type = "contains"

            search_type = st.radio(
                "Search type",
                ["Contains", "Starts with", "Exact match"],
                horizontal=True,
                index=["contains", "starts_with", "exact"].index(st.session_state.search_type)
            )

            # Map the display name to the internal value
            search_type_map = {
                "Contains": "contains",
                "Starts with": "starts_with",
                "Exact match": "exact"
            }

            if search_type_map[search_type] != st.session_state.search_type:
                st.session_state.search_type = search_type_map[search_type]
                st.session_state.current_page = 1  # Reset to first page

            filter_query = st.text_input(
                "",
                value=st.session_state.filter_query,
                placeholder="Type to search..."
            )

            if filter_query != st.session_state.filter_query:
                st.session_state.filter_query = filter_query
                st.session_state.current_page = 1  # Reset to first page

        with col2:
            # Create a container for the button with precise positioning
            container = st.container()
            # Add vertical space to push the button down (42px is approximately the height of the label + some margin)
            container.markdown('<div style="height: 42px;"></div>', unsafe_allow_html=True)
            # Now add the button in the container
            if container.button("🔄 Refresh"):
                # Use our centralized refresh function
                from utils.app_utils import refresh_data
                refresh_data(reset_page=True, show_message=True)
                st.rerun()

        # Advanced filtering
        with st.expander("Advanced Filters"):
            col1, col2 = st.columns(2)

            with col1:
                st.markdown(field_label("Sort by"), unsafe_allow_html=True)
                sort_options = ["country_code", "country", "country_number", "currency_code", "currency_name", "currency_number"]
                sort_by = st.selectbox("", sort_options, index=sort_options.index(st.session_state.sort_by))

                if sort_by != st.session_state.sort_by:
                    st.session_state.sort_by = sort_by

            with col2:
                st.markdown(field_label("Sort direction"), unsafe_allow_html=True)
                sort_direction = st.radio("", ["Ascending", "Descending"], horizontal=True, 
                                        index=0 if st.session_state.sort_ascending else 1)
                sort_ascending = (sort_direction == "Ascending")

                if sort_ascending != st.session_state.sort_ascending:
                    st.session_state.sort_ascending = sort_ascending

            # Numeric filters for country_number and currency_number
            st.markdown(field_label("Numeric Filters"), unsafe_allow_html=True)
            col1, col2 = st.columns(2)

            with col1:
                country_num_range = st.slider("Country Number Range", 0, 999, (0, 999))

            with col2:
                currency_num_range = st.slider("Currency Number Range", 0, 999, (0, 999))

        st.markdown(card_end(), unsafe_allow_html=True)

        # Data Table Card
        st.markdown(section_header("📋", "Country-Currency Data"), unsafe_allow_html=True)
        st.markdown(dataframe_container_start(), unsafe_allow_html=True)

        try:
            operations = DataOperations(st.session_state.databricks_client)

            # Get data count for pagination
            count_query = f"SELECT COUNT(*) as count FROM {operations.table_name}"
            count_result = operations.client.execute_query(count_query)
            total_records = count_result[0]['count'] if count_result else 0

            # Calculate pagination
            total_pages = (total_records // st.session_state.rows_per_page) + (1 if total_records % st.session_state.rows_per_page > 0 else 0)

            # Ensure current page is valid
            current_page = max(1, min(st.session_state.current_page, total_pages))
            if current_page != st.session_state.current_page:
                st.session_state.current_page = current_page

            # Pagination controls
            col1, col2, col3, col4 = st.columns([1, 1, 1, 1])

            with col1:
                if st.button("⏮️ First", disabled=current_page <= 1):
                    st.session_state.current_page = 1
                    st.rerun()

            with col2:
                if st.button("◀️ Previous", disabled=current_page <= 1):
                    st.session_state.current_page = current_page - 1
                    st.rerun()

            with col3:
                if st.button("Next ▶️", disabled=current_page >= total_pages):
                    st.session_state.current_page = current_page + 1
                    st.rerun()

            with col4:
                if st.button("Last ⏭️", disabled=current_page >= total_pages):
                    st.session_state.current_page = total_pages
                    st.rerun()

            # Show pagination info
            st.caption(f"Page {current_page} of {total_pages} ({total_records} total records)")

            # Get data for current page
            offset = (current_page - 1) * st.session_state.rows_per_page

            # Build query
            query = f"SELECT * FROM {operations.table_name}"

            # Add filters
            filters = []
            query_params = []

            if st.session_state.filter_query:
                # Build the filter string based on the search type
                search_query = st.session_state.filter_query

                if st.session_state.search_type == "contains":
                    # Contains search (default)
                    pattern = f"%{search_query}%"
                    filter_str = (
                        "LOWER(country) LIKE LOWER(?) OR " +
                        "LOWER(country_code) LIKE LOWER(?) OR " +
                        "LOWER(currency_name) LIKE LOWER(?) OR " +
                        "LOWER(currency_code) LIKE LOWER(?)"
                    )
                    query_params.extend([pattern, pattern, pattern, pattern])
                elif st.session_state.search_type == "starts_with":
                    # Starts with search
                    pattern = f"{search_query}%"
                    filter_str = (
                        "LOWER(country) LIKE LOWER(?) OR " +
                        "LOWER(country_code) LIKE LOWER(?) OR " +
                        "LOWER(currency_name) LIKE LOWER(?) OR " +
                        "LOWER(currency_code) LIKE LOWER(?)"
                    )
                    query_params.extend([pattern, pattern, pattern, pattern])
                elif st.session_state.search_type == "exact":
                    # Exact match search
                    filter_str = (
                        "LOWER(country) = LOWER(?) OR " +
                        "LOWER(country_code) = LOWER(?) OR " +
                        "LOWER(currency_name) = LOWER(?) OR " +
                        "LOWER(currency_code) = LOWER(?)"
                    )
                    query_params.extend([search_query, search_query, search_query, search_query])

                filters.append(f"({filter_str})")

            # Add numeric range filters
            if "country_num_range" in locals() and (country_num_range[0] > 0 or country_num_range[1] < 999):
                filters.append("country_number BETWEEN ? AND ?")
                query_params.extend([country_num_range[0], country_num_range[1]])

            if "currency_num_range" in locals() and (currency_num_range[0] > 0 or currency_num_range[1] < 999):
                filters.append("currency_number BETWEEN ? AND ?")
                query_params.extend([currency_num_range[0], currency_num_range[1]])

            if filters:
                query += f" WHERE {' AND '.join(filters)}"

            # Add sorting
            query += f" ORDER BY {st.session_state.sort_by} {'ASC' if st.session_state.sort_ascending else 'DESC'}"

            # Add pagination
            query += f" LIMIT {st.session_state.rows_per_page} OFFSET {offset}"

            # Execute query
            with st.spinner("Loading data..."):
                # Use parameterized query for security
                if query_params:
                    data = operations.client.execute_query(query, tuple(query_params))
                else:
                    data = operations.client.execute_query(query)

            if not data:
                st.markdown(info_box("No data found with the current filters. Try different search criteria."), unsafe_allow_html=True)
            else:
                # Convert to pandas DataFrame
                df = pd.DataFrame(data)

                # Display the data with row actions
                with st.container():
                    # Display the dataframe
                    st.dataframe(df, use_container_width=True)

                    # Action buttons for selected row
                    col1, col2, col3 = st.columns([1, 1, 1])

                    with col1:
                        selected_code = st.selectbox("Select a row by Country Code", 
                                                options=["-Select-"] + list(df['country_code']))

                    if selected_code and selected_code != "-Select-":
                        with col2:
                            if st.button("✏️ Edit", key="edit_btn"):
                                st.session_state.edit_record_id = selected_code
                                st.session_state.current_view = "edit"
                                st.rerun()

                        with col3:
                            if st.button("🗑️ Delete", key="delete_btn"):
                                st.session_state.delete_record_id = selected_code
                                st.session_state.current_view = "delete"
                                st.rerun()

                    # Info about selected row
                    if selected_code and selected_code != "-Select-":
                        selected_row = df[df['country_code'] == selected_code].iloc[0]
                        st.markdown(f"### Selected: {selected_row['country']} ({selected_row['country_code']})")

                        st.markdown(f"""
                        **Country Number:** {selected_row['country_number']}  
                        **Currency:** {selected_row['currency_name']} ({selected_row['currency_code']})  
                        **Currency Number:** {selected_row['currency_number']}  
                        """)

        except Exception as e:
            st.error(f"Error loading data: {str(e)}")
            st.exception(e)

        st.markdown(dataframe_container_end(), unsafe_allow_html=True)

        # Actions Card
        st.markdown(section_header("🔧", "Actions"), unsafe_allow_html=True)
        st.markdown(card_start(), unsafe_allow_html=True)

        # Data management actions
        st.subheader("Data Management")
        col1, col2 = st.columns(2)

        with col1:
            if st.button("➕ Add New Record", use_container_width=True):
                st.session_state.current_view = "add"
                st.rerun()

        with col2:
            if st.button("📤 Batch Upload", use_container_width=True):
                st.session_state.current_view = "batch_upload"
                st.rerun()

        # Export actions
        st.subheader("Export Data")

        # Only show export options if there's data to export
        if 'df' in locals() and not df.empty:
            export_col1, export_col2, export_col3 = st.columns(3)

            with export_col1:
                if st.button("📄 Export to CSV", use_container_width=True):
                    # Convert dataframe to CSV
                    csv = df.to_csv(index=False)

                    # Create a download button
                    st.download_button(
                        label="Download CSV",
                        data=csv,
                        file_name="country_currency_data.csv",
                        mime="text/csv",
                        use_container_width=True
                    )

            with export_col2:
                if st.button("📊 Export to Excel", use_container_width=True):
                    # Convert dataframe to Excel
                    output = io.BytesIO()
                    with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
                        df.to_excel(writer, sheet_name='Country_Currency_Data', index=False)
                    excel_data = output.getvalue()

                    # Create a download button
                    st.download_button(
                        label="Download Excel",
                        data=excel_data,
                        file_name="country_currency_data.xlsx",
                        mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                        use_container_width=True
                    )

            with export_col3:
                if st.button("📝 Export to JSON", use_container_width=True):
                    # Convert dataframe to JSON
                    json_data = df.to_json(orient="records")

                    # Create a download button
                    st.download_button(
                        label="Download JSON",
                        data=json_data,
                        file_name="country_currency_data.json",
                        mime="application/json",
                        use_container_width=True
                    )
        else:
            st.info("No data available to export. Please load data first.")

        st.markdown(card_end(), unsafe_allow_html=True)

        # Table Schema Information
        with st.expander("Table Schema Information"):
            st.markdown("### Table Structure")

            schema_data = {
                "Column Name": ["country_code", "country_number", "country", 
                              "currency_name", "currency_code", "currency_number"],
                "Data Type": ["STRING", "INT", "STRING", "STRING", "STRING", "INT"],
                "Description": [
                    "ISO 3166-1 alpha-3 country code",
                    "ISO 3166-1 numeric country code",
                    "Country name",
                    "Currency name",
                    "ISO 4217 currency code",
                    "ISO 4217 numeric currency code"
                ],
                "Nullable": ["Yes", "Yes", "Yes", "Yes", "Yes", "Yes"]
            }

            schema_df = pd.DataFrame(schema_data)
            st.dataframe(schema_df, use_container_width=True)
    else:
        st.warning("Please connect to Databricks to load data.")

def render_analytics():
    """Render the analytics tab with visualizations."""
    if not st.session_state.data_loaded:
        st.warning("Please connect to Databricks to view analytics.")
        return

    try:
        operations = DataOperations(st.session_state.databricks_client)

        # Get data for analytics
        query = f"SELECT * FROM {operations.table_name}"
        data = operations.client.execute_query(query)

        if not data:
            st.warning("No data available for analytics.")
            return

        # Convert to pandas DataFrame
        df = pd.DataFrame(data)

        # Display analytics dashboard
        st.markdown(section_header("📊", "Data Analytics Dashboard"), unsafe_allow_html=True)

        # Key metrics
        st.markdown(card_start(), unsafe_allow_html=True)

        col1, col2, col3, col4 = st.columns(4)

        with col1:
            st.metric("Total Records", len(df))

        with col2:
            st.metric("Unique Countries", df['country_code'].nunique())

        with col3:
            st.metric("Unique Currencies", df['currency_code'].nunique())

        with col4:
            # Calculate average countries per currency
            currency_counts = df['currency_code'].value_counts()
            avg_countries_per_currency = currency_counts.mean()
            st.metric("Avg Countries per Currency", f"{avg_countries_per_currency:.2f}")

        st.markdown(card_end(), unsafe_allow_html=True)

        # Visualization options
        st.markdown(section_header("📈", "Visualizations"), unsafe_allow_html=True)
        st.markdown(card_start(), unsafe_allow_html=True)

        viz_type = st.selectbox(
            "Select Visualization",
            ["Currency Distribution", "Country Distribution by Currency", 
             "Currency Number Distribution", "Country Number Distribution"]
        )

        if viz_type == "Currency Distribution":
            # Count currencies
            currency_counts = df['currency_code'].value_counts().reset_index()
            currency_counts.columns = ['Currency', 'Count']

            # Only show top currencies if there are many
            if len(currency_counts) > 10:
                shown_data = currency_counts.head(10)
                st.caption(f"Showing top 10 of {len(currency_counts)} currencies")
            else:
                shown_data = currency_counts

            # Create chart
            st.bar_chart(shown_data, x='Currency', y='Count', use_container_width=True)

            # Show data table
            st.write("Currency Distribution Data")
            st.dataframe(currency_counts, use_container_width=True)

        elif viz_type == "Country Distribution by Currency":
            # Get top currencies
            top_currencies = df['currency_code'].value_counts().head(5).index.tolist()

            # Filter data for top currencies
            filtered_df = df[df['currency_code'].isin(top_currencies)]

            # Group by currency and count countries
            currency_country_counts = filtered_df.groupby('currency_code').size().reset_index()
            currency_country_counts.columns = ['Currency', 'Count']

            # Create chart
            st.bar_chart(currency_country_counts, x='Currency', y='Count', use_container_width=True)
            st.caption("Number of countries using top 5 currencies")

        elif viz_type == "Currency Number Distribution":
            # Create histogram
            fig = px.histogram(df, x="currency_number",
                             title="Distribution of Currency Numbers",
                             labels={"currency_number": "Currency Number", "count": "Frequency"},
                             nbins=20)
            st.plotly_chart(fig, use_container_width=True)

        elif viz_type == "Country Number Distribution":
            # Create histogram
            fig = px.histogram(df, x="country_number",
                             title="Distribution of Country Numbers",
                             labels={"country_number": "Country Number", "count": "Frequency"},
                             nbins=20)
            st.plotly_chart(fig, use_container_width=True)

        st.markdown(card_end(), unsafe_allow_html=True)

        # Data correlation analysis
        st.markdown(section_header("🔍", "Data Analysis"), unsafe_allow_html=True)
        st.markdown(card_start(), unsafe_allow_html=True)

        # Calculate correlations between numeric columns
        numeric_df = df.select_dtypes(include=['number'])
        if len(numeric_df.columns) >= 2:
            corr = numeric_df.corr()

            st.write("### Correlation Matrix")
            st.dataframe(corr, use_container_width=True)

            st.write("### Statistical Summary")
            st.dataframe(numeric_df.describe(), use_container_width=True)
        else:
            st.info("Not enough numeric columns for correlation analysis.")

        st.markdown(card_end(), unsafe_allow_html=True)

    except Exception as e:
        st.error(f"Error generating analytics: {str(e)}")
        st.exception(e)
