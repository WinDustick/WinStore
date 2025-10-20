import os
import sys
import random
from typing import List, Dict, Any, Optional, Tuple

# Make utils importable
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils import get_db_connection, load_ids


# --- Configuration ---
BATCH_SIZE = 100

PREFERRED_MOBO_VENDORS = [
    'Asus', 'ASUS', 'MSI', 'Gigabyte Technology', 'Gigabyte', 'ASRock', 'Biostar',
    'EVGA Corporation', 'Intel', 'Supermicro', 'Tyan', 'Foxconn', 'Pegatron'
]

VENDOR_LINES = {
    'ASUS': ['ROG Strix', 'TUF Gaming', 'PRIME', 'ProArt'],
    'Asus': ['ROG Strix', 'TUF Gaming', 'PRIME', 'ProArt'],
    'MSI': ['MEG', 'MPG', 'MAG', 'PRO'],
    'Gigabyte': ['AORUS', 'Gaming X', 'Ultra Durable', 'VISION'],
    'Gigabyte Technology': ['AORUS', 'Gaming X', 'Ultra Durable', 'VISION'],
    'ASRock': ['Taichi', 'Steel Legend', 'Phantom Gaming', 'Pro'],
    'Biostar': ['Racing', 'TB', 'Hi-Fi'],
    'EVGA Corporation': ['Dark', 'FTW'],
    'Intel': ['Desktop Board'],
    'Supermicro': ['SuperO'],
    'Tyan': ['Server'],
    'Foxconn': ['OEM'],
    'Pegatron': ['OEM']
}

FORM_FACTORS = {
    'Mini-ITX': {'size': (170, 170), 'mem_slots': 2},
    'Micro-ATX': {'size': (244, 244), 'mem_slots': 4},
    'ATX': {'size': (305, 244), 'mem_slots': 4},
    'Mini-STX': {'size': (147, 140), 'mem_slots': 2},
    'Thin Mini-ITX': {'size': (170, 170), 'mem_slots': 2},
    'XL-ATX': {'size': (345, 272), 'mem_slots': 4},
    'E-ATX': {'size': (305, 272), 'mem_slots': 4},
}


AMD_PLATFORMS = [
    {
        'name': 'AM5',
        'socket': 'AM5',
        'chipsets': ['X670E', 'X670', 'B650E', 'B650', 'A620'],
        'memory_types': ['DDR5'],
        'pcie': {
            'X670E': 'PCIe 5.0 (GPU + NVMe)',
            'B650E': 'PCIe 5.0 (GPU)',
            'B650': 'PCIe 4.0',
            'A620': 'PCIe 4.0 (limited)'
        },
        'release': '2022',
        'cpu_support': ['Ryzen 7000 (Zen 4)', 'Ryzen 9000 (Zen 5)']
    },
    {
        'name': 'AM4',
        'socket': 'AM4',
        'chipsets': [
            'X570', 'B550', 'A520',
            'X470', 'B450', 'A320',
            'X370', 'B350'
        ],
        'memory_types': ['DDR4'],
        'pcie': {
            'X570': 'PCIe 4.0 (GPU + NVMe)',
            'B550': 'PCIe 4.0 (GPU) / PCIe 3.0 (NVMe)',
            'A520': 'PCIe 3.0'
        },
        'release': '2017',
        'cpu_support': ['Ryzen 1000–5000 (Zen–Zen 3)']
    },
    {
        'name': 'FM2+',
        'socket': 'FM2+',
        'chipsets': ['A88X', 'A78', 'A68H', 'A58'],
        'memory_types': ['DDR3'],
        'pcie': {'A88X': 'PCIe 3.0'},
        'release': '2014',
        'cpu_support': ['A-Series (Kaveri, Godavari)', 'Athlon X4 800/900']
    },
    {
        'name': 'AM3+',
        'socket': 'AM3+',
        'chipsets': ['990FX', '990X', '970'],
        'memory_types': ['DDR3'],
        'pcie': {'990FX': 'PCIe 2.0'},
        'release': '2011',
        'cpu_support': ['FX-Series (Bulldozer / Piledriver)']
    }
]

