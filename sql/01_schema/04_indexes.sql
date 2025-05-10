-- =====================================================================
-- WinStore - Database Indexes
-- =====================================================================
-- Description: Creates all required indexes for the database tables to
--              optimize query performance.
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-05-25
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: 01_core_schema.sql, 02_reference_data.sql, 03_status_transitions.sql
-- =====================================================================

USE WinStore
GO

-- =====================================================================
-- Core Table Indexes
-- =====================================================================

-- Product Indexes
CREATE INDEX IX_Products_CategoryID ON dbo.Products(category_ID);
CREATE INDEX IX_Products_VendorID ON dbo.Products(ven_ID);
CREATE INDEX IX_Products_Featured_Active ON dbo.Products(is_featured, is_active);
CREATE INDEX IX_Products_Name_Category_Price ON dbo.Products(product_NAME, category_ID, product_PRICE);
CREATE INDEX IX_Products_Category_Vendor ON dbo.Products(category_ID, ven_ID);

-- Order Indexes
CREATE INDEX IX_Orders_UserID ON dbo.Orders(user_ID);
CREATE INDEX IX_Orders_OrderStatusID ON dbo.Orders(order_STATUS_ID);
CREATE INDEX IX_Orders_DeliveryStatusID ON dbo.Orders(delivery_STATUS_ID);
CREATE INDEX IX_Orders_Status_Date_New ON dbo.Orders(order_STATUS_ID, order_DATE);

-- OrderItems Indexes
CREATE INDEX IX_OrderItems_OrderID ON dbo.OrderItems(order_ID);
CREATE INDEX IX_OrderItems_ProductID ON dbo.OrderItems(product_ID);
CREATE INDEX IX_OrderItems_Order_Product_Qty_Price ON dbo.OrderItems(order_ID, product_ID, quantity, price);

-- Payment Indexes
CREATE INDEX IX_Payments_OrderID ON dbo.Payments(order_ID);
CREATE INDEX IX_Payments_PaymentStatusID ON dbo.Payments(payment_STATUS_ID);
CREATE INDEX IX_Payments_Status_Date_New ON dbo.Payments(payment_STATUS_ID, payment_DATE);

-- Review Indexes
CREATE INDEX IX_Review_UserID ON dbo.Review(user_ID);
CREATE INDEX IX_Review_ProductID ON dbo.Review(product_ID);

-- Wishlist Indexes
CREATE INDEX IX_Wishlist_UserID_DateAdded ON dbo.Wishlist(user_ID, added_AT);

-- ProductMedia Indexes
CREATE INDEX IX_ProductMedia_ProductID_IsPrimary ON dbo.ProductMedia(product_ID, is_primary);
CREATE INDEX IX_ProductMedia_ProductID_Order ON dbo.ProductMedia(product_ID, display_order);

-- Promotion Indexes
CREATE INDEX IX_Promotions_IsActive_ValidDates ON dbo.Promotions(is_ACTIVE, valid_FROM, valid_TO);
CREATE INDEX IX_Promotions_Code ON dbo.Promotions(promo_CODE);

-- PromotionApplications Indexes
CREATE INDEX IX_PromotionApplications_TargetType_TargetID ON dbo.PromotionApplications(target_TYPE, target_ID);

-- Добавляем покрывающие индексы для частых запросов

-- Индекс для ускорения запросов к списку желаний с включением часто запрашиваемых столбцов
CREATE NONCLUSTERED INDEX IX_Wishlist_UserID_Covering 
ON dbo.Wishlist(user_ID)
INCLUDE (product_ID, added_AT, notes);
GO

-- Индекс для запросов к таблице OrderItems с часто используемыми столбцами
CREATE NONCLUSTERED INDEX IX_OrderItems_OrderID_ProductID_Covering
ON dbo.OrderItems(order_ID, product_ID)
INCLUDE (quantity, price);
GO

-- Индекс для улучшения производительности запросов к платежам с фильтрами по статусу
CREATE NONCLUSTERED INDEX IX_Payments_StatusID_OrderID
ON dbo.Payments(payment_STATUS_ID, order_ID)
INCLUDE (payment_DATE, payment_AMOUNT, transaction_ID);
GO

-- Индекс для ускорения запросов к таблице Orders по статусу заказа
CREATE NONCLUSTERED INDEX IX_Orders_StatusID_UserID_Covering
ON dbo.Orders(order_STATUS_ID, user_ID)
INCLUDE (order_DATE, order_AMOUNT, promo_ID, delivery_STATUS_ID);
GO

-- Индекс для оптимизации запросов к статусам с фильтрацией по ключам
CREATE NONCLUSTERED INDEX IX_OrderStatusTypes_StatusKey
ON dbo.OrderStatusTypes(status_KEY)
INCLUDE (status_NAME_RU, status_NAME_EN, display_ORDER);
GO

-- =====================================================================
-- Status Transition Indexes
-- =====================================================================

-- Create indexes on status transition tables for fast lookups
CREATE INDEX IX_OrderStatusTransitions_FromStatus 
ON dbo.OrderStatusTransitions(from_status_ID);

CREATE INDEX IX_PaymentStatusTransitions_FromStatus 
ON dbo.PaymentStatusTransitions(from_status_ID);

CREATE INDEX IX_DeliveryStatusTransitions_FromStatus 
ON dbo.DeliveryStatusTransitions(from_status_ID);

PRINT 'Database indexes created successfully.';
GO
