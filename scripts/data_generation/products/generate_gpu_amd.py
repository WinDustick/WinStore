import os
import sys
import random
from typing import List, Dict, Any, Optional, Tuple

# Make utils importable
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils import get_db_connection, load_ids


# --- Configuration ---
VENDORS_PER_MODEL = 10
BATCH_SIZE = 100
DEFAULT_FALLBACK_VARIANTS = 3  # used only for vendors without specific variant mapping

USE_URL_SEED = True
URL_SEED_FILE = os.path.join(os.path.dirname(__file__), '..', 'gpu_links', 'gpu_amd.txt')


# --- Domain models ---
PRICE_TABLE = {
    # tiers: x500, x600, x700, x800, x900
    'RX-400': [169, 239, 349, 429],     # Polaris 10/11
    'RX-500': [149, 229, 329, 399],     # Polaris refresh
    'RX-Vega': [399, 499, 699, 999],    # Vega 56/64
    'RX-5000': [179, 299, 399, 499],    # RDNA 1.0
    'RX-6000': [199, 369, 579, 999],    # RDNA 2.0
    'RX-7000': [269, 449, 599, 999],    # RDNA 3.0
    'Radeon PRO': [399, 699, 999, 1599], # Workstation cards
}


GEN_INFO = {
    'RX-400': {
        'arch': 'GCN 4.0 (Polaris)',
        'process': '14 nm',
        'directx': '12 (FL 12_0)',
        'memory_types': ['GDDR5']
    },
    'RX-500': {
        'arch': 'GCN 4.1 (Polaris Refresh)',
        'process': '14 nm',
        'directx': '12 (FL 12_0)',
        'memory_types': ['GDDR5']
    },
    'RX-Vega': {
        'arch': 'GCN 5.0 (Vega)',
        'process': '14 nm',
        'directx': '12 (FL 12_1)',
        'memory_types': ['HBM2']
    },
    'RX-5000': {
        'arch': 'RDNA 1.0 (Navi 10)',
        'process': '7 nm',
        'directx': '12 (FL 12_1)',
        'memory_types': ['GDDR6']
    },
    'RX-6000': {
        'arch': 'RDNA 2.0 (Navi 21)',
        'process': '7 nm',
        'directx': '12 Ultimate',
        'memory_types': ['GDDR6']
    },
    'RX-7000': {
        'arch': 'RDNA 3.0 (Navi 31)',
        'process': '5 nm',
        'directx': '12 Ultimate',
        'memory_types': ['GDDR6']
    },
    'Radeon PRO': {
        'arch': 'RDNA / RDNA 2 / RDNA 3 (varies)',
        'process': '7–5 nm',
        'directx': '12 Ultimate',
        'memory_types': ['GDDR6 ECC']
    }
}


TIER_DEF = {
    'x500': {
        'cls': 0,
        'vram_gb': [4, 8],
        'bus_bits': [128],
        'tdp': (75, 120),
        'psu': (350, 500),
        'slot': ['Single', 'Dual'],
        'length_mm': (170, 250),
        'base_boost': (1300, 2100)
    },
    'x600': {
        'cls': 1,
        'vram_gb': [8, 12],
        'bus_bits': [128],
        'tdp': (100, 180),
        'psu': (450, 600),
        'slot': ['Dual'],
        'length_mm': (200, 270),
        'base_boost': (1600, 2500),
    },
    'x700': {
        'cls': 2,
        'vram_gb': [8, 12, 16],
        'bus_bits': [192, 256],
        'tdp': (160, 260),
        'psu': (550, 750),
        'slot': ['Dual', 'Triple'],
        'length_mm': (240, 320),
        'base_boost': (1700, 2600),
    },
    'x800': {
        'cls': 3,
        'vram_gb': [16],
        'bus_bits': [256],
        'tdp': (220, 320),
        'psu': (650, 850),
        'slot': ['Triple'],
        'length_mm': (260, 340),
        'base_boost': (1800, 2700),
    },
    'x900': {
        'cls': 4,
        'vram_gb': [20, 24],
        'bus_bits': [320, 384],
        'tdp': (300, 380),
        'psu': (700, 1000),
        'slot': ['Triple'],
        'length_mm': (280, 350),
        'base_boost': (1900, 2800),
    },
}

