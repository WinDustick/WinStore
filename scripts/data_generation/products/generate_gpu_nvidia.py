import os
import sys
import math
import random
from typing import List, Dict, Any, Optional, Tuple

# Make utils importable
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils import get_db_connection, load_ids


# --- Configuration ---
# How many partner vendors to use per model (picked from available NVIDIA AIB partners found in Vendors table)
VENDORS_PER_MODEL = 6
# How many variant SKUs per (model, vendor) to generate (different coolers/OC bins)
VARIANTS_PER_VENDOR = 2
# Batch size for DB insertions (per generated chunk)
BATCH_SIZE = 100

# Toggle: optionally seed exact model set from the url list (names only, no web requests)
USE_URL_SEED = True
URL_SEED_FILE = os.path.join(os.path.dirname(__file__), '..', 'sources', 'links', 'gpu_links', 'gpu_nvidia.txt')


# --- Domain models ---
# Seven classes 1..7 drive price/perf/size. We define per-generation base prices
PRICE_TABLE = {
    # class: x050, x060, x060Ti/x070, x070Ti/x080, x080Ti, x090, x090Ti/Titan
    'GTX-900':   [129, 199, 319, 499, 649, 0,   0],
    'GTX-1000':  [149, 249, 379, 599, 699, 0,   0],
    'GTX-1600':  [159, 269, 349, 0,   0,   0,   0],
    'RTX-2000':  [229, 329, 449, 699, 999, 1199, 0],
    'RTX-3000':  [249, 329, 499, 699, 1199, 1499, 0],
    'RTX-4000':  [299, 329, 599, 999, 0,   1599, 0],
    'RTX-5000':  [299, 349, 599, 999, 0,   1699, 0],  # speculative/placeholder
}

# Architecture/process/features per generation
GEN_INFO = {
    'GTX-900':  {'arch': 'Maxwell', 'process': '28 nm', 'directx': '12 (FL 12_1)', 'memory_types': ['GDDR5']},
    'GTX-1000': {'arch': 'Pascal',  'process': '16 nm', 'directx': '12 (FL 12_1)', 'memory_types': ['GDDR5', 'GDDR5X']},
    'GTX-1600': {'arch': 'Turing',  'process': '12 nm', 'directx': '12 (FL 12_1)', 'memory_types': ['GDDR5', 'GDDR6']},
    'RTX-2000': {'arch': 'Turing',  'process': '12 nm', 'directx': '12 Ultimate',  'memory_types': ['GDDR6']},
    'RTX-3000': {'arch': 'Ampere',  'process': '8 nm',  'directx': '12 Ultimate',  'memory_types': ['GDDR6', 'GDDR6X']},
    'RTX-4000': {'arch': 'Ada Lovelace', 'process': '5 nm', 'directx': '12 Ultimate', 'memory_types': ['GDDR6', 'GDDR6X']},
    'RTX-5000': {'arch': 'Blackwell',    'process': '3 nm', 'directx': '12 Ultimate', 'memory_types': ['GDDR7']},  # speculative
}

