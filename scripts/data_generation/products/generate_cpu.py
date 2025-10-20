import os
import re
import sys
import time
import random
import requests
from bs4 import BeautifulSoup
from typing import List, Dict, Any, Optional, Tuple

# Add parent directory to path to import utils
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils import get_db_connection, batch_insert, load_ids

# --- Configuration ---
# If URL_DIR is set, the script will iterate all .txt files in that directory (sorted) and process each file separately.
# Otherwise, it falls back to a single file mode via URL_FILE.
URL_DIR = '../sources/links/cpu_links'
URL_FILE = '../sources/links/cpu_urls.txt'  # Single file fallback
BATCH_SIZE = 50
MIN_DELAY = 3  # seconds
MAX_DELAY = 5  # seconds

USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0',
]


class RateLimitError(Exception):
    """Raised when the target site responds with HTTP 429 (Too Many Requests)."""
    pass


def _normalize_nominal(value: Any) -> Optional[str]:
    """Convert spec value to a safe non-empty string for DB insert.
    - Lists: join by "; ".
    - Strip whitespace, convert 'N/A' or empty to None.
    - Truncate to a reasonable length if needed (DB is NCLOB, so usually fine).
    """
    if value is None:
        return None
    if isinstance(value, list):
        # Flatten list of features, ensure each item is string
        items = [str(x).strip() for x in value if str(x).strip()]
        joined = "; ".join(items)
        val = joined.strip()
    else:
        val = str(value).strip()

    if not val:
        return None
    # Normalize common empties
    lowered = val.lower()
    if lowered in {"n/a", "na", "none", "null", "-", "--"}:
        return None
    return val

def parse_cpu_page(url: str) -> Optional[Dict[str, Any]]:
    """Fetches and parses a single CPU page from a URL."""
    print(f"Parsing: {url}")
    try:
        headers = {'User-Agent': random.choice(USER_AGENTS)}
        response = requests.get(url, headers=headers, timeout=30)
        # Stop immediately on HTTP 429 to avoid getting blocked
        if response.status_code == 429:
            raise RateLimitError(f"HTTP 429 Too Many Requests for url: {url}")
        response.raise_for_status()
        time.sleep(random.uniform(MIN_DELAY, MAX_DELAY))

        soup = BeautifulSoup(response.content, 'html.parser')

        # --- Extract Product Name (robust) ---
        product_name_tag = (
            soup.select_one('h1.prodheader')
            or soup.select_one('div.cpudb-details h1')
            or soup.select_one('div.page h1')
            or soup.find('h1')
        )
        if product_name_tag and product_name_tag.get_text(strip=True):
            product_name = product_name_tag.get_text(strip=True)
        else:
            # Fallback to <title>
            title_tag = soup.find('title')
            if not title_tag or not title_tag.get_text(strip=True):
                print("Warning: Could not find product name on page. Skipping.")
                return None
            title_text = title_tag.get_text(strip=True)
            # Common patterns: "Athlon 64 2650e | TechPowerUp" or "Athlon 64 2650e Specs"
            for sep in ['|', '–', '-', '—']:
                if sep in title_text:
                    product_name = title_text.split(sep)[0].strip()
                    break
            else:
                product_name = title_text.strip()

        # --- Extract Specs ---
        specs = {}
        details_sections = soup.find_all('section', class_='details')
        for section in details_sections:
            section_title_tag = section.find(['h2', 'h1'])
            if not section_title_tag:
                continue
            
            section_title = section_title_tag.text.strip()
            
            if section_title == "Features":
                features_lis = section.select('ul.features li') or section.find_all('li')
                specs[section_title] = [li.get_text(strip=True) for li in features_lis]
            else:
                rows = section.find_all('tr')
                for row in rows:
                    th = row.find('th')
                    td = row.find('td')
                    if th and td:
                        key = th.text.strip().rstrip(':')
                        value = td.text.strip()
                        specs[key] = value

        # --- Validate if product is released ---
        release_date = specs.get('Release Date', '')
        if 'Never Released' in release_date or not release_date:
            print(f"Skipping '{product_name}' (Reason: Not released)")
            return None
        # Add more checks for future dates if necessary

        return {'name': product_name, 'specs': specs}

    except requests.RequestException as e:
        # If the exception carries a 429 response, convert to RateLimitError
        resp = getattr(e, 'response', None)
        if resp is not None and getattr(resp, 'status_code', None) == 429:
            raise RateLimitError(f"HTTP 429 Too Many Requests for url: {url}")
        print(f"Error fetching {url}: {e}")
        return None
    except RateLimitError:
        # Bubble up rate limit to stop the whole run
        raise
    except Exception as e:
        print(f"An error occurred during parsing {url}: {e}")
        return None

