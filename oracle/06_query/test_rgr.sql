-- =====================================================================
-- TEST: PKG_RGR_ANALYTICS
-- =====================================================================
-- Этот скрипт эмулирует работу клиентского приложения (Backend).
-- Он вызывает процедуры пакета, получает курсоры (REF CURSOR)
-- и форматирует вывод для пользователя.
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET VERIFY OFF;
SET FEEDBACK OFF;

DECLARE
    -- Курсоры для получения результатов из пакета
    rc_Stats      SYS_REFCURSOR;
    rc_Users      SYS_REFCURSOR;

    -- ПЕРЕМЕННЫЕ ДЛЯ ЧЕКА
    rc_Header     SYS_REFCURSOR;
    rc_Body     SYS_REFCURSOR;
    rc_Footer     SYS_REFCURSOR;
    
    -- Переменные для маппинга
    v_CatName     NVARCHAR2(100);
    v_OrderCount  NUMBER;
    v_FmtSales    VARCHAR2(100);
    v_HasPromo    VARCHAR2(10);
    
    v_UserName    NVARCHAR2(100);
    v_UserEmail   NVARCHAR2(100);
    v_LastDate    DATE;
    v_Loyalty     VARCHAR2(50);
    
    v_ProdName    NVARCHAR2(255);
    v_Quantity    NUMBER;
    v_PriceUnit   VARCHAR2(50);
    v_LineTotal   VARCHAR2(50);
    
    v_TestOrderID NUMBER;
    
    -- ПЕРЕМЕННЫЕ ДЛЯ ЧЕКА
    v_Shop        NVARCHAR2(200);
    v_RcptNo      NVARCHAR2(100);
    v_Date        NVARCHAR2(50);
    v_Cashier     NVARCHAR2(100);
    v_Client      NVARCHAR2(200);

    v_PosNum      NUMBER;
    v_Prod        NVARCHAR2(255);
    v_Qty         NUMBER;
    v_Price       NVARCHAR2(100);
    v_Sum         NVARCHAR2(100);
    
    v_Subtotal    NVARCHAR2(100);
    v_Discount    NVARCHAR2(100);
    v_Grand       NVARCHAR2(100);
    v_Fiscal      NVARCHAR2(200);
    
    -- Константы форматирования (дублируем логику отображения на "клиенте")
    c_Sep         VARCHAR2(180) := '════════════════════════════════════════════════════════════';

BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '═══ ЗАПУСК ТЕСТИРОВАНИЯ МОДУЛЯ АНАЛИТИКИ ═══');

    -- 1. ТЕСТ: Отчет по продажам (Dashboard)
    -- ─────────────────────────────────────────────────────────────────
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '[TEST 1] Sales Dashboard (sp_CategoryPerformanceReport)');
    DBMS_OUTPUT.PUT_LINE(c_Sep);
    
    -- Вызов процедуры пакета, получение курсора
    pkg_rgr_analytics.sp_CategoryPerformanceReport(
        p_MinSalesAmount => 0,
        p_Cursor         => rc_Stats
    );
    
    -- Обработка данных на "клиенте"
    DBMS_OUTPUT.PUT_LINE(RPAD('CATEGORY', 25) || ' | ' || RPAD('ORDERS', 8) || ' | ' || RPAD('REVENUE', 15) || ' | ' || 'PROMO');
    DBMS_OUTPUT.PUT_LINE(c_Sep);
    
    LOOP
        FETCH rc_Stats INTO v_CatName, v_OrderCount, v_FmtSales, v_HasPromo;
        EXIT WHEN rc_Stats%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE(
            RPAD(v_CatName, 25) || ' | ' || 
            LPAD(v_OrderCount, 8) || ' | ' || 
            LPAD(v_FmtSales, 15) || ' | ' || 
            v_HasPromo
        );
    END LOOP;
    CLOSE rc_Stats;

    -- 2. ТЕСТ: CRM Список (Retention)
    -- ─────────────────────────────────────────────────────────────────
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '[TEST 2] CRM Retention List (sp_DormantCustomersReport)');
    DBMS_OUTPUT.PUT_LINE(c_Sep);
    
    pkg_rgr_analytics.sp_DormantCustomersReport(
        p_DaysSinceLastOrder => 0,
        p_Cursor             => rc_Users
    );
    
    LOOP
        FETCH rc_Users INTO v_UserName, v_UserEmail, v_LastDate, v_Loyalty;
        EXIT WHEN rc_Users%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE(
            'Customer: ' || RPAD(v_UserName, 20) || 
            ' [Tier: ' || RPAD(v_Loyalty, 8) || '] ' ||
            ' Last Seen: ' || TO_CHAR(v_LastDate, 'YYYY-MM-DD')
        );
    END LOOP;
    CLOSE rc_Users;

    -- ─────────────────────────────────────────────────────────────────
    -- ТЕСТ 3 : ПЕЧАТЬ ФИСКАЛЬНОГО ЧЕКА (sp_GenerateFiscalReceipt)
    -- ─────────────────────────────────────────────────────────────────
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '[TEST 3] Generating Fiscal Receipt');
    DBMS_OUTPUT.PUT_LINE(c_Sep);
    
    -- Ищем заказ со статусом Completed (4)
    BEGIN
        SELECT order_ID INTO v_TestOrderID FROM Orders WHERE order_STATUS_ID = 4 FETCH FIRST 1 ROW ONLY;
        
        pkg_rgr_analytics.sp_GenerateFiscalReceipt(
            p_OrderID => v_TestOrderID,
            p_Header  => rc_Header,
            p_Items   => rc_Body,
            p_Footer  => rc_Footer
        );
        
        DBMS_OUTPUT.PUT_LINE('                ФИСКАЛЬНЫЙ ЧЕК                ');
        DBMS_OUTPUT.PUT_LINE('══════════════════════════════════════════════');
        
        -- 1. Шапка
        FETCH rc_Header INTO v_Shop, v_RcptNo, v_Date, v_Cashier, v_Client;
        DBMS_OUTPUT.PUT_LINE(v_Shop);
        DBMS_OUTPUT.PUT_LINE('Чек: ' || v_RcptNo);
        DBMS_OUTPUT.PUT_LINE('Дата: ' || v_Date);
        DBMS_OUTPUT.PUT_LINE('Клиент: ' || v_Client);
        CLOSE rc_Header;
        
        DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────────────');
        
        -- 2. Позиции
        LOOP
            FETCH rc_Body INTO v_PosNum, v_Prod, v_Qty, v_Price, v_Sum;
            EXIT WHEN rc_Body%NOTFOUND;
            -- Используем SUBSTR для безопасности вывода, но переменная v_Prod уже большая
            DBMS_OUTPUT.PUT_LINE(v_PosNum || '. ' || SUBSTR(v_Prod, 1, 40));
            DBMS_OUTPUT.PUT_LINE(LPAD(v_Qty, 5) || ' x ' || LPAD(v_Price, 15) || ' = ' || LPAD(v_Sum, 15));
        END LOOP;
        CLOSE rc_Body;
        
        DBMS_OUTPUT.PUT_LINE('══════════════════════════════════════════════');
        
        -- 3. Итоги
        FETCH rc_Footer INTO v_Subtotal, v_Discount, v_Grand, v_Fiscal;
        DBMS_OUTPUT.PUT_LINE(RPAD('ИТОГО:', 20) || LPAD(v_Grand, 20));
        DBMS_OUTPUT.PUT_LINE('ФП: ' || v_Fiscal);
        CLOSE rc_Footer;
        
    EXCEPTION WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Нет подходящих заказов для теста.');
    END;

    -- 4. ТЕСТ: Фоновые задачи
    -- ─────────────────────────────────────────────────────────────────
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '[TEST 4] Background Tasks');
    DBMS_OUTPUT.PUT_LINE(c_Sep);
    
    pkg_rgr_analytics.sp_RefreshStatsCache;
    DBMS_OUTPUT.PUT_LINE('-> Stats cache refreshed (Check audit log)');
    
    pkg_rgr_analytics.sp_ArchiveAuditLogs(SYSDATE - 30);
    DBMS_OUTPUT.PUT_LINE('-> Logs archived (Check audit log)');
    
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '═══ ТЕСТИРОВАНИЕ ЗАВЕРШЕНО УСПЕШНО ═══');
END;
/