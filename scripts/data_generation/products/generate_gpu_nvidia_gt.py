import os
import sys
import random
from typing import List, Dict, Any, Optional, Tuple

# Make utils importable
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils import get_db_connection, load_ids


# --- Configuration ---
VENDORS_PER_MODEL = 5
VARIANTS_PER_VENDOR = 2
BATCH_SIZE = 100

USE_URL_SEED = True
URL_SEED_FILE = os.path.join(os.path.dirname(__file__), '..', 'sources', 'links', 'gpu_links', 'gpu_nvidia.txt')


# --- Domain model for GT series ---
GEN_INFO_GT = {
    'GT-600':  {'arch': 'Kepler', 'process': '28 nm', 'directx': '12 (FL 11_0)'} , # GT 610 often Fermi; simplify to Kepler
    'GT-700':  {'arch': 'Kepler', 'process': '28 nm', 'directx': '12 (FL 11_0)'},
    'GT-1000': {'arch': 'Pascal', 'process': '16 nm', 'directx': '12 (FL 12_1)'},  # GT 1030/1010
}

# Price bands per generation & internal tier (low/mid/hi as 1/2/3)
PRICE_TABLE_GT = {
    'GT-600':  [39, 49, 59],
    'GT-700':  [45, 55, 69],
    'GT-1000': [65, 79, 99],
}

# Memory options per model (approximate real-world)
MODEL_MEMORY = {
    610:  {'sizes': [1, 2],   'types': ['DDR3']},
    710:  {'sizes': [1, 2],   'types': ['DDR3']},
    720:  {'sizes': [1, 2],   'types': ['DDR3']},
    730:  {'sizes': [1, 2, 4],'types': ['DDR3', 'GDDR5']},
    740:  {'sizes': [2],      'types': ['GDDR5']},
    1010: {'sizes': [2],      'types': ['GDDR5']},
    1030: {'sizes': [2, 4],   'types': ['GDDR5', 'DDR4']},
}

# Bus widths per model
MODEL_BUS = {
    610: [64],
    710: [64],
    720: [64],
    730: [64, 128],
    740: [128],
    1010: [64],
    1030: [64],
}

# TDP bands per model (W)
MODEL_TDP = {
    610: (20, 29),
    710: (19, 25),
    720: (19, 25),
    730: (23, 49),
    740: (49, 69),
    1010: (25, 35),
    1030: (25, 35),
}

# PSU suggestion minimal
def suggested_psu_for_gt(tdp: int) -> int:
    if tdp <= 30:
        return 250
    if tdp <= 50:
        return 300
    return 350


VENDOR_VARIANTS_GT = [
    'Low Profile', 'LP OC', 'Silent', 'Passive', 'Single Fan', 'Dual Fan'
]

NVIDIA_PARTNERS_PREFERRED = [
    'MSI', 'Asus', 'Gigabyte Technology', 'EVGA', 'Zotac', 'PNY', 'Palit', 'Gainward', 'KFA2', 'Colorful', 'Inno3D'
]


def _normalize_nominal(value: Any) -> Optional[str]:
    if value is None:
        return None
    if isinstance(value, (list, tuple)):
        s = '; '.join(str(x).strip() for x in value if str(x).strip())
    else:
        s = str(value).strip()
    if not s:
        return None
    if s.lower() in {'n/a', 'na', 'none', 'null', '-', '--'}:
        return None
    return s


def pick_available_vendors(vendors_map: Dict[str, int]) -> List[Tuple[str, int]]:
    vm_lower = {k.lower(): (k, vid) for k, vid in vendors_map.items()}
    chosen: List[Tuple[str, int]] = []
    for name in NVIDIA_PARTNERS_PREFERRED:
        hit = vm_lower.get(name.lower())
        if hit:
            chosen.append(hit)
    if 'nvidia' in vm_lower:
        chosen.append(vm_lower['nvidia'])
    unique = []
    seen = set()
    for name, vid in chosen:
        if vid not in seen:
            unique.append((name, vid))
            seen.add(vid)
    return unique[:VENDORS_PER_MODEL]


