import os
import sys
import random
from typing import List, Dict, Any, Optional, Tuple

# Make utils importable
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils import get_db_connection, load_ids


# --- Configuration ---
BATCH_SIZE = 100

PREFERRED_PSU_VENDORS = [
    'Seasonic', 'Sea Sonic', 'Super Flower', 'Corsair', 'EVGA Corporation', 'EVGA', 'Cooler Master',
    'be quiet!', 'FSP Group', 'Thermaltake', 'Chieftec', 'Antec', 'XFX', 'Gigabyte Technology', 'Gigabyte', 'MSI',
    'SilverStone', 'NZXT'
]

VENDOR_SERIES = {
    'Seasonic': [
        'PRIME TX', 'PRIME PX', 'PRIME GX', 'PRIME Fanless',
        'FOCUS GX', 'FOCUS PX', 'FOCUS GM', 'FOCUS SGX',
        'CORE GX', 'CORE GM', 'CORE GC'
    ],
    'Super Flower': [
        'LEADEX VII', 'LEADEX VI', 'LEADEX V', 'LEADEX Platinum',
        'Hydro G Pro', 'Hydro PTM', 'LEGION', 'SF', 'Golden King'
    ],
    'Corsair': [
        'AX', 'HX', 'HXi', 'RMx', 'RMe', 'RM', 'RMi',
        'TX', 'TX-M', 'CX', 'CX-M', 'VS', 'SF', 'SF-L',
        'RM SHIFT', 'HX SHIFT', 'AXi'
    ],
    'EVGA': [
        'SuperNOVA G', 'SuperNOVA P', 'SuperNOVA T', 'SuperNOVA GT',
        'SuperNOVA G2', 'SuperNOVA G3', 'SuperNOVA G5', 'SuperNOVA G6',
        'SuperNOVA P2', 'SuperNOVA T2', 'BQ', 'BT', 'BR', 'W1'
    ],
    'Cooler Master': [
        'V SFX', 'V Gold', 'V Platinum', 'V2', 'V Modular',
        'GX Gold', 'GX III', 'MWE', 'MWE Bronze', 'MWE Gold', 'MWE White',
        'MasterWatt', 'MasterWatt Lite', 'XG Plus Platinum', 'XG850 Plus'
    ],
    'be quiet!': [
        'Dark Power Pro', 'Dark Power', 'Straight Power', 'Pure Power',
        'System Power', 'SFX Power', 'TFX Power', 'Dark Power 13', 'Pure Power 12M'
    ],
    'FSP Group': [
        'Hydro PTM', 'Hydro PTM Pro', 'Hydro G Pro', 'Hydro Ti Pro',
        'Hydro M', 'Hydro K', 'Hydro GT Pro', 'Hydro PTM X Pro',
        'Dagger', 'Dagger Pro', 'HV Pro', 'Hexa', 'Hexa 85+', 'Aurora', 'CMT'
    ],
    'Thermaltake': [
        'Toughpower PF3', 'Toughpower GF3', 'Toughpower GX1', 'Toughpower Grand RGB',
        'Smart', 'Smart BX1', 'Smart RGB', 'Smart Pro RGB', 'Litepower', 'TR2',
        'Smart BM2', 'Smart BM3', 'Smart DPS G', 'Smart BX2'
    ],
    'Chieftec': [
        'PROTON', 'PowerPlay', 'A-90', 'Force', 'Polaris', 'Polaris 3.0',
        'SteelPower', 'Eco', 'Eco Series', 'Arena', 'Nitro', 'Smart', 'Compact'
    ],
    'Antec': [
        'HCG', 'HCG Extreme', 'HCG Gold', 'EarthWatts Gold Pro', 'EarthWatts Platinum',
        'NeoECO', 'NeoECO Gold', 'NeoECO Platinum', 'Signature', 'VP', 'VP Plus'
    ],
    'XFX': [
        'ProSeries', 'TS', 'XT', 'XTR', 'XTR2', 'XTR3', 'XTi', 'Core Edition', 'Black Edition'
    ],
    'Gigabyte': [
        'AORUS P', 'AORUS AP', 'UD Gold', 'UD Bronze', 'P', 'GP', 'PB', 'GP-P'
    ],
    'MSI': [
        'MPG A', 'MAG A', 'MEG Ai', 'MPG GF', 'MAG GF', 'A850G', 'A1000G', 'A850GL', 'A750BN'
    ],
    'NZXT': [
        'C', 'C Gold', 'C Bronze', 'E', 'H', 'P', 'E850 Digital'
    ],
    'SilverStone': [
        'Strider Platinum', 'Strider Gold', 'Strider Essential', 'Strider Titanium',
        'Decathlon', 'SFX', 'SX', 'DA', 'ET', 'ST', 'Heligon', 'Nightjar (Fanless)'
    ],
    'Fractal Design': [
        'Ion+', 'Ion Platinum', 'Ion Gold', 'Ion SFX-L', 'Anode', 'Newton R3'
    ],
    'Enermax': [
        'Revolution DF', 'Revolution D.F. X', 'MaxTytan', 'Platimax', 'Platimax D.F.',
        'MarbleBron', 'CyberBron', 'Revolution XT', 'Revolution ATX 3.0'
    ],
    'ASUS': [
        'ROG THOR', 'ROG LOKI', 'TUF Gaming', 'Prime', 'ROG STRIX'
    ],
    'ASRock': [
        'PG', 'PG Gold', 'PG Silver', 'PG Platinum'
    ],
    'Montech': [
        'Century', 'Titan Gold', 'Gamma', 'Beta', 'Air', 'Metal'
    ],
    'DeepCool': [
        'PQ', 'PM', 'PX', 'PF', 'DA', 'DQ-M', 'DQ-U', 'DQ-G', 'DN', 'DN-M', 'PK', 'PG'
    ],
    'ADATA': [
        'XPG Core Reactor', 'XPG Kyber', 'XPG CyberCore', 'XPG Pylon'
    ],
    'Seasonic Industrial': [
        'IPC', 'TFX', 'Flex ATX', 'Industrial Series'
    ]
}


