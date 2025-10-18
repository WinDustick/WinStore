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
WHENEVER SQLERROR CONTINUE;

PROMPT ========== STARTING SIMPLIFIED DATABASE RESET ==========

-- Connect with sufficient privileges
CONNECT SYS/123@PDB1 AS SYSDBA

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

-- Check for database links to WINSTORE_ADMIN objects from other schemas
DECLARE
  v_count NUMBER := 0;
BEGIN
  SELECT COUNT(*) INTO v_count FROM dba_objects 
  WHERE owner != 'WINSTORE_ADMIN'
  AND (object_name LIKE '%WINSTORE%' OR object_name LIKE '%ORDER%' 
       OR object_name LIKE '%PRODUCT%' OR object_name LIKE '%USER%');
  
  IF v_count > 0 THEN
    DBMS_OUTPUT.PUT_LINE('WARNING: Found ' || v_count || ' objects in other schemas that may reference WINSTORE objects.');
    DBMS_OUTPUT.PUT_LINE('You may need to clean these up manually after dropping the WINSTORE_ADMIN user.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('No external references to WINSTORE objects found.');
  END IF;
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