def map_gen_key(base_num: int) -> Optional[str]:
    if base_num // 100 == 6:
        return 'GT-600'
    if base_num // 100 == 7:
        return 'GT-700'
    if base_num // 100 == 10:  # 1010/1030
        return 'GT-1000'
    return None


def pick_outputs(gen_key: str) -> str:
    if gen_key in ('GT-600', 'GT-700'):
        return '1x VGA, 1x DVI, 1x HDMI 1.4'
    return '1x DVI, 1x HDMI 2.0, 1x DisplayPort 1.4'


def pick_connectors(base_num: int, tdp: int) -> str:
    # Most GT are bus-powered; 740 sometimes 6-pin
    if base_num == 740 and tdp >= 60:
        return '1x 6-pin'
    return 'None'


def directx_for(gen_key: str) -> str:
    return GEN_INFO_GT[gen_key]['directx']


def get_price(gen_key: str, level: int) -> float:
    base = PRICE_TABLE_GT[gen_key][max(0, min(level - 1, 2))]
    jitter = random.uniform(-0.15, 0.15)
    return round(base * (1 + jitter), 2)


def parse_seed_models() -> List[int]:
    models: List[int] = []
    if USE_URL_SEED and os.path.exists(URL_SEED_FILE):
        with open(URL_SEED_FILE, 'r') as f:
            for line in f:
                url = line.strip()
                if not url:
                    continue
                slug = url.rsplit('/', 1)[-1].split('.')[0]
                if not slug.startswith('geforce-gt-'):
                    continue
                digits = ''.join(ch for ch in slug if ch.isdigit())
                if len(digits) >= 3:
                    num = int(digits[-3:]) if len(digits) == 3 else int(digits[-4:])
                    # Normalize to known GT set
                    if num in MODEL_MEMORY:
                        models.append(num)
    if not models:
        # Fallback set
        models = [610, 710, 730, 740, 1010, 1030]
    return sorted(list({m for m in models}))


