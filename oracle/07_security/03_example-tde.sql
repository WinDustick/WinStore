-- =====================================================================
-- WinStore - Security: Multi-Algorithm Encryption Test (Corrected)
-- =====================================================================
-- Цель: Доказать возможность использования разных алгоритмов шифрования
--       для разных таблиц в одном табличном пространстве.
-- ВАЖНО: В одной таблице все шифрованные столбцы должны иметь один алгоритм!
-- =====================================================================

SET SERVEROUTPUT ON;
SET LINESIZE 200;

-- 1. Переключение
PROMPT >>> Switching to XEPDB1...
ALTER SESSION SET CONTAINER = XEPDB1;

-- 2. Создание ЧИСТОГО (нешифрованного) Tablespace
PROMPT >>> Creating Unencrypted Test Tablespace...
DECLARE
   v_Cnt NUMBER;
BEGIN
   -- Если пространство осталось с прошлого раза (возможно, зашифрованное), лучше его удалить
   SELECT count(*) INTO v_Cnt FROM dba_tablespaces WHERE tablespace_name = 'TEST_COL_ENC_TS';
   IF v_Cnt > 0 THEN
       EXECUTE IMMEDIATE 'DROP TABLESPACE TEST_COL_ENC_TS INCLUDING CONTENTS AND DATAFILES';
       DBMS_OUTPUT.PUT_LINE('Old tablespace dropped.');
   END IF;

   -- Создаем новое (без ключевого слова ENCRYPTION)
   EXECUTE IMMEDIATE 'CREATE TABLESPACE TEST_COL_ENC_TS 
                      DATAFILE ''/opt/oracle/oradata/test_col_enc.dbf'' SIZE 20M';
   DBMS_OUTPUT.PUT_LINE('Tablespace TEST_COL_ENC_TS created (Unencrypted).');
END;
/

-- 3. Создание Таблиц с РАЗНЫМИ алгоритмами
PROMPT >>> Creating Tables with Different Algos...
BEGIN
   -- Очистка
   BEGIN EXECUTE IMMEDIATE 'DROP TABLE WINSTORE_ADMIN.Table_AES128 PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
   BEGIN EXECUTE IMMEDIATE 'DROP TABLE WINSTORE_ADMIN.Table_AES256 PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;

   -- Таблица 1: Слабое шифрование (AES128)
   EXECUTE IMMEDIATE '
     CREATE TABLE WINSTORE_ADMIN.Table_AES128 (
        id NUMBER,
        data_low VARCHAR2(100) ENCRYPT USING ''AES128'' SALT
     ) TABLESPACE TEST_COL_ENC_TS';
   DBMS_OUTPUT.PUT_LINE('Table_AES128 created.');

   -- Таблица 2: Сильное шифрование (AES256)
   EXECUTE IMMEDIATE '
     CREATE TABLE WINSTORE_ADMIN.Table_AES256 (
        id NUMBER,
        data_high VARCHAR2(100) ENCRYPT USING ''AES256'' SALT
     ) TABLESPACE TEST_COL_ENC_TS';
   DBMS_OUTPUT.PUT_LINE('Table_AES256 created.');
END;
/

-- 4. Проверка (Verification Report)
PROMPT >>> VERIFICATION REPORT:

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
  AND table_name IN ('TABLE_AES128', 'TABLE_AES256')
ORDER BY table_name;

PROMPT >>> TEST COMPLETED.