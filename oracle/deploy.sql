-- =====================================================================
-- WinStore - Oracle Deployment Master Script
-- =====================================================================
-- Description: Master script that executes all Oracle SQL scripts in the correct order
--              to deploy the WinStore database.
-- Author:      WinStore Development Team
-- Created:     2025-09-28
-- Modified:    2025-09-28
-- Version:     1.0.0
-- =====================================================================

WHENEVER SQLERROR EXIT FAILURE;

-- Logging: timestamped spool captures full output. Console remains quiet; errors still appear.
COLUMN LOG_TS NEW_VALUE LOG_TS NOPRINT;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') AS LOG_TS FROM dual;
SPOOL /home/windustick/MyDB/WinStore/oracle/logs/oracle_deploy_&LOG_TS.log

-- Quiet console; keep rich output in the spool log
SET TERMOUT ON
SET ECHO ON
SET FEEDBACK ON
SET HEADING ON
SET PAGESIZE 50000
SET LINESIZE 200
SET LONG 1000000
SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT WRAPPED

-- Create admin user for WinStore database
WHENEVER SQLERROR EXIT SQL.SQLCODE;

PROMPT ========== CREATING WINSTORE ADMIN USER ==========

-- Check if user exists before creating
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'WINSTORE_ADMIN';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER WINSTORE_ADMIN IDENTIFIED BY 123 DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP';
    EXECUTE IMMEDIATE 'GRANT DBA TO WINSTORE_ADMIN WITH ADMIN OPTION';
    EXECUTE IMMEDIATE 'ALTER USER WINSTORE_ADMIN QUOTA UNLIMITED ON USERS';
    DBMS_OUTPUT.PUT_LINE('User WINSTORE_ADMIN created successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('User WINSTORE_ADMIN already exists');
  END IF;
END;
/

-- Connect as WINSTORE_ADMIN for all further operations
CONNECT WINSTORE_ADMIN/123@PDB1

-- Start deployment
PROMPT ========== STARTING WINSTORE ORACLE DATABASE DEPLOYMENT ==========

-- Schema creation
PROMPT ========== EXECUTING 01_core_schema.sql ==========
@@01_schema/01_core_schema.sql

PROMPT ========== EXECUTING 02_reference_data.sql ==========
@@01_schema/02_reference_data.sql

PROMPT ========== EXECUTING 03_status_transitions.sql ==========
@@01_schema/03_status_transitions.sql

PROMPT ========== EXECUTING 04_indexes.sql ==========
@@01_schema/04_indexes.sql

PROMPT ========== EXECUTING 05_users.sql ==========
@@01_schema/05_users.sql

-- Audit system setup
PROMPT ========== EXECUTING audit_setup.sql ==========
@@02_audit/audit_setup.sql

-- Views creation
PROMPT ========== EXECUTING product_views.sql ==========
@@03_views/product_views.sql

PROMPT ========== EXECUTING system_views.sql ==========
@@03_views/system_views.sql

-- Procedures creation
PROMPT ========== EXECUTING product_procedures.sql ==========
@@04_procedures/product_procedures.sql

PROMPT ========== EXECUTING user_procedures.sql ==========
@@04_procedures/user_procedures.sql

PROMPT ========== EXECUTING order_procedures.sql ==========
@@04_procedures/order_procedures.sql

PROMPT ========== EXECUTING payment_procedures.sql ==========
@@04_procedures/payment_procedures.sql

-- Triggers creation
PROMPT ========== EXECUTING triggers.sql ==========
@@05_triggers/triggers.sql

-- Deployment completed successfully
PROMPT ========== WINSTORE ORACLE DATABASE DEPLOYED SUCCESSFULLY ==========

-- Close log file
SPOOL OFF