INTEL_PLATFORMS = [
    {
        'name': 'LGA1700',
        'socket': 'LGA1700',
        'chipsets': ['Z790', 'Z690', 'B760', 'B660', 'H770', 'H610'],
        'memory_types': ['DDR5', 'DDR4'],
        'pcie': {
            'Z790': 'PCIe 5.0 (GPU) / PCIe 4.0 (NVMe)',
            'Z690': 'PCIe 5.0 (GPU) / PCIe 4.0 (NVMe)'
        },
        'release': '2021',
        'cpu_support': ['12th–14th Gen Core (Alder Lake–Raptor Lake–Arrow Lake)']
    },
    {
        'name': 'LGA1200',
        'socket': 'LGA1200',
        'chipsets': ['Z590', 'Z490', 'B560', 'B460', 'H510', 'H410'],
        'memory_types': ['DDR4'],
        'pcie': {'Z590': 'PCIe 4.0 (GPU + NVMe)', 'Z490': 'PCIe 3.0'},
        'release': '2020',
        'cpu_support': ['10th–11th Gen Core (Comet Lake / Rocket Lake)']
    },
    {
        'name': 'LGA1151-v2',
        'socket': 'LGA1151',
        'chipsets': ['Z390', 'Z370', 'B360', 'H370', 'H310'],
        'memory_types': ['DDR4'],
        'pcie': {'Z390': 'PCIe 3.0'},
        'release': '2017',
        'cpu_support': ['8th–9th Gen Core (Coffee Lake)']
    },
    {
        'name': 'LGA1151-v1',
        'socket': 'LGA1151',
        'chipsets': ['Z270', 'Z170', 'B250', 'H270', 'H110'],
        'memory_types': ['DDR4'],
        'pcie': {'Z170': 'PCIe 3.0'},
        'release': '2015',
        'cpu_support': ['6th–7th Gen Core (Skylake / Kaby Lake)']
    },
    {
        'name': 'LGA1150',
        'socket': 'LGA1150',
        'chipsets': ['Z97', 'Z87', 'B85', 'H97', 'H87', 'H81'],
        'memory_types': ['DDR3', 'DDR3L'],
        'pcie': {'Z97': 'PCIe 3.0'},
        'release': '2013',
        'cpu_support': ['4th–5th Gen Core (Haswell / Broadwell)']
    },
    {
        'name': 'LGA1155',
        'socket': 'LGA1155',
        'chipsets': ['Z77', 'Z68', 'P67', 'H77', 'H67', 'B75', 'H61'],
        'memory_types': ['DDR3'],
        'pcie': {'Z77': 'PCIe 3.0'},
        'release': '2011',
        'cpu_support': ['2nd–3rd Gen Core (Sandy Bridge / Ivy Bridge)']
    }
]

PLATFORMS = {
    'AMD': AMD_PLATFORMS,
    'Intel': INTEL_PLATFORMS
}


MEMORY_SUPPORT = {
    'DDR4': {'jedec': 3200, 'oc': [3600, 4000]},
    'DDR5': {'jedec': 5600, 'oc': [6000, 6400, 7200, 8000]},
    'DDR3': {'jedec': 1600, 'oc': [1866, 2133]},
    'DDR3L': {'jedec': 1600, 'oc': [1866]},
}


def _choice_weighted(items: List[Any], weights: Optional[List[float]] = None) -> Any:
    if not items:
        return None
    if weights and len(weights) == len(items):
        return random.choices(items, weights=weights, k=1)[0]
    return random.choice(items)


def pick_category_id(categories_map: Dict[str, int]) -> Optional[int]:
    # Prefer explicit names
    for name in ('Motherboard', 'Motherboards', 'Mainboard'):
        if name in categories_map:
            return categories_map[name]
    # Fallback by substring
    for k in categories_map.keys():
        if 'mother' in k.lower():
            return categories_map[k]
    return None


