-- =====================================================================
-- WinStore - Product Views
-- =====================================================================
-- Description: Creates views for accessing product data in a denormalized
--              format, particularly for specific product categories
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-05-25
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: 01_schema/01_core_schema.sql
-- =====================================================================

USE WinStore
GO

-- =====================================================================
-- GPU Product View
-- =====================================================================

-- View for GPU product details
CREATE OR ALTER VIEW dbo.view_gpu_details AS
SELECT
    p.product_ID,
    p.product_NAME,
    c.category_NAME,
    v.ven_NAME AS vendor_name,
    p.product_PRICE,
    p.product_STOCK,
    p.product_DESCRIPT,
    p.created_AT,
    -- Columns resulting from PIVOT
    pt.[GPU Name],
    pt.[Architecture],
    pt.[Foundry],
    pt.[Process Size],
    pt.[Transistors],
    pt.[Die Size],
    pt.[Release Date],
    pt.[Generation],
    pt.[Launch Price],
    pt.[Memory Clock],
    pt.[Memory Size],
    pt.[Memory Type],
    pt.[Memory Bus],
    pt.[Bandwidth],
    pt.[Shading Units],
    pt.[TMUs],
    pt.[ROPs],
    pt.[RT Cores],
    pt.[Tensor Cores],
    pt.[TDP],
    pt.[Outputs],
    pt.[DirectX],
    pt.[OpenGL],
    pt.[Vulkan],
    pt.[Shader Model],
    pt.[Bus Interface],
    pt.[Power Connectors],
    pt.[Suggested PSU]
FROM
    Products p
-- Join Category to ensure it's a GPU (category_ID = 1)
JOIN
    Categories c ON p.category_ID = c.category_ID AND c.category_ID = 1
-- Join Vendor
JOIN
    Vendors v ON p.ven_ID = v.ven_ID
-- Join the result of the PIVOT query
JOIN
    (
        -- Start of PIVOT subquery
        SELECT
            product_ID,
            -- Explicitly list ALL columns expected from the PIVOT
            [GPU Name], [Architecture], [Foundry], [Process Size], [Transistors], [Die Size],
            [Release Date], [Generation], [Launch Price], [Memory Clock],
            [Memory Size], [Memory Type], [Memory Bus], [Bandwidth], [Shading Units],
            [TMUs], [ROPs], [RT Cores], [Tensor Cores], [TDP], [Outputs], [DirectX],
            [OpenGL], [Vulkan], [Shader Model], [Bus Interface], [Power Connectors], [Suggested PSU]
        FROM
            (
                -- Source data for PIVOT: Product ID, Attribute Name, Attribute Value
                SELECT
                    pvt_p.product_ID,
                    pvt_a.att_NAME,
                    pvt_pa.nominal -- The value that will populate the new columns
                FROM
                    Products pvt_p
                JOIN
                    ProductAttributes pvt_pa ON pvt_p.product_ID = pvt_pa.product_ID
                JOIN
                    Attributes pvt_a ON pvt_pa.att_ID = pvt_a.att_ID
                WHERE
                    pvt_p.category_ID = 1 -- Crucial: Filter the SOURCE for PIVOT
                    -- And select only the attributes needed as columns
                    AND pvt_a.att_NAME IN (
                        'GPU Name', 'Architecture', 'Foundry', 'Process Size', 'Transistors', 'Die Size',
                        'Release Date', 'Generation', 'Launch Price', 'Memory Clock',
                        'Memory Size', 'Memory Type', 'Memory Bus', 'Bandwidth', 'Shading Units',
                        'TMUs', 'ROPs', 'RT Cores', 'Tensor Cores', 'TDP', 'Outputs', 'DirectX',
                        'OpenGL', 'Vulkan', 'Shader Model', 'Bus Interface', 'Power Connectors', 'Suggested PSU'
                    )
            ) AS SourceTable
        -- The PIVOT operator
        PIVOT
        (
            MAX(nominal) -- Aggregation function (MAX or MIN works for unique values)
            FOR att_NAME IN ( -- Specify which column contains the names of future columns
                -- Explicitly list ALL attribute names that will become columns
                [GPU Name], [Architecture], [Foundry], [Process Size], [Transistors], [Die Size],
                [Release Date], [Generation], [Launch Price], [Memory Clock],
                [Memory Size], [Memory Type], [Memory Bus], [Bandwidth], [Shading Units],
                [TMUs], [ROPs], [RT Cores], [Tensor Cores], [TDP], [Outputs], [DirectX],
                [OpenGL], [Vulkan], [Shader Model], [Bus Interface], [Power Connectors], [Suggested PSU]
            )
        ) AS PivotTable -- Alias for the PIVOT result
    ) AS pt ON p.product_ID = pt.product_ID;