# Per-tier heuristics across generations
TIER_DEF = {
    'x050': {
        'cls': 1,
        'vram_gb': [2, 3, 4, 6, 8],  # depends on gen
        'bus_bits': [64, 96, 128],
        'tdp': (40, 120),
        'psu': (300, 450),
        'connectors': ['None', '1x 6-pin', '1x 8-pin'],
        'slot': ['Dual'],
        'length_mm': (150, 210),
        'base_boost': (1000, 1700),
    },
    'x060': {
        'cls': 2,
        'vram_gb': [3, 4, 6, 8, 12],
        'bus_bits': [128, 192],
        'tdp': (75, 180),
        'psu': (350, 550),
        'connectors': ['1x 6-pin', '1x 8-pin'],
        'slot': ['Dual'],
        'length_mm': (200, 260),
        'base_boost': (1200, 1800),
    },
    'x060 Ti': {
        'cls': 3,
        'vram_gb': [8, 16],
        'bus_bits': [128, 192],
        'tdp': (160, 220),
        'psu': (450, 650),
        'connectors': ['1x 8-pin', '2x 8-pin'],
        'slot': ['Dual'],
        'length_mm': (230, 290),
        'base_boost': (1400, 2000),
    },
    'x070': {
        'cls': 3,
        'vram_gb': [8, 10, 12, 16],
        'bus_bits': [192, 256],
        'tdp': (150, 250),
        'psu': (500, 700),
        'connectors': ['1x 8-pin', '2x 8-pin'],
        'slot': ['Dual', 'Triple'],
        'length_mm': (240, 320),
        'base_boost': (1400, 2050),
    },
    'x070 Ti': {
        'cls': 4,
        'vram_gb': [8, 12, 16],
        'bus_bits': [192, 256],
        'tdp': (200, 290),
        'psu': (600, 750),
        'connectors': ['2x 8-pin'],
        'slot': ['Dual', 'Triple'],
        'length_mm': (260, 330),
        'base_boost': (1500, 2100),
    },
    'x080': {
        'cls': 4,
        'vram_gb': [8, 10, 12, 16],
        'bus_bits': [256, 320],
        'tdp': (220, 350),
        'psu': (650, 850),
        'connectors': ['2x 8-pin', '1x 12VHPWR'],
        'slot': ['Triple'],
        'length_mm': (270, 340),
        'base_boost': (1550, 2150),
    },
    'x080 Ti': {
        'cls': 5,
        'vram_gb': [11, 12, 16, 20],
        'bus_bits': [320, 384],
        'tdp': (250, 380),
        'psu': (700, 850),
        'connectors': ['2x 8-pin', '1x 12VHPWR'],
        'slot': ['Triple'],
        'length_mm': (280, 350),
        'base_boost': (1600, 2200),
    },
    'x090': {
        'cls': 6,
        'vram_gb': [24],
        'bus_bits': [384],
        'tdp': (320, 450),
        'psu': (850, 1000),
        'connectors': ['3x 8-pin', '1x 12VHPWR'],
        'slot': ['Triple'],
        'length_mm': (300, 360),
        'base_boost': (1600, 2300),
    },
}

SERIES_ORDER = [
    ('GTX-900',  'GTX', [950, 960, 970, 980]),
    ('GTX-1000', 'GTX', [1050, 1060, 1070, 1080]),
    ('GTX-1600', 'GTX', [1650, 1660]),
    ('RTX-2000', 'RTX', [2050, 2060, 2070, 2080]),
    ('RTX-3000', 'RTX', [3050, 3060, 3070, 3080, 3090]),
    ('RTX-4000', 'RTX', [4060, 4070, 4080, 4090]),
    ('RTX-5000', 'RTX', [5060, 5070, 5080, 5090]),
]

SUFFIXES = {
    'Ti': [' Ti'],
    'Super': [' Super'],
}

VENDOR_VARIANTS = [
    'Gaming X', 'Ventus 2X', 'Eagle', 'TUF Gaming', 'Dual OC', 'STRIX OC', 'AMP!', 'Trinity',
    'Phoenix', 'AERO ITX', 'Challenger', 'SG', 'Ultra WOC', 'SuperJetstream', 'EX', 'XC Ultra'
]

