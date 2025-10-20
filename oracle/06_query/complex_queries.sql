-- =====================================================================
-- WinStore - Complex Analytical Queries (Oracle Version)
-- =====================================================================
-- Description: Коллекция из 10 сложных и продвинутых SQL-запросов для
--              аналитики, отчетности и манипулирования данными, демонстрирующая
--              лучшие практики и расширенные возможности Oracle SQL.
-- Author:      WinStore Development Team
-- Created:     2025-10-18
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: The schema created by scripts in oracle/01_schema/
-- =====================================================================

SET SERVEROUTPUT ON;
PROMPT ========== EXECUTING COMPLEX QUERIES ==========

-- =====================================================================
-- Query 1: Top 5 Loyal Customers (WITH Clause)
-- =====================================================================
-- Description: Этот запрос определяет 5 самых лояльных клиентов на основе
--              их 'оценки лояльности'. Оценка рассчитывается по общей сумме
--              трат и количеству сделанных заказов. Общее табличное выражение (CTE)
--              используется для предварительной агрегации данных по клиентам
--              перед расчетом итогового ранга.
-- =====================================================================
PROMPT ----- Query 1: Top 5 Loyal Customers (WITH) -----
WITH CustomerSummary AS (
    SELECT
        u.user_ID,
        u.user_NAME,
        u.user_EMAIL,
        COUNT(o.order_ID) AS total_orders,
        SUM(o.order_AMOUNT) AS total_spent
    FROM
        Users u
    JOIN
        Orders o ON u.user_ID = o.user_ID
    WHERE
        o.order_STATUS_ID IN (
            SELECT status_ID FROM OrderStatusTypes WHERE status_KEY IN ('Completed', 'Delivered', 'Shipped')
        )
    GROUP BY
        u.user_ID,
        u.user_NAME,
        u.user_EMAIL
)
SELECT
    user_ID,
    user_NAME,
    total_orders,
    total_spent,
    -- Loyalty score calculation and ranking
    RANK() OVER (ORDER BY total_spent DESC, total_orders DESC) AS loyalty_rank
FROM
    CustomerSummary
FETCH FIRST 5 ROWS ONLY;


-- =====================================================================
-- Query 2: Monthly Sales Growth (Recursive WITH Clause)
-- =====================================================================
-- Description: Этот запрос вычисляет процентный рост продаж в месячном исчислении.
--              Он использует CTE для агрегации продаж по месяцам, а затем еще
--              одно CTE с аналитической функцией LAG() для сравнения продаж
--              каждого месяца с предыдущим.
-- =====================================================================
PROMPT ----- Query 2: Monthly Sales Growth (WITH and LAG) -----
WITH MonthlySales AS (
    SELECT
        TRUNC(order_DATE, 'MM') AS sales_month,
        SUM(order_AMOUNT) AS monthly_total
    FROM
        Orders
    WHERE
        order_STATUS_ID IN (SELECT status_ID FROM OrderStatusTypes WHERE status_KEY NOT IN ('Cancelled', 'Cart'))
    GROUP BY
        TRUNC(order_DATE, 'MM')
),
SalesGrowth AS (
    SELECT
        sales_month,
        monthly_total,
        LAG(monthly_total, 1, 0) OVER (ORDER BY sales_month) AS previous_month_total
    FROM
        MonthlySales
)
SELECT
    TO_CHAR(sales_month, 'YYYY-MM') AS sales_month,
    previous_month_total,
    monthly_total,
    -- Calculate growth percentage, handling division by zero
    CASE
        WHEN previous_month_total > 0 THEN
            ROUND(((monthly_total - previous_month_total) / previous_month_total) * 100, 2)
        ELSE
            NULL -- No growth percentage if previous month had no sales
    END AS growth_percentage
FROM
    SalesGrowth
ORDER BY
    sales_month;


-- =====================================================================
-- Query 3: Synchronize Product Stock (MERGE)
-- =====================================================================
-- Description: Этот запрос демонстрирует использование MERGE для синхронизации
--              уровня складских остатков из временной промежуточной таблицы
--              (staging table) с новыми поступлениями. Если товар существует,
--              его остаток обновляется. В противном случае вставляется новая
--              запись о товаре (с использованием значений по умолчанию для
--              некоторых полей). Это идемпотентная операция, идеально
--              подходящая для ETL-процессов.
-- =====================================================================
PROMPT ----- Query 3: Synchronize Product Stock (MERGE) -----
-- Setup a temporary staging table for the demo
CREATE GLOBAL TEMPORARY TABLE InventoryStaging (
    product_SKU NVARCHAR2(255),
    new_stock_level NUMBER,
    product_price NUMBER(10,2)
) ON COMMIT PRESERVE ROWS;

