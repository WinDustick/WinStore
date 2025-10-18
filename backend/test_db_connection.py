import os
import oracledb
import time
import sys

# --- Configuration ---
# Read connection details from environment variables
user = os.environ.get('ORACLE_DB_USER')
password = os.environ.get('ORACLE_DB_PASSWORD')
host = os.environ.get('ORACLE_DB_HOST')
port = os.environ.get('ORACLE_DB_PORT')
service_name = os.environ.get('ORACLE_DB_SERVICE')

# Connection details validation
if not all([user, password, host, port, service_name]):
    print("Error: One or more Oracle environment variables are not set.")
    print(f"USER: {user}, HOST: {host}, PORT: {port}, SERVICE: {service_name}")
    sys.exit(1)

# --- Connection Logic ---
# Construct the Data Source Name (DSN)
dsn = f'{host}:{port}/{service_name}'

print(f"Attempting to connect to Oracle database...")
print(f"DSN: {dsn}")
print(f"User: {user}")

# Retry logic to wait for the database to be ready
max_retries = 10
retry_interval_seconds = 5

for attempt in range(1, max_retries + 1):
    try:
        # Establish the connection
        with oracledb.connect(user=user, password=password, dsn=dsn) as connection:
            print("\n==================================================")
            print("SUCCESS: Successfully connected to Oracle database!")
            print(f"Oracle DB Version: {connection.version}")
            print("==================================================\n")
        # Exit successfully
        sys.exit(0)

    except oracledb.Error as e:
        print(f"\nAttempt {attempt}/{max_retries} failed.")
        print(f"Error connecting to Oracle: {e}")
        if attempt < max_retries:
            print(f"Retrying in {retry_interval_seconds} seconds...")
            time.sleep(retry_interval_seconds)
        else:
            print("\n==================================================")
            print("ERROR: Could not connect to the database after all retries.")
            print("==================================================\n")
            # Exit with an error code
            sys.exit(1)
