-- =====================================================================
-- WinStore - Oracle Database Users Creation
-- =====================================================================
-- Description: Creates database users with appropriate permissions for
--              different roles in the WinStore application
-- Author:      WinStore Development Team
-- Created:     2025-09-29
-- Modified:    2025-09-29
-- Version:     1.0.0
-- =====================================================================

SET SERVEROUTPUT ON
SET FEEDBACK ON

PROMPT ========== CREATING DATABASE ROLES ==========

-- Create application roles
DECLARE
  v_count NUMBER;
BEGIN
  -- Manager Role
  SELECT COUNT(*) INTO v_count FROM dba_roles WHERE role = 'WINSTORE_MANAGER_ROLE';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE ROLE WINSTORE_MANAGER_ROLE';
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION, ALTER SESSION TO WINSTORE_MANAGER_ROLE';
    EXECUTE IMMEDIATE 'GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE SEQUENCE TO WINSTORE_MANAGER_ROLE';
    DBMS_OUTPUT.PUT_LINE('Role WINSTORE_MANAGER_ROLE created successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Role WINSTORE_MANAGER_ROLE already exists');
  END IF;
  
  -- Developer Role
  SELECT COUNT(*) INTO v_count FROM dba_roles WHERE role = 'WINSTORE_DEV_ROLE';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE ROLE WINSTORE_DEV_ROLE';
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION, ALTER SESSION TO WINSTORE_DEV_ROLE';
    EXECUTE IMMEDIATE 'GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE SEQUENCE TO WINSTORE_DEV_ROLE';
    DBMS_OUTPUT.PUT_LINE('Role WINSTORE_DEV_ROLE created successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Role WINSTORE_DEV_ROLE already exists');
  END IF;
  
  -- Application Role
  SELECT COUNT(*) INTO v_count FROM dba_roles WHERE role = 'WINSTORE_APP_ROLE';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE ROLE WINSTORE_APP_ROLE';
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO WINSTORE_APP_ROLE';
    DBMS_OUTPUT.PUT_LINE('Role WINSTORE_APP_ROLE created successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Role WINSTORE_APP_ROLE already exists');
  END IF;
  
  -- Read-only Role
  SELECT COUNT(*) INTO v_count FROM dba_roles WHERE role = 'WINSTORE_READONLY_ROLE';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE ROLE WINSTORE_READONLY_ROLE';
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO WINSTORE_READONLY_ROLE';
    DBMS_OUTPUT.PUT_LINE('Role WINSTORE_READONLY_ROLE created successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Role WINSTORE_READONLY_ROLE already exists');
  END IF;
  
  -- Backup Role
  SELECT COUNT(*) INTO v_count FROM dba_roles WHERE role = 'WINSTORE_BACKUP_ROLE';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE ROLE WINSTORE_BACKUP_ROLE';
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO WINSTORE_BACKUP_ROLE';
    EXECUTE IMMEDIATE 'GRANT SELECT ANY TABLE TO WINSTORE_BACKUP_ROLE';
    EXECUTE IMMEDIATE 'GRANT EXP_FULL_DATABASE TO WINSTORE_BACKUP_ROLE';
    DBMS_OUTPUT.PUT_LINE('Role WINSTORE_BACKUP_ROLE created successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Role WINSTORE_BACKUP_ROLE already exists');
  END IF;
END;
/

PROMPT ========== CREATING APPLICATION USERS ==========

