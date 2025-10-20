-- =====================================================================
-- WinStore - Product Views (Oracle Version)
-- =====================================================================
-- Description: Creates views for accessing product data in a denormalized
--              format, particularly for specific product categories
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-09-28
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: 01_schema/01_core_schema.sql
-- =====================================================================

-- =====================================================================
-- GPU Product View
-- =====================================================================

-- View for GPU product details using Oracle's PIVOT syntax
CREATE OR REPLACE VIEW view_gpu_details AS
SELECT
    p.product_ID,
    p.product_NAME,
    c.category_NAME,
    v.ven_NAME AS vendor_name,
    NVL(p.product_PRICE, 0) AS product_PRICE,
    NVL(p.product_STOCK, 0) AS product_STOCK,
    MAX(DBMS_LOB.SUBSTR(p.product_DESCRIPT, 2000, 1)) AS product_DESCRIPT,
    p.created_AT,
    -- Columns resulting from PIVOT with NCLOB to VARCHAR2 conversion using DBMS_LOB
    MAX(DECODE(a.att_NAME, 'GPU Name', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "GPU Name",
    MAX(DECODE(a.att_NAME, 'Architecture', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Architecture",
    MAX(DECODE(a.att_NAME, 'Foundry', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Foundry",
    MAX(DECODE(a.att_NAME, 'Process Size', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Process Size",
    MAX(DECODE(a.att_NAME, 'Transistors', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Transistors",
    MAX(DECODE(a.att_NAME, 'Die Size', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Die Size",
    MAX(DECODE(a.att_NAME, 'Release Date', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Release Date",
    MAX(DECODE(a.att_NAME, 'Generation', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Generation",
    MAX(DECODE(a.att_NAME, 'Launch Price', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Launch Price",
    MAX(DECODE(a.att_NAME, 'Memory Clock', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Memory Clock",
    MAX(DECODE(a.att_NAME, 'Memory Size', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Memory Size",
    MAX(DECODE(a.att_NAME, 'Memory Type', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Memory Type",
    MAX(DECODE(a.att_NAME, 'Memory Bus', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Memory Bus",
    MAX(DECODE(a.att_NAME, 'Bandwidth', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Bandwidth",
    MAX(DECODE(a.att_NAME, 'Shading Units', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Shading Units",
    MAX(DECODE(a.att_NAME, 'TMUs', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "TMUs",
    MAX(DECODE(a.att_NAME, 'ROPs', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "ROPs",
    MAX(DECODE(a.att_NAME, 'RT Cores', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "RT Cores",
    MAX(DECODE(a.att_NAME, 'Tensor Cores', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Tensor Cores",
    MAX(DECODE(a.att_NAME, 'TDP', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "TDP",
    MAX(DECODE(a.att_NAME, 'Outputs', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Outputs",
    MAX(DECODE(a.att_NAME, 'DirectX', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "DirectX",
    MAX(DECODE(a.att_NAME, 'OpenGL', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "OpenGL",
    MAX(DECODE(a.att_NAME, 'Vulkan', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Vulkan",
    MAX(DECODE(a.att_NAME, 'Shader Model', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Shader Model",
    MAX(DECODE(a.att_NAME, 'Bus Interface', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Bus Interface",
    MAX(DECODE(a.att_NAME, 'Power Connectors', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Power Connectors",
    MAX(DECODE(a.att_NAME, 'Suggested PSU', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Suggested PSU"
FROM
    Products p
-- Join Category to ensure it's a GPU (category_ID = 1)
JOIN
    Categories c ON p.category_ID = c.category_ID AND c.category_ID = 1
-- Join Vendor
JOIN
    Vendors v ON p.ven_ID = v.ven_ID
-- Join ProductAttributes and Attributes
LEFT JOIN
    ProductAttributes pa ON p.product_ID = pa.product_ID
LEFT JOIN
    Attributes a ON pa.att_ID = a.att_ID AND a.att_NAME IN (
        'GPU Name', 'Architecture', 'Foundry', 'Process Size', 'Transistors', 'Die Size',
        'Release Date', 'Generation', 'Launch Price', 'Memory Clock',
        'Memory Size', 'Memory Type', 'Memory Bus', 'Bandwidth', 'Shading Units',
        'TMUs', 'ROPs', 'RT Cores', 'Tensor Cores', 'TDP', 'Outputs', 'DirectX',
        'OpenGL', 'Vulkan', 'Shader Model', 'Bus Interface', 'Power Connectors', 'Suggested PSU'
    )
GROUP BY
    p.product_ID,
    p.product_NAME,
    c.category_NAME,
    v.ven_NAME,
    p.product_PRICE,
    p.product_STOCK,
    p.created_AT;

-- =====================================================================
-- CPU Product View
-- =====================================================================

-- View for CPU product details
CREATE OR REPLACE VIEW view_cpu_details AS
SELECT
    p.product_ID,
    p.product_NAME,
    c.category_NAME,
    v.ven_NAME AS vendor_name,
    NVL(p.product_PRICE, 0) AS product_PRICE,
    NVL(p.product_STOCK, 0) AS product_STOCK,
    MAX(DBMS_LOB.SUBSTR(p.product_DESCRIPT, 2000, 1)) AS product_DESCRIPT,
    p.created_AT,
    -- Columns resulting from Oracle's equivalent of PIVOT with NCLOB to VARCHAR2 conversion using DBMS_LOB
    MAX(DECODE(a.att_NAME, 'Codename', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Codename",
    MAX(DECODE(a.att_NAME, 'Architecture', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Architecture",
    MAX(DECODE(a.att_NAME, 'Foundry', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Foundry",
    MAX(DECODE(a.att_NAME, 'Process Size', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Process Size",
    MAX(DECODE(a.att_NAME, 'Transistors', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Transistors",
    MAX(DECODE(a.att_NAME, 'Die Size', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Die Size",
    MAX(DECODE(a.att_NAME, 'Release Date', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Release Date",
    MAX(DECODE(a.att_NAME, 'Generation', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Generation",
    MAX(DECODE(a.att_NAME, 'Launch Price', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Launch Price",
    MAX(DECODE(a.att_NAME, '# of Cores', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "# of Cores",
    MAX(DECODE(a.att_NAME, '# of Threads', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "# of Threads",
    MAX(DECODE(a.att_NAME, 'Base Clock', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Base Clock",
    MAX(DECODE(a.att_NAME, 'Boost Clock', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Boost Clock",
    MAX(DECODE(a.att_NAME, 'Cache L1', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Cache L1",
    MAX(DECODE(a.att_NAME, 'Cache L2', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Cache L2",
    MAX(DECODE(a.att_NAME, 'Cache L3', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Cache L3",
    MAX(DECODE(a.att_NAME, 'TDP', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "TDP",
    MAX(DECODE(a.att_NAME, 'Socket', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Socket",
    MAX(DECODE(a.att_NAME, 'Integrated Graphics', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Integrated Graphics",
    MAX(DECODE(a.att_NAME, 'Memory Support', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Memory Support",
    MAX(DECODE(a.att_NAME, 'PCI-Express', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "PCI-Express",
    MAX(DECODE(a.att_NAME, 'Multiplier Unlocked', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Multiplier Unlocked",
    MAX(DECODE(a.att_NAME, 'SMT', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "SMT",
    MAX(DECODE(a.att_NAME, 'SSE4.2', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "SSE4.2",
    MAX(DECODE(a.att_NAME, 'AVX2', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "AVX2",
    MAX(DECODE(a.att_NAME, 'AES', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "AES",
    MAX(DECODE(a.att_NAME, 'AMD-V', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "AMD-V",
    MAX(DECODE(a.att_NAME, 'VT-x', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "VT-x"
FROM
    Products p
-- Join Category to filter for CPU (category_ID = 2)
JOIN
    Categories c ON p.category_ID = c.category_ID AND c.category_ID = 2
-- Join Vendor
JOIN
    Vendors v ON p.ven_ID = v.ven_ID
-- Join ProductAttributes and Attributes
LEFT JOIN
    ProductAttributes pa ON p.product_ID = pa.product_ID
LEFT JOIN
    Attributes a ON pa.att_ID = a.att_ID AND a.att_NAME IN (
        'Codename', 'Architecture', 'Foundry', 'Process Size', 'Transistors', 'Die Size',
        'Release Date', 'Generation', 'Launch Price', '# of Cores', '# of Threads',
        'Base Clock', 'Boost Clock', 'Cache L1', 'Cache L2', 'Cache L3', 'TDP', 'Socket',
        'Integrated Graphics', 'Memory Support', 'PCI-Express', 'Multiplier Unlocked',
        'SMT', 'SSE4.2', 'AVX2', 'AES', 'AMD-V', 'VT-x'
    )
GROUP BY
    p.product_ID,
    p.product_NAME,
    c.category_NAME,
    v.ven_NAME,
    p.product_PRICE,
    p.product_STOCK,
    p.created_AT;

-- =====================================================================
-- RAM Product View
-- =====================================================================

-- View for RAM product details
CREATE OR REPLACE VIEW view_ram_details AS
SELECT
    p.product_ID,
    p.product_NAME,
    c.category_NAME,
    v.ven_NAME AS vendor_name,
    NVL(p.product_PRICE, 0) AS product_PRICE,
    NVL(p.product_STOCK, 0) AS product_STOCK,
    MAX(DBMS_LOB.SUBSTR(p.product_DESCRIPT, 2000, 1)) AS product_DESCRIPT,
    p.created_AT,
    -- Columns resulting from Oracle's equivalent of PIVOT with NCLOB to VARCHAR2 conversion using DBMS_LOB
    MAX(DECODE(a.att_NAME, 'Memory Type', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Memory Type",
    MAX(DECODE(a.att_NAME, 'Speed (MT/s)', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Speed (MT/s)",
    MAX(DECODE(a.att_NAME, 'Timings', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Timings",
    MAX(DECODE(a.att_NAME, 'Voltage (V)', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Voltage (V)",
    MAX(DECODE(a.att_NAME, 'Capacity (GB)', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Capacity (GB)",
    MAX(DECODE(a.att_NAME, 'Profile Type', DBMS_LOB.SUBSTR(pa.nominal, 2000, 1), NULL)) AS "Profile Type"
FROM
    Products p
-- Join Category to filter for RAM (category_ID = 4)
JOIN
    Categories c ON p.category_ID = c.category_ID AND c.category_ID = 4
-- Join Vendor
JOIN
    Vendors v ON p.ven_ID = v.ven_ID
LEFT JOIN
    ProductAttributes pa ON p.product_ID = pa.product_ID
LEFT JOIN
    Attributes a ON pa.att_ID = a.att_ID AND a.att_NAME IN (
        'Memory Type', 'Speed (MT/s)', 'Timings', 'Voltage (V)', 'Capacity (GB)', 'Profile Type'
    )
GROUP BY
    p.product_ID,
    p.product_NAME,
    c.category_NAME,
    v.ven_NAME,
    p.product_PRICE,
    p.product_STOCK,
    p.created_AT;

-- View that lists product attributes row by row (useful for filtering and dynamic queries)
CREATE OR REPLACE VIEW view_product_attributes_list AS
SELECT
    -- Synthetic Primary Key for Directus (with NULL handling)
    TO_NCHAR(NVL(pa.product_ID, 0)) || '-' || TO_NCHAR(NVL(pa.att_ID, 0)) AS view_row_id,
    
    -- IDs from original tables
    p.product_ID,
    pa.att_ID,
    
    -- Product Information
    p.product_NAME,
    p.product_PRICE,
    p.product_STOCK,
    c.category_NAME,
    v.ven_NAME AS vendor_name,
    
    -- Attribute Information
    a.att_NAME,
    -- Use DBMS_LOB.SUBSTR to safely extract up to 2000 chars from NCLOB
    DBMS_LOB.SUBSTR(pa.nominal, 2000, 1) AS nominal,
    pa.unit_of_measurement
FROM
    ProductAttributes pa
INNER JOIN
    Products p ON pa.product_ID = p.product_ID
INNER JOIN
    Categories c ON p.category_ID = c.category_ID
INNER JOIN
    Attributes a ON pa.att_ID = a.att_ID
INNER JOIN
    Vendors v ON p.ven_ID = v.ven_ID;

-- Product summary view for frequently accessed product data
CREATE OR REPLACE VIEW view_product_summary AS
SELECT
    p.product_ID,
    p.product_NAME,
    NVL(p.product_PRICE, 0) AS product_PRICE,
    NVL(p.product_STOCK, 0) AS product_STOCK,
    NVL(p.is_featured, 0) AS is_featured,
    NVL(p.is_active, 1) AS is_active,
    c.category_ID,
    c.category_NAME,
    v.ven_ID,
    v.ven_NAME AS vendor_name
FROM
    Products p
LEFT JOIN
    Categories c ON p.category_ID = c.category_ID
LEFT JOIN
    Vendors v ON p.ven_ID = v.ven_ID;

-- Create Oracle materialized view for product summary to improve query performance
CREATE MATERIALIZED VIEW mv_product_summary
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT
    p.product_ID,
    p.product_NAME,
    NVL(p.product_PRICE, 0) AS product_PRICE,
    NVL(p.product_STOCK, 0) AS product_STOCK,
    NVL(p.is_featured, 0) AS is_featured,
    NVL(p.is_active, 1) AS is_active,
    c.category_ID,
    c.category_NAME,
    v.ven_ID,
    v.ven_NAME AS vendor_name
FROM
    Products p
LEFT JOIN
    Categories c ON p.category_ID = c.category_ID
LEFT JOIN
    Vendors v ON p.ven_ID = v.ven_ID;

-- Create indexes on the materialized view for optimal performance
CREATE UNIQUE INDEX IX_mv_product_summary_ID ON mv_product_summary(product_ID);
CREATE INDEX IX_mv_product_summary_Name_Category ON mv_product_summary(product_NAME, NVL(category_ID, 0));
CREATE INDEX IX_mv_product_summary_Featured_Active ON mv_product_summary(is_featured, is_active);

COMMIT;
PROMPT Product views created successfully

-- =====================================================================
-- Product Full Details (All-in-one for product_ID = 1)
-- =====================================================================
-- This view flattens most related information for a single product (ID=1)
-- into a key-value style result set to make it easy to inspect everything
-- associated with the product without running multiple queries.
--
-- Columns:
--   product_ID, product_NAME, category_NAME, vendor_name,
--   product_PRICE, product_STOCK, created_AT,
--   section, item_key, item_value
--
-- Notes:
-- - item_value is provided as NVARCHAR2 up to 2000 chars (CLOBs truncated).
-- - This is intentionally focused on product 1 as requested. For a reusable
--   variant, consider converting this to a parameterized pipelined function
--   or a generic view without WHERE and filter at query time.

CREATE OR REPLACE VIEW view_product_1_full_details AS
-- Base: core scalar fields as key/value rows
SELECT
    p.product_ID,
    p.product_NAME,
    c.category_NAME,
    v.ven_NAME AS vendor_name,
    NVL(p.product_PRICE, 0) AS product_PRICE,
    NVL(p.product_STOCK, 0) AS product_STOCK,
    p.created_AT,
    TO_NCHAR('product') AS section,
    TO_NCHAR('product_NAME') AS item_key,
    TO_NCHAR(p.product_NAME) AS item_value
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('product'), TO_NCHAR('product_PRICE'), TO_NCHAR(NVL(p.product_PRICE, 0))
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('product'), TO_NCHAR('product_STOCK'), TO_NCHAR(NVL(p.product_STOCK, 0))
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('product'), TO_NCHAR('is_featured'), TO_NCHAR(NVL(p.is_featured, 0))
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('product'), TO_NCHAR('is_active'), TO_NCHAR(NVL(p.is_active, 1))
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('product'), TO_NCHAR('product_DESCRIPT'), TO_NCHAR(DBMS_LOB.SUBSTR(p.product_DESCRIPT, 2000, 1))
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('product'), TO_NCHAR('updated_AT'), TO_NCHAR(TO_CHAR(p.updated_AT, 'YYYY-MM-DD"T"HH24:MI:SS'))
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1

-- Category info
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('category'), TO_NCHAR('category_ID'), TO_NCHAR(c.category_ID)
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('category'), TO_NCHAR('category_NAME'), TO_NCHAR(c.category_NAME)
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1

-- Vendor info
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('vendor'), TO_NCHAR('ven_ID'), TO_NCHAR(v.ven_ID)
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('vendor'), TO_NCHAR('ven_NAME'), TO_NCHAR(v.ven_NAME)
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('vendor'), TO_NCHAR('ven_COUNTRY'), TO_NCHAR(v.ven_COUNTRY)
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('vendor'), TO_NCHAR('ven_DESCRIPT'), TO_NCHAR(NVL(v.ven_DESCRIPT, ' '))
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1

-- Attributes (EAV -> key/value)
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('attribute'), a.att_NAME, TO_NCHAR(DBMS_LOB.SUBSTR(pa.nominal, 2000, 1))
FROM Products p
JOIN ProductAttributes pa ON pa.product_ID = p.product_ID
JOIN Attributes a ON a.att_ID = pa.att_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1

-- Media
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('media'), TO_NCHAR('media_URL'), TO_NCHAR(pm.media_URL)
FROM Products p
JOIN ProductMedia pm ON pm.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('media'), TO_NCHAR('media_TYPE'), TO_NCHAR(pm.media_TYPE)
FROM Products p
JOIN ProductMedia pm ON pm.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('media'), TO_NCHAR('is_primary'), TO_NCHAR(NVL(pm.is_primary, 0))
FROM Products p
JOIN ProductMedia pm ON pm.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('media'), TO_NCHAR('display_order'), TO_NCHAR(NVL(pm.display_order, 0))
FROM Products p
JOIN ProductMedia pm ON pm.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('media'), TO_NCHAR('alt_text'), TO_NCHAR(NVL(pm.alt_text, ' '))
FROM Products p
JOIN ProductMedia pm ON pm.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1

-- Reviews
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('review'), TO_NCHAR('rew_ID'), TO_NCHAR(r.rew_ID)
FROM Products p
JOIN Review r ON r.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('review'), TO_NCHAR('rew_RATING'), TO_NCHAR(r.rew_RATING)
FROM Products p
JOIN Review r ON r.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('review'), TO_NCHAR('rew_COMMENT'), TO_NCHAR(NVL(r.rew_COMMENT, ' '))
FROM Products p
JOIN Review r ON r.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('review'), TO_NCHAR('rew_DATE'), TO_NCHAR(TO_CHAR(r.rew_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
FROM Products p
JOIN Review r ON r.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1

-- Wishlist (users who saved the product)
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('wishlist'), TO_NCHAR('wishlist_ID'), TO_NCHAR(w.wishlist_ID)
FROM Products p
JOIN Wishlist w ON w.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('wishlist'), TO_NCHAR('user_ID'), TO_NCHAR(w.user_ID)
FROM Products p
JOIN Wishlist w ON w.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1

-- Orders and Order Items involving this product
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('order_item'), TO_NCHAR('OrderItems_ID'), TO_NCHAR(oi.OrderItems_ID)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('order_item'), TO_NCHAR('order_ID'), TO_NCHAR(oi.order_ID)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('order_item'), TO_NCHAR('quantity'), TO_NCHAR(oi.quantity)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('order_item'), TO_NCHAR('price'), TO_NCHAR(oi.price)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1

-- Orders meta
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('order'), TO_NCHAR('order_DATE'), TO_NCHAR(TO_CHAR(o.order_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('order'), TO_NCHAR('order_STATUS_ID'), TO_NCHAR(NVL(o.order_STATUS_ID, 0))
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('order'), TO_NCHAR('order_AMOUNT'), TO_NCHAR(NVL(o.order_AMOUNT, 0))
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1

-- Payments for those orders
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('payment'), TO_NCHAR('payment_ID'), TO_NCHAR(pay.payment_ID)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Payments pay ON pay.order_ID = o.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('payment'), TO_NCHAR('payment_METHOD'), TO_NCHAR(pay.payment_METHOD)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Payments pay ON pay.order_ID = o.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('payment'), TO_NCHAR('payment_STATUS_ID'), TO_NCHAR(NVL(pay.payment_STATUS_ID, 0))
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Payments pay ON pay.order_ID = o.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('payment'), TO_NCHAR('payment_AMOUNT'), TO_NCHAR(NVL(pay.payment_AMOUNT, 0))
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Payments pay ON pay.order_ID = o.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('payment'), TO_NCHAR('currency'), TO_NCHAR(pay.currency)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Payments pay ON pay.order_ID = o.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('payment'), TO_NCHAR('transaction_ID'), TO_NCHAR(pay.transaction_ID)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Payments pay ON pay.order_ID = o.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('payment'), TO_NCHAR('payment_DATE'), TO_NCHAR(TO_CHAR(pay.payment_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Payments pay ON pay.order_ID = o.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
WHERE p.product_ID = 1
;

COMMIT;
PROMPT view_product_1_full_details created successfully

-- =====================================================================
-- Product Full Details (Generic for all products)
-- =====================================================================
-- Same as view_product_1_full_details, but without hardcoded product_ID.
-- Filter by product_ID at query time: WHERE product_ID = :id

CREATE OR REPLACE VIEW view_product_full_details AS
-- Base: core scalar fields as key/value rows
SELECT
    p.product_ID,
    p.product_NAME,
    c.category_NAME,
    v.ven_NAME AS vendor_name,
    NVL(p.product_PRICE, 0) AS product_PRICE,
    NVL(p.product_STOCK, 0) AS product_STOCK,
    p.created_AT,
    TO_NCHAR('product') AS section,
    TO_NCHAR('product_NAME') AS item_key,
    TO_NCHAR(p.product_NAME) AS item_value
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('product'), TO_NCHAR('product_PRICE'), TO_NCHAR(NVL(p.product_PRICE, 0))
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('product'), TO_NCHAR('product_STOCK'), TO_NCHAR(NVL(p.product_STOCK, 0))
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('product'), TO_NCHAR('is_featured'), TO_NCHAR(NVL(p.is_featured, 0))
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('product'), TO_NCHAR('is_active'), TO_NCHAR(NVL(p.is_active, 1))
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('product'), TO_NCHAR('product_DESCRIPT'), TO_NCHAR(DBMS_LOB.SUBSTR(p.product_DESCRIPT, 2000, 1))
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('product'), TO_NCHAR('updated_AT'), TO_NCHAR(TO_CHAR(p.updated_AT, 'YYYY-MM-DD"T"HH24:MI:SS'))
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID

-- Category info
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('category'), TO_NCHAR('category_ID'), TO_NCHAR(c.category_ID)
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('category'), TO_NCHAR('category_NAME'), TO_NCHAR(c.category_NAME)
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID

-- Vendor info
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('vendor'), TO_NCHAR('ven_ID'), TO_NCHAR(v.ven_ID)
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('vendor'), TO_NCHAR('ven_NAME'), TO_NCHAR(v.ven_NAME)
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('vendor'), TO_NCHAR('ven_COUNTRY'), TO_NCHAR(v.ven_COUNTRY)
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('vendor'), TO_NCHAR('ven_DESCRIPT'), TO_NCHAR(NVL(v.ven_DESCRIPT, ' '))
FROM Products p
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID

-- Attributes (EAV -> key/value)
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('attribute'), a.att_NAME, TO_NCHAR(DBMS_LOB.SUBSTR(pa.nominal, 2000, 1))
FROM Products p
JOIN ProductAttributes pa ON pa.product_ID = p.product_ID
JOIN Attributes a ON a.att_ID = pa.att_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID

-- Media
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('media'), TO_NCHAR('media_URL'), TO_NCHAR(pm.media_URL)
FROM Products p
JOIN ProductMedia pm ON pm.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('media'), TO_NCHAR('media_TYPE'), TO_NCHAR(pm.media_TYPE)
FROM Products p
JOIN ProductMedia pm ON pm.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('media'), TO_NCHAR('is_primary'), TO_NCHAR(NVL(pm.is_primary, 0))
FROM Products p
JOIN ProductMedia pm ON pm.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('media'), TO_NCHAR('display_order'), TO_NCHAR(NVL(pm.display_order, 0))
FROM Products p
JOIN ProductMedia pm ON pm.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('media'), TO_NCHAR('alt_text'), TO_NCHAR(NVL(pm.alt_text, ' '))
FROM Products p
JOIN ProductMedia pm ON pm.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID

-- Reviews
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('review'), TO_NCHAR('rew_ID'), TO_NCHAR(r.rew_ID)
FROM Products p
JOIN Review r ON r.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('review'), TO_NCHAR('rew_RATING'), TO_NCHAR(r.rew_RATING)
FROM Products p
JOIN Review r ON r.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('review'), TO_NCHAR('rew_COMMENT'), TO_NCHAR(NVL(r.rew_COMMENT, ' '))
FROM Products p
JOIN Review r ON r.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('review'), TO_NCHAR('rew_DATE'), TO_NCHAR(TO_CHAR(r.rew_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
FROM Products p
JOIN Review r ON r.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID

-- Wishlist
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('wishlist'), TO_NCHAR('wishlist_ID'), TO_NCHAR(w.wishlist_ID)
FROM Products p
JOIN Wishlist w ON w.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('wishlist'), TO_NCHAR('user_ID'), TO_NCHAR(w.user_ID)
FROM Products p
JOIN Wishlist w ON w.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID

-- Order items
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('order_item'), TO_NCHAR('OrderItems_ID'), TO_NCHAR(oi.OrderItems_ID)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('order_item'), TO_NCHAR('order_ID'), TO_NCHAR(oi.order_ID)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('order_item'), TO_NCHAR('quantity'), TO_NCHAR(oi.quantity)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('order_item'), TO_NCHAR('price'), TO_NCHAR(oi.price)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID

-- Orders meta
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('order'), TO_NCHAR('order_DATE'), TO_NCHAR(TO_CHAR(o.order_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('order'), TO_NCHAR('order_STATUS_ID'), TO_NCHAR(NVL(o.order_STATUS_ID, 0))
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('order'), TO_NCHAR('order_AMOUNT'), TO_NCHAR(NVL(o.order_AMOUNT, 0))
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID

-- Payments for those orders
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('payment'), TO_NCHAR('payment_ID'), TO_NCHAR(pay.payment_ID)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Payments pay ON pay.order_ID = o.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('payment'), TO_NCHAR('payment_METHOD'), TO_NCHAR(pay.payment_METHOD)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Payments pay ON pay.order_ID = o.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('payment'), TO_NCHAR('payment_STATUS_ID'), TO_NCHAR(NVL(pay.payment_STATUS_ID, 0))
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Payments pay ON pay.order_ID = o.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('payment'), TO_NCHAR('payment_AMOUNT'), TO_NCHAR(NVL(pay.payment_AMOUNT, 0))
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Payments pay ON pay.order_ID = o.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('payment'), TO_NCHAR('currency'), TO_NCHAR(pay.currency)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Payments pay ON pay.order_ID = o.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('payment'), TO_NCHAR('transaction_ID'), TO_NCHAR(pay.transaction_ID)
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Payments pay ON pay.order_ID = o.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
UNION ALL
SELECT p.product_ID, p.product_NAME, c.category_NAME, v.ven_NAME,
       NVL(p.product_PRICE, 0), NVL(p.product_STOCK, 0), p.created_AT,
    TO_NCHAR('payment'), TO_NCHAR('payment_DATE'), TO_NCHAR(TO_CHAR(pay.payment_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
FROM Products p
JOIN OrderItems oi ON oi.product_ID = p.product_ID
JOIN Orders o ON o.order_ID = oi.order_ID
JOIN Payments pay ON pay.order_ID = o.order_ID
JOIN Categories c ON p.category_ID = c.category_ID
JOIN Vendors v ON p.ven_ID = v.ven_ID
;

COMMIT;
PROMPT view_product_full_details created successfully
