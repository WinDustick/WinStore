-- =====================================================================
-- WinStore - Database Indexes (Oracle Version)
-- =====================================================================
-- Description: Creates all required indexes for the database tables to
--              optimize query performance.
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-09-28
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: 01_core_schema.sql, 02_reference_data.sql, 03_status_transitions.sql
-- =====================================================================

-- =====================================================================
-- Core Table Indexes
-- =====================================================================

-- Product Indexes
CREATE INDEX IX_Products_CategoryID ON Products(category_ID);
CREATE INDEX IX_Products_VendorID ON Products(ven_ID);
CREATE INDEX IX_Products_Featured_Active ON Products(is_featured, is_active);
CREATE INDEX IX_Products_Name_Category_Price ON Products(product_NAME, category_ID, product_PRICE);
CREATE INDEX IX_Products_Category_Vendor ON Products(category_ID, ven_ID);

-- Order Indexes
CREATE INDEX IX_Orders_UserID ON Orders(user_ID);
CREATE INDEX IX_Orders_OrderStatusID ON Orders(order_STATUS_ID);
CREATE INDEX IX_Orders_DeliveryStatusID ON Orders(delivery_STATUS_ID);
CREATE INDEX IX_Orders_Status_Date_New ON Orders(order_STATUS_ID, order_DATE);

-- OrderItems Indexes
CREATE INDEX IX_OrderItems_OrderID ON OrderItems(order_ID);
CREATE INDEX IX_OrderItems_ProductID ON OrderItems(product_ID);
CREATE INDEX IX_OrderItems_Order_Product_Qty_Price ON OrderItems(order_ID, product_ID, quantity, price);

-- Payment Indexes
CREATE INDEX IX_Payments_OrderID ON Payments(order_ID);
CREATE INDEX IX_Payments_PaymentStatusID ON Payments(payment_STATUS_ID);
CREATE INDEX IX_Payments_Status_Date_New ON Payments(payment_STATUS_ID, payment_DATE);

-- Review Indexes
CREATE INDEX IX_Review_UserID ON Review(user_ID);
CREATE INDEX IX_Review_ProductID ON Review(product_ID);

-- Wishlist Indexes
CREATE INDEX IX_Wishlist_UserID_DateAdded ON Wishlist(user_ID, added_AT);

-- ProductMedia Indexes
CREATE INDEX IX_ProductMedia_ProductID_IsPrimary ON ProductMedia(product_ID, is_primary);
CREATE INDEX IX_ProductMedia_ProductID_Order ON ProductMedia(product_ID, display_order);

-- Promotion Indexes
CREATE INDEX IX_Promotions_IsActive_ValidDates ON Promotions(is_ACTIVE, valid_FROM, valid_TO);
-- CREATE INDEX IX_Promotions_Code ON Promotions(promo_CODE);

-- PromotionApplications Indexes
CREATE INDEX IX_PromotionApplications_TargetType_TargetID ON PromotionApplications(target_TYPE, target_ID);

-- Function-Based Indexes to optimize specific queries

-- Index for case-insensitive product name searches
CREATE INDEX IX_Products_Name_Upper ON Products(UPPER(product_NAME));

-- Индекс для ускорения запросов к списку желаний с включением часто запрашиваемых столбцов
CREATE INDEX IX_Wishlist_UserID_Covering
ON Wishlist(user_ID, product_ID, added_AT, notes);

-- Индекс для запросов к таблице OrderItems с часто используемыми столбцами
-- Этот индекс удален, так как дублирует IX_OrderItems_Order_Product_Qty_Price,
-- который уже включает те же столбцы (order_ID, product_ID, quantity, price)
-- CREATE INDEX IX_OrderItems_OrderID_ProductID_Covering ON OrderItems(order_ID, product_ID, quantity, price);

-- Индекс для улучшения производительности запросов к платежам с фильтрами по статусу
-- Oracle не поддерживает синтаксис INCLUDE, используем все поля в индексе
CREATE INDEX IX_Payments_StatusID_OrderID ON Payments(payment_STATUS_ID, order_ID, payment_DATE, payment_AMOUNT, transaction_ID);

-- Индекс для ускорения запросов к таблице Orders по статусу заказа
-- Oracle не поддерживает синтаксис INCLUDE, используем все поля в индексе
CREATE INDEX IX_Orders_StatusID_UserID_Covering ON Orders(order_STATUS_ID, user_ID, order_DATE, order_AMOUNT, promo_ID, delivery_STATUS_ID);

-- Индекс для оптимизации запросов к статусам с фильтрацией по ключам
-- Oracle не поддерживает синтаксис INCLUDE, используем все поля в индексе
CREATE INDEX IX_OrderStatusTypes_StatusKey ON OrderStatusTypes(status_KEY, status_NAME_RU, status_NAME_EN, display_ORDER);

-- =====================================================================
-- Status Transition Indexes
-- =====================================================================

-- Create indexes on status transition tables for fast lookups
CREATE INDEX IX_OrderStatusTransitions_FromStatus 
ON OrderStatusTransitions(from_status_ID);

CREATE INDEX IX_PaymentStatusTransitions_FromStatus 
ON PaymentStatusTransitions(from_status_ID);

CREATE INDEX IX_DeliveryStatusTransitions_FromStatus 
ON DeliveryStatusTransitions(from_status_ID);

COMMIT;
PROMPT Database indexes created successfully.;
