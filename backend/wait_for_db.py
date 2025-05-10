#!/usr/bin/env python
import os
import sys
import time
import pyodbc

# Maximum number of attempts to connect to the database
MAX_ATTEMPTS = 30
# Delay between attempts in seconds
DELAY = 2

# Get database connection parameters from environment
DB_HOST = os.environ.get("DB_HOST", "db")
DB_PORT = os.environ.get("DB_PORT", "1433")
DB_NAME = os.environ.get("DB_NAME", "WinStore")
DB_USER = os.environ.get("DB_USER", "sa")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "Sq1_53rv3r")

print(f"Waiting for MS SQL Server at {DB_HOST}:{DB_PORT}...")

# Connection string
conn_str = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={DB_HOST},{DB_PORT};DATABASE={DB_NAME};UID={DB_USER};PWD={DB_PASSWORD}"

attempt = 0
while attempt < MAX_ATTEMPTS:
    try:
        # Try to establish a connection
        connection = pyodbc.connect(conn_str)
        cursor = connection.cursor()
        cursor.execute("SELECT 1")
        cursor.close()
        connection.close()
        
        print("Database connection established successfully!")
        sys.exit(0)  # Exit with success code
    except Exception as e:
        attempt += 1
        if "Cannot open database" in str(e) and attempt < MAX_ATTEMPTS:
            # Database doesn't exist yet - create it
            try:
                master_conn_str = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={DB_HOST},{DB_PORT};DATABASE=master;UID={DB_USER};PWD={DB_PASSWORD}"
                master_conn = pyodbc.connect(master_conn_str)
                master_cursor = master_conn.cursor()
                print(f"Creating database {DB_NAME}...")
                master_cursor.execute(f"CREATE DATABASE {DB_NAME}")
                master_cursor.close()
                master_conn.close()
                print(f"Database {DB_NAME} created.")
                continue
            except Exception as create_e:
                print(f"Failed to create database: {create_e}")
                # Continue with the retry loop
        
        print(f"Attempt {attempt}/{MAX_ATTEMPTS} failed: {e}")
        if attempt < MAX_ATTEMPTS:
            print(f"Retrying in {DELAY} seconds...")
            time.sleep(DELAY)
        else:
            print("Max attempts reached. Could not connect to the database.")
            sys.exit(1)  # Exit with error code

# Should not reach here but just in case
sys.exit(1)
