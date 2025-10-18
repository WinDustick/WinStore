-- =====================================================================
-- WinStore - Reference Tables and Initial Data (Oracle Version)
-- =====================================================================
-- Description: Creates reference tables for status types and populates
--              them with initial values
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-09-28
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: 01_core_schema.sql
-- =====================================================================

-- =====================================================================
-- Create Sequences for Status Tables
-- =====================================================================

CREATE SEQUENCE SEQ_ORDERSTATUSTYPES_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

CREATE SEQUENCE SEQ_PAYMENTSTATUSTYPES_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

CREATE SEQUENCE SEQ_DELIVERYSTATUSTYPES_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- =====================================================================
-- Create Status Lookup Tables
-- =====================================================================

-- Order Status Types Table
CREATE TABLE OrderStatusTypes (
    status_ID NUMBER PRIMARY KEY,
    status_KEY NVARCHAR2(50) NOT NULL UNIQUE,    -- String key for code usage (e.g., 'Pending', 'Processing')
    status_NAME_RU NVARCHAR2(100) NOT NULL,      -- Display name in Russian
    status_DESCRIPTION_RU NVARCHAR2(255) NULL,   -- Description
    status_NAME_EN NVARCHAR2(100) NULL,          -- Display name in English
    status_DESCRIPTION_EN NVARCHAR2(255) NULL,   -- Description
    display_ORDER NUMBER DEFAULT 0 NOT NULL      -- For UI sorting
);

-- Payment Status Types Table
CREATE TABLE PaymentStatusTypes (
    status_ID NUMBER PRIMARY KEY,
    status_KEY NVARCHAR2(50) NOT NULL UNIQUE,
    status_NAME_RU NVARCHAR2(100) NOT NULL,
    status_DESCRIPTION_RU NVARCHAR2(255) NULL,
    status_NAME_EN NVARCHAR2(100) NOT NULL,
    status_DESCRIPTION_EN NVARCHAR2(255) NULL,
    display_ORDER NUMBER DEFAULT 0 NOT NULL
);

-- Delivery Status Types Table
CREATE TABLE DeliveryStatusTypes (
    status_ID NUMBER PRIMARY KEY,
    status_KEY NVARCHAR2(50) NOT NULL UNIQUE,
    status_NAME_RU NVARCHAR2(100) NOT NULL,
    status_DESCRIPTION_RU NVARCHAR2(255) NULL,
    status_NAME_EN NVARCHAR2(100) NOT NULL,
    status_DESCRIPTION_EN NVARCHAR2(255) NULL,
    display_ORDER NUMBER DEFAULT 0 NOT NULL
);

-- =====================================================================
-- Create Auto-increment triggers for Status tables
-- =====================================================================

CREATE OR REPLACE TRIGGER TRG_ORDERSTATUSTYPES_BI
BEFORE INSERT ON OrderStatusTypes
FOR EACH ROW
BEGIN
  SELECT SEQ_ORDERSTATUSTYPES_ID.NEXTVAL INTO :NEW.status_ID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER TRG_PAYMENTSTATUSTYPES_BI
BEFORE INSERT ON PaymentStatusTypes
FOR EACH ROW
BEGIN
  SELECT SEQ_PAYMENTSTATUSTYPES_ID.NEXTVAL INTO :NEW.status_ID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER TRG_DELIVERYSTATUSTYPES_BI
BEFORE INSERT ON DeliveryStatusTypes
FOR EACH ROW
BEGIN
  SELECT SEQ_DELIVERYSTATUSTYPES_ID.NEXTVAL INTO :NEW.status_ID FROM DUAL;
END;
/

-- =====================================================================
-- Add foreign keys to status tables now that they exist
-- =====================================================================
ALTER TABLE Orders
ADD CONSTRAINT FK_Orders_OrderStatusTypes 
    FOREIGN KEY (order_STATUS_ID) 
    REFERENCES OrderStatusTypes(status_ID);

ALTER TABLE Orders
ADD CONSTRAINT FK_Orders_DeliveryStatusTypes 
    FOREIGN KEY (delivery_STATUS_ID) 
    REFERENCES DeliveryStatusTypes(status_ID);

ALTER TABLE Payments
ADD CONSTRAINT FK_Payments_PaymentStatusTypes 
    FOREIGN KEY (payment_STATUS_ID) 
    REFERENCES PaymentStatusTypes(status_ID);

-- =====================================================================
-- Populate Status Tables with Initial Data
-- =====================================================================

