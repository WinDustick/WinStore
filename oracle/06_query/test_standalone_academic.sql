-- =====================================================================
-- WinStore - TEST for Standalone Academic Procedures
-- =====================================================================
-- Description: Скрипт для проверки и демонстрации работы отдельных 
--              процедур, созданных для выполнения академических требований.
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET VERIFY OFF;
SET FEEDBACK OFF;

DECLARE
    v_TestOrderID NUMBER;
    v_OldStatusID NUMBER;
    v_NewStatusID NUMBER;
    v_OldStatusKey NVARCHAR2(50);
    v_NewStatusKey NVARCHAR2(50);
BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('═', 60, '═'));
    DBMS_OUTPUT.PUT_LINE('  TESTING STANDALONE PROCEDURES');
    DBMS_OUTPUT.PUT_LINE(RPAD('═', 60, '═'));

    -- ═════════════════════════════════════════════════════════════════
    -- ТЕСТ 1: sp_QuickUpdateOrderStatus (Простая процедура + Функция)
    -- ═════════════════════════════════════════════════════════════════
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '[TEST 1] Quick Update Order Status');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
    
    -- 1. Находим любой заказ для теста
    BEGIN
        SELECT order_ID, order_STATUS_ID 
        INTO v_TestOrderID, v_OldStatusID 
        FROM Orders 
        WHERE order_STATUS_ID IS NOT NULL 
        FETCH FIRST 1 ROW ONLY;
        
        -- Получаем текстовое название текущего статуса (для наглядности)
        SELECT status_KEY INTO v_OldStatusKey FROM OrderStatusTypes WHERE status_ID = v_OldStatusID;
        
        DBMS_OUTPUT.PUT_LINE('Order found: #' || v_TestOrderID);
        DBMS_OUTPUT.PUT_LINE('Current Status: ' || v_OldStatusKey || ' (ID=' || v_OldStatusID || ')');
        
        -- 2. Вызываем процедуру обновления (Меняем на 'Processing' или 'Shipped')
        -- Если текущий статус Processing, меняем на Shipped, иначе на Processing
        IF v_OldStatusKey = 'Processing' THEN
            sp_QuickUpdateOrderStatus(v_TestOrderID, 'Shipped');
        ELSE
            sp_QuickUpdateOrderStatus(v_TestOrderID, 'Processing');
        END IF;
        
        -- 3. Проверяем результат
        SELECT order_STATUS_ID INTO v_NewStatusID FROM Orders WHERE order_ID = v_TestOrderID;
        SELECT status_KEY INTO v_NewStatusKey FROM OrderStatusTypes WHERE status_ID = v_NewStatusID;
        
        DBMS_OUTPUT.PUT_LINE('New Status:     ' || v_NewStatusKey || ' (ID=' || v_NewStatusID || ')');
        
        IF v_OldStatusID != v_NewStatusID THEN
            DBMS_OUTPUT.PUT_LINE('RESULT: SUCCESS (Status changed)');
        ELSE
            DBMS_OUTPUT.PUT_LINE('RESULT: FAIL (Status did not change)');
        END IF;
        
    EXCEPTION WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('SKIP: No orders found to test update.');
    END;

    -- ═════════════════════════════════════════════════════════════════
    -- ТЕСТ 2: sp_ReconcilePaymentStatuses (Курсор + Функция)
    -- ═════════════════════════════════════════════════════════════════
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '[TEST 2] Reconcile Payment Statuses');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
    DBMS_OUTPUT.PUT_LINE('Running reconciliation report...');
    
    -- Просто вызываем процедуру, она сама выведет данные в консоль
    sp_ReconcilePaymentStatuses;
    
    DBMS_OUTPUT.PUT_LINE('Done.');

    -- ═════════════════════════════════════════════════════════════════
    -- ТЕСТ 3: sp_DeliveryMonitor (Курсор + Функция)
    -- ═════════════════════════════════════════════════════════════════
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '[TEST 3] Delivery Monitor');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
    
    -- Проверяем доставки, которые "висят" дольше 5 дней
    sp_DeliveryMonitor(p_DaysThreshold => 5);
    
    DBMS_OUTPUT.PUT_LINE('Done.');

    -- ═════════════════════════════════════════════════════════════════
    -- ТЕСТ 4: sp_ProductImageAudit (Курсор)
    -- ═════════════════════════════════════════════════════════════════
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '[TEST 4] Product Image Audit');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
    
    -- Выводит список товаров без картинок
    sp_ProductImageAudit;
    
    DBMS_OUTPUT.PUT_LINE('Done.');
    
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '═══ ALL TESTS COMPLETED ═══');
END;
/