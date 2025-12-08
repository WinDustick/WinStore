SET SERVEROUTPUT ON;

DECLARE
    -- Переменные для курсоров
    rc_Header   SYS_REFCURSOR;
    rc_Items    SYS_REFCURSOR;
    rc_Footer   SYS_REFCURSOR;

    -- Переменные для данных (Шапка)
    v_Shop      VARCHAR2(200);
    v_RcptNo    VARCHAR2(100);
    v_Date      VARCHAR2(50);
    v_Cashier   VARCHAR2(100);
    v_Client    VARCHAR2(200);

    -- Переменные для данных (Позиции)
    v_PosNum    NUMBER;
    v_Prod      VARCHAR2(500);
    v_Qty       NUMBER;
    v_Price     VARCHAR2(100);
    v_Sum       VARCHAR2(100);

    -- Переменные для данных (Подвал)
    v_Subtotal  VARCHAR2(100);
    v_Discount  VARCHAR2(100);
    v_Grand     VARCHAR2(100);
    v_Fiscal    VARCHAR2(200);

    -- Технические переменные
    v_OrderID   NUMBER;
    -- ВАЖНО: Увеличили размер буфера, чтобы влезли символы '═'
    c_Sep       VARCHAR2(200) := '═══════════════════════════════════════════════';

BEGIN
    -- 1. Находим ID любого выполненного заказа для теста
    BEGIN
        SELECT order_ID INTO v_OrderID 
        FROM Orders 
        WHERE order_STATUS_ID = 4 
        FETCH FIRST 1 ROW ONLY;
    EXCEPTION 
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Нет заказов со статусом 4 (Completed) для теста.');
            RETURN; -- Прерываем выполнение
    END;

    DBMS_OUTPUT.PUT_LINE('Тестируем печать для Order ID: ' || v_OrderID);

    -- 2. Вызываем процедуру из твоего пакета
    pkg_rgr_analytics.sp_GenerateFiscalReceipt(
        p_OrderID => v_OrderID,
        p_Header  => rc_Header,
        p_Items   => rc_Items,
        p_Footer  => rc_Footer
    );

    -- 3. Вывод в консоль (DBMS_OUTPUT)
    
    -- === ШАПКА ===
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '                ФИСКАЛЬНЫЙ ЧЕК                ');
    DBMS_OUTPUT.PUT_LINE(c_Sep);
    
    FETCH rc_Header INTO v_Shop, v_RcptNo, v_Date, v_Cashier, v_Client;
    DBMS_OUTPUT.PUT_LINE(v_Shop);
    DBMS_OUTPUT.PUT_LINE('Чек: ' || v_RcptNo);
    DBMS_OUTPUT.PUT_LINE('Дата: ' || v_Date);
    DBMS_OUTPUT.PUT_LINE('Кассир: ' || v_Cashier);
    DBMS_OUTPUT.PUT_LINE('Клиент: ' || v_Client);
    CLOSE rc_Header;

    DBMS_OUTPUT.PUT_LINE('───────────────────────────────────────────────');
    DBMS_OUTPUT.PUT_LINE('#  НАИМЕНОВАНИЕ                  КОЛ-ВО   СУММА');
    DBMS_OUTPUT.PUT_LINE('───────────────────────────────────────────────');

    -- === ПОЗИЦИИ ===
    LOOP
        FETCH rc_Items INTO v_PosNum, v_Prod, v_Qty, v_Price, v_Sum;
        EXIT WHEN rc_Items%NOTFOUND;
        
        -- Форматируем вывод: номер и товар
        DBMS_OUTPUT.PUT_LINE(v_PosNum || '. ' || SUBSTR(v_Prod, 1, 35));
        -- Форматируем вывод: цена и расчет
        DBMS_OUTPUT.PUT_LINE('   ' || v_Qty || ' x ' || v_Price || ' = ' || v_Sum);
    END LOOP;
    CLOSE rc_Items;

    DBMS_OUTPUT.PUT_LINE(c_Sep);

    -- === ПОДВАЛ ===
    FETCH rc_Footer INTO v_Subtotal, v_Discount, v_Grand, v_Fiscal;
    DBMS_OUTPUT.PUT_LINE(RPAD('ПОДИТОГ:', 20) || LPAD(v_Subtotal, 26));
    DBMS_OUTPUT.PUT_LINE(RPAD('СКИДКА:', 20) || LPAD(v_Discount, 26));
    DBMS_OUTPUT.PUT_LINE(RPAD('ИТОГО К ОПЛАТЕ:', 20) || LPAD(v_Grand, 26));
    DBMS_OUTPUT.PUT_LINE('───────────────────────────────────────────────');
    DBMS_OUTPUT.PUT_LINE('ФП: ' || v_Fiscal);
    CLOSE rc_Footer;
    
    DBMS_OUTPUT.PUT_LINE(c_Sep || CHR(10));

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Произошла ошибка: ' || SQLERRM);
        -- Закрываем курсоры, если они остались открыты при ошибке
        IF rc_Header%ISOPEN THEN CLOSE rc_Header; END IF;
        IF rc_Items%ISOPEN THEN CLOSE rc_Items; END IF;
        IF rc_Footer%ISOPEN THEN CLOSE rc_Footer; END IF;
END;
/