import os
import sys
import random
from typing import List, Dict, Any, Optional, Tuple

# Make utils importable
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils import get_db_connection, load_ids


# --- Configuration ---
BATCH_SIZE = 100

# Use preferred RAM module vendors if present in Vendors. Fallback to any vendors.
PREFERRED_RAM_VENDORS = [
    'Corsair', 'G.Skill', 'Kingston Technology', 'Crucial', 'ADATA', 'GeIL', 'Mushkin',
    'Apacer', 'Transcend', 'PNY', 'Samsung Semiconductor', 'SK hynix', 'Micron Technology',
    'Wilk Elektronik', 'Silicon Power'
]

# Vendor -> product line mapping to generate more realistic names
VENDOR_LINES = {
    'Corsair': ['Vengeance', 'Dominator Platinum'],
    'G.Skill': ['Trident Z', 'Ripjaws', 'Flare X'],
    'Kingston Technology': ['FURY Beast', 'FURY Renegade'],
    'Crucial': ['Pro', 'Ballistix'],
    'ADATA': ['XPG Lancer', 'XPG Gammix'],
    'GeIL': ['EVO', 'Super Luce'],
    'Mushkin': ['Redline', 'Blackline'],
    'Apacer': ['NOX', 'Panther'],
    'Transcend': ['JetRAM'],
    'PNY': ['XLR8'],
    'Samsung Semiconductor': ['OEM'],
    'SK hynix': ['OEM'],
    'Micron Technology': ['OEM'],
    'Wilk Elektronik': ['GOODRAM'],
    'Silicon Power': ['XPOWER', 'Gaming'],
}

DDR_TYPES = ['DDR3', 'DDR4', 'DDR5']

# JEDEC base speeds per generation (MT/s)
JEDEC_SPEEDS = {
    'DDR3': [1333, 1600],
    'DDR4': [2133, 2400, 2666, 2933, 3200],
    'DDR5': [4800, 5200, 5600],
}

# Popular XMP/EXPO OC speeds per generation (MT/s)
OC_SPEEDS = {
    'DDR4': [3200, 3600, 4000],
    'DDR5': [5600, 6000, 6200, 6400, 7200],
}

# Typical module capacities per generation (GB)
MODULE_CAPACITIES = {
    'DDR3': [4, 8],
    'DDR4': [8, 16, 32],
    'DDR5': [16, 24, 32, 48],
}

# Form factor/type options
FORM_FACTORS = ['UDIMM', 'SO-DIMM']  # desktop vs laptop


def _choice_weighted(items: List[Any], weights: Optional[List[float]] = None) -> Any:
    if not items:
        return None
    if weights and len(weights) == len(items):
        return random.choices(items, weights=weights, k=1)[0]
    return random.choice(items)


def pick_category_id(categories_map: Dict[str, int]) -> Optional[int]:
    # Prefer exact 'RAM', fallback to similar
    if 'RAM' in categories_map:
        return categories_map['RAM']
    # Try common alternatives
    for k in categories_map.keys():
        kl = k.lower()
        if 'ram' in kl or 'memory' in kl:
            return categories_map[k]
    return None


def pick_ram_vendors(vendors_map: Dict[str, int]) -> List[Tuple[str, int]]:
    vm_lower = {k.lower(): (k, vid) for k, vid in vendors_map.items()}
    chosen: List[Tuple[str, int]] = []
    for name in PREFERRED_RAM_VENDORS:
        hit = vm_lower.get(name.lower())
        if hit:
            chosen.append(hit)
    if chosen:
        return chosen
    # Fallback to any vendors deterministically
    fallback = list(vendors_map.items())
    fallback.sort(key=lambda x: x[0].lower())
    return fallback[:10]


def pick_line_for_vendor(vendor_name: str) -> str:
    for k, lines in VENDOR_LINES.items():
        if k.lower() == vendor_name.lower():
            return random.choice(lines)
    return 'Series'


