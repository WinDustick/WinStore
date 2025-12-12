-- =====================================================================
-- WinStore - Security: Audit Sandbox Simulation
-- =====================================================================
-- User: SYS as SYSDBA
-- Description: Создает изолированную среду для демонстрации работы
--              Unified Auditing без конфликтов с бизнес-логикой.
-- =====================================================================

SET SERVEROUTPUT ON;

-- 1. Настройка контекста
PROMPT >>> Switching to PDB (XEPDB1)...
ALTER SESSION SET CONTAINER = XEPDB1;
ALTER SESSION SET CURRENT_SCHEMA = WINSTORE_ADMIN;

-- 2. Подготовка "Песочницы" (Test Table)
PROMPT >>> Creating Sandbox Table...
BEGIN
   -- Удаляем старую, если есть
   BEGIN EXECUTE IMMEDIATE 'DROP TABLE AuditSandbox PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
   
   -- Создаем максимально простую таблицу
   EXECUTE IMMEDIATE 'CREATE TABLE AuditSandbox (
                        id NUMBER, 
                        secret_data VARCHAR2(100), 
                        changed_by VARCHAR2(100)
                      )';
                      
   DBMS_OUTPUT.PUT_LINE('Table WINSTORE_ADMIN.AuditSandbox created.');
END;
/

-- 3. Настройка Политики Аудита
PROMPT >>> Configuring Audit Policy for Sandbox...
DECLARE
   v_PolExists NUMBER;
BEGIN
   -- Удаляем старую политику, если есть (чтобы пересоздать чисто)
   SELECT COUNT(*) INTO v_PolExists FROM audit_unified_policies WHERE policy_name = 'POL_AUDIT_SANDBOX';
   IF v_PolExists > 0 THEN
      EXECUTE IMMEDIATE 'NOAUDIT POLICY POL_AUDIT_SANDBOX'; -- Выключаем
      EXECUTE IMMEDIATE 'DROP AUDIT POLICY POL_AUDIT_SANDBOX'; -- Удаляем
   END IF;

   -- Создаем новую политику: следим за ВСЕМ (INSERT, UPDATE, DELETE, SELECT)
   EXECUTE IMMEDIATE 'CREATE AUDIT POLICY POL_AUDIT_SANDBOX 
                      ACTIONS SELECT ON AuditSandbox,
                              INSERT ON AuditSandbox, 
                              UPDATE ON AuditSandbox, 
                              DELETE ON AuditSandbox';
                              
   DBMS_OUTPUT.PUT_LINE('Policy POL_AUDIT_SANDBOX created.');
   
   -- Включаем политику
   EXECUTE IMMEDIATE 'AUDIT POLICY POL_AUDIT_SANDBOX';
   DBMS_OUTPUT.PUT_LINE('Policy POL_AUDIT_SANDBOX enabled.');
END;
/

-- 4. Генерация событий (Simulation)
PROMPT >>> Executing Triggers (Actions)...
BEGIN
   -- Действие 1: INSERT
   INSERT INTO AuditSandbox (id, secret_data, changed_by) VALUES (1, 'Top Secret', 'Admin');
   
   -- Действие 2: UPDATE
   UPDATE AuditSandbox SET secret_data = 'Compromised' WHERE id = 1;
   
   -- Действие 3: SELECT (Чтение тоже аудируется)
   FOR r IN (SELECT * FROM AuditSandbox) LOOP
       NULL; -- Просто читаем
   END LOOP;
   
   -- Действие 4: DELETE
   DELETE FROM AuditSandbox WHERE id = 1;
   
   COMMIT;
   
   -- Сброс буфера аудита на диск (чтобы увидеть сразу)
   BEGIN DBMS_AUDIT_MGMT.FLUSH_UNIFIED_AUDIT_TRAIL; EXCEPTION WHEN OTHERS THEN NULL; END;
   
   DBMS_OUTPUT.PUT_LINE('Actions performed: INSERT -> UPDATE -> SELECT -> DELETE');
END;
/

-- 5. Отчет (Результат)
PROMPT >>> AUDIT TRAIL REPORT (Target: AuditSandbox)

SET LINESIZE 200
COL event_time FORMAT A22
COL dbusername FORMAT A15
COL action_name FORMAT A10
COL object_name FORMAT A15
COL sql_text FORMAT A50

SELECT to_char(event_timestamp, 'DD-MON-YY HH24:MI:SS') as event_time, 
       dbusername, 
       action_name, 
       object_name, 
       sql_text
FROM unified_audit_trail
WHERE object_name = 'AUDITSANDBOX' -- Фильтруем только нашу таблицу
  AND event_timestamp > SYSTIMESTAMP - INTERVAL '15' MINUTE
ORDER BY event_timestamp ASC;

PROMPT === SANDBOX TEST COMPLETED ===