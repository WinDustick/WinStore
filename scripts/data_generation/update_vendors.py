import os
import csv
import sys
from typing import List, Dict, Any

# Add parent directory to path to import utils
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from utils import get_db_connection

def load_vendors_from_csv() -> List[Dict[str, str]]:
    """Loads vendor data from the clean CSV file."""
    print("Loading vendors from clean CSV...")
    vendor_data = []
    scripts_dir = os.path.dirname(__file__)
    csv_path = os.path.join(scripts_dir, 'sources/vendors/vendors_clean_en.csv')

    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                vendor_data.append({
                    'name': row['ven_NAME'],
                    'country': row['ven_COUNTRY'],
                    'descr': row['ven_DESCRIPT']
                })
    except FileNotFoundError:
        print(f"FATAL: Clean vendor file not found at {csv_path}")
        raise

    print(f"Loaded {len(vendor_data)} vendors.")
    return vendor_data

def main():
    """Main function to update vendors in the database."""
    print("--- Starting Vendor Update/Insert Script ---")
    conn = None
    try:
        vendor_data = load_vendors_from_csv()
        if not vendor_data:
            print("No vendor data to process. Exiting.")
            return

        conn = get_db_connection()
        cursor = conn.cursor()

        # SQL MERGE statement is standard for UPSERT operations
        # It's atomic and more efficient than SELECT -> UPDATE/INSERT.
        merge_sql = """
        MERGE INTO Vendors v
        USING (SELECT :name AS ven_NAME, :country AS ven_COUNTRY, :descr AS ven_DESCRIPT FROM dual) new_v
        ON (v.ven_NAME = new_v.ven_NAME)
        WHEN MATCHED THEN
            UPDATE SET v.ven_COUNTRY = new_v.ven_COUNTRY, v.ven_DESCRIPT = new_v.ven_DESCRIPT
        WHEN NOT MATCHED THEN
            INSERT (ven_NAME, ven_COUNTRY, ven_DESCRIPT)
            VALUES (new_v.ven_NAME, new_v.ven_COUNTRY, new_v.ven_DESCRIPT)
        """

        print(f"Processing {len(vendor_data)} vendors...")
        # executemany is efficient for running the same statement with different data
        cursor.executemany(merge_sql, vendor_data)

        conn.commit()
        print(f"Successfully updated/inserted {cursor.rowcount} vendors.")

    except Exception as e:
        print(f"An error occurred: {e}")
        if conn:
            conn.rollback()
            print("Transaction rolled back.")
    finally:
        if conn:
            conn.close()
            print("Database connection closed.")

if __name__ == '__main__':
    main()
