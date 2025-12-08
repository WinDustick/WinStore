-- =====================================================================
-- WinStore - Security Layer: Transparent Data Encryption (TDE)
-- =====================================================================
-- Pre-requisites (выполнить в консоли сервера/Docker перед запуском):
-- 1. mkdir -p /opt/oracle/oradata/dbconfig/$ORACLE_SID/wallet
-- 2. Добавить в sqlnet.ora:
--    ENCRYPTION_WALLET_LOCATION = (SOURCE = (METHOD = FILE) (METHOD_DATA = (DIRECTORY = /opt/oracle/oradata/dbconfig/ORCLCDB/wallet)))
-- =====================================================================

SET SERVEROUTPUT ON;
SET ECHO ON;

PROMPT >>> Настройка TDE (Wallet Setup)...

-- 1. Настройка и открытие Keystore (Кошелька)
-- ПРИМЕЧАНИЕ: Если кошелек уже создан, эта команда выдаст ошибку. 
-- В реальном скрипте деплоя это оборачивают в BEGIN-EXCEPTION, но для академ. целей оставляем явно.
BEGIN
   EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT CREATE KEYSTORE ''/opt/oracle/oradata/dbconfig/ORCLCDB/wallet'' IDENTIFIED BY "WinStore_Secur1ty"';
   DBMS_OUTPUT.PUT_LINE('Keystore created.');
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Keystore already exists or path invalid. Continuing...');
END;
/

-- 2. Открытие кошелька (нужно делать после каждого перезапуска БД, если не настроен Auto-Login)
BEGIN
   EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "WinStore_Secur1ty" CONTAINER=ALL';
   DBMS_OUTPUT.PUT_LINE('Keystore opened.');
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Keystore already open or error: ' || SQLERRM);
END;
/

-- 3. Установка Мастер-ключа (Master Key)
-- Это действие активирует TDE.
BEGIN
   EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT SET KEY IDENTIFIED BY "WinStore_Secur1ty" WITH BACKUP CONTAINER=ALL';
   DBMS_OUTPUT.PUT_LINE('Master key set.');
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Master key set error (maybe already set): ' || SQLERRM);
END;
/

PROMPT >>> Создание защищенных структур хранения...

-- 4. Создание зашифрованного табличного пространства (Tablespace Encryption)
-- Данные в этом пространстве будут зашифрованы алгоритмом AES256
DECLARE
   v_Exists NUMBER;
BEGIN
   SELECT COUNT(*) INTO v_Exists FROM dba_tablespaces WHERE tablespace_name = 'WINSTORE_SECURE_TS';
   IF v_Exists = 0 THEN
      -- Обратите внимание: Путь к datafile зависит от вашей ОС. Здесь пример для Linux/Docker
      EXECUTE IMMEDIATE 'CREATE TABLESPACE WINSTORE_SECURE_TS 
                         DATAFILE ''/opt/oracle/oradata/ORCLCDB/winstore_secure01.dbf'' SIZE 100M 
                         ENCRYPTION USING ''AES256'' DEFAULT STORAGE(ENCRYPT)';
      DBMS_OUTPUT.PUT_LINE('Encrypted tablespace WINSTORE_SECURE_TS created.');
   ELSE
      DBMS_OUTPUT.PUT_LINE('Tablespace WINSTORE_SECURE_TS already exists.');
   END IF;
END;
/

-- 5. Создание полностью зашифрованной таблицы (Table Encryption)
-- Мы создаем архивную таблицу платежей в защищенном пространстве
BEGIN
   EXECUTE IMMEDIATE 'CREATE TABLE SecurePaymentsArchive 
                      TABLESPACE WINSTORE_SECURE_TS 
                      AS SELECT * FROM Payments WHERE 1=0';
   DBMS_OUTPUT.PUT_LINE('Table SecurePaymentsArchive created in encrypted tablespace.');
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Table SecurePaymentsArchive already exists.');
END;
/

PROMPT >>> Шифрование отдельных колонок (Column Encryption)...

-- 6. Шифрование чувствительных данных в существующей таблице
-- Шифруем хэш пароля пользователя. 
-- NO SALT используется, если мы хотим индексировать эту колонку (хотя для паролей лучше SALT).
DECLARE
   v_Encrypted VARCHAR2(3);
BEGIN
   -- Проверяем, зашифрована ли уже колонка
   SELECT encryption_alg INTO v_Encrypted
   FROM user_encrypted_columns
   WHERE table_name = 'USERS' AND column_name = 'USER_PASSWORD_HASH';
   
   DBMS_OUTPUT.PUT_LINE('Column is already encrypted.');
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      -- Если не зашифрована - шифруем
      EXECUTE IMMEDIATE 'ALTER TABLE Users MODIFY (user_PASSWORD_HASH ENCRYPT USING ''AES192'' SALT)';
      DBMS_OUTPUT.PUT_LINE('Column Users.user_PASSWORD_HASH encrypted successfully.');
END;
/

PROMPT === TDE SETUP COMPLETED ===