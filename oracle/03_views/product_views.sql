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
