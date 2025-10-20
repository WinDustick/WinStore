-- =====================================================================
-- WinStore - Oracle Recovery Bootstrap Script
-- Purpose: Prepare a clean instance (or post-reset) for schema import
--          Creates WINSTORE_ADMIN, related users, and DIRECTORY for impdp
-- Usage:   Run as SYSDBA
-- =====================================================================

SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON
SET VERIFY OFF

-- Parameters (override via DEFINE before @recovery.sql if desired)
DEFINE ADMIN_PASS = 'AdminPass'
DEFINE MANAGER_PASS = 'ManagerPass'
DEFINE DEV_PASS = 'DevPass'
DEFINE APP_PASS = 'AppPass'
DEFINE READONLY_PASS = 'ReadonlyPass'
DEFINE BACKUP_PASS = 'BackupPass'
DEFINE DIRECTORY_NAME = 'WINSTORE_DUMP'
DEFINE DIRECTORY_PATH = '/opt/oracle/full_backups'

PROMPT ========== RECOVERY PREP: CREATE USERS AND DIRECTORY ==========

-- Create WINSTORE_ADMIN (schema owner)
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'WINSTORE_ADMIN';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER WINSTORE_ADMIN IDENTIFIED BY "' || '&ADMIN_PASS' || '" ' ||
                      'DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP';
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO WINSTORE_ADMIN';
    EXECUTE IMMEDIATE 'ALTER USER WINSTORE_ADMIN QUOTA UNLIMITED ON USERS';
    DBMS_OUTPUT.PUT_LINE('User WINSTORE_ADMIN created.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('User WINSTORE_ADMIN already exists.');
  END IF;
END;
/

-- Application users (minimal privileges; impdp will assign object grants if present)
DECLARE
  PROCEDURE ensure_user(p_name IN VARCHAR2, p_pass IN VARCHAR2) IS
    v_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt FROM dba_users WHERE username = UPPER(p_name);
    IF v_cnt = 0 THEN
      EXECUTE IMMEDIATE 'CREATE USER '||p_name||' IDENTIFIED BY "' || p_pass || '"';
      EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO '||p_name;
      DBMS_OUTPUT.PUT_LINE('User '||p_name||' created.');
    ELSE
      DBMS_OUTPUT.PUT_LINE('User '||p_name||' already exists.');
    END IF;
  END;
BEGIN
  ensure_user('WINSTORE_MANAGER', '&MANAGER_PASS');
  ensure_user('WINSTORE_DEV', '&DEV_PASS');
  ensure_user('WINSTORE_APP', '&APP_PASS');
  ensure_user('WINSTORE_READONLY', '&READONLY_PASS');
  ensure_user('WINSTORE_BACKUP', '&BACKUP_PASS');
END;
/

-- DIRECTORY for Data Pump
DECLARE
  v_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists FROM all_directories WHERE directory_name = '&DIRECTORY_NAME';
  IF v_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE DIRECTORY '||'&DIRECTORY_NAME'||' AS '''||'&DIRECTORY_PATH'||'''';
  ELSE
    EXECUTE IMMEDIATE 'CREATE OR REPLACE DIRECTORY '||'&DIRECTORY_NAME'||' AS '''||'&DIRECTORY_PATH'||'''';
  END IF;
  EXECUTE IMMEDIATE 'GRANT READ, WRITE ON DIRECTORY '||'&DIRECTORY_NAME'||' TO WINSTORE_ADMIN';
  EXECUTE IMMEDIATE 'GRANT READ, WRITE ON DIRECTORY '||'&DIRECTORY_NAME'||' TO SYSTEM';
  DBMS_OUTPUT.PUT_LINE('DIRECTORY '||'&DIRECTORY_NAME'||' set to '||'&DIRECTORY_PATH');
END;
/

PROMPT ========== RECOVERY PREP COMPLETED ==========