def profile_and_timings(ddr: str, speed: int) -> Tuple[str, str, str]:
    """Return (profile_type, timings, voltage)"""
    if ddr == 'DDR3':
        # JEDEC only typical
        if speed <= 1333:
            return 'JEDEC', '9-9-9-24', '1.5'
        return 'JEDEC', '11-11-11-28', '1.5'
    if ddr == 'DDR4':
        if speed in (2133, 2400, 2666, 2933, 3200):
            return 'JEDEC', ('19-19-19-43' if speed <= 2666 else '22-22-22-52'), '1.2'
        # OC profile XMP/EXPO
        if speed == 3200:
            return _choice_weighted(['XMP', 'EXPO']), '16-18-18-36', '1.35'
        if speed == 3600:
            return _choice_weighted(['XMP', 'EXPO']), '18-22-22-42', '1.35'
        if speed >= 4000:
            return _choice_weighted(['XMP', 'EXPO']), '19-23-23-46', '1.4'
    if ddr == 'DDR5':
        if speed in (4800, 5200, 5600):
            return 'JEDEC', ('40-40-40-77' if speed <= 4800 else '46-46-46-89'), '1.1'
        if speed == 6000:
            # two common profiles
            if random.random() < 0.5:
                return _choice_weighted(['XMP', 'EXPO']), '36-36-36-76', '1.30'
            return _choice_weighted(['XMP', 'EXPO']), '30-38-38-76', '1.35'
        if speed in (6200, 6400):
            return _choice_weighted(['XMP', 'EXPO']), '32-39-39-80', '1.40'
        if speed >= 7200:
            return 'XMP', '34-44-44-84', '1.45'
    # Fallback
    return 'JEDEC', 'Auto', '1.20'


