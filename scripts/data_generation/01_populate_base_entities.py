import os
import re
import csv
from faker import Faker
from typing import Set, List, Dict, Any

# Assuming 00_utils.py is in the same directory
from utils import get_db_connection, batch_insert, save_ids

# --- Configuration ---
NUM_USERS_TO_GENERATE = 200

# --- Data Definitions ---

CATEGORIES = [
    {'name': 'CPU', 'description': 'Central Processing Units'},
    {'name': 'Motherboard', 'description': 'Main circuit board of the computer'},
    {'name': 'RAM', 'description': 'Random-Access Memory modules'},
    {'name': 'GPU', 'description': 'Graphics Processing Units / Graphics Cards'},
    {'name': 'Storage', 'description': 'Solid State Drives, Hard Disk Drives, etc.'},
    {'name': 'PSU', 'description': 'Power Supply Units'},
    {'name': 'Cooling', 'description': 'CPU Coolers, Case Fans, and Water Cooling Systems'},
]

# A comprehensive list of attributes for different categories
ATTRIBUTES = {
    # General & CPU
    'Architecture', 'Codename', 'Generation', 'Market', 'Production Status', 'Release Date', 'Launch Price', 'Part#', 'Bundled Cooler',
    'Foundry', 'Process Size', 'Transistors', 'Die Size', 'TDP', 'Package', 'tJMax', 'tCaseMax', 'SMP # CPUs',
    '# of Cores', 'Cores', '# of Threads', 'Base Clock', 'Boost Clock', 'Turbo Clock', 'Frequency', 'Socket', 'Integrated Graphics', 'Connectivity',
    'Memory Support', 'Memory Bus', 'ECC Memory', 'PCI-Express', 'Secondary PCIe', 'Chipsets', 'Multiplier', 'Multiplier Unlocked',
    'Cache L1', 'Cache L2', 'Cache L3', 'L1 Cache', 'L2 Cache', 'L3 Cache',
    'I/O Process Size', 'I/O Die Size', 'PPT', 'Memory Bandwidth', 'Rated Speed', 'Bundled Heatsink', 'Features', 'Notes', # AMD/CPU specifics
    'E-Core Frequency', 'PL1', 'PL2', 'PL2 Tau Limit', 'Hybrid Cores', 'E-Core L1', 'E-Core L2', 'DDR4 Speed', 'DDR5 Speed', # Intel specifics

    # GPU core specs
    'GPU Name', 'GPU Variant', 'Graphics Processor', 'Architecture', 'Foundry', 'Process Type', 'Process Size', 'Transistors', 'Die Size',
    'MCD Process', 'GCD Transistors', 'MCD Transistors', 'Density', 'GCD Density', 'MCD Density', 'GCD Die Size', 'MCD Die Size', 'Chip Package',
    'Bus Interface',

    # GPU clocks & memory
    'GPU Clock', 'Base Clock', 'Game Clock', 'Boost Clock', 'Shader Clock', 'Memory Clock',
    'VRAM', 'Memory Size', 'Memory Type', 'Memory Bus', 'Bus Width', 'Bandwidth', 'Memory Bandwidth',

    # GPU physical/board
    'Slot Width', 'Length', 'Height', 'Width', 'Suggested PSU', 'Outputs', 'Power Connectors', 'Board Number', 'TDP', 'Recommended Gaming Resolutions',

    # GPU APIs/features
    'DirectX', 'OpenGL', 'OpenCL', 'Vulkan', 'Shader Model', 'CUDA', 'NVENC', 'NVDEC', 'Graphics/Compute', 'Shader ISA', 'Display Core Next', 'Video Core Next', 'System DMA',
    'SM Count', 'Tensor Cores', 'RT Cores', 'Matrix Cores', 'Shading Units', 'TMUs', 'ROPs', 'Compute Units',
    'Pixel Rate', 'Texture Rate', 'FP16 (half)', 'FP32 (float)', 'FP64 (double)',

    # GPU meta
    'Release Date', 'Availability', 'Announced', 'Generation', 'Predecessor', 'Successor', 'Production', 'Current Price',

    # GPU caches (extra)
    'L0 Cache', 'L1 Cache', 'L2 Cache', 'L3 Cache',

    # RAM
    'Speed (MT/s)', 'Timings', 'Voltage (V)', 'Capacity (GB)', 'Module Count', 'Profile Type',

    # Motherboard
    'Form Factor', 'Chipset', 'Memory Slots', 'Max Memory', 'PCIe Slots',

    # Storage
    'Interface', 'Capacity', 'Type', 'Read Speed', 'Write Speed',

    # PSU
    'Wattage', 'Efficiency Rating', 'Modularity',

    # Cooling
    'Fan RPM', 'Noise Level', 'Radiator Size',
}


