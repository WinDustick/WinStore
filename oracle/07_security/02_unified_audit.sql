-- =====================================================================
-- WinStore - Security Layer: Oracle Unified Auditing
-- =====================================================================
-- Description: Настройка политик аудита для отслеживания чувствительных
--              операций.
-- =====================================================================

SET SERVEROUTPUT ON;

PROMPT >>> Настройка Unified Auditing...

-- 1. Создание политики аудита
-- Мы хотим знать, кто и когда трогает деньги (таблицу Payments) и пользователей (Users)
DECLARE
   v_PolExists NUMBER;
BEGIN
   SELECT COUNT(*) INTO v_PolExists FROM audit_unified_policies WHERE policy_name = 'POL_WINSTORE_CRITICAL';
   
   IF v_PolExists = 0 THEN
      EXECUTE IMMEDIATE 'CREATE AUDIT POLICY POL_WINSTORE_CRITICAL 
                         ACTIONS INSERT ON Payments, 
                                 UPDATE ON Payments, 
                                 DELETE ON Payments,
                                 UPDATE ON Users';
      DBMS_OUTPUT.PUT_LINE('Audit policy POL_WINSTORE_CRITICAL created.');
   ELSE
      DBMS_OUTPUT.PUT_LINE('Audit policy POL_WINSTORE_CRITICAL already exists.');
   END IF;
END;
/

-- 2. Включение политики
-- Включаем для всех пользователей, кроме, возможно, технических, но здесь для всех
AUDIT POLICY POL_WINSTORE_CRITICAL;
PROMPT Policy enabled.

-- 3. Тестовый сценарий (Simulation)
-- Выполняем действия, которые должны попасть в аудит
PROMPT >>> Executing Audit Simulation...

DECLARE
   v_TestUserID NUMBER;
   v_TestPaymentID NUMBER;
BEGIN
   -- Находим пользователя для теста
   SELECT user_ID INTO v_TestUserID FROM Users FETCH FIRST 1 ROW ONLY;
   
   -- 1. Действие: Обновление пользователя (должно попасть в аудит)
   UPDATE Users SET updated_AT = SYSTIMESTAMP WHERE user_ID = v_TestUserID;
   
   -- 2. Действие: Вставка платежа (должно попасть в аудит)
   INSERT INTO Payments (payment_ID, order_ID, payment_DATE, payment_AMOUNT, payment_METHOD, payment_STATUS_ID)
   VALUES (-999, NULL, SYSTIMESTAMP, 1.00, 'AuditTest', 1); -- ID -999 маркер теста
   
   -- 3. Действие: Удаление платежа (должно попасть в аудит)
   DELETE FROM Payments WHERE payment_ID = -999;
   
   COMMIT;
   DBMS_OUTPUT.PUT_LINE('Simulation transactions committed.');
END;
/

-- 4. Проверка результатов (Reporting)
PROMPT >>> Reading Unified Audit Trail (Last 5 events)...

SET LINESIZE 200
COL event_timestamp FORMAT A25
COL dbusername FORMAT A15
COL action_name FORMAT A15
COL object_name FORMAT A15
COL sql_text FORMAT A50

SELECT event_timestamp, 
       dbusername, 
       action_name, 
       object_name, 
       sql_text
FROM unified_audit_trail
WHERE unified_audit_policies LIKE '%POL_WINSTORE_CRITICAL%'
  AND event_timestamp > SYSTIMESTAMP - INTERVAL '5' MINUTE
ORDER BY event_timestamp DESC
FETCH FIRST 5 ROWS ONLY;

PROMPT === AUDIT SETUP COMPLETED ===