def make_ram_products(vendors_map: Dict[str, int], categories_map: Dict[str, int], attributes_map: Dict[str, int]) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    cat_id = pick_category_id(categories_map)
    if not cat_id:
        raise RuntimeError('RAM category not found. Add a RAM/Memory category first.')

    vendors = pick_ram_vendors(vendors_map)
    if not vendors:
        raise RuntimeError('No suitable RAM vendors found.')

    products: List[Dict[str, Any]] = []
    attributes: List[Dict[str, Any]] = []

    def add_attr(pname: str, ven_id: int, key: str, value: Any):
        att_id = attributes_map.get(key)
        if att_id is None:
            return
        val = None
        if value is None:
            val = None
        elif isinstance(value, (list, tuple)):
            val = '; '.join(str(x).strip() for x in value if str(x).strip())
        else:
            s = str(value).strip()
            if s and s.lower() not in {'n/a', 'na', 'none', 'null', '-', '--'}:
                val = s
        if val:
            attributes.append({'product_NAME': pname, 'att_ID': att_id, 'nominal': val, 'ven_ID': ven_id})

    # Generate across DDR types, speeds, capacities, and kit sizes
    seen_names: set[Tuple[int, str]] = set()  # (ven_ID, product_NAME) to avoid duplicates within one run
    for ddr in DDR_TYPES:
        base_speeds = list(JEDEC_SPEEDS.get(ddr, []))
        oc_speeds = OC_SPEEDS.get(ddr, [])
        # Avoid duplicate speeds that do not produce distinct profiles (e.g., DDR5 5600)
        if ddr == 'DDR5':
            oc_speeds = [s for s in oc_speeds if s not in base_speeds]
        speeds = base_speeds + oc_speeds
        capacities = MODULE_CAPACITIES[ddr]
        for vendor_name, ven_id in vendors:
            line = pick_line_for_vendor(vendor_name)
            # Choose a form factor (mostly UDIMM)
            form_factor = _choice_weighted(FORM_FACTORS, weights=[0.85, 0.15])
            type_value = 'UDIMM' if form_factor == 'UDIMM' else 'SO-DIMM'
            # ECC presence: mostly false for consumer lines
            ecc = 'Yes' if (type_value != 'SO-DIMM' and random.random() < 0.10) else 'No'

            for speed in speeds:
                # Skip unreasonable combos (e.g., DDR3 with >1866)
                if ddr == 'DDR3' and speed > 1866:
                    continue
                profile, timings, voltage = profile_and_timings(ddr, speed)
                for module_capacity in capacities:
                    # Reasonable pairing: DDR5 typically 16GB+ modules
                    if ddr == 'DDR5' and module_capacity < 16:
                        continue
                    # Kit sizes
                    for modules in (1, 2, 4):
                        kit_capacity = module_capacity * modules

                        # Price model: base per-GB, speed premium, profile premium, ECC premium, per-module premium
                        base_per_gb = 2.5 if ddr == 'DDR3' else 3.5 if ddr == 'DDR4' else 5.0
                        speed_mult = 1.0 + (speed - min(speeds)) / (max(speeds) - min(speeds) + 1) * 0.35
                        profile_premium = 1.00 if profile == 'JEDEC' else 1.18
                        ecc_premium = 1.10 if ecc == 'Yes' else 1.00
                        module_factor = 1.00 + (modules - 1) * 0.03  # small overhead for multi-stick kits
                        price = round(kit_capacity * base_per_gb * speed_mult * profile_premium * ecc_premium * module_factor, 2)

                        # Physical dimensions
                        if type_value == 'SO-DIMM':
                            height_mm = random.randint(30, 32)
                            width_mm = 70
                            interface = 'SO-DIMM'
                        else:
                            height_mm = random.randint(31, 55)  # with/without heatsink
                            width_mm = 133
                            interface = 'DIMM'

                        # Build product name
                        cl_part = ''
                        if timings and '-' in timings:
                            cl_part = f" CL{timings.split('-')[0]}"
                        kit_part = f" ({modules}x{module_capacity}GB)"
                        series = f" {line}" if line and line != 'OEM' else ''
                        profile_sfx = '' if profile == 'JEDEC' else f" {profile}"
                        display_name = f"{vendor_name}{series} {ddr} {speed}MT/s{cl_part} {kit_capacity}GB{kit_part}{profile_sfx}"

                        # Avoid duplicate names for same vendor within one generation
                        if (ven_id, display_name) in seen_names:
                            continue
                        seen_names.add((ven_id, display_name))

                        # Assemble product record
                        products.append({
                            'category_ID': cat_id,
                            'product_NAME': display_name,
                            'product_DESCRIPT': f"{vendor_name} {line} {ddr} memory kit {kit_capacity}GB {modules}x{module_capacity}GB, {speed}MT/s {profile}, timings {timings}, {voltage}V, {interface} {('ECC' if ecc=='Yes' else 'Non-ECC')}",
                            'product_PRICE': price,
                            'product_STOCK': random.randint(10, 120),
                            'ven_ID': ven_id,
                        })

                        # Part number (synthetic)
                        part_prefix = ''.join(ch for ch in vendor_name.upper() if ch.isalnum())[:4]
                        part_num = f"{part_prefix}-{ddr.replace('DDR','D')}{speed}-{modules}x{module_capacity}"

                        # Attributes (avoid duplicates per product/att key)
                        added_keys = set()
                        def add_once(key: str, value: Any):
                            if key in added_keys:
                                return
                            added_keys.add(key)
                            add_attr(display_name, ven_id, key, value)

                        add_once('Memory Type', ddr)
                        add_once('Speed (MT/s)', f"{speed}")
                        add_once('Timings', timings)
                        add_once('Voltage (V)', voltage)
                        add_once('Capacity (GB)', f"{kit_capacity}")
                        add_once('Profile Type', profile)
                        add_once('Module Count', str(modules))
                        add_once('Form Factor', interface)
                        add_once('Type', type_value)
                        add_once('ECC Memory', ecc)
                        add_once('Height', f"{height_mm} mm")
                        add_once('Width', f"{width_mm} mm")
                        add_once('Part#', part_num)

    return products, attributes


