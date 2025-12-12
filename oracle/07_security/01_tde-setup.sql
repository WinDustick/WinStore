-- =====================================================================
-- WinStore - TDE Fix: Set PDB Key & Re-enable Autologin
-- =====================================================================
-- Выполнять ПОСЛЕ удаления cwallet.sso
-- =====================================================================
SET SERVEROUTPUT ON;

-- 1. Настройка PDB (Теперь кошелек не заблокирован)
PROMPT >>> Switching to XEPDB1...
ALTER SESSION SET CONTAINER = XEPDB1;

PROMPT >>> Opening Wallet (Write Mode)...
BEGIN
   -- Теперь это откроет ewallet.p12 в режиме RW
   EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "WinStore_Secur1ty" CONTAINER=CURRENT';
   DBMS_OUTPUT.PUT_LINE('SUCCESS: Wallet opened with password.');
EXCEPTION 
   WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('WALLET ERROR: ' || SQLERRM); 
END;
/

PROMPT >>> Setting Master Key...
BEGIN
   -- Теперь это должно сработать
   EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT SET KEY IDENTIFIED BY "WinStore_Secur1ty" WITH BACKUP CONTAINER=CURRENT';
   DBMS_OUTPUT.PUT_LINE('SUCCESS: PDB Master Key set.');
EXCEPTION 
   WHEN OTHERS THEN 
      -- ORA-28374 означает, что ключ уже был установлен ранее (это хорошо)
      IF SQLCODE = -28374 THEN 
          DBMS_OUTPUT.PUT_LINE('INFO: Master key was already set.');
      ELSE 
          DBMS_OUTPUT.PUT_LINE('KEY ERROR: ' || SQLERRM); 
      END IF;
END;
/

-- 2. Создание зашифрованных объектов
PROMPT >>> Creating Encrypted Objects...
ALTER SESSION SET CURRENT_SCHEMA = WINSTORE_ADMIN;

-- Tablespace
BEGIN
   EXECUTE IMMEDIATE 'CREATE TABLESPACE WINSTORE_SECURE_TS 
                      DATAFILE ''/opt/oracle/oradata/winstore_secure01.dbf'' SIZE 50M 
                      ENCRYPTION USING ''AES256'' DEFAULT STORAGE(ENCRYPT)';
   DBMS_OUTPUT.PUT_LINE('SUCCESS: Tablespace created.');
EXCEPTION
   WHEN OTHERS THEN 
      IF SQLCODE = -959 OR SQLCODE = -1543 THEN DBMS_OUTPUT.PUT_LINE('INFO: Tablespace already exists.');
      ELSE DBMS_OUTPUT.PUT_LINE('TABLESPACE ERROR: ' || SQLERRM); END IF;
END;
/

-- Таблицы
BEGIN
   BEGIN EXECUTE IMMEDIATE 'DROP TABLE SecurePaymentsArchive PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
   
   DECLARE cnt NUMBER; BEGIN
     SELECT count(*) INTO cnt FROM user_tablespaces WHERE tablespace_name = 'WINSTORE_SECURE_TS';
     IF cnt > 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE SecurePaymentsArchive TABLESPACE WINSTORE_SECURE_TS AS SELECT * FROM Payments';
        DBMS_OUTPUT.PUT_LINE('SUCCESS: Encrypted Table created.');
     ELSE
        DBMS_OUTPUT.PUT_LINE('SKIP: Tablespace not ready.');
     END IF;
   END;
   
   -- Копия для ручного теста
   BEGIN EXECUTE IMMEDIATE 'DROP TABLE SecureUsersCopy PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
   EXECUTE IMMEDIATE 'CREATE TABLE SecureUsersCopy TABLESPACE USERS AS SELECT * FROM Users';
   DBMS_OUTPUT.PUT_LINE('SUCCESS: SecureUsersCopy created (Ready for manual encryption).');
END;
/

-- 3. Возвращаем Auto-Login (чтобы после рестарта всё работало само)
PROMPT >>> Re-enabling Auto-Login (Global)...
ALTER SESSION SET CONTAINER = CDB$ROOT;

BEGIN
   EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT CREATE AUTO_LOGIN KEYSTORE FROM KEYSTORE IDENTIFIED BY "WinStore_Secur1ty"';
   DBMS_OUTPUT.PUT_LINE('SUCCESS: Auto-login (cwallet.sso) restored.');
EXCEPTION 
   WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('AUTOLOGIN ERROR: ' || SQLERRM); 
END;
/

PROMPT === FIX COMPLETED ===