def make_products(vendors_map: Dict[str, int], categories_map: Dict[str, int], attributes_map: Dict[str, int]) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    gpu_category_id = categories_map.get('GPU')
    if not gpu_category_id:
        raise RuntimeError("GPU category not found. Run base entities population first.")

    partners = pick_available_vendors(vendors_map)
    if not partners:
        raise RuntimeError("No NVIDIA partners found in Vendors table.")

    base_models = parse_seed_models()

    products: List[Dict[str, Any]] = []
    attributes: List[Dict[str, Any]] = []

    for base_num in base_models:
        gen_key = map_gen_key(base_num)
        if not gen_key:
            continue
        info = GEN_INFO_GT[gen_key]

        mem_info = MODEL_MEMORY.get(base_num, {'sizes': [2], 'types': ['DDR3']})
        sizes = mem_info['sizes']
        types = mem_info['types']
        buses = MODEL_BUS.get(base_num, [64])
        tdp_range = MODEL_TDP.get(base_num, (20, 50))

        # Classify level within GT (1 low, 2 mid, 3 hi)
        if base_num in (610, 710, 720):
            level = 1
        elif base_num in (730, 740):
            level = 2
        else:
            level = 3  # 1010/1030

        for vendor_name, ven_id in partners:
            chosen_variants = random.sample(VENDOR_VARIANTS_GT, k=min(VARIANTS_PER_VENDOR, len(VENDOR_VARIANTS_GT)))
            for variant in chosen_variants:
                vram = random.choice(sizes)
                mem_type = random.choice(types)
                bus_bits = random.choice(buses)
                tdp = random.randint(*tdp_range)
                psu = suggested_psu_for_gt(tdp)
                slot = 'Single' if bus_bits == 64 and tdp <= 30 else 'Dual'
                length = random.randint(145, 190) if slot == 'Single' else random.randint(170, 225)
                height = random.randint(100, 120)
                width_mm = 35 if slot == 'Single' else 40
                base_clk = random.randint(800, 1200)
                boost_clk = base_clk + random.randint(50, 150)
                mem_clk = 1800 if mem_type in ('DDR3', 'DDR4') else 6000

                price = get_price(gen_key, level)
                display_name = f"{vendor_name} GeForce GT {base_num} {variant} {vram} GB"

                products.append({
                    'category_ID': gpu_category_id,
                    'product_NAME': display_name,
                    'product_DESCRIPT': f"{vendor_name} low-profile/HTPC oriented GT {base_num} variant {variant}.",
                    'product_PRICE': price,
                    'product_STOCK': random.randint(10, 80),
                    'ven_ID': ven_id,
                })

                def add_attr(key: str, value: Any):
                    att_id = attributes_map.get(key)
                    val = _normalize_nominal(value)
                    if att_id and val:
                        attributes.append({'product_NAME': display_name, 'att_ID': att_id, 'nominal': val, 'ven_ID': ven_id})

                add_attr('Architecture', info['arch'])
                add_attr('Process Size', info['process'])
                add_attr('DirectX', directx_for(gen_key))
                add_attr('VRAM', f"{vram} GB {mem_type}")
                add_attr('Memory Size', f"{vram} GB")
                add_attr('Memory Type', mem_type)
                add_attr('Bus Width', f"{bus_bits}-bit")
                add_attr('Memory Bus', f"{bus_bits}-bit")
                add_attr('GPU Clock', f"{base_clk} MHz")
                add_attr('Boost Clock', f"{boost_clk} MHz")
                add_attr('Memory Clock', f"{mem_clk} MHz")
                add_attr('TDP', f"{tdp} W")
                add_attr('Suggested PSU', f"{psu} W")
                add_attr('Slot Width', slot)
                add_attr('Length', f"{length} mm")
                add_attr('Height', f"{height} mm")
                add_attr('Width', f"{width_mm} mm")
                add_attr('Outputs', pick_outputs(gen_key))
                add_attr('Power Connectors', pick_connectors(base_num, tdp))
                add_attr('CUDA', 'Yes')
                # Codec blocks vary; keep conservative
                if gen_key in ('GT-1000',):
                    add_attr('NVENC', 'Yes')
                    add_attr('NVDEC', 'Yes')
                else:
                    add_attr('NVENC', 'No')
                    add_attr('NVDEC', 'No')
                # No RT/Tensor for GT series
                add_attr('RT Cores', 'No')
                add_attr('Tensor Cores', 'No')
                add_attr('Recommended Gaming Resolutions', '720p' if level <= 2 else '1080p')

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
        for a in attributes:
            pid = id_map.get((a['product_NAME'], a['ven_ID']))
            if pid and a.get('nominal'):
                final_attrs.append({'product_ID': pid, 'att_ID': a['att_ID'], 'nominal': a['nominal']})

        if final_attrs:
            attr_sql = "INSERT INTO ProductAttributes (product_ID, att_ID, nominal) VALUES (:product_ID, :att_ID, :nominal)"
            cur.executemany(attr_sql, final_attrs, batcherrors=False)

        conn.commit()
        print(f"Inserted {len(new_products)} GT products and {len(final_attrs)} attributes.")

    except Exception as e:
        if conn:
            conn.rollback()
        print(f"Error inserting GT GPUs. Rolled back. Details: {e}")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()


def main():
    print('--- NVIDIA GT GPU Data Generator ---')
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

    if 'GPU' not in categories_map:
        print('GPU category missing. Populate base entities first.')
        return

    products, attrs = make_products(vendors_map, categories_map, attributes_map)
    for i in range(0, len(products), BATCH_SIZE):
        chunk_products = products[i:i+BATCH_SIZE]
        names_in_chunk = {p['product_NAME'] for p in chunk_products}
        attrs_chunk = [a for a in attrs if a['product_NAME'] in names_in_chunk]
        insert_into_db(chunk_products, attrs_chunk)

    print('--- GT Generation finished ---')


if __name__ == '__main__':
    main()
