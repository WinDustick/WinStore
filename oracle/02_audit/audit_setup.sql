-- =====================================================================
-- WinStore - Audit System Configuration (Oracle Version)
-- =====================================================================
-- Description: Sets up the audit system for Oracle, creates the BusinessAuditLog
--              table, procedures, and configures Oracle Database Audit
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-09-30
-- Version:     1.0.1
-- =====================================================================
-- Dependencies: 01_schema/01_core_schema.sql
-- =====================================================================

-- =====================================================================
-- Create sequence for BusinessAuditLog
-- =====================================================================
CREATE SEQUENCE SEQ_BUSINESSAUDITLOG_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

PROMPT Audit sequence created

-- =====================================================================
-- Create BusinessAuditLog table
-- =====================================================================
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = 'BUSINESSAUDITLOG';
  
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE '
    CREATE TABLE BusinessAuditLog (
        audit_ID NUMBER PRIMARY KEY,
        user_ID NUMBER NULL,                       -- ID of WinStore user
        username NVARCHAR2(100) NULL,              -- Username (for application accounts)
        audit_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
        table_name NVARCHAR2(128) NOT NULL,        -- Table name
        operation NVARCHAR2(10) NOT NULL,          -- INSERT, UPDATE, DELETE
        record_ID NVARCHAR2(50) NOT NULL,          -- ID of the main record (for reference)
        column_name NVARCHAR2(128) NULL,           -- Changed column name (for UPDATE)
        old_value NCLOB NULL,                      -- Old value (for UPDATE, DELETE)
        new_value NCLOB NULL,                      -- New value (for INSERT, UPDATE)
        business_context NVARCHAR2(2000) NULL,     -- Business context of the operation
        application_name NVARCHAR2(128) NULL,      -- Application name
        host_name NVARCHAR2(128) NULL,             -- Host name
        ip_address NVARCHAR2(50) NULL              -- Client IP address
    )';
    
    -- Create indexes for performance
    EXECUTE IMMEDIATE '
    CREATE INDEX IX_BusinessAuditLog_Table_Op_Time 
    ON BusinessAuditLog(table_name, operation, audit_timestamp)';
    
    EXECUTE IMMEDIATE '
    CREATE INDEX IX_BusinessAuditLog_UserID 
    ON BusinessAuditLog(user_ID, audit_timestamp)';
    
    EXECUTE IMMEDIATE '
    CREATE INDEX IX_BusinessAuditLog_RecordID 
    ON BusinessAuditLog(record_ID, table_name)';
    
    -- Используем DBMS_OUTPUT.PUT_LINE внутри PL/SQL блока, так как PROMPT недоступен внутри блока
    DBMS_OUTPUT.PUT_LINE('BusinessAuditLog table created successfully.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('BusinessAuditLog table already exists.');
  END IF;
END;
/

-- =====================================================================
-- Create auto-increment trigger for BusinessAuditLog
-- =====================================================================
CREATE OR REPLACE TRIGGER TRG_BUSINESSAUDITLOG_BI
BEFORE INSERT ON BusinessAuditLog
FOR EACH ROW
BEGIN
  SELECT SEQ_BUSINESSAUDITLOG_ID.NEXTVAL INTO :NEW.audit_ID FROM DUAL;
END;
/

PROMPT Audit ID auto-increment trigger created

-- =====================================================================
-- Create stored procedure for logging business events
-- =====================================================================
CREATE OR REPLACE PROCEDURE sp_LogBusinessAuditEvent(
    p_UserID IN NUMBER DEFAULT NULL,                 -- User ID from Users table
    p_Username IN NVARCHAR2 DEFAULT NULL,            -- Username/login
    p_TableName IN NVARCHAR2,                        -- Table name
    p_Operation IN NVARCHAR2,                        -- INSERT, UPDATE, DELETE
    p_RecordID IN NVARCHAR2,                         -- Record ID
    p_ColumnName IN NVARCHAR2 DEFAULT NULL,          -- Column name (for UPDATE)
    p_OldValue IN NCLOB DEFAULT NULL,                -- Old value
    p_NewValue IN NCLOB DEFAULT NULL,                -- New value
    p_BusinessContext IN NVARCHAR2 DEFAULT NULL,     -- Business context (action description)
    p_AuditID OUT NUMBER
)
AS
    v_AppName NVARCHAR2(128);
    v_HostName NVARCHAR2(128);
    v_IPAddress NVARCHAR2(50);
BEGIN
    -- Get session information (equivalent to APP_NAME, HOST_NAME, etc.)
    SELECT SYS_CONTEXT('USERENV', 'MODULE') INTO v_AppName FROM DUAL;
    SELECT SYS_CONTEXT('USERENV', 'HOST') INTO v_HostName FROM DUAL;
    SELECT SYS_CONTEXT('USERENV', 'IP_ADDRESS') INTO v_IPAddress FROM DUAL;
    
    -- Insert audit record
    INSERT INTO BusinessAuditLog
    (
        user_ID, username, table_name, operation, 
        record_ID, column_name, old_value, new_value, 
        business_context, application_name, host_name, ip_address
    )
    VALUES
    (
        p_UserID, p_Username, p_TableName, p_Operation,
        p_RecordID, p_ColumnName, p_OldValue, p_NewValue,
        p_BusinessContext, v_AppName, v_HostName, v_IPAddress
    )
    RETURNING audit_ID INTO p_AuditID;
    
    COMMIT;
END sp_LogBusinessAuditEvent;
/

PROMPT Audit logging procedure created

-- =====================================================================
-- Configure Oracle Database Audit
-- =====================================================================
-- Check if unified auditing is available (Oracle 12c and above)
DECLARE
  v_count NUMBER;
  v_version VARCHAR2(100);
  e_policy_exists  EXCEPTION; PRAGMA EXCEPTION_INIT(e_policy_exists, -46358);
  e_policy_enabled EXCEPTION; PRAGMA EXCEPTION_INIT(e_policy_enabled, -46359);
BEGIN
  SELECT version INTO v_version FROM product_component_version 
  WHERE product LIKE 'Oracle Database%';
  
  DBMS_OUTPUT.PUT_LINE('Oracle Database version: ' || v_version);
  
  -- Create unified audit policies (Oracle 12c and above) 
  -- or use traditional audit (Oracle 11g and below)
  IF SUBSTR(v_version, 1, 2) >= '12' THEN
    -- Check if audit policy already exists
    SELECT COUNT(*) INTO v_count FROM audit_unified_policies 
    WHERE policy_name = 'WINSTORE_AUDIT_POLICY';
    
    IF v_count = 0 THEN
      BEGIN
        -- Create unified audit policy
        EXECUTE IMMEDIATE q'[
        CREATE AUDIT POLICY winstore_audit_policy
        ACTIONS 
          INSERT ON Orders,
          UPDATE ON Orders,
          DELETE ON Orders,
          SELECT ON Payments, 
          INSERT ON Payments,
          UPDATE ON Payments, 
          DELETE ON Payments,
          INSERT ON Users,
          UPDATE ON Users,
          DELETE ON Users,
          UPDATE ON Products,
          DELETE ON Products,
          CREATE TABLE, 
          ALTER TABLE,
          DROP TABLE,
          CREATE VIEW,
          DROP VIEW,
          CREATE PROCEDURE,
          ALTER PROCEDURE,
          DROP PROCEDURE,
          CREATE TRIGGER,
          ALTER TRIGGER,
          DROP TRIGGER,
          CREATE USER,
          ALTER USER,
          DROP USER,
          GRANT,
          REVOKE,
          ALTER SYSTEM,
          AUDIT]';
      EXCEPTION WHEN e_policy_exists THEN NULL; END;
    END IF;
    
    BEGIN
      EXECUTE IMMEDIATE 'AUDIT POLICY winstore_audit_policy';
    EXCEPTION WHEN e_policy_enabled THEN NULL; END;
    
    DBMS_OUTPUT.PUT_LINE('Unified Audit policy ensured (exists/enabled).');
  ELSE
    -- Use traditional audit for older Oracle versions
    -- Enable auditing for standard operations
    EXECUTE IMMEDIATE 'AUDIT INSERT, UPDATE, DELETE ON Orders BY ACCESS';
    EXECUTE IMMEDIATE 'AUDIT SELECT, INSERT, UPDATE, DELETE ON Payments BY ACCESS';
    EXECUTE IMMEDIATE 'AUDIT INSERT, UPDATE, DELETE ON Users BY ACCESS';
    EXECUTE IMMEDIATE 'AUDIT UPDATE, DELETE ON Products BY ACCESS';
    
    -- Audit DDL statements
    EXECUTE IMMEDIATE 'AUDIT TABLE, VIEW, PROCEDURE, TRIGGER BY ACCESS';
    
    -- Audit user and permission changes
    EXECUTE IMMEDIATE 'AUDIT USER, SYSTEM GRANT, ROLE BY ACCESS';
    
    DBMS_OUTPUT.PUT_LINE('Traditional Oracle Audit configured.');
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error configuring Oracle Audit: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('Continuing with application-level audit only.');
END;
/

