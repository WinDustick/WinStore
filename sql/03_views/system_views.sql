-- =====================================================================
-- WinStore - System Views
-- =====================================================================
-- Description: Creates views for system entities like status types,
--              transitions, and audit data
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-05-25
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: 01_schema/01_core_schema.sql, 01_schema/02_reference_data.sql,
--               01_schema/03_status_transitions.sql, 02_audit/audit_setup.sql
-- =====================================================================

USE WinStore
GO

-- =====================================================================
-- Status Transition Views
-- =====================================================================

-- View for order status transitions with readable names
CREATE OR ALTER VIEW dbo.vw_OrderStatusTransitions
AS
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
    dbo.OrderStatusTransitions t
JOIN
    dbo.OrderStatusTypes f ON t.from_status_ID = f.status_ID
JOIN
    dbo.OrderStatusTypes d ON t.to_status_ID = d.status_ID
WHERE
    t.is_allowed = 1;
GO

-- View for payment status transitions with readable names
CREATE OR ALTER VIEW dbo.vw_PaymentStatusTransitions
AS
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
    dbo.PaymentStatusTransitions t
JOIN
    dbo.PaymentStatusTypes f ON t.from_status_ID = f.status_ID
JOIN
    dbo.PaymentStatusTypes d ON t.to_status_ID = d.status_ID
WHERE
    t.is_allowed = 1;
GO

-- View for delivery status transitions with readable names
CREATE OR ALTER VIEW dbo.vw_DeliveryStatusTransitions
AS
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
    dbo.DeliveryStatusTransitions t
JOIN
    dbo.DeliveryStatusTypes f ON t.from_status_ID = f.status_ID
JOIN
    dbo.DeliveryStatusTypes d ON t.to_status_ID = d.status_ID
WHERE
    t.is_allowed = 1;
GO

-- =====================================================================
-- Order & Product Analysis Views
-- =====================================================================

-- Order summary view with status names
CREATE OR ALTER VIEW dbo.vw_OrderSummary
AS
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
    dbo.Orders o
JOIN
    dbo.Users u ON o.user_ID = u.user_ID
LEFT JOIN
    dbo.OrderStatusTypes os ON o.order_STATUS_ID = os.status_ID
LEFT JOIN
    dbo.DeliveryStatusTypes ds ON o.delivery_STATUS_ID = ds.status_ID
LEFT JOIN
    dbo.OrderItems oi ON o.order_ID = oi.order_ID
GROUP BY
    o.order_ID, o.user_ID, u.user_NAME, o.order_DATE, o.order_STATUS_ID, 
    os.status_KEY, os.status_NAME_RU, o.order_AMOUNT, o.promo_ID, o.promo_SAVINGS,
    o.delivery_ADDRESS, o.shipped_DATE, o.estimated_delivery_DATE, o.actual_delivery_DATE,
    o.delivery_STATUS_ID, ds.status_KEY, ds.status_NAME_RU,
    o.shipping_carrier_NAME, o.tracking_NUMBER;
GO

-- Payment summary view with status names
CREATE OR ALTER VIEW dbo.vw_PaymentSummary
AS
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
    dbo.Payments p
JOIN
    dbo.Orders o ON p.order_ID = o.order_ID
JOIN
    dbo.Users u ON o.user_ID = u.user_ID
LEFT JOIN
    dbo.PaymentStatusTypes ps ON p.payment_STATUS_ID = ps.status_ID;
GO

PRINT 'System views created successfully';
GO
