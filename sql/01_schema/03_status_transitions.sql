-- =====================================================================
-- WinStore - Status Transition Tables and Data
-- =====================================================================
-- Description: Creates tables for status transitions and populates
--              them with allowed transitions between statuses
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-05-25
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: 02_reference_data.sql
-- =====================================================================

USE WinStore
GO

-- =====================================================================
-- Create Status Transition Tables
-- =====================================================================

-- Order Status Transitions Table
CREATE TABLE dbo.OrderStatusTransitions (
    from_status_ID INT NOT NULL,
    to_status_ID INT NOT NULL,
    is_allowed BIT NOT NULL DEFAULT 1,
    transition_name NVARCHAR(100) NULL,
    PRIMARY KEY (from_status_ID, to_status_ID),
    CONSTRAINT FK_OrderStatusTransitions_From FOREIGN KEY (from_status_ID) 
        REFERENCES dbo.OrderStatusTypes(status_ID),
    CONSTRAINT FK_OrderStatusTransitions_To FOREIGN KEY (to_status_ID) 
        REFERENCES dbo.OrderStatusTypes(status_ID)
);
GO

-- Payment Status Transitions Table
CREATE TABLE dbo.PaymentStatusTransitions (
    from_status_ID INT NOT NULL,
    to_status_ID INT NOT NULL,
    is_allowed BIT NOT NULL DEFAULT 1,
    transition_name NVARCHAR(100) NULL,
    PRIMARY KEY (from_status_ID, to_status_ID),
    CONSTRAINT FK_PaymentStatusTransitions_From FOREIGN KEY (from_status_ID) 
        REFERENCES dbo.PaymentStatusTypes(status_ID),
    CONSTRAINT FK_PaymentStatusTransitions_To FOREIGN KEY (to_status_ID) 
        REFERENCES dbo.PaymentStatusTypes(status_ID)
);
GO

-- Delivery Status Transitions Table
CREATE TABLE dbo.DeliveryStatusTransitions (
    from_status_ID INT NOT NULL,
    to_status_ID INT NOT NULL,
    is_allowed BIT NOT NULL DEFAULT 1,
    transition_name NVARCHAR(100) NULL,
    PRIMARY KEY (from_status_ID, to_status_ID),
    CONSTRAINT FK_DeliveryStatusTransitions_From FOREIGN KEY (from_status_ID) 
        REFERENCES dbo.DeliveryStatusTypes(status_ID),
    CONSTRAINT FK_DeliveryStatusTransitions_To FOREIGN KEY (to_status_ID) 
        REFERENCES dbo.DeliveryStatusTypes(status_ID)
);
GO

-- =====================================================================
-- Populate Transition Tables with Initial Data
-- =====================================================================

-- Order Status Transitions initial data
INSERT INTO dbo.OrderStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES
-- Assuming the OrderStatusTypes have been inserted in the order defined above
-- Main "successful" path
(1, 2, N'Оформление заказа (Cart -> Pending)'),           -- Cart to Pending
(2, 3, N'Начало обработки (Pending -> Processing)'),      -- Pending to Processing
(3, 6, N'Отправка заказа (Processing -> Shipped)'),       -- Processing to Shipped
(6, 7, N'Заказ в пути (Shipped -> InTransit)'),           -- Shipped to InTransit
(7, 9, N'Заказ доставлен (InTransit -> Delivered)'),      -- InTransit to Delivered
(9, 4, N'Завершение заказа (Delivered -> Completed)'),    -- Delivered to Completed

-- Alternative cancellation paths
(2, 5, N'Отмена заказа (Pending -> Cancelled)'),         -- Pending to Cancelled
(3, 5, N'Отмена заказа (Processing -> Cancelled)'),      -- Processing to Cancelled

-- Alternative return and refund paths
(9, 8, N'Возврат товара (Delivered -> Returned)'),       -- Delivered to Returned
(8, 10, N'Возмещение по возврату (Returned -> Refunded)'), -- Returned to Refunded
(4, 10, N'Возмещение по завершенному заказу (Completed -> Refunded)'); -- Completed to Refunded
GO

-- Payment Status Transitions initial data
INSERT INTO dbo.PaymentStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES
-- Main "successful" path
(1, 2, N'Начало обработки платежа (Pending -> Processing)'),      -- Pending to Processing
(2, 3, N'Успешное завершение платежа (Processing -> Completed)'), -- Processing to Completed

-- Alternative paths with errors
(1, 4, N'Ошибка платежа (Pending -> Failed)'),                   -- Pending to Failed
(2, 4, N'Ошибка обработки (Processing -> Failed)'),              -- Processing to Failed

-- Refunds
(3, 5, N'Полный возврат средств (Completed -> Refunded)'),       -- Completed to Refunded
(3, 6, N'Частичный возврат (Completed -> PartiallyRefunded)'),   -- Completed to PartiallyRefunded
(6, 5, N'Полный возврат после частичного (PartiallyRefunded -> Refunded)'); -- PartiallyRefunded to Refunded
GO

-- Delivery Status Transitions initial data
INSERT INTO dbo.DeliveryStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES
-- Main "successful" path
(1, 2, N'Отправка заказа (Preparing -> Shipped)'),                      -- Preparing to Shipped
(2, 3, N'Заказ в пути (Shipped -> InTransit)'),                         -- Shipped to InTransit
(3, 4, N'Передача курьеру (InTransit -> OutForDelivery)'),              -- InTransit to OutForDelivery
(4, 5, N'Успешная доставка (OutForDelivery -> Delivered)'),             -- OutForDelivery to Delivered

-- Alternative paths with issues and returns
(4, 6, N'Неудачная попытка доставки (OutForDelivery -> FailedAttempt)'),  -- OutForDelivery to FailedAttempt
(6, 4, N'Повторная попытка доставки (FailedAttempt -> OutForDelivery)'),  -- FailedAttempt to OutForDelivery
(6, 7, N'Возврат на склад (FailedAttempt -> Returned)'),                  -- FailedAttempt to Returned
(3, 7, N'Возврат в пути (InTransit -> Returned)');                        -- InTransit to Returned
GO

PRINT 'Status transition tables created and populated successfully.';
GO