def parse_vendor_files() -> Set[str]:
    """Parses all provided manufacturer files and returns a unique set of names."""
    print("Parsing vendor files...")
    vendor_names = set()
    scripts_dir = os.path.dirname(__file__)

    files_to_parse = [
        'sources/vendors/PSU_manufacturers.txt',
        'sources/vendors/motherboard_manufacturers.txt',
        'sources/vendors/ram_manufacturers.txt',
        'sources/vendors/Cooling_systems_manufacturers.txt',
        'sources/vendors/Fans_manufacturers.txt',
    ]

    # Add base vendors
    vendor_names.update(['Intel', 'AMD', 'NVIDIA'])

    # Parse .txt files
    for file_path in files_to_parse:
        full_path = os.path.join(scripts_dir, file_path)
        try:
            with open(full_path, 'r', encoding='utf-8') as f:
                for line in f:
                    # Clean up the line
                    line = line.strip()
                    if not line or ':' in line or '(' in line and ')' in line:
                        continue
                    # Remove list markers and other noise
                    name = re.sub(r'^\s*[-*]\s*', '', line).strip()
                    if name and len(name) > 1:
                        vendor_names.add(name)
        except FileNotFoundError:
            print(f"Warning: Vendor file not found at {full_path}")

    # Parse .csv file
    csv_path = os.path.join(scripts_dir, 'sources/vendors/gpu_vendors.csv')
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            next(reader)  # Skip header
            for row in reader:
                if row:
                    name = row[0].replace('*', '').strip()
                    vendor_names.add(name)
    except FileNotFoundError:
        print(f"Warning: Vendor file not found at {csv_path}")

    print(f"Found {len(vendor_names)} unique vendors.")
    return vendor_names

def sanitize_phone(raw: str) -> str:
    raw = raw.strip()
    plus = '+' if raw.startswith('+') else ''
    digits = re.sub(r'\D', '', raw)
    s = (plus + digits)[:11]
    return s if s else '0000000000'

def generate_users(count: int) -> List[Dict[str, Any]]:
    print(f"Generating {count} users...")
    faker = Faker()
    users = []
    for _ in range(count):
        phone = sanitize_phone(faker.phone_number())
        users.append({
            'user_name': faker.user_name(),
            'user_pass': faker.password(length=12),
            'user_email': faker.unique.email(),
            'user_phone': phone,
            'user_role': 'Customer'
        })
    return users

def main():
    print("--- Starting Step 1: Populate Base Entities ---")
    conn = None
    try:
        conn = get_db_connection()

        vendors = list(parse_vendor_files())
        users = generate_users(NUM_USERS_TO_GENERATE)

        vendor_data = [{'p_name': v, 'p_country': 'N/A', 'p_descr': ''} for v in vendors]
        batch_insert(conn,
            "INSERT INTO Vendors (ven_NAME, ven_COUNTRY, ven_DESCRIPT) VALUES (:p_name, :p_country, :p_descr)",
            vendor_data,
            commit_now=False
        )

        batch_insert(conn,
            "INSERT INTO Categories (category_NAME, category_DESCRIPT) VALUES (:name, :description)",
            CATEGORIES,
            commit_now=False
        )

        attribute_data = [{'name': attr} for attr in ATTRIBUTES]
        batch_insert(conn,
            "INSERT INTO Attributes (att_NAME) VALUES (:name)",
            attribute_data,
            commit_now=False
        )

        batch_insert(conn,
            "INSERT INTO Users (user_NAME, user_PASS, user_EMAIL, user_PHONE, user_ROLE) VALUES (:user_name, :user_pass, :user_email, :user_phone, :user_role)",
            users,
            commit_now=False
        )

        conn.commit()

        cursor = conn.cursor()
        cursor.execute("SELECT ven_ID, ven_NAME FROM Vendors")
        vendor_rows = cursor.fetchall()
        vendors_payload = [{"id": vid, "name": vname} for (vid, vname) in vendor_rows]
        save_ids('vendors', vendors_payload)

        cursor.execute("SELECT category_ID, category_NAME FROM Categories")
        category_rows = cursor.fetchall()
        categories_payload = [{"id": cid, "name": cname} for (cid, cname) in category_rows]
        save_ids('categories', categories_payload)

        cursor.execute("SELECT att_ID, att_NAME FROM Attributes")
        attribute_rows = cursor.fetchall()
        attributes_payload = [{"id": aid, "name": aname} for (aid, aname) in attribute_rows]
        save_ids('attributes', attributes_payload)

        cursor.execute("SELECT user_ID FROM Users")
        user_ids = [row[0] for row in cursor.fetchall()]
        save_ids('users', user_ids)

        cursor.close()
        print("--- Step 1 completed successfully! ---")

    except Exception as e:
        print(f"An error occurred during step 1: {e}")
        if conn:
            conn.rollback()
            print("Transaction rolled back.")
    finally:
        if conn:
            conn.close()
            print("Database connection closed.")

if __name__ == '__main__':
    main()