NVIDIA_PARTNERS_PREFERRED = [
    # Popular AIBs (names should match Vendors table as-is where possible)
    'MSI', 'Asus', 'Gigabyte Technology', 'Gigabyte', 'EVGA', 'Zotac', 'PNY', 'Palit', 'Gainward', 'KFA2', 'Colorful', 'Inno3D', 'GALAX', 'Super Flower'
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
    # Case-insensitive pick from preferred list
    vm_lower = {k.lower(): (k, vid) for k, vid in vendors_map.items()}
    chosen: List[Tuple[str, int]] = []
    for name in NVIDIA_PARTNERS_PREFERRED:
        hit = vm_lower.get(name.lower())
        if hit:
            chosen.append(hit)
    # Fallback: include NVIDIA itself for FE variants if present
    if 'nvidia' in vm_lower:
        chosen.append(vm_lower['nvidia'])
    # Deduplicate and limit
    unique = []
    seen = set()
    for name, vid in chosen:
        if vid not in seen:
            unique.append((name, vid))
            seen.add(vid)
    return unique[:VENDORS_PER_MODEL]


def classify_tier(num: int) -> str:
    # e.g., 3060 -> x060, 3070 -> x070
    if num % 100 in (50,):
        return 'x050'
    if num % 100 in (60,):
        return 'x060'
    if num % 100 in (70,):
        return 'x070'
    if num % 100 in (80,):
        return 'x080'
    if num % 100 in (90,):
        return 'x090'
    # Fallback to x060
    return 'x060'


def derive_memory_options(gen_key: str, tier_key: str, base_num: int) -> List[int]:
    opts = TIER_DEF[tier_key]['vram_gb'][:]
    # Narrow to realistic options by generation & tier number
    if gen_key == 'GTX-900':
        if base_num in (950,):
            return [2]
        if base_num in (960,):
            return [2, 4]
        if base_num in (970,):
            return [4]
        if base_num in (980,):
            return [4]
    if gen_key == 'GTX-1000':
        if base_num == 1050:
            return [2, 3]
        if base_num == 1060:
            return [3, 6]
        if base_num == 1070:
            return [8]
        if base_num == 1080:
            return [8]
    if gen_key == 'GTX-1600':
        if base_num == 1650:
            return [4, 6]
        if base_num == 1660:
            return [6]
    if gen_key == 'RTX-2000':
        if base_num == 2050:
            return [4]
        if base_num == 2060:
            return [6]
        if base_num == 2070:
            return [8]
        if base_num == 2080:
            return [8]
    if gen_key == 'RTX-3000':
        if base_num == 3050:
            return [8]
        if base_num == 3060:
            return [8, 12]
        if base_num == 3070:
            return [8]
        if base_num == 3080:
            return [10, 12]
        if base_num == 3090:
            return [24]
    if gen_key == 'RTX-4000':
        if base_num == 4060:
            return [8, 16]
        if base_num == 4070:
            return [12]
        if base_num == 4080:
            return [16]
        if base_num == 4090:
            return [24]
    if gen_key == 'RTX-5000':
        if base_num == 5060:
            return [12]
        if base_num == 5070:
            return [16]
        if base_num == 5080:
            return [16]
        if base_num == 5090:
            return [24]
    return opts


def memory_type_for(gen_key: str, base_num: int, vram: int) -> str:
    types = GEN_INFO[gen_key]['memory_types']
    if gen_key in ('GTX-1000',) and base_num == 1080:
        return 'GDDR5X'
    if gen_key in ('RTX-3000', 'RTX-4000') and (base_num in (3080, 3090, 4080, 4090) or (gen_key == 'RTX-3000' and vram >= 10)):
        return 'GDDR6X'
    # Default pick first
    return types[-1]


def bus_width_for(tier_key: str, base_num: int, vram: int) -> int:
    # Bias to common configs
    if base_num in (3060, 4060):
        return 128
    if base_num in (3070, 4070):
        return 256 if tier_key != 'x070' or vram >= 12 else 192
    if base_num in (3080,):
        return 320 if vram >= 12 else 320
    if base_num in (3090, 4090):
        return 384
    return random.choice(TIER_DEF[tier_key]['bus_bits'])


def suggested_psu_for(tdp: int, gen_key: str) -> int:
    base = 300 if tdp <= 120 else 450 if tdp <= 200 else 650 if tdp <= 300 else 850
    # 40/50 series transient spikes -> add margin
    if gen_key in ('RTX-4000', 'RTX-5000'):
        base += 100
    return base


def outputs_for(gen_key: str, base_num: int) -> str:
    if gen_key.startswith('GTX-9'):
        return '1x DVI, 1x HDMI 2.0, 3x DisplayPort 1.2'
    if gen_key.startswith('GTX-1'):
        return '1x DVI, 1x HDMI 2.0b, 3x DisplayPort 1.4'
    # RTX
    if gen_key == 'RTX-5000':
        return '1x HDMI 2.1b, 3x DisplayPort 2.1b'
    return '1x HDMI 2.1, 3x DisplayPort 1.4a'


def power_connectors_for(gen_key: str, tier_key: str) -> str:
    if gen_key in ('RTX-4000', 'RTX-5000') and tier_key in ('x080', 'x080 Ti', 'x090'):
        return '1x 16-pin'
    return random.choice(TIER_DEF[tier_key]['connectors'])


def directx_for(gen_key: str) -> str:
    return GEN_INFO[gen_key]['directx']


def get_price(gen_key: str, tier_class: int) -> float:
    base_list = PRICE_TABLE.get(gen_key) or PRICE_TABLE['RTX-3000']
    base = base_list[tier_class - 1] if tier_class - 1 < len(base_list) else 0
    # If base price missing for this gen/tier (e.g., 900 series lacks 90), fallback from 3000-series
    if base == 0:
        base = PRICE_TABLE['RTX-3000'][tier_class - 1]
    # +/- 15%
    jitter = random.uniform(-0.15, 0.15)
    return round(base * (1 + jitter), 2)


def foundry_for(gen_key: str) -> str:
    if gen_key in ('RTX-3000',):
        return 'Samsung'
    # Others primarily TSMC
    return 'TSMC'


def process_type_for(gen_key: str) -> str:
    return 'Planar' if gen_key == 'GTX-900' else 'FinFET'


def bus_interface_for(gen_key: str) -> str:
    if gen_key in ('GTX-900', 'GTX-1000', 'GTX-1600', 'RTX-2000'):
        return 'PCIe 3.0 x16'
    if gen_key in ('RTX-3000', 'RTX-4000'):
        return 'PCIe 4.0 x16'
    if gen_key in ('RTX-5000',):
        return 'PCIe 5.0 x16'
    return 'PCIe x16'


def api_caps_for(gen_key: str) -> Dict[str, str]:
    if gen_key.startswith('GTX'):
        return {
            'OpenGL': '4.6',
            'OpenCL': '1.2',
            'Vulkan': '1.2',
            'Shader Model': '5.1',
            'CUDA': '11.0',
        }
    if gen_key == 'RTX-2000':
        return {'OpenGL': '4.6', 'OpenCL': '3.0', 'Vulkan': '1.2', 'Shader Model': '6.5', 'CUDA': '11.8'}
    if gen_key == 'RTX-3000':
        return {'OpenGL': '4.6', 'OpenCL': '3.0', 'Vulkan': '1.3', 'Shader Model': '6.6', 'CUDA': '12.0'}
    if gen_key == 'RTX-4000':
        return {'OpenGL': '4.6', 'OpenCL': '3.0', 'Vulkan': '1.3', 'Shader Model': '6.7', 'CUDA': '12.3'}
    if gen_key == 'RTX-5000':
        return {'OpenGL': '4.6', 'OpenCL': '3.0', 'Vulkan': '1.4', 'Shader Model': '6.8', 'CUDA': '12.4'}
    return {'OpenGL': '4.6', 'OpenCL': '3.0', 'Vulkan': '1.2', 'Shader Model': '6.0', 'CUDA': '11.0'}


def generation_labels(gen_key: str) -> Tuple[str, Optional[str]]:
    mapping = {
        'GTX-900': ('GeForce 900', None),
        'GTX-1000': ('GeForce 10', 'GeForce 900'),
        'GTX-1600': ('GeForce 16', 'GeForce 10'),
        'RTX-2000': ('GeForce 20', 'GeForce 16'),
        'RTX-3000': ('GeForce 30', 'GeForce 20'),
        'RTX-4000': ('GeForce 40', 'GeForce 30'),
        'RTX-5000': ('GeForce 50', 'GeForce 40'),
    }
    return mapping.get(gen_key, ('GeForce', None))


def format_bandwidth(mem_clk_mhz: int, bus_bits: int) -> str:
    # Assume mem_clk_mhz is effective (e.g., 14000 MHz == 14 Gbps per pin)
    gbps = mem_clk_mhz / 1000.0
    gb_per_s = gbps * (bus_bits / 8.0)
    if gb_per_s >= 1000:
        return f"{gb_per_s/1000:.2f} TB/s"
    return f"{gb_per_s:.0f} GB/s"


def _cores_per_sm(gen_key: str) -> int:
    # Approximate cores per SM by architecture
    if gen_key in ('GTX-1600', 'RTX-2000'):  # Turing
        return 64
    # Maxwell, Pascal, Ampere, Ada, Blackwell
    return 128


def _sm_range_for(tier_key: str, gen_key: str) -> Tuple[int, int]:
    # Broad, plausible SM count ranges per tier; older gens trend lower
    base_ranges = {
        'x050': (8, 24),
        'x060': (16, 38),
        'x070': (30, 60),
        'x070 Ti': (36, 68),
        'x080': (48, 84),
        'x080 Ti': (60, 96),
        'x090': (72, 128),
    }
    lo, hi = base_ranges.get(tier_key, (16, 38))
    # Cap maxima for very old gens
    if gen_key in ('GTX-900', 'GTX-1000'):
        hi = min(hi, 64)
    return lo, hi


def _tmus_ratio_for(gen_key: str) -> int:
    # Shading Units to TMUs ratio approximation
    if gen_key in ('GTX-900', 'GTX-1000'):
        return 16
    # Turing/Ampere/Ada/Blackwell
    return 32


def make_products(vendors_map: Dict[str, int], categories_map: Dict[str, int], attributes_map: Dict[str, int]) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    gpu_category_id = categories_map.get('GPU')
    if not gpu_category_id:
        raise RuntimeError("GPU category not found. Run base entities population first.")

    # Vendor picks
    partner_vendors = pick_available_vendors(vendors_map)
    if not partner_vendors:
        raise RuntimeError("No NVIDIA partners found in Vendors table. Please ensure vendors are populated.")

    # Build seed model list either from URLs or canonical grid
    model_grid: List[Tuple[str, str, int, str]] = []  # (gen_key, prefix GTX/RTX, base_num, suffix '')
    if USE_URL_SEED and os.path.exists(URL_SEED_FILE):
        with open(URL_SEED_FILE, 'r') as f:
            for line in f:
                url = line.strip()
                if not url:
                    continue
                # URL like .../geforce-rtx-3060-ti.c3681
                slug = url.rsplit('/', 1)[-1].split('.')[0]
                name_bits = slug.replace('geforce-', '').replace('-', ' ').upper()
                # Extract gen & base number
                if name_bits.startswith('RTX'):
                    prefix = 'RTX'
                elif name_bits.startswith('GTX'):
                    prefix = 'GTX'
                else:
                    # Skip GT/TITAN/other prefixes not modeled
                    continue
                digits = ''.join(ch for ch in name_bits if ch.isdigit())
                # Require at least 4 digits to map cleanly (e.g., 1060, 4070)
                if len(digits) < 4:
                    continue
                base_num = int(digits[:4])
                # Only support x050/x060/x070/x080/x090 families
                if base_num % 100 not in (50, 60, 70, 80, 90):
                    continue
                # Map to gen_key
                if prefix == 'GTX' and base_num // 100 == 9:
                    gen_key = 'GTX-900'
                elif prefix == 'GTX' and base_num // 100 == 10:
                    gen_key = 'GTX-1000'
                elif prefix == 'GTX' and base_num // 100 == 16:
                    gen_key = 'GTX-1600'
                elif prefix == 'RTX' and base_num // 100 == 20:
                    gen_key = 'RTX-2000'
                elif prefix == 'RTX' and base_num // 100 == 30:
                    gen_key = 'RTX-3000'
                elif prefix == 'RTX' and base_num // 100 == 40:
                    gen_key = 'RTX-4000'
                elif prefix == 'RTX' and base_num // 100 == 50:
                    gen_key = 'RTX-5000'
                else:
                    continue
                model_grid.append((gen_key, prefix, base_num, ''))
    else:
        for gen_key, prefix, numbers in SERIES_ORDER:
            for base_num in numbers:
                model_grid.append((gen_key, prefix, base_num, ''))

    # De-duplicate
    uniq = {}
    for g, p, n, s in model_grid:
        uniq[(g, p, n)] = (g, p, n, s)
    model_grid = list(uniq.values())

    products: List[Dict[str, Any]] = []
    attributes: List[Dict[str, Any]] = []

    for gen_key, prefix, base_num, _ in model_grid:
        tier_key = classify_tier(base_num)
        tier = TIER_DEF[tier_key]
        tier_class = tier['cls']
        info = GEN_INFO[gen_key]

        vram_options = derive_memory_options(gen_key, tier_key, base_num)
        if not vram_options:
            vram_options = TIER_DEF[tier_key]['vram_gb']

        for vendor_name, ven_id in partner_vendors:
            chosen_variants = random.sample(VENDOR_VARIANTS, k=min(VARIANTS_PER_VENDOR, len(VENDOR_VARIANTS)))
            for variant in chosen_variants:
                vram = random.choice(vram_options)
                mem_type = memory_type_for(gen_key, base_num, vram)
                bus_bits = bus_width_for(tier_key, base_num, vram)
                tdp = random.randint(*tier['tdp'])
                psu = suggested_psu_for(tdp, gen_key)
                slot = random.choice(tier['slot'])
                length = random.randint(*tier['length_mm'])
                height = random.randint(110, 150)
                width_mm = 40 if slot == 'Dual' else 60
                base_clk = random.randint(*tier['base_boost'])
                boost_clk = base_clk + random.randint(100, 250)
                # Memory clock (effective MHz)
                if mem_type == 'GDDR5':
                    mem_clk = 7000
                elif mem_type == 'GDDR6':
                    mem_clk = 14000
                elif mem_type == 'GDDR6X':
                    mem_clk = 19000
                elif mem_type == 'GDDR7':
                    mem_clk = 28000
                else:
                    mem_clk = 12000

                price = get_price(gen_key, tier_class)
                model_name = f"{vendor_name} GeForce {prefix} {base_num}{'' if base_num % 100 not in (60, 70, 80) else ''}"
                # Add Ti/Super variants if appropriate by probabilistic choice
                variant_suffix = ''
                if tier_key in ('x060', 'x070', 'x080'):
                    roll = random.random()
                    if roll < 0.25 and f"{prefix}-Ti" in ['RTX-Ti', 'GTX-Ti']:
                        variant_suffix = ' Ti'
                    elif roll < 0.5 and f"{prefix}-Super" in ['RTX-Super', 'GTX-Super']:
                        variant_suffix = ' Super'
                # For specific known Ti options
                if base_num in (3060, 3070, 3080, 4070):
                    if random.random() < 0.5:
                        variant_suffix = ' Ti'

                display_name = f"{vendor_name} GeForce {prefix} {base_num}{variant_suffix} {variant} {vram} GB"
                # Synthesize a plausible board number
                board_num = f"PG{random.randint(120, 199)} SKU {random.randint(10, 99)}"

                products.append({
                    'category_ID': gpu_category_id,
                    'product_NAME': display_name,
                    'product_DESCRIPT': f"{vendor_name} custom design based on NVIDIA {prefix} {base_num} {variant}.",
                    'product_PRICE': price,
                    'product_STOCK': random.randint(15, 120),
                    'ven_ID': ven_id,
                })

                # Attribute helpers
                def add_attr(key: str, value: Any):
                    att_id = attributes_map.get(key)
                    val = _normalize_nominal(value)
                    if att_id and val:
                        attributes.append({'product_NAME': display_name, 'att_ID': att_id, 'nominal': val, 'ven_ID': ven_id})

                add_attr('Architecture', info['arch'])
                add_attr('Process Size', info['process'])
                add_attr('Process Type', process_type_for(gen_key))
                add_attr('Foundry', foundry_for(gen_key))
                add_attr('DirectX', directx_for(gen_key))
                api = api_caps_for(gen_key)
                add_attr('OpenGL', api['OpenGL'])
                add_attr('OpenCL', api['OpenCL'])
                add_attr('Vulkan', api['Vulkan'])
                add_attr('Shader Model', api['Shader Model'])
                add_attr('CUDA', api['CUDA'])
                add_attr('VRAM', f"{vram} GB {mem_type}")
                add_attr('Memory Size', f"{vram} GB")
                add_attr('Memory Type', mem_type)
                add_attr('Bus Width', f"{bus_bits}-bit")
                add_attr('Memory Bus', f"{bus_bits}-bit")
                add_attr('Bus Interface', bus_interface_for(gen_key))
                add_attr('Bandwidth', format_bandwidth(mem_clk, bus_bits))
                add_attr('GPU Clock', f"{base_clk} MHz")
                add_attr('Boost Clock', f"{boost_clk} MHz")
                add_attr('Memory Clock', f"{mem_clk} MHz")
                add_attr('TDP', f"{tdp} W")
                add_attr('Suggested PSU', f"{psu} W")
                add_attr('Slot Width', slot)
                add_attr('Length', f"{length} mm")
                add_attr('Height', f"{height} mm")
                add_attr('Width', f"{width_mm} mm")
                add_attr('Outputs', outputs_for(gen_key, base_num))
                add_attr('Power Connectors', power_connectors_for(gen_key, tier_key))
                add_attr('Board Number', board_num)
                add_attr('NVENC', 'Yes')
                add_attr('NVDEC', 'Yes')
                # Core configuration approximations
                sm_lo, sm_hi = _sm_range_for(tier_key, gen_key)
                sm_count = random.randint(sm_lo, sm_hi)
                cores_per_sm = _cores_per_sm(gen_key)
                shader_units = sm_count * cores_per_sm
                tmu_ratio = _tmus_ratio_for(gen_key)
                tmus = max(1, shader_units // tmu_ratio)
                # Heuristic ROPs: typically proportional to bus width, divide by 8
                rops = max(16, (bus_bits // 8))
                add_attr('SM Count', sm_count)
                add_attr('Shading Units', shader_units)
                add_attr('TMUs', tmus)
                add_attr('ROPs', rops)
                # Ray tracing for RTX only
                if gen_key.startswith('RTX'):
                    add_attr('RT Cores', 'Yes')
                    add_attr('Tensor Cores', 'Yes')
                # Recommended resolution
                if tier_class <= 2:
                    add_attr('Recommended Gaming Resolutions', '1080p')
                elif tier_class <= 4:
                    add_attr('Recommended Gaming Resolutions', '1440p')
                else:
                    add_attr('Recommended Gaming Resolutions', '4K')
                # Meta
                gen_label, predecessor = generation_labels(gen_key)
                add_attr('Generation', gen_label)
                if predecessor:
                    add_attr('Predecessor', predecessor)
                add_attr('Production', 'Active')
                add_attr('Launch Price', f"{price} USD")

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

        # Deduplicate against existing by (product_NAME, ven_ID)
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

        # Insert products
        prod_sql = (
            "INSERT INTO Products (category_ID, product_NAME, product_DESCRIPT, product_PRICE, product_STOCK, ven_ID) "
            "VALUES (:category_ID, :product_NAME, :product_DESCRIPT, :product_PRICE, :product_STOCK, :ven_ID)"
        )
        cur.executemany(prod_sql, new_products, batcherrors=False)

        # Map names to IDs post-insert
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

        # Prepare attributes rows
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
        print(f"Error inserting GPUs. Rolled back. Details: {e}")
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()


def main():
    print('--- NVIDIA GPU Data Generator ---')
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
    # Chunked insert to avoid very large binds
    for i in range(0, len(products), BATCH_SIZE):
        chunk_products = products[i:i+BATCH_SIZE]
        # Filter attributes for just this chunk to reduce mapping cost
        names_in_chunk = {p['product_NAME'] for p in chunk_products}
        attrs_chunk = [a for a in attrs if a['product_NAME'] in names_in_chunk]
        insert_into_db(chunk_products, attrs_chunk)

    print('--- Generation finished ---')


if __name__ == '__main__':
    main()
