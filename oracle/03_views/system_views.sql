-- =====================================================================
-- WinStore - System Views (Oracle Version)
-- =====================================================================
-- Description: Creates views for system entities like status types,
--              transitions, and audit data
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-09-28
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: 01_schema/01_core_schema.sql, 01_schema/02_reference_data.sql,
--               01_schema/03_status_transitions.sql, 02_audit/audit_setup.sql
-- =====================================================================

-- =====================================================================
-- Status Transition Views
-- =====================================================================

-- View for order status transitions with readable names
CREATE OR REPLACE VIEW vw_OrderStatusTransitions AS
SELECT
    t.from_status_ID,
    f.status_KEY AS from_status_KEY,
    f.status_NAME_RU AS from_status_NAME,
    t.to_status_ID,
    d.status_KEY AS to_status_KEY,
    d.status_NAME_RU AS to_status_NAME,
    t.is_allowed,
    t.transition_name
FROM
    OrderStatusTransitions t
JOIN
    OrderStatusTypes f ON t.from_status_ID = f.status_ID
JOIN
    OrderStatusTypes d ON t.to_status_ID = d.status_ID
WHERE
    t.is_allowed = 1;

-- View for payment status transitions with readable names
CREATE OR REPLACE VIEW vw_PaymentStatusTransitions AS
SELECT
    t.from_status_ID,
    f.status_KEY AS from_status_KEY,
    f.status_NAME_RU AS from_status_NAME,
    t.to_status_ID,
    d.status_KEY AS to_status_KEY,
    d.status_NAME_RU AS to_status_NAME,
    t.is_allowed,
    t.transition_name
FROM
    PaymentStatusTransitions t
JOIN
    PaymentStatusTypes f ON t.from_status_ID = f.status_ID
JOIN
    PaymentStatusTypes d ON t.to_status_ID = d.status_ID
WHERE
    t.is_allowed = 1;

-- View for delivery status transitions with readable names
CREATE OR REPLACE VIEW vw_DeliveryStatusTransitions AS
SELECT
    t.from_status_ID,
    f.status_KEY AS from_status_KEY,
    f.status_NAME_RU AS from_status_NAME,
    t.to_status_ID,
    d.status_KEY AS to_status_KEY,
    d.status_NAME_RU AS to_status_NAME,
    t.is_allowed,
    t.transition_name
FROM
    DeliveryStatusTransitions t
JOIN
    DeliveryStatusTypes f ON t.from_status_ID = f.status_ID
JOIN
    DeliveryStatusTypes d ON t.to_status_ID = d.status_ID
WHERE
    t.is_allowed = 1;

-- =====================================================================
-- Order & Product Analysis Views
-- =====================================================================

-- Order summary view with status names
CREATE OR REPLACE VIEW vw_OrderSummary AS
SELECT
    o.order_ID,
    o.user_ID,
    u.user_NAME,
    o.order_DATE,
    o.order_STATUS_ID,
    os.status_KEY AS order_status_KEY,
    os.status_NAME_RU AS order_status_NAME,
    o.order_AMOUNT,
    o.promo_ID,
    o.promo_SAVINGS,
    o.delivery_ADDRESS,
    o.shipped_DATE,
    o.estimated_delivery_DATE,
    o.actual_delivery_DATE,
    o.delivery_STATUS_ID,
    ds.status_KEY AS delivery_status_KEY,
    ds.status_NAME_RU AS delivery_status_NAME,
    o.shipping_carrier_NAME,
    o.tracking_NUMBER,
    COUNT(oi.OrderItems_ID) AS total_items,
    SUM(oi.quantity) AS total_quantity
FROM
    Orders o
JOIN
    Users u ON o.user_ID = u.user_ID
LEFT JOIN
    OrderStatusTypes os ON o.order_STATUS_ID = os.status_ID
LEFT JOIN
    DeliveryStatusTypes ds ON o.delivery_STATUS_ID = ds.status_ID
LEFT JOIN
    OrderItems oi ON o.order_ID = oi.order_ID
GROUP BY
    o.order_ID, o.user_ID, u.user_NAME, o.order_DATE, o.order_STATUS_ID, 
    os.status_KEY, os.status_NAME_RU, o.order_AMOUNT, o.promo_ID, o.promo_SAVINGS,
    o.delivery_ADDRESS, o.shipped_DATE, o.estimated_delivery_DATE, o.actual_delivery_DATE,
    o.delivery_STATUS_ID, ds.status_KEY, ds.status_NAME_RU,
    o.shipping_carrier_NAME, o.tracking_NUMBER;

-- Payment summary view with status names
CREATE OR REPLACE VIEW vw_PaymentSummary AS
SELECT
    p.payment_ID,
    p.order_ID,
    o.user_ID,
    u.user_NAME,
    p.payment_DATE,
    p.payment_METHOD,
    p.payment_STATUS_ID,
    ps.status_KEY AS payment_status_KEY,
    ps.status_NAME_RU AS payment_status_NAME,
    p.payment_AMOUNT,
    p.currency,
    p.transaction_ID,
    p.created_at,
    p.updated_at
FROM
    Payments p
JOIN
    Orders o ON p.order_ID = o.order_ID
JOIN
    Users u ON o.user_ID = u.user_ID
LEFT JOIN
    PaymentStatusTypes ps ON p.payment_STATUS_ID = ps.status_ID;

-- =====================================================================
-- System Status and Performance Views
-- =====================================================================

-- View for monitoring database object growth
CREATE OR REPLACE VIEW vw_DatabaseObjectStats AS
SELECT
    table_name,
    num_rows,
    blocks,
    empty_blocks,
    avg_row_len,
    last_analyzed
FROM
    user_tables
ORDER BY
    num_rows DESC;

-- View for monitoring system status and health
CREATE OR REPLACE VIEW vw_SystemStatus AS
SELECT
    'Orders' AS entity_name,
    COUNT(*) AS total_count,
    TO_CHAR(NVL(MAX(order_DATE), SYSDATE), 'YYYY-MM-DD HH24:MI:SS') AS last_activity,
    SUM(NVL(order_AMOUNT, 0)) AS total_amount
FROM
    Orders
UNION ALL
SELECT
    'Products' AS entity_name,
    COUNT(*) AS total_count,
    TO_CHAR(NVL(MAX(created_AT), SYSDATE), 'YYYY-MM-DD HH24:MI:SS') AS last_activity,
    SUM(NVL(product_PRICE, 0) * NVL(product_STOCK, 0)) AS total_value
FROM
    Products
UNION ALL
SELECT
    'Users' AS entity_name,
    COUNT(*) AS total_count,
    TO_CHAR(NVL(MAX(created_AT), SYSDATE), 'YYYY-MM-DD HH24:MI:SS') AS last_activity,
    NULL AS total_value
FROM
    Users
UNION ALL
SELECT
    'Payments' AS entity_name,
    COUNT(*) AS total_count,
    TO_CHAR(NVL(MAX(payment_DATE), SYSDATE), 'YYYY-MM-DD HH24:MI:SS') AS last_activity,
    SUM(NVL(payment_AMOUNT, 0)) AS total_amount
FROM
    Payments;

COMMIT;
PROMPT System views created successfully