SERIES_ORDER = [
    ('RX-400', 'RX', [460, 470, 480]),
    ('RX-500', 'RX', [550, 560, 570, 580, 590]),
    ('RX-Vega', 'RX', ['Vega 56', 'Vega 64']),
    ('RX-5000', 'RX', [5300, 5500, 5600, 5700]),
    ('RX-6000', 'RX', [6400, 6500, 6600, 6700, 6800, 6900]),
    ('RX-7000', 'RX', [7600, 7700, 7800, 7900]),
    ('Radeon PRO', 'PRO', ['W5500', 'W5700', 'W6600', 'W6800', 'W7900'])
]


VENDOR_VARIANTS = [
    'Pulse', 'Nitro+', 'Red Devil', 'Hellhound', 'Gaming Trio', 'Ventus 3X', 'TUF Gaming', 'ROG Strix',
    'Challenger', 'Phantom Gaming', 'AERO', 'Eagle', 'Gaming OC', 'Steel Legend', 'MERC', 'QICK'
]

AMD_PARTNERS_PREFERRED = [
    'Sapphire', 'PowerColor', 'XFX', 'ASRock', 'Asus', 'MSI', 'Gigabyte', 'Biostar', 'Yeston', 'Colorful'
]

# Vendor-specific variant families (case-insensitive match)
AMD_VENDOR_VARIANTS: Dict[str, List[str]] = {
    'Sapphire': ['Nitro', 'Nitro+', 'Pulse', 'Tri-X', 'Dual-X', 'Toxic'],
    'PowerColor': ['Red Devil', 'Hellhound', 'Red Dragon', 'Fighter', 'StormX', 'Liquid Devil', 'VIPER'],
    'XFX': ['Merc', 'Speedster', 'Thicc', 'QICK', 'SWFT', 'Ultra'],
    'ASRock': ['Challenger', 'Phantom Gaming', 'Taichi', 'Steel Legend', 'Aqua'],
    'ASUS': ['ROG Strix', 'TUF Gaming', 'Dual', 'Phoenix', 'KO', 'Turbo'],
    'MSI': ['Gaming X', 'Gaming', 'Ventus', 'Mech', 'Suprim', 'Armor', 'Sea Hawk'],
    'Gigabyte': ['Eagle', 'Gaming OC', 'AORUS', 'WindForce', 'Vision', 'Turbo'],
    'Biostar': ['Racing', 'TB', 'Advanced'],
    'Yeston': ['IceStorm', 'Gamer', 'Pro'],
    'Colorful': ['iGame', 'Ultra', 'Neptune', 'BattleAx', 'Vulcan'],
}

def variants_for_vendor(vendor_name: str) -> List[str]:
    key_lower = vendor_name.lower()
    for k, vs in AMD_VENDOR_VARIANTS.items():
        if k.lower() == key_lower:
            return vs
    # Handle common alias: Asus vs ASUS
    if key_lower == 'asus' and 'ASUS' in AMD_VENDOR_VARIANTS:
        return AMD_VENDOR_VARIANTS['ASUS']
    return VENDOR_VARIANTS

def vendor_has_specific_variants(vendor_name: str) -> bool:
    key_lower = vendor_name.lower()
    if key_lower == 'asus' and 'ASUS' in AMD_VENDOR_VARIANTS:
        return True
    return any(k.lower() == key_lower for k in AMD_VENDOR_VARIANTS.keys())


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
    for name in AMD_PARTNERS_PREFERRED:
        hit = vm_lower.get(name.lower())
        if hit:
            chosen.append(hit)
    # Include AMD reference if present
    if 'amd' in vm_lower:
        chosen.append(vm_lower['amd'])
    # Dedup and limit
    unique: List[Tuple[str, int]] = []
    seen = set()
    for nm, vid in chosen:
        if vid not in seen:
            unique.append((nm, vid))
            seen.add(vid)
    if unique:
        return unique[:VENDORS_PER_MODEL]
    # Fallback: pick first vendors in map deterministically
    fallback = list(vendors_map.items())
    fallback.sort(key=lambda x: x[0].lower())
    return [(nm, vid) for nm, vid in fallback[:VENDORS_PER_MODEL]]


