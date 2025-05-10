-- =====================================================================
-- WinStore - Reference Tables and Initial Data
-- =====================================================================
-- Description: Creates reference tables for status types and populates
--              them with initial values
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-05-25
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: 01_core_schema.sql
-- =====================================================================

USE WinStore
GO

-- =====================================================================
-- Create Status Lookup Tables
-- =====================================================================

-- Order Status Types Table
CREATE TABLE dbo.OrderStatusTypes (
    status_ID INT IDENTITY(1,1) PRIMARY KEY,
    status_KEY NVARCHAR(50) NOT NULL UNIQUE,    -- String key for code usage (e.g., 'Pending', 'Processing')
    status_NAME_RU NVARCHAR(100) NOT NULL,      -- Display name in Russian
    status_DESCRIPTION_RU NVARCHAR(255) NULL,   -- Description
    status_NAME_EN NVARCHAR(100) NULL,          -- Display name in English
    status_DESCRIPTION_EN NVARCHAR(255) NULL,   -- Description
    display_ORDER INT DEFAULT 0 NOT NULL        -- For UI sorting
);
GO

-- Payment Status Types Table
CREATE TABLE dbo.PaymentStatusTypes (
    status_ID INT IDENTITY(1,1) PRIMARY KEY,
    status_KEY NVARCHAR(50) NOT NULL UNIQUE,
    status_NAME_RU NVARCHAR(100) NOT NULL,
    status_DESCRIPTION_RU NVARCHAR(255) NULL,
    status_NAME_EN NVARCHAR(100) NOT NULL,
    status_DESCRIPTION_EN NVARCHAR(255) NULL,
    display_ORDER INT DEFAULT 0 NOT NULL
);
GO

-- Delivery Status Types Table
CREATE TABLE dbo.DeliveryStatusTypes (
    status_ID INT IDENTITY(1,1) PRIMARY KEY,
    status_KEY NVARCHAR(50) NOT NULL UNIQUE,
    status_NAME_RU NVARCHAR(100) NOT NULL,
    status_DESCRIPTION_RU NVARCHAR(255) NULL,
    status_NAME_EN NVARCHAR(100) NOT NULL,
    status_DESCRIPTION_EN NVARCHAR(255) NULL,
    display_ORDER INT DEFAULT 0 NOT NULL
);
GO

-- =====================================================================
-- Add foreign keys to status tables now that they exist
-- =====================================================================
ALTER TABLE dbo.Orders
ADD CONSTRAINT FK_Orders_OrderStatusTypes 
    FOREIGN KEY (order_STATUS_ID) 
    REFERENCES dbo.OrderStatusTypes(status_ID);
GO

ALTER TABLE dbo.Orders
ADD CONSTRAINT FK_Orders_DeliveryStatusTypes 
    FOREIGN KEY (delivery_STATUS_ID) 
    REFERENCES dbo.DeliveryStatusTypes(status_ID);
GO

ALTER TABLE dbo.Payments
ADD CONSTRAINT FK_Payments_PaymentStatusTypes 
    FOREIGN KEY (payment_STATUS_ID) 
    REFERENCES dbo.PaymentStatusTypes(status_ID);
GO

-- =====================================================================
-- Populate Status Tables with Initial Data
-- =====================================================================

-- Order Status Types initial data
INSERT INTO dbo.OrderStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Cart', N'В корзине', N'Заказ находится в корзине пользователя, еще не оформлен.', N'In Cart', N'The order is in the user cart, not yet processed.', 0),
('Pending', N'Ожидает обработки', N'Заказ оформлен и ожидает дальнейшей обработки.', N'Pending', N'The order has been placed and is awaiting further processing.', 10),
('Processing', N'В обработке', N'Заказ находится в процессе сборки или выполнения.', N'Processing', N'The order is being assembled or fulfilled.', 20),
('Completed', N'Завершен', N'Заказ успешно выполнен и завершен.', N'Completed', N'The order has been successfully completed.', 30),
('Cancelled', N'Отменен', N'Заказ был отменен.', N'Cancelled', N'The order was cancelled.', 40),
('Shipped', N'Отправлен', N'Заказ передан в службу доставки.', N'Shipped', N'The order has been handed over to the shipping service.', 50),
('InTransit', N'В пути', N'Заказ находится в пути к получателю.', N'In Transit', N'The order is on its way to the recipient.', 60),
('Returned', N'Возвращен', N'Заказ был возвращен обратно.', N'Returned', N'The order has been returned back.', 70),
('Delivered', N'Доставлен', N'Заказ успешно доставлен получателю.', N'Delivered', N'The order has been successfully delivered to the recipient.', 80),
('Refunded', N'Возврат средств', N'По заказу был произведен возврат средств.', N'Refunded', N'A refund has been processed for this order.', 90);
GO

-- Payment Status Types initial data
INSERT INTO dbo.PaymentStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Pending', N'Ожидает оплаты', N'Оплата инициирована, но еще не подтверждена.', N'Pending', N'Payment has been initiated but not yet confirmed.', 10),
('Processing', N'Обрабатывается', N'Платеж обрабатывается платежной системой.', N'Processing', N'Payment is being processed by the payment system.', 20),
('Completed', N'Оплачен', N'Оплата успешно произведена и подтверждена.', N'Completed', N'Payment has been successfully completed and confirmed.', 30),
('Failed', N'Ошибка оплаты', N'Произошла ошибка при попытке оплаты.', N'Failed', N'An error occurred during the payment attempt.', 40),
('Refunded', N'Возвращен', N'Средства по платежу были возвращены.', N'Refunded', N'The payment amount has been refunded.', 50),
('PartiallyRefunded', N'Частичный возврат', N'Часть средств по платежу была возвращена.', N'Partially Refunded', N'Part of the payment amount has been refunded.', 60);
GO

-- Delivery Status Types initial data
INSERT INTO dbo.DeliveryStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Preparing', N'Подготовка к отправке', N'Заказ готовится к передаче в службу доставки.', N'Preparing', N'The order is being prepared for shipping.', 10),
('Shipped', N'Отправлен', N'Заказ передан в службу доставки.', N'Shipped', N'The order has been handed over to the shipping service.', 20),
('InTransit', N'В пути', N'Заказ находится в процессе транспортировки к получателю.', N'In Transit', N'The order is in transit to the recipient.', 30),
('OutForDelivery', N'Выдан курьеру', N'Заказ передан курьеру для доставки получателю.', N'Out For Delivery', N'The order has been given to a courier for final delivery.', 40),
('Delivered', N'Доставлен', N'Заказ успешно доставлен получателю.', N'Delivered', N'The order has been successfully delivered to the recipient.', 50),
('FailedAttempt', N'Неудачная попытка', N'Служба доставки предприняла неудачную попытку вручения заказа.', N'Failed Attempt', N'The delivery service made an unsuccessful delivery attempt.', 60),
('Returned', N'Возвращен', N'Заказ был возвращен на склад.', N'Returned', N'The order has been returned to the warehouse.', 70);
GO

PRINT 'Reference tables created and populated successfully.';
GO