WATTAGE_TIERS = [450, 550, 650, 750, 850, 1000, 1200, 1300, 1600]

EFFICIENCY_LEVELS = {
    '80 PLUS Bronze': 1.00,
    '80 PLUS Silver': 1.05,
    '80 PLUS Gold': 1.15,
    '80 PLUS Platinum': 1.35,
    '80 PLUS Titanium': 1.60,
}

MODULARITY_LEVELS = [
    ('Non-Modular', 1.00),
    ('Semi-Modular', 1.10),
    ('Fully Modular', 1.20),
]

FORM_FACTORS = {
    'ATX': {'w': 150, 'h': 86, 'l_range': (140, 180), 'mult': 1.00},
    'SFX': {'w': 125, 'h': 63.5, 'l_range': (100, 100), 'mult': 1.25},
    'SFX-L': {'w': 125, 'h': 63.5, 'l_range': (125, 130), 'mult': 1.35},
}

BASE_PRICE_BY_WATT = {
    450: 45, 550: 60, 650: 80, 750: 100, 850: 120, 1000: 180, 1200: 230, 1300: 260, 1600: 320
}


def pick_category_id(categories_map: Dict[str, int]) -> Optional[int]:
    for name in ('Power Supply', 'Power Supplies', 'PSU', 'Power Supply Unit'):
        if name in categories_map:
            return categories_map[name]
    # Fallback by substring
    for k in categories_map.keys():
        lk = k.lower()
        if 'power' in lk and 'supply' in lk:
            return categories_map[k]
    return None


def pick_psu_vendors(vendors_map: Dict[str, int]) -> List[Tuple[str, int]]:
    vm_lower = {k.lower(): (k, vid) for k, vid in vendors_map.items()}
    chosen: List[Tuple[str, int]] = []
    for name in PREFERRED_PSU_VENDORS:
        hit = vm_lower.get(name.lower())
        if hit:
            chosen.append(hit)
    if chosen:
        return chosen
    # Fallback deterministic sample
    fallback = list(vendors_map.items())
    fallback.sort(key=lambda x: x[0].lower())
    return fallback[:10]


