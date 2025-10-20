import oracledb
import os
import json
from typing import List, Dict, Any

# --- Database Connection ---

def get_db_connection():
    """
    Establishes a connection to the Oracle database using environment variables.
    Returns the connection object.
    """
    try:
        user = os.environ.get('ORACLE_DB_USER', os.environ.get('ORACLE_USER', 'WINSTORE_ADMIN'))
        password = (
            os.environ.get('ORACLE_DB_PASSWORD')
            or os.environ.get('ORACLE_ADMIN_PASSWORD')
            or os.environ.get('ORACLE_PASSWORD')
            or '123'
        )
        host = os.environ.get('ORACLE_DB_HOST', 'localhost')
        port = os.environ.get('ORACLE_DB_PORT', '1521')
        service_name = os.environ.get('ORACLE_DB_SERVICE', os.environ.get('ORACLE_SERVICE', 'XEPDB1'))
        dsn = os.environ.get('ORACLE_DSN', f'{host}:{port}/{service_name}')
        print(f"[Oracle] Connecting dsn={dsn} user={user}")
        try:
            connection = oracledb.connect(user=user, password=password, dsn=dsn, encoding="UTF-8")
        except oracledb.DatabaseError as e:
            alt = 'ORCLPDB1' if service_name.upper() == 'XEPDB1' else 'XEPDB1'
            alt_dsn = f'{host}:{port}/{alt}'
            print(f"[Oracle] Primary connect failed: {e}. Trying fallback dsn={alt_dsn}")
            connection = oracledb.connect(user=user, password=password, dsn=alt_dsn, encoding="UTF-8")
        with connection.cursor() as cur:
            cur.execute("select sys_context('USERENV','CON_NAME') from dual")
            con_name, = cur.fetchone()
            print(f"[Oracle] Connected to container: {con_name}")
        return connection
    except oracledb.DatabaseError as e:
        print(f"[Oracle] Connection failed: {e}")
        print("- Проверьте сервис (XEPDB1 для gvenzl/oracle-xe).")
        print("- Проверьте пароль (ORACLE_DB_PASSWORD/ORACLE_PASSWORD).")
        print("- Убедитесь, что порт 1521 доступен (docker compose порт проброшен).")
        raise

# --- Batch Insertion ---

def batch_insert(conn: oracledb.Connection, sql: str, data: List[Dict[str, Any]], batch_size: int = 100, commit_now: bool = True):
    """
    Inserts data in batches into the database.

    Args:
        conn: The database connection object.
        sql: The SQL INSERT statement with bind variables.
        data: A list of dictionaries, where each dictionary represents a row.
        batch_size: The number of records to insert per batch.
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

# --- ID and File Management ---

IDS_DIR = os.path.join(os.path.dirname(__file__), 'generated_ids')

def save_ids(entity_name: str, ids: List[int]):
    """Saves a list of generated IDs to a JSON file."""
    if not os.path.exists(IDS_DIR):
        os.makedirs(IDS_DIR)
    file_path = os.path.join(IDS_DIR, f'{entity_name}.json')
    with open(file_path, 'w') as f:
        json.dump(ids, f, indent=4)
    print(f"Saved {len(ids)} IDs to {file_path}")

def load_ids(entity_name: str) -> List[int]:
    """Loads a list of IDs from a JSON file."""
    file_path = os.path.join(IDS_DIR, f'{entity_name}.json')
    try:
        with open(file_path, 'r') as f:
            ids = json.load(f)
        print(f"Loaded {len(ids)} IDs from {file_path}")
        return ids
    except FileNotFoundError:
        print(f"Error: ID file not found at {file_path}. Please run the prerequisite script.")
        return []
