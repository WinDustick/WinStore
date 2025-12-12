-- =====================================================================
-- WinStore - Security: Double Encryption Test (Tablespace + Columns)
-- =====================================================================
-- Цель: 
-- 1. Создать зашифрованное табличное пространство (AES128).
-- 2. Внутри него создать Таблицу А с колонкой (AES192).
-- 3. Внутри него создать Таблицу Б с колонкой (AES256).
-- ЭТО ДОКАЗЫВАЕТ независимость ключей таблиц друг от друга и от TS.
-- =====================================================================

SET SERVEROUTPUT ON;
SET LINESIZE 200;

-- 1. Настройка контекста
PROMPT >>> Switching to XEPDB1...
ALTER SESSION SET CONTAINER = XEPDB1;

-- 2. Открытие кошелька (на всякий случай)
BEGIN
   EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "WinStore_Secur1ty" CONTAINER=CURRENT';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- 3. Создание ЗАШИФРОВАННОГО Tablespace (Уровень ввода-вывода)
PROMPT >>> Creating Encrypted Tablespace (Algo: AES128)...
DECLARE
   v_Cnt NUMBER;
BEGIN
   -- Чистим старое
   SELECT count(*) INTO v_Cnt FROM dba_tablespaces WHERE tablespace_name = 'TS_DOUBLE_ENC_TEST';
   IF v_Cnt > 0 THEN
       EXECUTE IMMEDIATE 'DROP TABLESPACE TS_DOUBLE_ENC_TEST INCLUDING CONTENTS AND DATAFILES';
       DBMS_OUTPUT.PUT_LINE('Old tablespace dropped.');
   END IF;

   -- Создаем новое c шифрованием AES128
   EXECUTE IMMEDIATE 'CREATE TABLESPACE TS_DOUBLE_ENC_TEST 
                      DATAFILE ''/opt/oracle/oradata/ts_double_enc.dbf'' SIZE 20M
                      ENCRYPTION USING ''AES128'' DEFAULT STORAGE(ENCRYPT)';
                      
   DBMS_OUTPUT.PUT_LINE('Tablespace TS_DOUBLE_ENC_TEST created (Encrypted with AES128).');
END;
/

-- 4. Создание Таблиц с РАЗНЫМИ алгоритмами (Уровень SQL)
PROMPT >>> Creating Tables inside the Encrypted TS...
BEGIN
   -- Очистка
   BEGIN EXECUTE IMMEDIATE 'DROP TABLE WINSTORE_ADMIN.Tab_Inner_AES192 PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
   BEGIN EXECUTE IMMEDIATE 'DROP TABLE WINSTORE_ADMIN.Tab_Inner_AES256 PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;

   -- Таблица 1: Колонка шифруется AES192 (живет внутри TS AES128)
   EXECUTE IMMEDIATE '
     CREATE TABLE WINSTORE_ADMIN.Tab_Inner_AES192 (
        id NUMBER,
        secret_med VARCHAR2(100) ENCRYPT USING ''AES192'' SALT
     ) TABLESPACE TS_DOUBLE_ENC_TEST';
   DBMS_OUTPUT.PUT_LINE('Table Tab_Inner_AES192 created (Column Algo: AES192).');

   -- Таблица 2: Колонка шифруется AES256 (живет внутри TS AES128)
   EXECUTE IMMEDIATE '
     CREATE TABLE WINSTORE_ADMIN.Tab_Inner_AES256 (
        id NUMBER,
        secret_high VARCHAR2(100) ENCRYPT USING ''AES256'' SALT
     ) TABLESPACE TS_DOUBLE_ENC_TEST';
   DBMS_OUTPUT.PUT_LINE('Table Tab_Inner_AES256 created (Column Algo: AES256).');
END;
/

-- 5. Доказательство (Verification Report)
PROMPT >>> VERIFICATION REPORT:

PROMPT 1. Tablespace Level Encryption:
COL tablespace_name FORMAT A20
COL encrypted FORMAT A10

SELECT tablespace_name, encrypted 
FROM dba_tablespaces 
WHERE tablespace_name = 'TS_DOUBLE_ENC_TEST';

PROMPT 2. Column Level Encryption (Different Algorithms):
COL table_name FORMAT A20
COL column_name FORMAT A15
COL encryption_alg FORMAT A15
COL salt FORMAT A5

SELECT table_name, 
       column_name, 
       encryption_alg, 
       salt
FROM all_encrypted_columns
WHERE owner = 'WINSTORE_ADMIN'
  AND table_name IN ('TAB_INNER_AES192', 'TAB_INNER_AES256')
ORDER BY table_name;

PROMPT >>> TEST COMPLETED.