def insert_into_db(products: List[Dict[str, Any]], attributes: List[Dict[str, Any]]):
    if not products:
        print('No products to insert.')
        return

    conn = None
    cur = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        # Deduplicate existing
        candidate_names = list({p['product_NAME'] for p in products})
        candidate_vendors = list({p['ven_ID'] for p in products})
        existing_map: Dict[Tuple[str, int], int] = {}
        if candidate_names and candidate_vendors:
            name_binds = ','.join([f":n{i+1}" for i in range(len(candidate_names))])
            ven_binds = ','.join([f":v{i+1}" for i in range(len(candidate_vendors))])
            q = (
                f"SELECT product_ID, product_NAME, ven_ID FROM Products "
                f"WHERE product_NAME IN ({name_binds}) AND ven_ID IN ({ven_binds})"
            )
            bind_values = {}
            for i, name in enumerate(candidate_names):
                bind_values[f'n{i+1}'] = name
            for i, vid in enumerate(candidate_vendors):
                bind_values[f'v{i+1}'] = vid
            cur.execute(q, bind_values)
            for pid, pname, pven in cur.fetchall():
                existing_map[(pname, pven)] = pid

        new_products = [p for p in products if (p['product_NAME'], p['ven_ID']) not in existing_map]
        if not new_products:
            print('All generated products already exist. Nothing to insert.')
            return

        prod_sql = (
            "INSERT INTO Products (category_ID, product_NAME, product_DESCRIPT, product_PRICE, product_STOCK, ven_ID) "
            "VALUES (:category_ID, :product_NAME, :product_DESCRIPT, :product_PRICE, :product_STOCK, :ven_ID)"
        )
        cur.executemany(prod_sql, new_products, batcherrors=False)

        # Map names to IDs
        names = list({p['product_NAME'] for p in new_products})
        vens = list({p['ven_ID'] for p in new_products})
        name_binds = ','.join([f":n{i+1}" for i in range(len(names))])
        ven_binds = ','.join([f":v{i+1}" for i in range(len(vens))])
        q2 = (
            f"SELECT product_ID, product_NAME, ven_ID FROM Products "
            f"WHERE product_NAME IN ({name_binds}) AND ven_ID IN ({ven_binds})"
        )
        bind = {}
        for i, name in enumerate(names):
            bind[f'n{i+1}'] = name
        for i, vid in enumerate(vens):
            bind[f'v{i+1}'] = vid
        cur.execute(q2, bind)
        id_map: Dict[Tuple[str, int], int] = {(n, v): i for i, n, v in cur.fetchall()}

        final_attrs = []
        seen_attr_keys: set[Tuple[int, int, str]] = set()
        for a in attributes:
            pid = id_map.get((a['product_NAME'], a['ven_ID']))
            if pid and a.get('nominal'):
                key = (pid, a['att_ID'], str(a['nominal']))
                if key in seen_attr_keys:
                    continue
                seen_attr_keys.add(key)
                final_attrs.append({'product_ID': pid, 'att_ID': a['att_ID'], 'nominal': a['nominal']})

        if final_attrs:
            attr_sql = "INSERT INTO ProductAttributes (product_ID, att_ID, nominal) VALUES (:product_ID, :att_ID, :nominal)"
            cur.executemany(attr_sql, final_attrs, batcherrors=False)

        conn.commit()
        print(f"Inserted {len(new_products)} products and {len(final_attrs)} attributes.")

    except Exception as e:
        if conn:
            conn.rollback()
        print(f"Error inserting RAM products. Rolled back. Details: {e}")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()


def main():
    print('--- RAM Data Generator ---')
    vendors_raw = load_ids('vendors')
    categories_raw = load_ids('categories')
    attributes_raw = load_ids('attributes')
    try:
        vendors_map = {v['name']: v['id'] for v in vendors_raw}
        categories_map = {c['name']: c['id'] for c in categories_raw}
        attributes_map = {a['name']: a['id'] for a in attributes_raw}
    except Exception:
        print('ID maps malformed. Re-run 01_populate_base_entities.py')
        return

    cat_id = pick_category_id(categories_map)
    if not cat_id:
        print('RAM category missing. Populate base entities first (add RAM/Memory category).')
        return

    products, attrs = make_ram_products(vendors_map, categories_map, attributes_map)
    print(f'Prepared {len(products)} products and {len(attrs)} attributes for insertion.')
    for i in range(0, len(products), BATCH_SIZE):
        chunk_products = products[i:i+BATCH_SIZE]
        names_in_chunk = {p['product_NAME'] for p in chunk_products}
        attrs_chunk = [a for a in attrs if a['product_NAME'] in names_in_chunk]
        insert_into_db(chunk_products, attrs_chunk)

    print('--- RAM Generation finished ---')


if __name__ == '__main__':
    main()