GO

-- =====================================================================
-- CPU Product View
-- =====================================================================

-- View for CPU product details
CREATE OR ALTER VIEW dbo.view_cpu_details AS
SELECT
    p.product_ID,
    p.product_NAME,
    c.category_NAME,
    v.ven_NAME AS vendor_name,
    p.product_PRICE,
    p.product_STOCK,
    p.product_DESCRIPT,
    p.created_AT,
    -- Columns resulting from PIVOT
    pt.[Codename],
    pt.[Architecture],
    pt.[Foundry],
    pt.[Process Size],
    pt.[Transistors],
    pt.[Die Size],
    pt.[Release Date],
    pt.[Generation],
    pt.[Launch Price],
    pt.[# of Cores],
    pt.[# of Threads],
    pt.[Base Clock],
    pt.[Boost Clock],
    pt.[Cache L1],
    pt.[Cache L2],
    pt.[Cache L3],
    pt.[TDP],
    pt.[Socket],
    pt.[Integrated Graphics],
    pt.[Memory Support],
    pt.[PCI-Express],
    pt.[Multiplier Unlocked],
    pt.[SMT],
    pt.[SSE4.2],
    pt.[AVX2],
    pt.[AES],
    pt.[AMD-V],
    pt.[VT-x]
FROM
    Products p
-- Join Category to filter for CPU (category_ID = 2)
JOIN
    Categories c ON p.category_ID = c.category_ID AND c.category_ID = 2
-- Join Vendor
JOIN
    Vendors v ON p.ven_ID = v.ven_ID
-- Join the PIVOT result
JOIN
    (
        -- Start of PIVOT subquery for CPU
        SELECT
            product_ID,
            -- List all expected column names
            [Codename], [Architecture], [Foundry], [Process Size], [Transistors], [Die Size],
            [Release Date], [Generation], [Launch Price], [# of Cores], [# of Threads],
            [Base Clock], [Boost Clock], [Cache L1], [Cache L2], [Cache L3], [TDP], [Socket],
            [Integrated Graphics], [Memory Support], [PCI-Express], [Multiplier Unlocked],
            [SMT], [SSE4.2], [AVX2], [AES], [AMD-V], [VT-x]
        FROM
            (
                -- Source data for PIVOT
                SELECT
                    pvt_p.product_ID,
                    pvt_a.att_NAME,
                    pvt_pa.nominal
                FROM
                    Products pvt_p
                JOIN
                    ProductAttributes pvt_pa ON pvt_p.product_ID = pvt_pa.product_ID
                JOIN
                    Attributes pvt_a ON pvt_pa.att_ID = pvt_a.att_ID
                WHERE
                    pvt_p.category_ID = 2 -- Filter for CPU category
                    AND pvt_a.att_NAME IN (
                        'Codename', 'Architecture', 'Foundry', 'Process Size', 'Transistors', 'Die Size',
                        'Release Date', 'Generation', 'Launch Price', '# of Cores', '# of Threads',
                        'Base Clock', 'Boost Clock', 'Cache L1', 'Cache L2', 'Cache L3', 'TDP', 'Socket',
                        'Integrated Graphics', 'Memory Support', 'PCI-Express', 'Multiplier Unlocked',
                        'SMT', 'SSE4.2', 'AVX2', 'AES', 'AMD-V', 'VT-x'
                    )
            ) AS SourceTable
        -- The PIVOT operator
        PIVOT
        (
            MAX(nominal)
            FOR att_NAME IN (
                [Codename], [Architecture], [Foundry], [Process Size], [Transistors], [Die Size],
                [Release Date], [Generation], [Launch Price], [# of Cores], [# of Threads],
                [Base Clock], [Boost Clock], [Cache L1], [Cache L2], [Cache L3], [TDP], [Socket],
                [Integrated Graphics], [Memory Support], [PCI-Express], [Multiplier Unlocked],
                [SMT], [SSE4.2], [AVX2], [AES], [AMD-V], [VT-x]
            )
        ) AS PivotTable -- Alias for the PIVOT result
    ) AS pt ON p.product_ID = pt.product_ID;
GO

-- =====================================================================
-- RAM Product View
-- =====================================================================

-- View for RAM product details
CREATE OR ALTER VIEW dbo.view_ram_details AS
SELECT
    p.product_ID,
    p.product_NAME,
    c.category_NAME,
    v.ven_NAME AS vendor_name,
    p.product_PRICE,
    p.product_STOCK,
    p.product_DESCRIPT,
    p.created_AT,
    -- Columns resulting from PIVOT
    pt.[Memory Type],
    pt.[Speed (MT/s)],
    pt.[Timings],
    pt.[Voltage (V)],
    pt.[Capacity (GB)],
    pt.[Profile Type]
FROM
    Products p
-- Join Category to filter for RAM (category_ID = 4)
JOIN
    Categories c ON p.category_ID = c.category_ID AND c.category_ID = 4
-- Join Vendor
JOIN
    Vendors v ON p.ven_ID = v.ven_ID
-- Join the PIVOT result
JOIN
    (
        -- Start of PIVOT subquery for RAM
        SELECT
            product_ID,
            -- List all expected column names
            [Memory Type], [Speed (MT/s)], [Timings], [Voltage (V)], [Capacity (GB)], [Profile Type]
        FROM
            (
                -- Source data for PIVOT
                SELECT
                    pvt_p.product_ID,
                    pvt_a.att_NAME,
                    pvt_pa.nominal
                FROM
                    Products pvt_p
                JOIN
                    ProductAttributes pvt_pa ON pvt_p.product_ID = pvt_pa.product_ID
                JOIN
                    Attributes pvt_a ON pvt_pa.att_ID = pvt_a.att_ID
                WHERE
                    pvt_p.category_ID = 4 -- Filter for RAM category
                    AND pvt_a.att_NAME IN (
                        'Memory Type', 'Speed (MT/s)', 'Timings', 'Voltage (V)', 'Capacity (GB)', 'Profile Type'
                    )
            ) AS SourceTable
        -- The PIVOT operator
        PIVOT
        (
            MAX(nominal)
            FOR att_NAME IN (
                [Memory Type], [Speed (MT/s)], [Timings], [Voltage (V)], [Capacity (GB)], [Profile Type]
            )
        ) AS PivotTable -- Alias for the PIVOT result
    ) AS pt ON p.product_ID = pt.product_ID;
GO

-- View that lists product attributes row by row (useful for filtering and dynamic queries)
CREATE OR ALTER VIEW dbo.view_product_attributes_list AS
SELECT
    -- Synthetic Primary Key for Directus
    CAST(pa.product_ID AS VARCHAR(10)) + '-' + CAST(pa.att_ID AS VARCHAR(10)) AS view_row_id,
    
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
    pa.nominal,
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
GO

-- Создаём индексированное представление для часто запрашиваемых данных о товарах
CREATE OR ALTER VIEW dbo.view_product_summary
WITH SCHEMABINDING
AS
SELECT
    p.product_ID,
    p.product_NAME,
    p.product_PRICE,
    p.product_STOCK,
    p.is_featured,
    p.is_active,
    c.category_ID,
    c.category_NAME,
    v.ven_ID,
    v.ven_NAME AS vendor_name
FROM
    dbo.Products p
JOIN
    dbo.Categories c ON p.category_ID = c.category_ID
JOIN
    dbo.Vendors v ON p.ven_ID = v.ven_ID;
GO

-- Создаем уникальный кластерный индекс на представлении, превращая его в индексированное представление
CREATE UNIQUE CLUSTERED INDEX IX_view_product_summary
ON dbo.view_product_summary(product_ID);
GO

-- Создаем некластерный индекс для поиска по названию и категории
CREATE NONCLUSTERED INDEX IX_view_product_summary_Name_Category
ON dbo.view_product_summary(product_NAME, category_ID);
GO

-- Создаем некластерный индекс для фильтрации по активности и рекомендуемым товарам
CREATE NONCLUSTERED INDEX IX_view_product_summary_Featured_Active
ON dbo.view_product_summary(is_featured, is_active)
INCLUDE (product_NAME, product_PRICE, category_NAME);
GO

PRINT 'Product views created successfully';
GO