def pick_mobo_vendors(vendors_map: Dict[str, int]) -> List[Tuple[str, int]]:
    vm_lower = {k.lower(): (k, vid) for k, vid in vendors_map.items()}
    chosen: List[Tuple[str, int]] = []
    for name in PREFERRED_MOBO_VENDORS:
        hit = vm_lower.get(name.lower())
        if hit:
            chosen.append(hit)
    if chosen:
        return chosen
    # Fallback deterministic
    fallback = list(vendors_map.items())
    fallback.sort(key=lambda x: x[0].lower())
    return fallback[:10]


def vendor_line(vendor: str) -> str:
    for k, lines in VENDOR_LINES.items():
        if k.lower() == vendor.lower():
            return random.choice(lines)
    return ''


def pcie_string(platform: Dict[str, Any], chipset: str) -> str:
    extra = platform.get('pcie', {}).get(chipset)
    if extra:
        return extra
    # Defaults
    if platform['socket'] in ('AM5', 'LGA1700'):
        return 'PCIe 4.0 (GPU) / PCIe 4.0 (NVMe)'
    return 'PCIe 3.0 (GPU) / PCIe 3.0 (NVMe)'


def m2_slots_for(form: str, chipset: str) -> int:
    base = 2 if form in ('Mini-ITX',) else 3 if form == 'Micro-ATX' else 4
    if chipset in ('X670E', 'Z790', 'X570'):
        base += 1
    return min(base, 5)


def pcie_slots_string(form: str, chipset: str) -> str:
    # Simplified but plausible slot layout
    if form == 'Mini-ITX':
        return '1 x PCIe x16'
    if form == 'Micro-ATX':
        return '1 x PCIe x16, 1 x PCIe x16 (x4), 1 x PCIe x1'
    # ATX/E-ATX
    return '2 x PCIe x16 (x16/x4), 2 x PCIe x1'


def features_for(chipset: str, wifi: bool) -> str:
    feats = []
    if wifi:
        feats.append('Wi‑Fi 6E')
        feats.append('Bluetooth 5.3')
    feats.append('2.5G LAN')
    feats.append('USB-C Front Header')
    if chipset in ('X670E', 'Z790', 'X570'):
        feats.append('PCIe 5.0 Ready')
    feats.append('ARGB Headers')
    return '; '.join(feats)


def power_connectors_for(chipset: str) -> str:
    if chipset in ('X670E', 'Z790', 'X570'):
        return '24-pin ATX; 8+4-pin EPS'
    return '24-pin ATX; 8-pin EPS'


def price_for(chipset: str, form: str, has_wifi: bool) -> float:
    tier = {'Z790': 320, 'X670E': 360, 'X670': 300, 'B650E': 270, 'B650': 220, 'A620': 130,
            'Z690': 260, 'H770': 220, 'B760': 180, 'X570': 250, 'B550': 160, 'A520': 120}
    base = tier.get(chipset, 180)
    form_add = {'Mini-ITX': 40, 'Micro-ATX': 0, 'ATX': 30, 'E-ATX': 80}.get(form, 0)
    wifi_add = 30 if has_wifi else 0
    jitter = random.uniform(-0.08, 0.08)
    return round((base + form_add + wifi_add) * (1 + jitter), 2)


