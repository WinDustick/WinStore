-- =====================================================================
-- WinStore - Audit System Configuration
-- =====================================================================
-- Description: Sets up the audit system, creates the BusinessAuditLog
--              table, procedures, and configures SQL Server Audit
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-05-25
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: 01_schema/01_core_schema.sql
-- =====================================================================

USE WinStore;
GO

-- =====================================================================
-- Check SQL Server version for Audit support
-- =====================================================================
DECLARE @SQLVersion NVARCHAR(128) = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128))
DECLARE @MajorVersion INT = CAST(SUBSTRING(@SQLVersion, 1, CHARINDEX('.', @SQLVersion) - 1) AS INT)
DECLARE @EditionName NVARCHAR(128) = CAST(SERVERPROPERTY('Edition') AS NVARCHAR(128))

IF @MajorVersion < 10 OR @EditionName LIKE '%Express%'
BEGIN
    PRINT 'WARNING: Current SQL Server version or edition has limited or no support for Server Audit.'
    PRINT 'Version: ' + @SQLVersion + ' / Edition: ' + @EditionName
    PRINT 'Consider using an alternative approach with triggers.'
    
    -- Continue with BusinessAuditLog table which works in all editions
END

-- =====================================================================
-- Create BusinessAuditLog table
-- =====================================================================
IF OBJECT_ID('dbo.BusinessAuditLog', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.BusinessAuditLog (
        audit_ID BIGINT IDENTITY(1,1) PRIMARY KEY,
        user_ID INT NULL,                       -- ID of WinStore user
        username NVARCHAR(100) NULL,            -- Username (for application accounts)
        audit_timestamp DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        table_name NVARCHAR(128) NOT NULL,      -- Table name
        operation NVARCHAR(10) NOT NULL,        -- INSERT, UPDATE, DELETE
        record_ID NVARCHAR(50) NOT NULL,        -- ID of the main record (for reference)
        column_name NVARCHAR(128) NULL,         -- Changed column name (for UPDATE)
        old_value NVARCHAR(MAX) NULL,           -- Old value (for UPDATE, DELETE)
        new_value NVARCHAR(MAX) NULL,           -- New value (for INSERT, UPDATE)
        business_context NVARCHAR(4000) NULL,   -- Business context of the operation
        application_name NVARCHAR(128) NULL,    -- Application name
        host_name NVARCHAR(128) NULL,           -- Host name
        ip_address NVARCHAR(50) NULL            -- Client IP address
    );
    
    -- Create indexes for performance
    CREATE NONCLUSTERED INDEX IX_BusinessAuditLog_Table_Op_Time 
    ON dbo.BusinessAuditLog(table_name, operation, audit_timestamp);
    
    CREATE NONCLUSTERED INDEX IX_BusinessAuditLog_UserID 
    ON dbo.BusinessAuditLog(user_ID, audit_timestamp);
    
    CREATE NONCLUSTERED INDEX IX_BusinessAuditLog_RecordID 
    ON dbo.BusinessAuditLog(record_ID, table_name);
    
    PRINT 'BusinessAuditLog table created successfully.';
END
ELSE
    PRINT 'BusinessAuditLog table already exists.';
GO

-- =====================================================================
-- Create stored procedure for logging business events
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_LogBusinessAuditEvent
    @UserID INT = NULL,                    -- User ID from Users table
    @Username NVARCHAR(100) = NULL,        -- Username/login
    @TableName NVARCHAR(128),              -- Table name
    @Operation NVARCHAR(10),               -- INSERT, UPDATE, DELETE
    @RecordID NVARCHAR(50),                -- Record ID
    @ColumnName NVARCHAR(128) = NULL,      -- Column name (for UPDATE)
    @OldValue NVARCHAR(MAX) = NULL,        -- Old value
    @NewValue NVARCHAR(MAX) = NULL,        -- New value
    @BusinessContext NVARCHAR(4000) = NULL -- Business context (action description)
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.BusinessAuditLog
    (
        user_ID, username, table_name, operation, 
        record_ID, column_name, old_value, new_value, 
        business_context, application_name, host_name, ip_address
    )
    VALUES
    (
        @UserID, @Username, @TableName, @Operation,
        @RecordID, @ColumnName, @OldValue, @NewValue,
        @BusinessContext, APP_NAME(), HOST_NAME(), 
        CAST(CONNECTIONPROPERTY('client_net_address') AS NVARCHAR(50))
    );
    
    RETURN SCOPE_IDENTITY();
END
GO

-- =====================================================================
-- Configure SQL Server Audit (if version supports it)
-- =====================================================================
IF @MajorVersion >= 10 AND @EditionName NOT LIKE '%Express%'
BEGIN
    -- Clean up existing audit objects if they exist
    IF EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = 'WinStoreServerAudit')
    BEGIN
        ALTER SERVER AUDIT SPECIFICATION WinStoreServerAudit WITH (STATE = OFF);
        DROP SERVER AUDIT SPECIFICATION WinStoreServerAudit;
        PRINT 'Existing server audit specification removed.';
    END

    IF EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = 'WinStoreDatabaseAudit')
    BEGIN
        ALTER DATABASE AUDIT SPECIFICATION WinStoreDatabaseAudit WITH (STATE = OFF);
        DROP DATABASE AUDIT SPECIFICATION WinStoreDatabaseAudit;
        PRINT 'Existing database audit specification removed.';
    END

    IF EXISTS (SELECT 1 FROM sys.server_audits WHERE name = 'WinStoreAudit')
    BEGIN
        ALTER SERVER AUDIT WinStoreAudit WITH (STATE = OFF);
        DROP SERVER AUDIT WinStoreAudit;
        PRINT 'Existing server audit removed.';
    END

    -- Create server audit
    CREATE SERVER AUDIT WinStoreAudit
    TO FILE 
    (
        FILEPATH = '/var/opt/mssql/data/audit',
        MAXSIZE = 100MB,
        MAX_FILES = 20,
        RESERVE_DISK_SPACE = OFF
    )
    WITH 
    (
        QUEUE_DELAY = 1000,      -- Millisecond delay for event batching (performance)
        ON_FAILURE = CONTINUE    -- Continue operation if audit fails
    );

    -- Enable the audit
    ALTER SERVER AUDIT WinStoreAudit WITH (STATE = ON);

    -- Create database audit specification
    CREATE DATABASE AUDIT SPECIFICATION WinStoreDatabaseAudit
    FOR SERVER AUDIT WinStoreAudit
    ADD (INSERT, UPDATE, DELETE ON dbo.Orders BY public),
    ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.Payments BY public),
    ADD (INSERT, UPDATE, DELETE ON dbo.Users BY public),
    ADD (UPDATE, DELETE ON dbo.Products BY public),
    ADD (DATABASE_OBJECT_CHANGE_GROUP),         -- DDL changes
    ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),      -- DB user changes
    ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),-- Object permission changes
    ADD (DATABASE_PERMISSION_CHANGE_GROUP),     -- Database permission changes
    ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),    -- Role membership changes
    ADD (APPLICATION_ROLE_CHANGE_PASSWORD_GROUP)-- Application role password changes
    WITH (STATE = ON);

    PRINT 'SQL Server Audit successfully configured.';
END
ELSE
    PRINT 'SQL Server Audit configuration skipped due to version/edition limitations.';
GO

-- =====================================================================
-- Create view for audit data
-- =====================================================================
CREATE OR ALTER VIEW dbo.vw_AuditSummary AS
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
    dbo.BusinessAuditLog a
LEFT JOIN 
    dbo.Users u ON a.user_ID = u.user_ID;
GO

PRINT 'WinStore audit system setup complete.';
GO