-- Order Status Types initial data
INSERT INTO OrderStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Cart', N'В корзине', N'Заказ находится в корзине пользователя, еще не оформлен.', N'In Cart', N'The order is in the user cart, not yet processed.', 0);

INSERT INTO OrderStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Pending', N'Ожидает обработки', N'Заказ оформлен и ожидает дальнейшей обработки.', N'Pending', N'The order has been placed and is awaiting further processing.', 10);

INSERT INTO OrderStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Processing', N'В обработке', N'Заказ находится в процессе сборки или выполнения.', N'Processing', N'The order is being assembled or fulfilled.', 20);

INSERT INTO OrderStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Completed', N'Завершен', N'Заказ успешно выполнен и завершен.', N'Completed', N'The order has been successfully completed.', 30);

INSERT INTO OrderStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Cancelled', N'Отменен', N'Заказ был отменен.', N'Cancelled', N'The order was cancelled.', 40);

INSERT INTO OrderStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Shipped', N'Отправлен', N'Заказ передан в службу доставки.', N'Shipped', N'The order has been handed over to the shipping service.', 50);

INSERT INTO OrderStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('InTransit', N'В пути', N'Заказ находится в пути к получателю.', N'In Transit', N'The order is on its way to the recipient.', 60);

INSERT INTO OrderStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Returned', N'Возвращен', N'Заказ был возвращен обратно.', N'Returned', N'The order has been returned back.', 70);

INSERT INTO OrderStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Delivered', N'Доставлен', N'Заказ успешно доставлен получателю.', N'Delivered', N'The order has been successfully delivered to the recipient.', 80);

INSERT INTO OrderStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Refunded', N'Возврат средств', N'По заказу был произведен возврат средств.', N'Refunded', N'A refund has been processed for this order.', 90);

-- Payment Status Types initial data
INSERT INTO PaymentStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Pending', N'Ожидает оплаты', N'Оплата инициирована, но еще не подтверждена.', N'Pending', N'Payment has been initiated but not yet confirmed.', 10);

INSERT INTO PaymentStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Processing', N'Обрабатывается', N'Платеж обрабатывается платежной системой.', N'Processing', N'Payment is being processed by the payment system.', 20);

INSERT INTO PaymentStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Completed', N'Оплачен', N'Оплата успешно произведена и подтверждена.', N'Completed', N'Payment has been successfully completed and confirmed.', 30);

INSERT INTO PaymentStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Failed', N'Ошибка оплаты', N'Произошла ошибка при попытке оплаты.', N'Failed', N'An error occurred during the payment attempt.', 40);

INSERT INTO PaymentStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Refunded', N'Возвращен', N'Средства по платежу были возвращены.', N'Refunded', N'The payment amount has been refunded.', 50);

INSERT INTO PaymentStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('PartiallyRefunded', N'Частичный возврат', N'Часть средств по платежу была возвращена.', N'Partially Refunded', N'Part of the payment amount has been refunded.', 60);

-- Delivery Status Types initial data
INSERT INTO DeliveryStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Preparing', N'Подготовка к отправке', N'Заказ готовится к передаче в службу доставки.', N'Preparing', N'The order is being prepared for shipping.', 10);

INSERT INTO DeliveryStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Shipped', N'Отправлен', N'Заказ передан в службу доставки.', N'Shipped', N'The order has been handed over to the shipping service.', 20);

INSERT INTO DeliveryStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('InTransit', N'В пути', N'Заказ находится в процессе транспортировки к получателю.', N'In Transit', N'The order is in transit to the recipient.', 30);

INSERT INTO DeliveryStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('OutForDelivery', N'Выдан курьеру', N'Заказ передан курьеру для доставки получателю.', N'Out For Delivery', N'The order has been given to a courier for final delivery.', 40);

INSERT INTO DeliveryStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Delivered', N'Доставлен', N'Заказ успешно доставлен получателю.', N'Delivered', N'The order has been successfully delivered to the recipient.', 50);

INSERT INTO DeliveryStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('FailedAttempt', N'Неудачная попытка', N'Служба доставки предприняла неудачную попытку вручения заказа.', N'Failed Attempt', N'The delivery service made an unsuccessful delivery attempt.', 60);

INSERT INTO DeliveryStatusTypes 
(status_KEY, status_NAME_RU, status_DESCRIPTION_RU, status_NAME_EN, status_DESCRIPTION_EN, display_ORDER) 
VALUES
('Returned', N'Возвращен', N'Заказ был возвращен на склад.', N'Returned', N'The order has been returned to the warehouse.', 70);

COMMIT;

PROMPT Reference tables created and populated successfully.;
