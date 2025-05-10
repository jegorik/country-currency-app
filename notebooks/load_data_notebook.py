# Databricks notebook source

# COMMAND ----------
# MAGIC %md
# MAGIC # Data Loading Notebook
# MAGIC This notebook loads data from CSV file into the country currency table

# COMMAND ----------
dbutils.widgets.text("catalog_name", "", "Catalog Name")
dbutils.widgets.text("schema_name", "", "Schema Name")
dbutils.widgets.text("table_name", "", "Table Name")
dbutils.widgets.text("csv_path", "", "CSV Path")

# COMMAND ----------
# Get parameters from widgets
catalog_name = dbutils.widgets.get("catalog_name")
schema_name = dbutils.widgets.get("schema_name")
table_name = dbutils.widgets.get("table_name")
csv_path = dbutils.widgets.get("csv_path")

# COMMAND ----------
# Check if all parameters are provided
if not all([catalog_name, schema_name, table_name, csv_path]):
    raise ValueError("All parameters must be provided")

# COMMAND ----------
try:
    # Display parameters for debugging
    print(f"Loading data with parameters:")
    print(f"Catalog: {catalog_name}")
    print(f"Schema: {schema_name}")
    print(f"Table: {table_name}")
    print(f"CSV Path: {csv_path}")
    
    # Define the full table name with proper quoting
    full_table_name = f"`{catalog_name}`.`{schema_name}`.`{table_name}`"
    
    # Read the CSV file directly
    df = spark.read.csv(
        csv_path,
        header=True,
        inferSchema=True
    )
    
    # Show sample data for verification
    print("Sample data from CSV:")
    df.show(5)
    
    # Write data to the table
    print(f"Writing data to {full_table_name}")
    df.write.format("delta").mode("overwrite").saveAsTable(full_table_name)
    
    # Verify the data was loaded - also need backticks here
    count_df = spark.sql(f"SELECT COUNT(*) as row_count FROM {full_table_name}")
    row_count = count_df.collect()[0]['row_count']
    print(f"Successfully loaded {row_count} rows into {full_table_name}")
    
    if row_count == 0:
        raise Exception("No data was loaded into the table")

        
except Exception as e:
    error_message = str(e)
    print(f"Error loading data: {error_message}")
    raise Exception(f"Failed to load data: {error_message}")