PROMPT Oracle database audit configuration completed

-- =====================================================================
-- Create generic audit trigger template
-- =====================================================================
-- Вместо создания триггера на системную таблицу DUAL (принадлежащую SYS),
-- создаем шаблонную процедуру, которая будет использоваться как основа для триггеров
CREATE OR REPLACE PROCEDURE sp_AuditTriggerTemplate(
  p_TableName IN NVARCHAR2,
  p_OperationType IN NVARCHAR2, -- 'INSERT', 'UPDATE', 'DELETE'
  p_RecordID IN NVARCHAR2,
  p_Context IN NVARCHAR2 DEFAULT 'Table audit'
) AS
  v_user_id NUMBER;
  v_audit_id NUMBER;
BEGIN
  -- Try to get current user ID if applicable
  BEGIN
    SELECT user_ID INTO v_user_id 
    FROM Users 
    WHERE user_NAME = SYS_CONTEXT('USERENV', 'SESSION_USER');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_user_id := NULL;
  END;

  -- Log the event
  sp_LogBusinessAuditEvent(
    p_UserID => v_user_id,
    p_TableName => p_TableName,
    p_Operation => p_OperationType,
    p_RecordID => p_RecordID,
    p_BusinessContext => p_Context,
    p_AuditID => v_audit_id
  );
