-- =====================================================================
-- WinStore - Oracle Database Reset Script (win_db_reset_simple.sql)
-- =====================================================================
-- Author:      WinStore Development Team
-- Created:     2025-09-30
-- Modified:    2025-09-30
-- Description: Simplified database reset through cascaded user drop
-- =====================================================================

SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON

DEFINE HOST = 'localhost'
DEFINE PORT = '1521'
DEFINE SERVICE = 'XEPDB1'
DEFINE SYS_PASS = '0r4c13_53rV3r'

PROMPT ========== STARTING SIMPLIFIED DATABASE RESET ==========
WHENEVER SQLERROR EXIT SQL.SQLCODE

-- Connect with sufficient privileges
CONNECT sys/&SYS_PASS@//&HOST:&PORT/&SERVICE AS SYSDBA
WHENEVER SQLERROR CONTINUE;

-- Terminate active sessions for WINSTORE users to avoid ORA-01940
BEGIN
  FOR s IN (
    SELECT DISTINCT sid, serial#
    FROM   v$session
    WHERE  username IN ('WINSTORE_ADMIN', 'WINSTORE_MANAGER', 'WINSTORE_DEV',
                        'WINSTORE_APP', 'WINSTORE_READONLY', 'WINSTORE_BACKUP')
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'ALTER SYSTEM KILL SESSION '''||s.sid||','||s.serial#||''' IMMEDIATE';
      DBMS_OUTPUT.PUT_LINE('Killed session '||s.sid||','||s.serial#);
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Failed to kill session '||s.sid||','||s.serial#||': '||SQLERRM);
    END;
  END LOOP;
END;
/

-- Drop application users first (preventing references to WINSTORE_ADMIN objects)
BEGIN
  FOR user_rec IN (SELECT username FROM dba_users
                   WHERE username IN ('WINSTORE_MANAGER', 'WINSTORE_DEV',
                                      'WINSTORE_APP', 'WINSTORE_READONLY',
                                      'WINSTORE_BACKUP'))
  LOOP
    BEGIN  -- НАЧАЛО внутреннего блока BEGIN
      EXECUTE IMMEDIATE 'DROP USER ' || user_rec.username || ' CASCADE';
      DBMS_OUTPUT.PUT_LINE('Dropped user: ' || user_rec.username);
    EXCEPTION -- Секция EXCEPTION находится внутри BEGIN...END
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Failed to drop user ' || user_rec.username || ': ' || SQLERRM);
    END;    -- КОНЕЦ внутреннего блока BEGIN
  END LOOP;
END;
/

-- Drop application roles
BEGIN
  FOR role_rec IN (SELECT role FROM dba_roles
                   WHERE role IN ('WINSTORE_MANAGER_ROLE', 'WINSTORE_DEV_ROLE',
                                  'WINSTORE_APP_ROLE', 'WINSTORE_READONLY_ROLE',
                                  'WINSTORE_BACKUP_ROLE'))
  LOOP
    BEGIN  -- НАЧАЛО внутреннего блока BEGIN
      EXECUTE IMMEDIATE 'DROP ROLE ' || role_rec.role;
      DBMS_OUTPUT.PUT_LINE('Dropped role: ' || role_rec.role);
    EXCEPTION -- Секция EXCEPTION находится внутри BEGIN...END
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Failed to drop role ' || role_rec.role || ': ' || SQLERRM);
    END;    -- КОНЕЦ внутреннего блока BEGIN
  END LOOP;
END;
/

-- Drop the WINSTORE_ADMIN user with CASCADE option to remove all objects
BEGIN
  EXECUTE IMMEDIATE 'DROP USER WINSTORE_ADMIN CASCADE';
  DBMS_OUTPUT.PUT_LINE('Successfully dropped user WINSTORE_ADMIN and all associated objects');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error dropping WINSTORE_ADMIN: ' || SQLERRM);
END;
/

PROMPT ========== DATABASE RESET COMPLETED ==========
PROMPT Ready for fresh deployment