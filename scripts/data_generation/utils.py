import os
import json
from typing import List, Dict, Any

import oracledb


# This module mirrors helpers from 00_utils.py to provide a stable import path
# for scripts that do `from utils import ...` after adjusting sys.path.


def get_db_connection():
    """
    Establishes a connection to the Oracle database using environment variables.
    Returns the connection object.
    """
    try:
        user = os.environ.get('ORACLE_DB_USER', 'WINSTORE_ADMIN')
        password = os.environ.get('ORACLE_ADMIN_PASSWORD', '123')
        host = os.environ.get('ORACLE_DB_HOST', 'localhost')
        port = os.environ.get('ORACLE_DB_PORT', '1521')
        service_name = os.environ.get('ORACLE_DB_SERVICE', 'XEPDB1')

        dsn = f"{host}:{port}/{service_name}"

        print(f"Attempting to connect to Oracle: {dsn} with user {user}...")
        connection = oracledb.connect(user=user, password=password, dsn=dsn)
        print("Database connection successful.")
        return connection
    except oracledb.Error as e:
        print(f"Error connecting to Oracle database: {e}")
        raise


def batch_insert(
    conn: oracledb.Connection,
    sql: str,
    data: List[Dict[str, Any]],
    batch_size: int = 100,
    commit_now: bool = True,
):
    """
    Inserts data in batches into the database.

    Args:
        conn: The database connection object.
        sql: The SQL INSERT statement with bind variables.
        data: A list of dictionaries, where each dictionary represents a row.
        batch_size: The number of records to insert per batch.
        commit_now: If True, commit immediately; otherwise the caller manages commit/rollback.
    """
    cursor = conn.cursor()
    try:
        cursor.executemany(sql, data, batch_size=batch_size)
        if commit_now:
            conn.commit()
        print(f"Successfully inserted {len(data)} records in batches of {batch_size}.")
    except oracledb.Error as e:
        print(f"Database error during batch insert: {e}")
        if commit_now:
            print("Rolling back transaction.")
            conn.rollback()
        raise
    finally:
        cursor.close()


IDS_DIR = os.path.join(os.path.dirname(__file__), 'generated_ids')


def save_ids(entity_name: str, ids: List[Any]):
    """Saves a list of generated IDs or objects to a JSON file."""
    if not os.path.exists(IDS_DIR):
        os.makedirs(IDS_DIR)
    file_path = os.path.join(IDS_DIR, f'{entity_name}.json')
    with open(file_path, 'w') as f:
        json.dump(ids, f, indent=4)
    print(f"Saved {len(ids)} records to {file_path}")


def load_ids(entity_name: str):
    """Loads a list of IDs or objects from a JSON file."""
    file_path = os.path.join(IDS_DIR, f'{entity_name}.json')
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
        print(f"Loaded {len(data)} records from {file_path}")
        return data
    except FileNotFoundError:
        print(f"Error: ID file not found at {file_path}. Please run the prerequisite script.")
        return []