def classify_tier(num: int) -> str:
    rem = num % 100
    if rem in (60,):
        return 'x600'
    if rem in (70,):
        return 'x700'
    if rem in (80,):
        return 'x800'
    if rem in (90,):
        return 'x900'
    return 'x700'


def derive_memory_options(gen_key: str, tier_key: str, base_num: int) -> List[int]:
    opts = TIER_DEF[tier_key]['vram_gb'][:]
    if gen_key == 'RX-6000':
        if base_num == 6600:
            return [8]
        if base_num == 6700:
            return [10, 12]
        if base_num == 6800:
            return [16]
        if base_num == 6900:
            return [16]
    if gen_key == 'RX-7000':
        if base_num == 7600:
            return [8, 12]
        if base_num == 7700:
            return [12]
        if base_num == 7800:
            return [16]
        if base_num == 7900:
            return [20, 24]
    return opts


def memory_type_for(gen_key: str) -> str:
    return GEN_INFO[gen_key]['memory_types'][-1]


def bus_width_for(gen_key: str, tier_key: str, base_num: int, vram: int) -> int:
    if gen_key == 'RX-7000':
        if base_num == 7600:
            return 128
        if base_num == 7700:
            return 192
        if base_num == 7800:
            return 256
        if base_num == 7900:
            return 320 if vram == 20 else 384
    if gen_key == 'RX-6000':
        if base_num == 6600:
            return 128
        if base_num == 6700:
            return 160 if 10 in derive_memory_options(gen_key, tier_key, base_num) else 192
        if base_num == 6800:
            return 256
        if base_num == 6900:
            return 256
    return random.choice(TIER_DEF[tier_key]['bus_bits'])


def suggested_psu_for(tdp: int, gen_key: str) -> int:
    base = 450 if tdp <= 180 else 650 if tdp <= 260 else 750 if tdp <= 320 else 850
    return base


def outputs_for(gen_key: str, base_num: int) -> str:
    if gen_key == 'RX-7000':
        # Many RDNA3 cards: DP 2.1 + HDMI 2.1a
        return '1x HDMI 2.1a, 2x DisplayPort 2.1, 1x USB Type-C'
    # RDNA2 typical
    return '1x HDMI 2.1, 3x DisplayPort 1.4a'


def bus_interface_for(gen_key: str) -> str:
    if gen_key in ('RX-6000', 'RX-7000'):
        return 'PCIe 4.0 x16'
    return 'PCIe 3.0 x16'


def api_caps_for(gen_key: str) -> Dict[str, str]:
    if gen_key == 'RX-5000':
        return {'OpenGL': '4.6', 'OpenCL': '2.1', 'Vulkan': '1.2', 'Shader Model': '6.5'}
    if gen_key == 'RX-6000':
        return {'OpenGL': '4.6', 'OpenCL': '2.2', 'Vulkan': '1.3', 'Shader Model': '6.6'}
    if gen_key == 'RX-7000':
        return {'OpenGL': '4.6', 'OpenCL': '3.0', 'Vulkan': '1.3', 'Shader Model': '6.8'}
    return {'OpenGL': '4.6', 'OpenCL': '2.1', 'Vulkan': '1.2', 'Shader Model': '6.5'}


def foundry_for(_: str) -> str:
    return 'TSMC'


def process_type_for(_: str) -> str:
    return 'FinFET'


def format_bandwidth(mem_clk_mhz: int, bus_bits: int) -> str:
    gbps = mem_clk_mhz / 1000.0
    gb_per_s = gbps * (bus_bits / 8.0)
    return f"{gb_per_s:.0f} GB/s" if gb_per_s < 1000 else f"{gb_per_s/1000:.2f} TB/s"


def price_for(gen_key: str, tier_key: str) -> float:
    tier_index = {'x600': 0, 'x700': 1, 'x800': 2, 'x900': 3}[tier_key]
    base = PRICE_TABLE.get(gen_key, PRICE_TABLE['RX-6000'])[tier_index]
    jitter = random.uniform(-0.12, 0.12)
    return round(base * (1 + jitter), 2)