def vendor_series(vendor: str) -> str:
    for k, lines in VENDOR_SERIES.items():
        if k.lower() == vendor.lower():
            return random.choice(lines)
    return ''


def atx_version_for(watt: int, efficiency: str) -> str:
    # Higher chance of ATX 3.x on higher watt and higher efficiency
    base = 0.15
    base += 0.2 if watt >= 750 else 0
    base += 0.15 if efficiency in ('80 PLUS Platinum', '80 PLUS Titanium') else 0
    if random.random() < min(base, 0.8):
        return 'ATX 3.0' if random.random() < 0.6 else 'ATX 3.1'
    return 'ATX 2.4'


def connectors_for(watt: int, form: str, atx_version: str) -> Dict[str, int]:
    # Baseline counts by wattage
    pcie_map = [
        (500, 2), (650, 3), (750, 4), (900, 4), (1100, 6), (1300, 8), (10_000, 8)
    ]
    pcie = 2
    for limit, count in pcie_map:
        if watt <= limit:
            pcie = count
            break
    eps = 1 if watt <= 650 else 2
    sata = 4 if watt <= 550 else 8 if watt <= 850 else 10
    molex = 2 if watt <= 650 else 4

    if form == 'SFX':
        sata = max(3, sata - 2)
        molex = max(1, molex - 1)
        pcie = max(2, pcie - 1)

    hpwr = 0
    if atx_version in ('ATX 3.0', 'ATX 3.1') and watt >= 650:
        hpwr = 1

    return {
        'ATX24': 1,
        'EPS8': eps,
        'PCIe6+2': pcie,
        '12VHPWR': hpwr,
        'SATA': sata,
        'Molex': molex
    }


def fan_for(form: str, efficiency: str) -> Tuple[str, str]:
    if form == 'SFX':
        size = '92 mm'
        rpm_max = 2200
    elif form == 'SFX-L':
        size = '120 mm'
        rpm_max = 2000
    else:
        size = random.choice(['120 mm', '135 mm'])
        rpm_max = 1800
    silent_bias = 1 if efficiency in ('80 PLUS Gold', '80 PLUS Platinum', '80 PLUS Titanium') else 0
    rpm_max = int(rpm_max * (0.9 if silent_bias else 1.0))
    rpm = f"0–{rpm_max} RPM (Zero RPM mode)" if silent_bias else f"Up to {rpm_max} RPM"
    noise = 'Up to 24 dBA' if silent_bias else 'Up to 30 dBA'
    return rpm, noise


def price_for(watt: int, efficiency: str, modularity: str, form: str, atx_version: str) -> float:
    base = BASE_PRICE_BY_WATT.get(watt, 100)
    eff_mult = EFFICIENCY_LEVELS[efficiency]
    mod_mult = dict(MODULARITY_LEVELS)[modularity]
    form_mult = FORM_FACTORS[form]['mult']
    hpwr_add = 15 if atx_version in ('ATX 3.0', 'ATX 3.1') else 0
    price = (base * eff_mult * mod_mult * form_mult) + hpwr_add
    jitter = random.uniform(-0.07, 0.07)
    return round(price * (1 + jitter), 2)