def process_batch(urls: List[str], vendors_map: Dict, categories_map: Dict, attributes_map: Dict):
    """Parses a batch of URLs and inserts the data into the database transactionally."""
    print(f"--- Processing batch of {len(urls)} URLs ---")
    
    products_to_insert = []
    attributes_to_link: List[Dict[str, Any]] = []
    cpu_category_id = categories_map.get('CPU')
    seen_names = set()

    for url in urls:
        parsed_data = parse_cpu_page(url)
        if not parsed_data:
            continue

        # Find vendor ID (first token usually vendor; fallback to known vendors)
        name_tokens = parsed_data['name'].split(' ')
        vendor_name = name_tokens[0] if name_tokens else ''
        vendor_id = vendors_map.get(vendor_name)
        if not vendor_id:
            print(f"Warning: Vendor '{vendor_name}' for product '{parsed_data['name']}' not in DB. Skipping.")
            continue

        # Deduplicate within batch by product name
        if parsed_data['name'] in seen_names:
            print(f"Skipping duplicate product name in batch: {parsed_data['name']}")
            continue
        seen_names.add(parsed_data['name'])

        # Parse price safely; default to 0 on failure
        launch_price_raw = parsed_data['specs'].get('Launch Price', '0')
        try:
            price_clean = re.sub(r'[^0-9.]+', '', str(launch_price_raw))
            product_price = float(price_clean) if price_clean else 0.0
        except Exception:
            product_price = 0.0

        products_to_insert.append({
            'category_ID': cpu_category_id,
            'product_NAME': parsed_data['name'],
            'product_DESCRIPT': f"Specifications for {parsed_data['name']}.",
            'product_PRICE': product_price,
            'product_STOCK': random.randint(25, 150),
            'ven_ID': vendor_id
        })

        for spec_name, spec_value in parsed_data['specs'].items():
            attribute_id = attributes_map.get(spec_name)
            if not attribute_id:
                continue
            nominal = _normalize_nominal(spec_value)
            if nominal is None:
                # Skip empty/meaningless spec values to avoid ORA-01400
                continue
            attributes_to_link.append({
                'product_NAME': parsed_data['name'],
                'att_ID': attribute_id,
                'nominal': nominal,
                'ven_ID': vendor_id,
            })

    if not products_to_insert:
        print("No valid products to insert in this batch.")
        return

    # --- Database Insertion (single transaction per batch) ---
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Filter out products that already exist (by name & vendor)
        if products_to_insert:
            candidate_names = list({p['product_NAME'] for p in products_to_insert})
            candidate_vendors = list({p['ven_ID'] for p in products_to_insert})
            name_binds = ','.join([f':en{i+1}' for i in range(len(candidate_names))])
            ven_binds = ','.join([f':ev{i+1}' for i in range(len(candidate_vendors))])
            existing_map: Dict[Tuple[str, int], int] = {}
            if candidate_names and candidate_vendors:
                exists_query = (
                    f"SELECT product_ID, product_NAME, ven_ID FROM Products "
                    f"WHERE product_NAME IN ({name_binds}) AND ven_ID IN ({ven_binds})"
                )
                bind_values = {}
                for i, name in enumerate(candidate_names):
                    bind_values[f'en{i+1}'] = name
                for i, vid in enumerate(candidate_vendors):
                    bind_values[f'ev{i+1}'] = vid
                cursor.execute(exists_query, bind_values)
                for pid, pname, pven in cursor.fetchall():
                    existing_map[(pname, pven)] = pid

            if existing_map:
                before = len(products_to_insert)
                products_to_insert = [p for p in products_to_insert if (p['product_NAME'], p['ven_ID']) not in existing_map]
                if before != len(products_to_insert):
                    print(f"Skipped {before - len(products_to_insert)} products already existing in DB.")

        # Insert products (no auto-commit)
        product_sql = (
            "INSERT INTO Products (category_ID, product_NAME, product_DESCRIPT, product_PRICE, product_STOCK, ven_ID) "
            "VALUES (:category_ID, :product_NAME, :product_DESCRIPT, :product_PRICE, :product_STOCK, :ven_ID)"
        )
        cursor.executemany(product_sql, products_to_insert, batcherrors=False)

        # Build mapping of (name, ven_ID) -> product_ID to avoid ambiguity
        product_names = list({p['product_NAME'] for p in products_to_insert})
        vendor_ids = list({p['ven_ID'] for p in products_to_insert})
        name_binds = ','.join([f':n{i+1}' for i in range(len(product_names))]) if product_names else None
        ven_binds = ','.join([f':v{i+1}' for i in range(len(vendor_ids))]) if vendor_ids else None

        if name_binds and ven_binds:
            sql_query = (
                f"SELECT product_ID, product_NAME, ven_ID FROM Products "
                f"WHERE product_NAME IN ({name_binds}) AND ven_ID IN ({ven_binds})"
            )
            bind_values = {}
            for i, name in enumerate(product_names):
                bind_values[f'n{i+1}'] = name
            for i, vid in enumerate(vendor_ids):
                bind_values[f'v{i+1}'] = vid

            cursor.execute(sql_query, bind_values)
            product_id_map: Dict[Tuple[str, int], int] = {}
            for pid, pname, pven in cursor.fetchall():
                product_id_map[(pname, pven)] = pid
        else:
            product_id_map = {}

        # Link attributes and prepare insert rows
        final_attributes_to_insert = []
        for attr in attributes_to_link:
            key = (attr['product_NAME'], attr['ven_ID'])
            product_id = product_id_map.get(key)
            if product_id:
                final_attributes_to_insert.append({
                    'product_ID': product_id,
                    'att_ID': attr['att_ID'],
                    'nominal': attr['nominal']
                })

        if final_attributes_to_insert:
            # Safety filter: ensure 'nominal' is not None or empty after mapping
            safe_final_attrs = [row for row in final_attributes_to_insert if row.get('nominal')]
            if safe_final_attrs:
                attribute_sql = "INSERT INTO ProductAttributes (product_ID, att_ID, nominal) VALUES (:product_ID, :att_ID, :nominal)"
                cursor.executemany(attribute_sql, safe_final_attrs, batcherrors=False)

        conn.commit()
        print(f"Successfully processed and inserted data for {len(products_to_insert)} products.")

    except RateLimitError:
        # Bubble up to stop the run at a higher level
        raise
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"A critical error occurred during batch processing. Transaction rolled back. Error: {e}")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