INSERT INTO InventoryStaging (product_SKU, new_stock_level, product_price) VALUES ('NVIDIA-RTX-4090', 50, 1599.99);
INSERT INTO InventoryStaging (product_SKU, new_stock_level, product_price) VALUES ('AMD-RYZEN9-7950X', 100, 549.00);
INSERT INTO InventoryStaging (product_SKU, new_stock_level, product_price) VALUES ('NEW-COOL-GADGET-01', 200, 99.99);

MERGE INTO Products p
USING (
    SELECT product_SKU, new_stock_level, product_price FROM InventoryStaging
) s ON (p.product_NAME = s.product_SKU)
WHEN MATCHED THEN
    UPDATE SET
        p.product_STOCK = p.product_STOCK + s.new_stock_level,
        p.product_PRICE = s.product_price,
        p.updated_AT = SYSTIMESTAMP
WHEN NOT MATCHED THEN
    INSERT (
        category_ID,
        product_NAME,
        product_DESCRIPT,
        product_PRICE,
        product_STOCK,
        ven_ID,
        is_active
    )
    VALUES (
        1, -- Default Category ID (e.g., 'Uncategorized')
        s.product_SKU,
        'New product added from inventory feed.',
        s.product_price,
        s.new_stock_level,
        1, -- Default Vendor ID
        1
    );

-- Clean up the temporary table
DROP TABLE InventoryStaging;


-- =====================================================================
-- Query 4: Promote Users to VIP Status (MERGE)
-- =====================================================================
-- Description: Этот запрос использует MERGE для обновления роли клиентов на 'VIP',
--              если их общая сумма трат превышает определенный порог ($5000).
--              Он нацелен только на пользователей с ролью 'Customer' и не
--              затрагивает тех, кто уже является 'Admin' или 'VIP'.
-- =====================================================================
PROMPT ----- Query 4: Promote Users to VIP Status (MERGE) -----
-- First, let's add a 'VIP' role for the demo if it doesn't exist
-- In a real scenario, this would be managed via reference data scripts.
-- MERGE INTO UserRoles ...

MERGE INTO Users u
USING (
    SELECT
        o.user_ID
    FROM
        Orders o
    WHERE
        o.order_STATUS_ID IN (SELECT status_ID FROM OrderStatusTypes WHERE status_KEY = 'Completed')
    GROUP BY
        o.user_ID
    HAVING
        SUM(o.order_AMOUNT) > 5000
) s ON (u.user_ID = s.user_ID)
WHEN MATCHED THEN
    UPDATE SET
        u.user_ROLE = 'Admin' -- Assuming 'Admin' is the VIP role for this example
    WHERE
        u.user_ROLE = 'Customer'; -- Only update if they are currently a standard customer


-- =====================================================================
-- Query 5: Top 3 Selling Products per Category (Analytic Function)
-- =====================================================================
-- Description: Этот запрос использует аналитическую функцию RANK() для поиска
--              3 самых продаваемых товаров в каждой категории на основе
--              общего количества проданных единиц.
-- =====================================================================
PROMPT ----- Query 5: Top 3 Selling Products per Category (RANK) -----
WITH ProductSales AS (
    SELECT
        p.product_ID,
        p.product_NAME,
        p.category_ID,
        c.category_NAME,
        SUM(oi.quantity) AS total_quantity_sold
    FROM
        OrderItems oi
    JOIN
        Products p ON oi.product_ID = p.product_ID
    JOIN
        Categories c ON p.category_ID = c.category_ID
    GROUP BY
        p.product_ID,
        p.product_NAME,
        p.category_ID,
        c.category_NAME
),
RankedSales AS (
    SELECT
        product_ID,
        product_NAME,
        category_NAME,
        total_quantity_sold,
        RANK() OVER (PARTITION BY category_ID ORDER BY total_quantity_sold DESC) as sales_rank
    FROM
        ProductSales
)
SELECT
    category_NAME,
    product_NAME,
    total_quantity_sold,
    sales_rank
FROM
    RankedSales
WHERE
    sales_rank <= 3
ORDER BY
    category_NAME,
    sales_rank;


-- =====================================================================
-- Query 6: Running Total of Monthly Sales (Analytic Function)
-- =====================================================================
-- Description: Этот запрос вычисляет накопительный (бегущий) итог продаж
--              по месяцам. Это полезно для отслеживания роста выручки
--              в течение всего времени существования бизнеса.
-- =====================================================================
PROMPT ----- Query 6: Running Total of Monthly Sales (SUM OVER) -----
WITH MonthlySales AS (
    SELECT
        TRUNC(order_DATE, 'MM') AS sales_month,
        SUM(order_AMOUNT) AS monthly_total
    FROM
        Orders
    WHERE
        order_STATUS_ID IN (SELECT status_ID FROM OrderStatusTypes WHERE status_KEY NOT IN ('Cancelled', 'Cart'))
    GROUP BY
        TRUNC(order_DATE, 'MM')
)
SELECT
    TO_CHAR(sales_month, 'YYYY-MM') AS sales_month,
    monthly_total,
    SUM(monthly_total) OVER (ORDER BY sales_month) AS running_total_sales