END;
/

PROMPT Audit trigger template procedure created

-- =====================================================================
-- Create actual audit triggers for key tables
-- =====================================================================
-- Audit trigger for Orders
CREATE OR REPLACE TRIGGER TRG_AUDIT_ORDERS
AFTER INSERT OR UPDATE OR DELETE ON Orders
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE
  v_operation NVARCHAR2(10);
  v_record_id NVARCHAR2(50);
  v_user_id NUMBER;
  v_audit_id NUMBER;
BEGIN
  -- Determine operation type
  IF INSERTING THEN
    v_operation := 'INSERT';
    v_record_id := TO_CHAR(:NEW.order_ID);
  ELSIF UPDATING THEN
    v_operation := 'UPDATE';
    v_record_id := TO_CHAR(:OLD.order_ID);
  ELSIF DELETING THEN
    v_operation := 'DELETE';
    v_record_id := TO_CHAR(:OLD.order_ID);
  END IF;
  
  -- Log the event
  sp_LogBusinessAuditEvent(
    p_UserID => NVL2(:NEW.user_ID, :NEW.user_ID, :OLD.user_ID), -- Use the order's user ID
    p_TableName => 'Orders',
    p_Operation => v_operation,
    p_RecordID => v_record_id,
    p_BusinessContext => 'Order audit',
    p_AuditID => v_audit_id
  );
  
  -- Log specific column changes for updates
  IF UPDATING THEN
    -- Log order status changes
    IF :OLD.order_STATUS_ID != :NEW.order_STATUS_ID OR 
       (:OLD.order_STATUS_ID IS NULL AND :NEW.order_STATUS_ID IS NOT NULL) OR
       (:OLD.order_STATUS_ID IS NOT NULL AND :NEW.order_STATUS_ID IS NULL) THEN
      
      sp_LogBusinessAuditEvent(
        p_UserID => :NEW.user_ID,
        p_TableName => 'Orders',
        p_Operation => 'UPDATE',
        p_RecordID => v_record_id,
        p_ColumnName => 'order_STATUS_ID',
        p_OldValue => TO_CHAR(:OLD.order_STATUS_ID),
        p_NewValue => TO_CHAR(:NEW.order_STATUS_ID),
        p_BusinessContext => 'Order status change',
        p_AuditID => v_audit_id
      );
    END IF;
    
    -- Log delivery status changes
    IF :OLD.delivery_STATUS_ID != :NEW.delivery_STATUS_ID OR 
       (:OLD.delivery_STATUS_ID IS NULL AND :NEW.delivery_STATUS_ID IS NOT NULL) OR
       (:OLD.delivery_STATUS_ID IS NOT NULL AND :NEW.delivery_STATUS_ID IS NULL) THEN
      
      sp_LogBusinessAuditEvent(
        p_UserID => :NEW.user_ID,
        p_TableName => 'Orders',
        p_Operation => 'UPDATE',
        p_RecordID => v_record_id,
        p_ColumnName => 'delivery_STATUS_ID',
        p_OldValue => TO_CHAR(:OLD.delivery_STATUS_ID),
        p_NewValue => TO_CHAR(:NEW.delivery_STATUS_ID),
        p_BusinessContext => 'Delivery status change',
        p_AuditID => v_audit_id
      );
    END IF;
  END IF;
