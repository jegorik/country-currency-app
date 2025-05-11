# Databricks notebook source

# COMMAND ----------
# MAGIC %md
# MAGIC # Country Currency Data Loading Notebook
# MAGIC 
# MAGIC ## Overview
# MAGIC This notebook processes country-to-currency mapping data from a CSV file and loads it into a Delta table.
# MAGIC 
# MAGIC ## Input Parameters
# MAGIC - catalog_name: The catalog where the schema exists
# MAGIC - schema_name: The schema where the table will be created
# MAGIC - table_name: The name of the target table
# MAGIC - csv_path: Path to the CSV file in the volume
# MAGIC - warehouse_id: SQL warehouse ID (optional)
# MAGIC 
# MAGIC ## Process Flow
# MAGIC 1. Read parameters from widgets
# MAGIC 2. Load data from CSV file
# MAGIC 3. Write data to Delta table
# MAGIC 4. Validate data was loaded successfully

# COMMAND ----------
# Define input parameters as widgets
dbutils.widgets.text("catalog_name", "", "Catalog Name")
dbutils.widgets.text("schema_name", "", "Schema Name")
dbutils.widgets.text("table_name", "", "Table Name")
dbutils.widgets.text("csv_path", "", "CSV Path")
dbutils.widgets.text("warehouse_id", "", "SQL Warehouse ID (optional)")
dbutils.widgets.text("warehouse_name", "", "SQL Warehouse Name (optional)")

# COMMAND ----------
# Get parameters from widgets
catalog_name = dbutils.widgets.get("catalog_name")
schema_name = dbutils.widgets.get("schema_name")
table_name = dbutils.widgets.get("table_name")
csv_path = dbutils.widgets.get("csv_path")
warehouse_id = dbutils.widgets.get("warehouse_id")
warehouse_name = dbutils.widgets.get("warehouse_name")

# COMMAND ----------
# MAGIC %md
# MAGIC ## Parameter Validation
# MAGIC Verify that all required parameters are provided

# COMMAND ----------
# Check if all required parameters are provided
if not all([catalog_name, schema_name, table_name, csv_path]):
    error_msg = "Missing required parameters. Please provide catalog_name, schema_name, table_name, and csv_path."
    print(f"ERROR: {error_msg}")
    raise ValueError(error_msg)

# COMMAND ----------
# MAGIC %md
# MAGIC ## Data Processing
# MAGIC Load data from CSV file and write to Delta table

# COMMAND ----------
try:
    # Log parameters for debugging and auditing
    print(f"Starting data loading process with parameters:")
    print(f"Catalog: {catalog_name}")
    print(f"Schema: {schema_name}")
    print(f"Table: {table_name}")
    print(f"CSV Path: {csv_path}")
    if warehouse_name:
        print(f"Warehouse: {warehouse_name}")
    
    # Define the full table name with proper quoting for SQL operations
    full_table_name = f"`{catalog_name}`.`{schema_name}`.`{table_name}`"
    
    # COMMAND ----------
    # MAGIC %md
    # MAGIC ### Step 1: Read CSV Data
    
    # COMMAND ----------
    # Read the CSV file using PySpark
    df = spark.read.csv(
        csv_path,
        header=True,
        inferSchema=True,
        sep=",",
        nullValue="",
        timestampFormat="yyyy-MM-dd HH:mm:ss"
    )
    
    # Add metadata column with processing timestamp
    from pyspark.sql.functions import current_timestamp
    df = df.withColumn("processing_time", current_timestamp())
    
    # Show sample data for verification
    print("Sample data from CSV:")
    df.show(5, truncate=False)
    
    # COMMAND ----------
    # MAGIC %md
    # MAGIC ### Step 2: Data Quality Checks
    
    # COMMAND ----------
    # Check for null values in key columns
    null_counts = [(col_name, df.filter(df[col_name].isNull()).count()) 
                  for col_name in ["country_code", "currency_code"]]
    
    for col_name, count in null_counts:
        if count > 0:
            print(f"WARNING: Found {count} rows with null {col_name}")
    
    # Get record count for validation
    record_count = df.count()
    print(f"Total records to load: {record_count}")
    
    if record_count == 0:
        raise ValueError("CSV file contains no data to load")
    
    # COMMAND ----------
    # MAGIC %md
    # MAGIC ### Step 3: Write to Delta Table
    
    # COMMAND ----------
    # Write data to the table using Delta format
    print(f"Writing data to table: {full_table_name}")
    
    # Write with optimizations
    df.write.format("delta") \
        .mode("overwrite") \
        .option("overwriteSchema", "true") \
        .option("mergeSchema", "true") \
        .saveAsTable(full_table_name)
    
    # COMMAND ----------
    # MAGIC %md
    # MAGIC ### Step 4: Validate Data Load
    
    # COMMAND ----------
    # Verify the data was loaded correctly
    count_df = spark.sql(f"SELECT COUNT(*) as row_count FROM {full_table_name}")
    row_count = count_df.collect()[0]['row_count']
    print(f"Successfully loaded {row_count} rows into {full_table_name}")
    
    if row_count == 0:
        raise Exception("No data was loaded into the table")
    elif row_count != record_count:
        print(f"WARNING: Record count mismatch. CSV had {record_count} rows, but table has {row_count} rows")
        
except Exception as e:
    error_message = str(e)
    print(f"ERROR: Failed to load data: {error_message}")
    raise Exception(f"Failed to load data: {error_message}")
