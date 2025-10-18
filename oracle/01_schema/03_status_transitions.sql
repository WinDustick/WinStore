-- =====================================================================
-- WinStore - Status Transition Tables and Data (Oracle Version)
-- =====================================================================
-- Description: Creates tables for status transitions and populates
--              them with allowed transitions between statuses
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-09-28
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: 02_reference_data.sql
-- =====================================================================

-- =====================================================================
-- Create Status Transition Tables
-- =====================================================================

-- Order Status Transitions Table
CREATE TABLE OrderStatusTransitions (
    from_status_ID NUMBER NOT NULL,
    to_status_ID NUMBER NOT NULL,
    is_allowed NUMBER(1) DEFAULT 1 NOT NULL,
    transition_name NVARCHAR2(100) NULL,
    CONSTRAINT PK_OrderStatusTransitions PRIMARY KEY (from_status_ID, to_status_ID),
    CONSTRAINT FK_OrderStatusTransitions_From FOREIGN KEY (from_status_ID) 
        REFERENCES OrderStatusTypes(status_ID),
    CONSTRAINT FK_OrderStatusTransitions_To FOREIGN KEY (to_status_ID) 
        REFERENCES OrderStatusTypes(status_ID)
);

-- Payment Status Transitions Table
CREATE TABLE PaymentStatusTransitions (
    from_status_ID NUMBER NOT NULL,
    to_status_ID NUMBER NOT NULL,
    is_allowed NUMBER(1) DEFAULT 1 NOT NULL,
    transition_name NVARCHAR2(100) NULL,
    CONSTRAINT PK_PaymentStatusTransitions PRIMARY KEY (from_status_ID, to_status_ID),
    CONSTRAINT FK_PaymentStatusTransitions_From FOREIGN KEY (from_status_ID) 
        REFERENCES PaymentStatusTypes(status_ID),
    CONSTRAINT FK_PaymentStatusTransitions_To FOREIGN KEY (to_status_ID) 
        REFERENCES PaymentStatusTypes(status_ID)
);

-- Delivery Status Transitions Table
CREATE TABLE DeliveryStatusTransitions (
    from_status_ID NUMBER NOT NULL,
    to_status_ID NUMBER NOT NULL,
    is_allowed NUMBER(1) DEFAULT 1 NOT NULL,
    transition_name NVARCHAR2(100) NULL,
    CONSTRAINT PK_DeliveryStatusTransitions PRIMARY KEY (from_status_ID, to_status_ID),
    CONSTRAINT FK_DeliveryStatusTransitions_From FOREIGN KEY (from_status_ID) 
        REFERENCES DeliveryStatusTypes(status_ID),
    CONSTRAINT FK_DeliveryStatusTransitions_To FOREIGN KEY (to_status_ID) 
        REFERENCES DeliveryStatusTypes(status_ID)
);

-- =====================================================================
-- Helper procedure to get status_ID by key (used for populating transitions)
-- =====================================================================

CREATE OR REPLACE FUNCTION get_order_status_id(p_key IN NVARCHAR2)
RETURN NUMBER IS
  v_status_id NUMBER;
BEGIN
  SELECT status_ID INTO v_status_id 
  FROM OrderStatusTypes 
  WHERE status_KEY = p_key;
  
  RETURN v_status_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END get_order_status_id;
/

CREATE OR REPLACE FUNCTION get_payment_status_id(p_key IN NVARCHAR2)
RETURN NUMBER IS
  v_status_id NUMBER;
BEGIN
  SELECT status_ID INTO v_status_id 
  FROM PaymentStatusTypes
  WHERE status_KEY = p_key;
  
  RETURN v_status_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END get_payment_status_id;
/

CREATE OR REPLACE FUNCTION get_delivery_status_id(p_key IN NVARCHAR2)
RETURN NUMBER IS
  v_status_id NUMBER;
BEGIN
  SELECT status_ID INTO v_status_id 
  FROM DeliveryStatusTypes
  WHERE status_KEY = p_key;
  
  RETURN v_status_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END get_delivery_status_id;
/

-- =====================================================================
-- Populate Transition Tables with Initial Data
-- =====================================================================

-- Order Status Transitions initial data
-- Main "successful" path
INSERT INTO OrderStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_order_status_id('Cart'), get_order_status_id('Pending'), 
        N'Оформление заказа (Cart -> Pending)');

INSERT INTO OrderStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_order_status_id('Pending'), get_order_status_id('Processing'), 
        N'Начало обработки (Pending -> Processing)');

INSERT INTO OrderStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_order_status_id('Processing'), get_order_status_id('Shipped'), 
        N'Отправка заказа (Processing -> Shipped)');

