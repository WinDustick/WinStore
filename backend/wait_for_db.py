#!/usr/bin/env python
import os
import sys
import time

MAX_ATTEMPTS = int(os.environ.get("DB_WAIT_MAX_ATTEMPTS", "60"))
DELAY = int(os.environ.get("DB_WAIT_DELAY", "2"))

DB_TYPE = os.environ.get("DB_TYPE", "mssql").lower()

def wait_mssql():
    import pyodbc
    host = os.environ.get("MSSQL_DB_HOST", "db")
    port = os.environ.get("MSSQL_DB_PORT", "1433")
    name = os.environ.get("MSSQL_DB_NAME", "WinStore")
    user = os.environ.get("MSSQL_DB_USER", "sa")
    pwd  = os.environ.get("MSSQL_DB_PASSWORD", "Sq1_53rv3r")
    conn_str = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={host},{port};DATABASE={name};UID={user};PWD={pwd}"
    attempt = 0
    while attempt < MAX_ATTEMPTS:
        try:
            with pyodbc.connect(conn_str, timeout=5) as cn:
                cn.cursor().execute("SELECT 1")
            print("MSSQL is ready.")
            return 0
        except Exception as e:
            attempt += 1
            print(f"[MSSQL] Attempt {attempt}/{MAX_ATTEMPTS} failed: {e}")
            time.sleep(DELAY)
    return 1

def wait_oracle():
    import oracledb
    host = os.environ.get("ORACLE_DB_HOST", "oracle")
    port = os.environ.get("ORACLE_DB_PORT", "1521")
    service = os.environ.get("ORACLE_DB_SERVICE", "XE")
    user = os.environ.get("ORACLE_DB_USER", "system")
    pwd  = os.environ.get("ORACLE_DB_PASSWORD", os.environ.get("ORACLE_PASSWORD", "oracle"))
    dsn = f"{host}:{port}/{service}"
    attempt = 0
    while attempt < MAX_ATTEMPTS:
        try:
            with oracledb.connect(user=user, password=pwd, dsn=dsn, encoding="UTF-8") as cn:
                cn.cursor().execute("SELECT 1 FROM dual")
            print("Oracle is ready.")
            return 0
        except Exception as e:
            attempt += 1
            print(f"[Oracle] Attempt {attempt}/{MAX_ATTEMPTS} failed: {e}")
            time.sleep(DELAY)
    return 1

def main():
    if DB_TYPE == "oracle":
        sys.exit(wait_oracle())
    else:
        sys.exit(wait_mssql())

if __name__ == "__main__":
    main()