END;
/

PROMPT Orders audit trigger created

-- Audit trigger for Payments
CREATE OR REPLACE TRIGGER TRG_AUDIT_PAYMENTS
AFTER INSERT OR UPDATE OR DELETE ON Payments
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE
  v_operation NVARCHAR2(10);
  v_record_id NVARCHAR2(50);
  v_user_id NUMBER;
  v_audit_id NUMBER;
  v_order_user_id NUMBER;
BEGIN
  -- Determine operation type
  IF INSERTING THEN
    v_operation := 'INSERT';
    v_record_id := TO_CHAR(:NEW.payment_ID);
  ELSIF UPDATING THEN
    v_operation := 'UPDATE';
    v_record_id := TO_CHAR(:OLD.payment_ID);
  ELSIF DELETING THEN
    v_operation := 'DELETE';
    v_record_id := TO_CHAR(:OLD.payment_ID);
  END IF;
  
  -- Get the user ID from the related order
  BEGIN
    SELECT user_ID INTO v_order_user_id 
    FROM Orders 
    WHERE order_ID = NVL(:NEW.order_ID, :OLD.order_ID);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_order_user_id := NULL;
  END;
  
  -- Log the event
  sp_LogBusinessAuditEvent(
    p_UserID => v_order_user_id,
    p_TableName => 'Payments',
    p_Operation => v_operation,
    p_RecordID => v_record_id,
    p_BusinessContext => 'Payment audit',
    p_AuditID => v_audit_id
  );
  
  -- Log payment status changes
  IF UPDATING THEN
    IF :OLD.payment_STATUS_ID != :NEW.payment_STATUS_ID OR 
       (:OLD.payment_STATUS_ID IS NULL AND :NEW.payment_STATUS_ID IS NOT NULL) OR
       (:OLD.payment_STATUS_ID IS NOT NULL AND :NEW.payment_STATUS_ID IS NULL) THEN
      
      sp_LogBusinessAuditEvent(
        p_UserID => v_order_user_id,
        p_TableName => 'Payments',
        p_Operation => 'UPDATE',
        p_RecordID => v_record_id,
        p_ColumnName => 'payment_STATUS_ID',
        p_OldValue => TO_CHAR(:OLD.payment_STATUS_ID),
        p_NewValue => TO_CHAR(:NEW.payment_STATUS_ID),
        p_BusinessContext => 'Payment status change',
        p_AuditID => v_audit_id
      );
    END IF;
  END IF;
END;
/

PROMPT Payments audit trigger created

-- =====================================================================
-- Create view for audit data
-- =====================================================================
CREATE OR REPLACE VIEW vw_AuditSummary AS
SELECT 
    a.audit_ID,
    a.user_ID,
    COALESCE(a.username, u.user_NAME) AS user_name,
    a.audit_timestamp,
    a.table_name,
    a.operation,
    a.record_ID,
    a.column_name,
    a.old_value,
    a.new_value,
    a.business_context,
    a.application_name,
    a.host_name,
    a.ip_address
FROM 
    BusinessAuditLog a
LEFT JOIN 
    Users u ON a.user_ID = u.user_ID;

PROMPT Audit summary view created

COMMIT;

PROMPT WinStore audit system setup complete for Oracle.