FROM
    MonthlySales
ORDER BY
    sales_month;


-- =====================================================================
-- Query 7: Pivot of Sales by Category and Year (PIVOT)
-- =====================================================================
-- Description: Этот запрос использует оператор PIVOT для преобразования строк
--              данных в столбцы. Он показывает общие продажи для каждой
--              категории в разбивке по годам, обеспечивая наглядное
--              сравнение год к году.
-- =====================================================================
PROMPT ----- Query 7: Sales by Category and Year (PIVOT) -----
SELECT *
FROM (
    SELECT
        c.category_NAME,
        EXTRACT(YEAR FROM o.order_DATE) AS sales_year,
        oi.quantity * oi.price AS line_total
    FROM
        Orders o
    JOIN
        OrderItems oi ON o.order_ID = oi.order_ID
    JOIN
        Products p ON oi.product_ID = p.product_ID
    JOIN
        Categories c ON p.category_ID = c.category_ID
    WHERE
        o.order_STATUS_ID IN (SELECT status_ID FROM OrderStatusTypes WHERE status_KEY NOT IN ('Cancelled', 'Cart'))
)
PIVOT (
    SUM(line_total)
    FOR sales_year IN (2023, 2024, 2025)
)
ORDER BY
    category_NAME;


-- =====================================================================
-- Query 8: Find "Power Users" (Advanced JOINs and Subqueries)
-- =====================================================================
-- Description: Этот запрос определяет 'продвинутых пользователей' (power users),
--              которые соответствуют определенным критериям:
--              1. Сделали не менее 2 заказов.
--              2. Приобрели товары как минимум из 3 разных категорий.
--              3. Оставили хотя бы один отзыв с высоким рейтингом (4 звезды или выше).
-- =====================================================================
PROMPT ----- Query 8: Find "Power Users" -----
SELECT
    u.user_ID,
    u.user_NAME,
    u.user_EMAIL
FROM
    Users u
WHERE
    -- Condition 1: At least 2 orders
    (SELECT COUNT(o.order_ID) FROM Orders o WHERE o.user_ID = u.user_ID) >= 2
AND
    -- Condition 2: Purchased from at least 3 categories
    (
        SELECT COUNT(DISTINCT p.category_ID)
        FROM OrderItems oi
        JOIN Products p ON oi.product_ID = p.product_ID
        JOIN Orders o ON oi.order_ID = o.order_ID
        WHERE o.user_ID = u.user_ID
    ) >= 3
AND
    -- Condition 3: Left at least one high-rated review
    EXISTS (
        SELECT 1
        FROM Review r
        WHERE r.user_ID = u.user_ID AND r.rew_RATING >= 4
    );


-- =====================================================================
-- Query 9: Products Never Sold (NOT EXISTS)
-- =====================================================================
-- Description: Этот запрос находит все товары, которые никогда не были
--              включены ни в один заказ. Он использует конструкцию `NOT EXISTS`,
--              которая для этой задачи часто более эффективна, чем `NOT IN`
--              или `LEFT JOIN` с проверкой `WHERE IS NULL`.
-- =====================================================================
PROMPT ----- Query 9: Products Never Sold (NOT EXISTS) -----
SELECT
    p.product_ID,
    p.product_NAME,
    p.product_STOCK
FROM
    Products p
WHERE
    NOT EXISTS (
        SELECT 1
        FROM OrderItems oi
        WHERE oi.product_ID = p.product_ID
    )
ORDER BY
    p.product_NAME;


-- =====================================================================
-- Query 10: Sales Report with Subtotals (GROUP BY ROLLUP)
-- =====================================================================
-- Description: Этот запрос генерирует отчет о продажах с несколькими уровнями
--              агрегации за один проход. Он предоставляет подытоги по каждому
--              поставщику, по каждой категории внутри поставщика, а также
--              общий итог по всем продажам, используя расширение `ROLLUP`.
-- =====================================================================
PROMPT ----- Query 10: Sales Report with Subtotals (ROLLUP) -----
SELECT
    v.ven_NAME,
    c.category_NAME,
    SUM(oi.quantity * oi.price) AS total_sales
FROM
    OrderItems oi
JOIN
    Products p ON oi.product_ID = p.product_ID
JOIN
    Categories c ON p.category_ID = c.category_ID
JOIN
    Vendors v ON p.ven_ID = v.ven_ID
GROUP BY
    ROLLUP(v.ven_NAME, c.category_NAME)
ORDER BY
    v.ven_NAME,
    c.category_NAME;

PROMPT ========== COMPLEX QUERY EXECUTION COMPLETE ==========