INSERT INTO OrderStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_order_status_id('Shipped'), get_order_status_id('InTransit'), 
        N'Заказ в пути (Shipped -> InTransit)');

INSERT INTO OrderStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_order_status_id('InTransit'), get_order_status_id('Delivered'), 
        N'Заказ доставлен (InTransit -> Delivered)');

INSERT INTO OrderStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_order_status_id('Delivered'), get_order_status_id('Completed'), 
        N'Завершение заказа (Delivered -> Completed)');

-- Alternative cancellation paths
INSERT INTO OrderStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_order_status_id('Pending'), get_order_status_id('Cancelled'), 
        N'Отмена заказа (Pending -> Cancelled)');

INSERT INTO OrderStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_order_status_id('Processing'), get_order_status_id('Cancelled'), 
        N'Отмена заказа (Processing -> Cancelled)');

-- Alternative return and refund paths
INSERT INTO OrderStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_order_status_id('Delivered'), get_order_status_id('Returned'), 
        N'Возврат товара (Delivered -> Returned)');

INSERT INTO OrderStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_order_status_id('Returned'), get_order_status_id('Refunded'), 
        N'Возмещение по возврату (Returned -> Refunded)');

INSERT INTO OrderStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_order_status_id('Completed'), get_order_status_id('Refunded'), 
        N'Возмещение по завершенному заказу (Completed -> Refunded)');

-- Payment Status Transitions initial data
-- Main "successful" path
INSERT INTO PaymentStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_payment_status_id('Pending'), get_payment_status_id('Processing'), 
        N'Начало обработки платежа (Pending -> Processing)');

INSERT INTO PaymentStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_payment_status_id('Processing'), get_payment_status_id('Completed'), 
        N'Успешное завершение платежа (Processing -> Completed)');

-- Alternative paths with errors
INSERT INTO PaymentStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_payment_status_id('Pending'), get_payment_status_id('Failed'), 
        N'Ошибка платежа (Pending -> Failed)');

INSERT INTO PaymentStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_payment_status_id('Processing'), get_payment_status_id('Failed'), 
        N'Ошибка обработки (Processing -> Failed)');

-- Refunds
INSERT INTO PaymentStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_payment_status_id('Completed'), get_payment_status_id('Refunded'), 
        N'Полный возврат средств (Completed -> Refunded)');

INSERT INTO PaymentStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_payment_status_id('Completed'), get_payment_status_id('PartiallyRefunded'), 
        N'Частичный возврат (Completed -> PartiallyRefunded)');

INSERT INTO PaymentStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_payment_status_id('PartiallyRefunded'), get_payment_status_id('Refunded'), 
        N'Полный возврат после частичного (PartiallyRefunded -> Refunded)');

-- Delivery Status Transitions initial data
-- Main "successful" path
INSERT INTO DeliveryStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_delivery_status_id('Preparing'), get_delivery_status_id('Shipped'), 
        N'Отправка заказа (Preparing -> Shipped)');

INSERT INTO DeliveryStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_delivery_status_id('Shipped'), get_delivery_status_id('InTransit'), 
        N'Заказ в пути (Shipped -> InTransit)');

INSERT INTO DeliveryStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_delivery_status_id('InTransit'), get_delivery_status_id('OutForDelivery'), 
        N'Передача курьеру (InTransit -> OutForDelivery)');

INSERT INTO DeliveryStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_delivery_status_id('OutForDelivery'), get_delivery_status_id('Delivered'), 
        N'Успешная доставка (OutForDelivery -> Delivered)');

-- Alternative paths with issues and returns
INSERT INTO DeliveryStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_delivery_status_id('OutForDelivery'), get_delivery_status_id('FailedAttempt'), 
        N'Неудачная попытка доставки (OutForDelivery -> FailedAttempt)');

INSERT INTO DeliveryStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_delivery_status_id('FailedAttempt'), get_delivery_status_id('OutForDelivery'), 
        N'Повторная попытка доставки (FailedAttempt -> OutForDelivery)');

INSERT INTO DeliveryStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_delivery_status_id('FailedAttempt'), get_delivery_status_id('Returned'), 
        N'Возврат на склад (FailedAttempt -> Returned)');

INSERT INTO DeliveryStatusTransitions (from_status_ID, to_status_ID, transition_name) 
VALUES (get_delivery_status_id('InTransit'), get_delivery_status_id('Returned'), 
        N'Возврат в пути (InTransit -> Returned)');

COMMIT;

PROMPT Status transition tables created and populated successfully.;