def read_urls_from_file(file_path: str) -> List[str]:
    try:
        with open(file_path, 'r') as f:
            return [line.strip() for line in f if line.strip()]
    except FileNotFoundError:
        print(f"Error: URL file not found at {file_path}.")
        return []


def main():
    """Main function to run the CPU data generation process."""
    print("--- Starting CPU Data Generation via Live Parser ---")
    
    # 1. Load prerequisite IDs from JSON files
    # These are created by 01_populate_base_entities.py
    vendors_raw = load_ids('vendors')
    categories_raw = load_ids('categories')
    attributes_raw = load_ids('attributes')
    try:
        vendors_map = {v['name']: v['id'] for v in vendors_raw}
        categories_map = {c['name']: c['id'] for c in categories_raw}
        attributes_map = {a['name']: a['id'] for a in attributes_raw}
    except (TypeError, KeyError):
        print("Error: ID maps are malformed. Please re-run `01_populate_base_entities.py`.")
        return

    # Validate essential entries
    if not vendors_map or not attributes_map or 'CPU' not in categories_map:
        print("Error: Missing vendors, attributes, or CPU category. Run `01_populate_base_entities.py` first.")
        return

    # 2. Determine input: directory of files or single file
    base_dir = os.path.dirname(__file__)
    url_dir_path = os.path.join(base_dir, URL_DIR)
    if os.path.isdir(url_dir_path):
        # Process each .txt file in sorted order
        entries = sorted(
            [os.path.join(url_dir_path, name) for name in os.listdir(url_dir_path) if name.endswith('.txt')]
        )
        if not entries:
            print(f"No .txt files found in {url_dir_path}")
            return
        for path in entries:
            urls = read_urls_from_file(path)
            if not urls:
                print(f"Skipping empty or missing file: {path}")
                continue
            print(f"=== Processing URL file: {os.path.basename(path)} ({len(urls)} URLs) ===")
            for i in range(0, len(urls), BATCH_SIZE):
                batch_urls = urls[i:i + BATCH_SIZE]
                try:
                    process_batch(batch_urls, vendors_map, categories_map, attributes_map)
                except RateLimitError as e:
                    print(f"Rate limit encountered. Stopping early. Details: {e}")
                    print("Tip: Wait some time before retrying, or reduce request rate.")
                    sys.exit(2)
    else:
        # Fallback to single file mode
        url_file_path = os.path.join(base_dir, URL_FILE)
        urls = read_urls_from_file(url_file_path)
        if not urls:
            print(f"Error: URL file not found at {url_file_path}. Please create it and add CPU URLs.")
            return
        for i in range(0, len(urls), BATCH_SIZE):
            batch_urls = urls[i:i + BATCH_SIZE]
            try:
                process_batch(batch_urls, vendors_map, categories_map, attributes_map)
            except RateLimitError as e:
                print(f"Rate limit encountered. Stopping early. Details: {e}")
                print("Tip: Wait some time before retrying, or reduce request rate.")
                sys.exit(2)

    print("--- CPU Data Generation Process Finished ---")

if __name__ == '__main__':
    main()