def rdna_params(gen_key: str) -> Tuple[int, Optional[str], Optional[str], Optional[str]]:
    # returns: (shaders_per_cu, shader_isa, dcn, vcn)
    if gen_key == 'RX-7000':
        return 64, 'GFX11.x', '3.x', '4.x'
    if gen_key == 'RX-6000':
        return 64, 'GFX10.3', '3.0', '3.0'
    return 64, 'GFX10.1', '2.x', '2.x'


def compute_core_config(gen_key: str, tier_key: str) -> Tuple[int, int, int, int, Optional[int]]:
    # Returns: (compute_units, shader_units, tmus, rops, matrix_cores)
    # CU ranges per tier
    cu_ranges = {
        'x600': (28, 40),
        'x700': (36, 60),
        'x800': (54, 72),
        'x900': (72, 96),
    }
    cu_lo, cu_hi = cu_ranges.get(tier_key, (36, 60))
    cu = random.randint(cu_lo, cu_hi)
    shaders_per_cu, _, _, _ = rdna_params(gen_key)
    shaders = cu * shaders_per_cu
    tmus = cu * 4  # RDNA typically ~4 TMUs per CU
    if gen_key == 'RX-7000':
        rops = cu * 2  # RDNA3 often ~2 ROPs per CU (e.g., 96 CU -> 192 ROPs)
        matrix = cu * 2  # AI accelerators
    else:
        rops = max(32, (cu * 3) // 2)
        # Round ROPs to nearest multiple of 16 for plausibility
        rops = max(16, (rops + 8) // 16 * 16)
        matrix = None
    return cu, shaders, tmus, rops, matrix


def make_products(vendors_map: Dict[str, int], categories_map: Dict[str, int], attributes_map: Dict[str, int]) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    gpu_category_id = categories_map.get('GPU')
    if not gpu_category_id:
        raise RuntimeError('GPU category not found. Run base entities population first.')

    partner_vendors = pick_available_vendors(vendors_map)
    if not partner_vendors:
        raise RuntimeError('No AMD partners found in Vendors table. Please ensure vendors are populated.')

    # Seed grid from URLs or canonical
    model_grid: List[Tuple[str, str, int]] = []  # (gen_key, prefix RX, base_num)
    if USE_URL_SEED and os.path.exists(URL_SEED_FILE):
        with open(URL_SEED_FILE, 'r') as f:
            for line in f:
                url = line.strip()
                if not url:
                    continue
                slug = url.rsplit('/', 1)[-1].split('.')[0]
                name_bits = slug.replace('radeon-', '').replace('rx-', '').replace('-', ' ').upper()
                if not name_bits.startswith('RX'):
                    continue
                digits = ''.join(ch for ch in name_bits if ch.isdigit())
                if len(digits) < 4:
                    continue
                base_num = int(digits[:4])
                # Only accept x600/x700/x800/x900
                if base_num % 100 not in (60, 70, 80, 90):
                    continue
                if base_num // 100 == 56 or base_num // 100 == 57:
                    gen_key = 'RX-5000'
                elif base_num // 100 == 66 or base_num // 100 == 67 or base_num // 100 == 68 or base_num // 100 == 69:
                    gen_key = 'RX-6000'
                elif base_num // 100 == 76 or base_num // 100 == 77 or base_num // 100 == 78 or base_num // 100 == 79:
                    gen_key = 'RX-7000'
                else:
                    continue
                model_grid.append((gen_key, 'RX', base_num))
    else:
        for gen_key, prefix, numbers in SERIES_ORDER:
            for base_num in numbers:
                if isinstance(base_num, int):
                    model_grid.append((gen_key, prefix, base_num))
                else:
                    # try to parse leading digits
                    digits = ''.join(ch for ch in str(base_num) if ch.isdigit())
                    if digits.isdigit():
                        try:
                            n = int(digits)
                            model_grid.append((gen_key, prefix, n))
                        except Exception:
                            pass

    # Fallback if URL seed produced nothing
    if not model_grid:
        print('Seed file empty or unsupported models. Falling back to default RX series set.')
        for gen_key, prefix, numbers in SERIES_ORDER:
            for base_num in numbers:
                if isinstance(base_num, int):
                    model_grid.append((gen_key, prefix, base_num))
                else:
                    digits = ''.join(ch for ch in str(base_num) if ch.isdigit())
                    if digits.isdigit():
                        try:
                            n = int(digits)
                            model_grid.append((gen_key, prefix, n))
                        except Exception:
                            pass

    # Deduplicate
    uniq = {}
    for g, p, n in model_grid:
        uniq[(g, p, n)] = (g, p, n)
    model_grid = list(uniq.values())

    products: List[Dict[str, Any]] = []
    attributes: List[Dict[str, Any]] = []

    # Sanity: ensure a few critical attributes exist to avoid generating nothing due to missing IDs
    critical_attrs = ['VRAM', 'Memory Type', 'Bus Width', 'Boost Clock', 'Shading Units']
    missing = [a for a in critical_attrs if a not in attributes_map]
    if missing:
        print(f"Warning: Missing attributes in dictionary: {', '.join(missing)}. Generation will continue but some attributes won't be inserted.")

    for gen_key, prefix, base_num in model_grid:
        tier_key = classify_tier(base_num)
        tier = TIER_DEF[tier_key]
        vram_options = derive_memory_options(gen_key, tier_key, base_num)
        if not vram_options:
            vram_options = tier['vram_gb']

        for vendor_name, ven_id in partner_vendors:
            vlist = variants_for_vendor(vendor_name)
            if vendor_has_specific_variants(vendor_name):
                # Generate all variants for mapped vendors
                chosen_variants = list(vlist)
                random.shuffle(chosen_variants)
            else:
                # For unmapped vendors, use a small default sample to avoid explosion
                k = min(DEFAULT_FALLBACK_VARIANTS, len(vlist))
                chosen_variants = random.sample(vlist, k=k) if k > 0 else []
            for variant in chosen_variants:
                vram = random.choice(vram_options)
                mem_type = memory_type_for(gen_key)
                bus_bits = bus_width_for(gen_key, tier_key, base_num, vram)
                tdp = random.randint(*tier['tdp'])
                psu = suggested_psu_for(tdp, gen_key)
                slot = random.choice(tier['slot'])
                length = random.randint(*tier['length_mm'])
                height = random.randint(110, 150)
                width_mm = 40 if slot == 'Dual' else 60
                base_clk = random.randint(*tier['base_boost'])
                game_clk = base_clk + random.randint(50, 100)
                boost_clk = game_clk + random.randint(50, 150)
                # memory clock effective
                mem_clk = 18000 if gen_key == 'RX-6000' else 20000 if gen_key == 'RX-7000' else 14000

                price = price_for(gen_key, tier_key)
                display_name = f"{vendor_name} Radeon {prefix} {base_num} {variant} {vram} GB"
                board_num = f"{random.choice(['109', '113'])}-D{random.randint(600,799)}-{random.randint(10,99):02d}"

                products.append({
                    'category_ID': gpu_category_id,
                    'product_NAME': display_name,
                    'product_DESCRIPT': f"{vendor_name} custom design based on AMD Radeon {prefix} {base_num} {variant}.",
                    'product_PRICE': price,
                    'product_STOCK': random.randint(15, 120),
                    'ven_ID': ven_id,
                })

                def add_attr(key: str, value: Any):
                    att_id = attributes_map.get(key)
                    val = _normalize_nominal(value)
                    if att_id and val:
                        attributes.append({'product_NAME': display_name, 'att_ID': att_id, 'nominal': val, 'ven_ID': ven_id})
                    elif val and att_id is None:
                        # Helpful once per missing attribute key
                        pass

                info = GEN_INFO[gen_key]
                add_attr('Architecture', info['arch'])
                add_attr('Process Size', info['process'])
                add_attr('Process Type', process_type_for(gen_key))
                add_attr('Foundry', foundry_for(gen_key))
                add_attr('DirectX', info['directx'])
                api = api_caps_for(gen_key)
                add_attr('OpenGL', api['OpenGL'])
                add_attr('OpenCL', api['OpenCL'])
                add_attr('Vulkan', api['Vulkan'])
                add_attr('Shader Model', api['Shader Model'])
                add_attr('VRAM', f"{vram} GB {mem_type}")
                add_attr('Memory Size', f"{vram} GB")
                add_attr('Memory Type', mem_type)
                add_attr('Bus Width', f"{bus_bits}-bit")
                add_attr('Memory Bus', f"{bus_bits}-bit")
                add_attr('Bus Interface', bus_interface_for(gen_key))
                add_attr('Bandwidth', format_bandwidth(mem_clk, bus_bits))
                add_attr('GPU Clock', f"{base_clk} MHz")
                add_attr('Game Clock', f"{game_clk} MHz")
                add_attr('Boost Clock', f"{boost_clk} MHz")
                add_attr('Memory Clock', f"{mem_clk} MHz")
                add_attr('TDP', f"{tdp} W")
                add_attr('Suggested PSU', f"{psu} W")
                add_attr('Slot Width', slot)
                add_attr('Length', f"{length} mm")
                add_attr('Height', f"{height} mm")
                add_attr('Width', f"{width_mm} mm")
                add_attr('Outputs', outputs_for(gen_key, base_num))
                add_attr('Power Connectors', '2x 8-pin' if tier_key in ('x800', 'x900') else '1x 8-pin')
                add_attr('Board Number', board_num)

                # Compute configuration
                cu, shaders, tmus, rops, matrix = compute_core_config(gen_key, tier_key)
                add_attr('Compute Units', cu)
                add_attr('Shading Units', shaders)
                add_attr('TMUs', tmus)
                add_attr('ROPs', rops)
                if matrix is not None:
                    add_attr('Matrix Cores', matrix)
                # RT cores introduced with RDNA2
                if gen_key in ('RX-6000', 'RX-7000'):
                    add_attr('RT Cores', cu)

                # Generation/meta
                gen_label = 'Radeon RX 5000' if gen_key == 'RX-5000' else 'Radeon RX 6000' if gen_key == 'RX-6000' else 'Radeon RX 7000'
                predecessor = None
                if gen_key == 'RX-6000':
                    predecessor = 'Radeon RX 5000'
                elif gen_key == 'RX-7000':
                    predecessor = 'Radeon RX 6000'
                add_attr('Generation', gen_label)
                if predecessor:
                    add_attr('Predecessor', predecessor)
                add_attr('Production', 'Active')
                add_attr('Launch Price', f"{price} USD")

                # Extras (from example)
                shaders_per_cu, shader_isa, dcn, vcn = rdna_params(gen_key)
                if shader_isa:
                    add_attr('Shader ISA', shader_isa)
                if dcn:
                    add_attr('Display Core Next', dcn)
                if vcn:
                    add_attr('Video Core Next', vcn)
                add_attr('Chip Package', 'MCM' if gen_key == 'RX-7000' and base_num >= 7900 else 'Monolithic')

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
        for a in attributes:
            pid = id_map.get((a['product_NAME'], a['ven_ID']))
            if pid and a.get('nominal'):
                final_attrs.append({'product_ID': pid, 'att_ID': a['att_ID'], 'nominal': a['nominal']})

        if final_attrs:
            attr_sql = "INSERT INTO ProductAttributes (product_ID, att_ID, nominal) VALUES (:product_ID, :att_ID, :nominal)"
            cur.executemany(attr_sql, final_attrs, batcherrors=False)

        conn.commit()
        print(f"Inserted {len(new_products)} products and {len(final_attrs)} attributes.")

    except Exception as e:
        if conn:
            conn.rollback()
        print(f"Error inserting AMD GPUs. Rolled back. Details: {e}")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()


def main():
    print('--- AMD GPU Data Generator ---')
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
    print(f'Prepared {len(products)} products and {len(attrs)} attributes for insertion.')
    for i in range(0, len(products), BATCH_SIZE):
        chunk_products = products[i:i+BATCH_SIZE]
        names_in_chunk = {p['product_NAME'] for p in chunk_products}
        attrs_chunk = [a for a in attrs if a['product_NAME'] in names_in_chunk]
        insert_into_db(chunk_products, attrs_chunk)

    print('--- Generation finished ---')


if __name__ == '__main__':
    main()
