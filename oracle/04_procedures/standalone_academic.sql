-- =====================================================================
-- WinStore - Standalone Procedures (Academic Requirements)
-- =====================================================================
-- Description: Набор отдельных (не пакетных) процедур для выполнения
--              административных задач. Реализует требования к курсовой:
--              использование курсоров и вызов отдельных функций.
-- =====================================================================

-- ═════════════════════════════════════════════════════════════════
-- 1. Простая процедура: Быстрое обновление статуса заказа по ключу
-- [Использует отдельную функцию get_order_status_id]
-- ═════════════════════════════════════════════════════════════════
CREATE OR REPLACE PROCEDURE sp_QuickUpdateOrderStatus(
    p_OrderID IN NUMBER,
    p_StatusKey IN NVARCHAR2
) IS
    v_StatusID NUMBER;
BEGIN
    -- Вызов отдельной функции
    v_StatusID := get_order_status_id(p_StatusKey);
    
    IF v_StatusID IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid Status Key: ' || p_StatusKey);
    END IF;

    UPDATE Orders 
    SET order_STATUS_ID = v_StatusID
    WHERE order_ID = p_OrderID;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Order ' || p_OrderID || ' updated to status ' || p_StatusKey);
END sp_QuickUpdateOrderStatus;
/

-- ═════════════════════════════════════════════════════════════════
-- 2. Процедура с курсором: Сверка статусов платежей
-- [Использует курсор + отдельную функцию get_payment_status_id]
-- ═════════════════════════════════════════════════════════════════
CREATE OR REPLACE PROCEDURE sp_ReconcilePaymentStatuses IS
    -- Явный курсор: ищем завершенные заказы с "подвисшей" оплатой
    CURSOR c_Mismatch IS
        SELECT o.order_ID, o.order_AMOUNT
        FROM Orders o
        JOIN Payments p ON o.order_ID = p.order_ID
        WHERE o.order_STATUS_ID = 4 -- Completed (ID=4)
          AND p.payment_STATUS_ID = get_payment_status_id('Pending'); -- Использование функции в условии
          
    v_OrderID NUMBER;
    v_Amount  NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Starting Payment Reconciliation ---');
    
    OPEN c_Mismatch;
    LOOP
        FETCH c_Mismatch INTO v_OrderID, v_Amount;
        EXIT WHEN c_Mismatch%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('Alert: Order #' || v_OrderID || ' is Completed but Payment is Pending. Amount: ' || v_Amount);
        -- Здесь могла бы быть логика авто-исправления
    END LOOP;
    CLOSE c_Mismatch;
END sp_ReconcilePaymentStatuses;
/

-- ═════════════════════════════════════════════════════════════════
-- 3. Процедура с курсором: Монитор доставки
-- [Использует курсор + отдельную функцию get_delivery_status_id]
-- ═════════════════════════════════════════════════════════════════
CREATE OR REPLACE PROCEDURE sp_DeliveryMonitor(p_DaysThreshold IN NUMBER) IS
    v_TargetStatusID NUMBER;
    
    CURSOR c_StuckDeliveries IS
        SELECT o.order_ID, o.shipped_DATE, u.user_EMAIL
        FROM Orders o
        JOIN Users u ON o.user_ID = u.user_ID
        WHERE o.delivery_STATUS_ID = v_TargetStatusID
          AND o.shipped_DATE < SYSDATE - p_DaysThreshold;
          
    rec_Deliv c_StuckDeliveries%ROWTYPE;
BEGIN
    -- Получаем ID статуса через функцию
    v_TargetStatusID := get_delivery_status_id('InTransit');
    
    DBMS_OUTPUT.PUT_LINE('--- Checking Stuck Deliveries (> ' || p_DaysThreshold || ' days) ---');
    
    OPEN c_StuckDeliveries;
    LOOP
        FETCH c_StuckDeliveries INTO rec_Deliv;
        EXIT WHEN c_StuckDeliveries%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('Late Delivery: Order #' || rec_Deliv.order_ID || 
                             ' Shipped: ' || rec_Deliv.shipped_DATE || 
                             ' Contact: ' || rec_Deliv.user_EMAIL);
    END LOOP;
    CLOSE c_StuckDeliveries;
END sp_DeliveryMonitor;
/

-- ═════════════════════════════════════════════════════════════════
-- 4. Процедура с курсором: Аудит товаров без изображений
-- [Использует курсор]
-- ═════════════════════════════════════════════════════════════════
CREATE OR REPLACE PROCEDURE sp_ProductImageAudit IS
    CURSOR c_NoImageProducts IS
        SELECT p.product_ID, p.product_NAME
        FROM Products p
        WHERE NOT EXISTS (
            SELECT 1 FROM ProductMedia pm WHERE pm.product_ID = p.product_ID
        );
        
    v_ProdID   Products.product_ID%TYPE;
    v_ProdName Products.product_NAME%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Products Missing Images ---');
    
    OPEN c_NoImageProducts;
    LOOP
        FETCH c_NoImageProducts INTO v_ProdID, v_ProdName;
        EXIT WHEN c_NoImageProducts%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_ProdID || ' | Name: ' || v_ProdName);
    END LOOP;
    CLOSE c_NoImageProducts;
END sp_ProductImageAudit;
/