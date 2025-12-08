-- =====================================================================
-- WinStore - RGR Analytics Package
-- =====================================================================
-- Description: Специализированный пакет для генерации сложной аналитики.
--              Реализует академические требования (курсоры, функции в пакете,
--              скрытые процедуры) в рамках изолированного модуля отчетности.
-- Author:      WinStore Development Team
-- Version:     1.0.0
-- =====================================================================

-- ═════════════════════════════════════════════════════════════════════════════
-- СПЕЦИФИКАЦИЯ ПАКЕТА
-- ═════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE PACKAGE pkg_rgr_analytics AS
    
    -- ═══════════════════════════════════════════════════════════════
    -- КОНСТАНТЫ ПАКЕТА 
    -- ═══════════════════════════════════════════════════════════════
    
    c_output_buffer_size CONSTANT INTEGER := 1000000;
    c_money_mask         CONSTANT VARCHAR2(20) := 'FM999G999G990D00';
    
    -- ═══════════════════════════════════════════════════════════════
    -- ТИПЫ ДАННЫХ (RECORD) ДЛЯ КУРСОРОВ 
    -- ═══════════════════════════════════════════════════════════════
    
    -- Тип для отчета по категориям
    TYPE t_CatStatsRec IS RECORD (
        category_name    NVARCHAR2(100),
        order_count      NUMBER,
        formatted_sales  VARCHAR2(100),
        has_active_promo VARCHAR2(10)
    );

    -- Тип для отчета по "спящим" клиентам
    TYPE t_DormantUserRec IS RECORD (
        user_name     NVARCHAR2(100),
        user_email    NVARCHAR2(100),
        last_order_dt DATE,
        loyalty_tier  VARCHAR2(50)
    );

    -- Тип для детализации чека
    TYPE t_ReceiptItemRec IS RECORD (
        product_name  NVARCHAR2(255),
        quantity      NUMBER,
        price_unit    VARCHAR2(50),
        line_total    VARCHAR2(50)
    );

    -- Данные шапки чека
    TYPE t_ReceiptHeaderRec IS RECORD (
        shop_name       VARCHAR2(100),
        receipt_no      VARCHAR2(50),
        dt_print        VARCHAR2(30),
        cashier         VARCHAR2(100),
        client_name     VARCHAR2(100)
    );

    -- Данные подвала чека
    TYPE t_ReceiptFooterRec IS RECORD (
        subtotal        VARCHAR2(50),
        discount        VARCHAR2(50),
        grand_total     VARCHAR2(50),
        fiscal_sign     VARCHAR2(100)
    );
    
    -- Тип для проверки склада
    TYPE t_LowStockRec IS RECORD (
        product_id    NUMBER,
        product_name  NVARCHAR2(255),
        stock         NUMBER
    );

    -- ═══════════════════════════════════════════════════════════════
    -- ОБЪЯВЛЕНИЕ КУРСОРОВ
    -- ═══════════════════════════════════════════════════════════════
    -- Мы объявляем их здесь, чтобы показать структуру данных,
    -- даже если процедуры будут открывать динамические курсоры для клиента.
    
    CURSOR c_LowStockItems RETURN t_LowStockRec;

    -- ═══════════════════════════════════════════════════════════════
    -- ПУБЛИЧНЫЕ ФУНКЦИИ 
    -- ═══════════════════════════════════════════════════════════════
    
    FUNCTION f_FormatPrice(p_Amount IN NUMBER) RETURN VARCHAR2;
    FUNCTION f_CalculateLoyaltyTier(p_TotalSpent IN NUMBER) RETURN VARCHAR2;
    FUNCTION f_HasActivePromo(p_CategoryID IN NUMBER) RETURN NUMBER; 

    -- ═══════════════════════════════════════════════════════════════
    -- ПУБЛИЧНЫЕ ПРОЦЕДУРЫ
    -- ═══════════════════════════════════════════════════════════════
    
    -- Возвращают SYS_REFCURSOR вместо печати текста
    PROCEDURE sp_CategoryPerformanceReport(
        p_MinSalesAmount IN NUMBER, 
        p_Cursor OUT SYS_REFCURSOR
    );
    
    PROCEDURE sp_DormantCustomersReport(
        p_DaysSinceLastOrder IN NUMBER, 
        p_Cursor OUT SYS_REFCURSOR
    );
    