def make_mobo_products(vendors_map: Dict[str, int], categories_map: Dict[str, int], attributes_map: Dict[str, int]) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    cat_id = pick_category_id(categories_map)
    if not cat_id:
        raise RuntimeError('Motherboard category not found. Add a Motherboard category first.')

    vendors = pick_mobo_vendors(vendors_map)
    if not vendors:
        raise RuntimeError('No suitable motherboard vendors found.')

    products: List[Dict[str, Any]] = []
    attributes: List[Dict[str, Any]] = []

    def add_attr(pname: str, ven_id: int, key: str, value: Any):
        att_id = attributes_map.get(key)
        if att_id is None:
            return
        s = None
        if value is None:
            s = None
        elif isinstance(value, (list, tuple)):
            s = '; '.join(str(x).strip() for x in value if str(x).strip())
        else:
            s = str(value).strip()
        if s and s.lower() not in {'n/a', 'na', 'none', 'null', '-', '--'}:
            attributes.append({'product_NAME': pname, 'att_ID': att_id, 'nominal': s, 'ven_ID': ven_id})

    seen_names: set[Tuple[int, str]] = set()

    # Iterate across all vendor platforms (AMD, Intel)
    for vendor_platforms in PLATFORMS.values():
        for platform in vendor_platforms:
            for chipset in platform['chipsets']:
                for mem_type in platform['memory_types']:
                    for form in FORM_FACTORS.keys():
                        mem_slots = FORM_FACTORS[form]['mem_slots']
                        length, width = FORM_FACTORS[form]['size']
                        mspec = MEMORY_SUPPORT.get(mem_type, {'jedec': 3200, 'oc': []})
                        max_mem_per_slot = 48 if mem_type == 'DDR5' else 32
                        max_memory = max_mem_per_slot * mem_slots

                        for vendor_name, ven_id in vendors:
                            line = vendor_line(vendor_name)
                            has_wifi = random.random() < (0.7 if form in ('Mini-ITX', 'ATX') else 0.4)
                            pcie = pcie_string(platform, chipset)
                            m2_slots = m2_slots_for(form, chipset)
                            pcie_slots = pcie_slots_string(form, chipset)
                            feats = features_for(chipset, has_wifi)
                            power_con = power_connectors_for(chipset)
                            price = price_for(chipset, form, has_wifi)

                            # Name
                            wifi_tag = ' WIFI' if has_wifi else ''
                            series = f" {line}" if line and line != 'OEM' else ''
                            display_name = f"{vendor_name}{series} {chipset} {form}{wifi_tag}"

                            if (ven_id, display_name) in seen_names:
                                continue
                            seen_names.add((ven_id, display_name))

                            products.append({
                                'category_ID': cat_id,
                                'product_NAME': display_name,
                                'product_DESCRIPT': f"{vendor_name} {line} motherboard {chipset} {form}. Socket {platform['socket']}, {mem_type} up to {mspec['jedec']} MT/s JEDEC, OC up to {max(mspec['oc']) if mspec['oc'] else mspec['jedec']} MT/s. {feats}.",
                                'product_PRICE': price,
                                'product_STOCK': random.randint(5, 60),
                                'ven_ID': ven_id,
                            })

                            # Attributes (guard duplicates per product)
                            added = set()
                            def add_once(key: str, value: Any):
                                if key in added:
                                    return
                                added.add(key)
                                add_attr(display_name, ven_id, key, value)

                            add_once('Socket', platform['socket'])
                            add_once('Chipset', chipset)
                            add_once('Form Factor', form)
                            add_once('Memory Type', mem_type)
                            add_once('Memory Support', f"JEDEC {mspec['jedec']} MT/s; OC up to {max(mspec['oc']) if mspec['oc'] else mspec['jedec']} MT/s")
                            add_once('Memory Slots', str(mem_slots))
                            add_once('Max Memory', f"{max_memory} GB")
                            add_once('PCIe Slots', pcie_slots)
                            add_once('PCI-Express', pcie)
                            add_once('M.2 Slots', str(m2_slots))
                            add_once('Features', feats)
                            add_once('Power Connectors', power_con)
                            add_once('Length', f"{length} mm")
                            add_once('Width', f"{width} mm")
                            add_once('Part#', f"{vendor_name[:4].upper()}-{chipset}-{form.replace('-', '')}")

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
        print(f"Error inserting Motherboards. Rolled back. Details: {e}")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()


def main():
    print('--- Motherboard Data Generator ---')
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
        print('Motherboard category missing. Populate base entities first (add Motherboard category).')
        return

    products, attrs = make_mobo_products(vendors_map, categories_map, attributes_map)
    print(f'Prepared {len(products)} products and {len(attrs)} attributes for insertion.')
    for i in range(0, len(products), BATCH_SIZE):
        chunk_products = products[i:i+BATCH_SIZE]
        names_in_chunk = {p['product_NAME'] for p in chunk_products}
        attrs_chunk = [a for a in attrs if a['product_NAME'] in names_in_chunk]
        insert_into_db(chunk_products, attrs_chunk)

    print('--- Motherboard Generation finished ---')


if __name__ == '__main__':
    main()