def make_psu_products(vendors_map: Dict[str, int], categories_map: Dict[str, int], attributes_map: Dict[str, int]) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    cat_id = pick_category_id(categories_map)
    if not cat_id:
        raise RuntimeError('Power Supply category not found. Add a PSU category first.')

    vendors = pick_psu_vendors(vendors_map)
    if not vendors:
        raise RuntimeError('No suitable PSU vendors found.')

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

    for vendor_name, ven_id in vendors:
        series = vendor_series(vendor_name)
        for form in FORM_FACTORS.keys():
            for efficiency in EFFICIENCY_LEVELS.keys():
                for modularity, _ in MODULARITY_LEVELS:
                    # Keep SFX mostly in mid-watt range
                    watts = [w for w in WATTAGE_TIERS if (
                        (form == 'SFX' and 450 <= w <= 850) or (form == 'SFX-L' and 550 <= w <= 1000) or (form == 'ATX')
                    )]
                    # Sample a subset per vendor/series/form/eff/modularity to avoid explosion
                    sample_count = 4 if form == 'ATX' else 2
                    sampled_watts = random.sample(watts, k=min(sample_count, len(watts)))

                    for watt in sampled_watts:
                        atx_v = atx_version_for(watt, efficiency)
                        size = FORM_FACTORS[form]
                        length = random.randint(size['l_range'][0], size['l_range'][1])
                        rpm, noise = fan_for(form, efficiency)
                        con = connectors_for(watt, form, atx_v)

                        # Name
                        ser = f" {series}" if series else ''
                        display_name = f"{vendor_name}{ser} {watt}W {modularity} {form} {efficiency}"
                        if (ven_id, display_name) in seen_names:
                            continue
                        seen_names.add((ven_id, display_name))

                        price = price_for(watt, efficiency, modularity, form, atx_v)

                        # Product row
                        products.append({
                            'category_ID': cat_id,
                            'product_NAME': display_name,
                            'product_DESCRIPT': (
                                f"{vendor_name} {series} {watt}W {form} PSU, {modularity}, {efficiency}, {atx_v}. "
                                f"Connectors: 24-pin, {con['EPS8']}x EPS 8-pin, {con['PCIe6+2']}x PCIe 6+2, "
                                + (f"{con['12VHPWR']}x 12VHPWR, " if con['12VHPWR'] else '')
                                + f"{con['SATA']}x SATA, {con['Molex']}x Molex. Noise: {noise}."
                            ),
                            'product_PRICE': price,
                            'product_STOCK': random.randint(8, 80),
                            'ven_ID': ven_id,
                        })

                        # Attributes (guard duplicates per product)
                        added = set()

                        def add_once(key: str, value: Any):
                            if key in added:
                                return
                            added.add(key)
                            add_attr(display_name, ven_id, key, value)

                        add_once('Wattage', f"{watt} W")
                        add_once('Efficiency Rating', efficiency)
                        add_once('Modularity', modularity)
                        add_once('Form Factor', form)
                        add_once('Type', atx_v)
                        add_once('Power Connectors', (
                            f"1 x 24-pin ATX; {con['EPS8']} x 8-pin EPS; {con['PCIe6+2']} x 6+2-pin PCIe; "
                            + (f"{con['12VHPWR']} x 12VHPWR (600W); " if con['12VHPWR'] else '')
                            + f"{con['SATA']} x SATA; {con['Molex']} x Molex"
                        ))
                        add_once('Fan RPM', rpm)
                        add_once('Noise Level', noise)
                        add_once('Length', f"{length} mm")
                        add_once('Width', f"{size['w']} mm")
                        add_once('Height', f"{size['h']} mm")
                        features = ['Active PFC', 'Over/Under Voltage Protection', 'Short Circuit Protection', 'Over Power Protection', 'DC-DC topology']
                        if efficiency in ('80 PLUS Gold', '80 PLUS Platinum', '80 PLUS Titanium'):
                            features.append('Zero RPM Fan Mode')
                            features.append('100% Japanese Capacitors')
                        if atx_v in ('ATX 3.0', 'ATX 3.1') and con['12VHPWR']:
                            features.append('Native 12VHPWR Cable')
                        warranty = random.choice(['7-year warranty', '10-year warranty'])
                        features.append(warranty)
                        add_once('Features', '; '.join(features))

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
        print(f"Error inserting PSUs. Rolled back. Details: {e}")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()


def main():
    print('--- PSU Data Generator ---')
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
        print('PSU category missing. Populate base entities first (add Power Supply category).')
        return

    products, attrs = make_psu_products(vendors_map, categories_map, attributes_map)
    print(f'Prepared {len(products)} products and {len(attrs)} attributes for insertion.')
    for i in range(0, len(products), BATCH_SIZE):
        chunk_products = products[i:i+BATCH_SIZE]
        names_in_chunk = {p['product_NAME'] for p in chunk_products}
        attrs_chunk = [a for a in attrs if a['product_NAME'] in names_in_chunk]
        insert_into_db(chunk_products, attrs_chunk)

    print('--- PSU Generation finished ---')


if __name__ == '__main__':
    main()