--  Возвращает 3 курсора для построения полного документа
    PROCEDURE sp_GenerateFiscalReceipt(
        p_OrderID   IN NUMBER, 
        p_Header    OUT SYS_REFCURSOR,
        p_Items     OUT SYS_REFCURSOR,
        p_Footer    OUT SYS_REFCURSOR
    );
    
    -- Служебные процедуры (без возврата данных)
    PROCEDURE sp_RefreshStatsCache;
    PROCEDURE sp_ArchiveAuditLogs(p_OlderThanDate IN DATE);

END pkg_rgr_analytics;
/

-- ═════════════════════════════════════════════════════════════════════════════
-- ТЕЛО ПАКЕТА
-- ═════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE PACKAGE BODY pkg_rgr_analytics AS

    -- ═══════════════════════════════════════════════════════════════
    -- РЕАЛИЗАЦИЯ КУРСОРОВ
    -- ═══════════════════════════════════════════════════════════════
    
    CURSOR c_LowStockItems RETURN t_LowStockRec IS
        SELECT product_ID, product_NAME, product_STOCK 
        FROM Products 
        WHERE product_STOCK < 5;

    -- ═══════════════════════════════════════════════════════════════
    -- СКРЫТАЯ (ПРИВАТНАЯ) ПРОЦЕДУРА
    -- ═══════════════════════════════════════════════════════════════
    
    PROCEDURE log_report_exec(p_ReportName IN VARCHAR2, p_Params IN VARCHAR2) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        -- Логирование (эмуляция)
        DBMS_OUTPUT.PUT_LINE('[AUDIT SYSTEM] Logged execution of: ' || p_ReportName || ' {' || p_Params || '}');
        COMMIT;
    END log_report_exec;

    -- ═══════════════════════════════════════════════════════════════
    -- РЕАЛИЗАЦИЯ ФУНКЦИЙ
    -- ═══════════════════════════════════════════════════════════════

    FUNCTION f_FormatPrice(p_Amount IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN TO_CHAR(p_Amount, c_money_mask) || ' USD';
    END f_FormatPrice;

    FUNCTION f_CalculateLoyaltyTier(p_TotalSpent IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        IF p_TotalSpent > 5000 THEN RETURN 'Platinum';
        ELSIF p_TotalSpent > 2000 THEN RETURN 'Gold';
        ELSIF p_TotalSpent > 500 THEN RETURN 'Silver';
        ELSE RETURN 'Bronze';
        END IF;
    END f_CalculateLoyaltyTier;

    FUNCTION f_HasActivePromo(p_CategoryID IN NUMBER) RETURN NUMBER IS
        v_Count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_Count
        FROM PromotionApplications pa
        JOIN Promotions p ON pa.promo_ID = p.promo_ID
        WHERE pa.target_TYPE = 'category' 
          AND pa.target_ID = p_CategoryID
          AND p.is_ACTIVE = 1
          AND SYSTIMESTAMP BETWEEN p.valid_FROM AND p.valid_TO;
          
        IF v_Count > 0 THEN RETURN 1; ELSE RETURN 0; END IF;
    END f_HasActivePromo;

    -- ═══════════════════════════════════════════════════════════════
    -- РЕАЛИЗАЦИЯ ПРОЦЕДУР
    -- ═══════════════════════════════════════════════════════════════

    -- 1. Отчет по категориям (возвращает курсор)
    PROCEDURE sp_CategoryPerformanceReport(
        p_MinSalesAmount IN NUMBER, 
        p_Cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        log_report_exec('CategoryPerformance', 'Min=' || p_MinSalesAmount);

        -- Открываем курсор для клиента.
        -- Используем функции пакета (f_FormatPrice, f_HasActivePromo) прямо в SQL
        OPEN p_Cursor FOR
            SELECT 
                c.category_NAME,
                COUNT(o.order_ID) as order_count,
                pkg_rgr_analytics.f_FormatPrice(SUM(oi.quantity * oi.price)) as formatted_sales,
                CASE 
                    WHEN pkg_rgr_analytics.f_HasActivePromo(c.category_ID) = 1 THEN 'YES' 
                    ELSE 'NO' 
                END as has_active_promo
            FROM Categories c
            JOIN Products p ON c.category_ID = p.category_ID
            JOIN OrderItems oi ON p.product_ID = oi.product_ID
            JOIN Orders o ON oi.order_ID = o.order_ID
            WHERE o.order_STATUS_ID = 4 
            GROUP BY c.category_ID, c.category_NAME
            HAVING SUM(oi.quantity * oi.price) >= p_MinSalesAmount;
    END sp_CategoryPerformanceReport;

    -- 2. Отчет по спящим клиентам (возвращает курсор)
    PROCEDURE sp_DormantCustomersReport(
        p_DaysSinceLastOrder IN NUMBER, 
        p_Cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        log_report_exec('DormantCustomers', 'Days=' || p_DaysSinceLastOrder);

        -- Используем функцию f_CalculateLoyaltyTier в SQL
        OPEN p_Cursor FOR
            SELECT 
                u.user_NAME,
                u.user_EMAIL,
                MAX(o.order_DATE) as last_order_date,
                pkg_rgr_analytics.f_CalculateLoyaltyTier(SUM(o.order_AMOUNT)) as loyalty_tier
            FROM Users u
            JOIN Orders o ON u.user_ID = o.user_ID
            GROUP BY u.user_ID, u.user_NAME, u.user_EMAIL
            HAVING MAX(o.order_DATE) < SYSTIMESTAMP - p_DaysSinceLastOrder;
    END sp_DormantCustomersReport;

    -- 3. Детализация чека (возвращает 3 курсора)
    PROCEDURE sp_GenerateFiscalReceipt(
            p_OrderID   IN NUMBER, 
            p_Header    OUT SYS_REFCURSOR,
            p_Items     OUT SYS_REFCURSOR,
            p_Footer    OUT SYS_REFCURSOR
        ) IS
            -- Используем переменную для хранения хэша
            v_FiscalSign VARCHAR2(100);
    BEGIN
        log_report_exec('FiscalReceipt', 'Order=' || p_OrderID);

        -- Генерируем хэш через нативный PL/SQL пакет DBMS_UTILITY
        -- Это работает в любой версии Oracle без ошибок компиляции
        v_FiscalSign := 'FP-' || DBMS_UTILITY.GET_HASH_VALUE(
            NAME      => TO_CHAR(p_OrderID) || TO_CHAR(SYSTIMESTAMP, 'FF'), 
            BASE      => 100000, 
            HASH_SIZE => 999999
        );

        -- 1. Header
        OPEN p_Header FOR
            SELECT 
                'OOO "WINSTORE KAZAKHSTAN"' as shop_name,
                'CHK-' || LPAD(o.order_ID, 8, '0') as receipt_no,
                TO_CHAR(o.order_DATE, 'DD.MM.YYYY HH24:MI') as dt_print,
                'System Bot' as cashier,
                u.user_NAME as client_name
            FROM Orders o
            JOIN Users u ON o.user_ID = u.user_ID
            WHERE o.order_ID = p_OrderID;

        -- 2. Items
        OPEN p_Items FOR
            SELECT 
                ROW_NUMBER() OVER (ORDER BY p.product_NAME) as pos_num,
                SUBSTR(p.product_NAME, 1, 40) as product_name,
                oi.quantity,
                pkg_rgr_analytics.f_FormatPrice(oi.price) as price_unit,
                pkg_rgr_analytics.f_FormatPrice(oi.quantity * oi.price) as total_line
            FROM OrderItems oi
            JOIN Products p ON oi.product_ID = p.product_ID
            WHERE oi.order_ID = p_OrderID;

        -- 3. Footer (Передаем готовую переменную v_FiscalSign)
        OPEN p_Footer FOR
            SELECT 
                pkg_rgr_analytics.f_FormatPrice(o.order_AMOUNT + NVL(o.promo_SAVINGS, 0)) as subtotal,
                pkg_rgr_analytics.f_FormatPrice(NVL(o.promo_SAVINGS, 0)) as discount,
                pkg_rgr_analytics.f_FormatPrice(o.order_AMOUNT) as grand_total,
                v_FiscalSign as fiscal_sign
            FROM Orders o
            WHERE o.order_ID = p_OrderID;

    END sp_GenerateFiscalReceipt;

    -- 4. Обновление кэша (Служебная, работает внутри)
    PROCEDURE sp_RefreshStatsCache IS
        -- Используем тип данных из спецификации
        rec_Low t_LowStockRec;
    BEGIN
        log_report_exec('RefreshStats', 'None');
        
        -- Работаем с явным курсором c_LowStockItems (объявлен в теле)
        OPEN c_LowStockItems;
        LOOP
            FETCH c_LowStockItems INTO rec_Low;
            EXIT WHEN c_LowStockItems%NOTFOUND;
            -- Имитация работы
            NULL; 
        END LOOP;
        CLOSE c_LowStockItems;
    END sp_RefreshStatsCache;

    -- 5. Архивация (Служебная)
    PROCEDURE sp_ArchiveAuditLogs(p_OlderThanDate IN DATE) IS
    BEGIN
        log_report_exec('ArchiveLogs', 'Date=' || TO_CHAR(p_OlderThanDate, 'YYYY-MM-DD'));
    END sp_ArchiveAuditLogs;

END pkg_rgr_analytics;
/