-- Create Manager user (for database administration)
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'WINSTORE_MANAGER';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER WINSTORE_MANAGER IDENTIFIED BY "123Mgr"';
    EXECUTE IMMEDIATE 'GRANT WINSTORE_MANAGER_ROLE TO WINSTORE_MANAGER';
    EXECUTE IMMEDIATE 'ALTER USER WINSTORE_MANAGER QUOTA UNLIMITED ON USERS';
    DBMS_OUTPUT.PUT_LINE('User WINSTORE_MANAGER created successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('User WINSTORE_MANAGER already exists');
  END IF;
END;
/

-- Create Developer user
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'WINSTORE_DEV';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER WINSTORE_DEV IDENTIFIED BY "123Dev"';
    EXECUTE IMMEDIATE 'GRANT WINSTORE_DEV_ROLE TO WINSTORE_DEV';
    EXECUTE IMMEDIATE 'ALTER USER WINSTORE_DEV QUOTA UNLIMITED ON USERS';
    DBMS_OUTPUT.PUT_LINE('User WINSTORE_DEV created successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('User WINSTORE_DEV already exists');
  END IF;
END;
/

-- Create Application user
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'WINSTORE_APP';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER WINSTORE_APP IDENTIFIED BY "123App"';
    EXECUTE IMMEDIATE 'GRANT WINSTORE_APP_ROLE TO WINSTORE_APP';
    DBMS_OUTPUT.PUT_LINE('User WINSTORE_APP created successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('User WINSTORE_APP already exists');
  END IF;
END;
/

-- Create Read-only user
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'WINSTORE_READONLY';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER WINSTORE_READONLY IDENTIFIED BY "123Read"';
    EXECUTE IMMEDIATE 'GRANT WINSTORE_READONLY_ROLE TO WINSTORE_READONLY';
    DBMS_OUTPUT.PUT_LINE('User WINSTORE_READONLY created successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('User WINSTORE_READONLY already exists');
  END IF;
END;
/

-- Create Backup user
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'WINSTORE_BACKUP';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER WINSTORE_BACKUP IDENTIFIED BY "123Bkp"';
    EXECUTE IMMEDIATE 'GRANT WINSTORE_BACKUP_ROLE TO WINSTORE_BACKUP';
    DBMS_OUTPUT.PUT_LINE('User WINSTORE_BACKUP created successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('User WINSTORE_BACKUP already exists');
  END IF;
END;
/

-- Grant specific object privileges to roles
PROMPT ========== GRANTING OBJECT PRIVILEGES TO ROLES ==========

BEGIN
  -- Grant privileges on all tables to manager role
  FOR t IN (SELECT table_name FROM user_tables) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON ' || t.table_name || ' TO WINSTORE_MANAGER_ROLE';
      DBMS_OUTPUT.PUT_LINE('Granted DML privileges on ' || t.table_name || ' to WINSTORE_MANAGER_ROLE');
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error granting privileges on ' || t.table_name || ': ' || SQLERRM);
    END;
  END LOOP;
  
  -- Grant privileges on all tables to developer role
  FOR t IN (SELECT table_name FROM user_tables) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON ' || t.table_name || ' TO WINSTORE_DEV_ROLE';
      DBMS_OUTPUT.PUT_LINE('Granted DML privileges on ' || t.table_name || ' to WINSTORE_DEV_ROLE');
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error granting privileges on ' || t.table_name || ': ' || SQLERRM);
    END;
  END LOOP;
  
  -- Grant SELECT privileges on all tables to readonly role
  FOR t IN (SELECT table_name FROM user_tables) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'GRANT SELECT ON ' || t.table_name || ' TO WINSTORE_READONLY_ROLE';
      DBMS_OUTPUT.PUT_LINE('Granted SELECT on ' || t.table_name || ' to WINSTORE_READONLY_ROLE');
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error granting privileges on ' || t.table_name || ': ' || SQLERRM);
    END;
  END LOOP;
  
  -- Grant privileges on views to app role
  FOR v IN (SELECT view_name FROM user_views) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'GRANT SELECT ON ' || v.view_name || ' TO WINSTORE_APP_ROLE';
      DBMS_OUTPUT.PUT_LINE('Granted SELECT on ' || v.view_name || ' to WINSTORE_APP_ROLE');
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error granting privileges on ' || v.view_name || ': ' || SQLERRM);
    END;
  END LOOP;
  
  -- Grant execution privileges on packages to app role
  FOR p IN (SELECT object_name FROM user_objects WHERE object_type = 'PACKAGE') LOOP
    BEGIN
      EXECUTE IMMEDIATE 'GRANT EXECUTE ON ' || p.object_name || ' TO WINSTORE_APP_ROLE';
      DBMS_OUTPUT.PUT_LINE('Granted EXECUTE on ' || p.object_name || ' to WINSTORE_APP_ROLE');
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error granting privileges on ' || p.object_name || ': ' || SQLERRM);
    END;
  END LOOP;
END;
/

PROMPT ========== APPLICATION USERS CREATED AND PERMISSIONS GRANTED SUCCESSFULLY ==========