-- =====================================================================
-- WinStore - Master Deployment Script
-- =====================================================================
-- Description: Executes all SQL scripts in the correct order to deploy
--              the complete WinStore database from scratch
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-05-25
-- Version:     1.0.0
-- =====================================================================
-- NOTE: THIS SCRIPT MUST BE RUN IN SQLCMD MODE!
-- In SSMS: Query -> SQLCMD Mode
-- In VS Code SQL Tools: Connect with "Enable SQLCMD" option
-- Command-line: sqlcmd -S server -U user -P password -i deploy.sql
-- =====================================================================

:SETVAR SCRIPTS_DIR "/home/windustick/MyDB/WinStore/sql"

PRINT '===============================================';
PRINT 'WinStore Database Deployment - Start';
PRINT 'Started at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '===============================================';

-- Variable to track errors
DECLARE @Error INT = 0;
DECLARE @ErrorMessage NVARCHAR(4000);

BEGIN TRY
    -- =====================================================================
    -- 01_schema - Database structure
    -- =====================================================================
    PRINT 'Executing: 01_schema/01_core_schema.sql';
    :r $(SCRIPTS_DIR)/01_schema/01_core_schema.sql
    PRINT 'Completed: 01_schema/01_core_schema.sql';
    
    PRINT 'Executing: 01_schema/02_reference_data.sql';
    :r $(SCRIPTS_DIR)/01_schema/02_reference_data.sql
    PRINT 'Completed: 01_schema/02_reference_data.sql';
    
    PRINT 'Executing: 01_schema/03_status_transitions.sql';
    :r $(SCRIPTS_DIR)/01_schema/03_status_transitions.sql
    PRINT 'Completed: 01_schema/03_status_transitions.sql';
    
    PRINT 'Executing: 01_schema/04_indexes.sql';
    :r $(SCRIPTS_DIR)/01_schema/04_indexes.sql
    PRINT 'Completed: 01_schema/04_indexes.sql';
    
    -- =====================================================================
    -- 02_audit - Audit configuration
    -- =====================================================================
    PRINT 'Executing: 02_audit/audit_setup.sql';
    :r $(SCRIPTS_DIR)/02_audit/audit_setup.sql
    PRINT 'Completed: 02_audit/audit_setup.sql';
    
    -- =====================================================================
    -- 03_views - Database views
    -- =====================================================================
    PRINT 'Executing: 03_views/product_views.sql';
    :r $(SCRIPTS_DIR)/03_views/product_views.sql
    PRINT 'Completed: 03_views/product_views.sql';
    
    PRINT 'Executing: 03_views/system_views.sql';
    :r $(SCRIPTS_DIR)/03_views/system_views.sql
    PRINT 'Completed: 03_views/system_views.sql';
    
    -- =====================================================================
    -- 04_procedures - Stored procedures
    -- =====================================================================
    PRINT 'Executing: 04_procedures/product_procedures.sql';
    :r $(SCRIPTS_DIR)/04_procedures/product_procedures.sql
    PRINT 'Completed: 04_procedures/product_procedures.sql';
    
    PRINT 'Executing: 04_procedures/order_procedures.sql';
    :r $(SCRIPTS_DIR)/04_procedures/order_procedures.sql
    PRINT 'Completed: 04_procedures/order_procedures.sql';
    
    PRINT 'Executing: 04_procedures/payment_procedures.sql';
    :r $(SCRIPTS_DIR)/04_procedures/payment_procedures.sql
    PRINT 'Completed: 04_procedures/payment_procedures.sql';
    
    PRINT 'Executing: 04_procedures/user_procedures.sql';
    :r $(SCRIPTS_DIR)/04_procedures/user_procedures.sql
    PRINT 'Completed: 04_procedures/user_procedures.sql';
    
    -- =====================================================================
    -- 05_triggers - Database triggers
    -- =====================================================================
    PRINT 'Executing: 05_triggers/triggers.sql';
    :r $(SCRIPTS_DIR)/05_triggers/triggers.sql
    PRINT 'Completed: 05_triggers/triggers.sql';
    
    PRINT '===============================================';
    PRINT 'WinStore Database Deployment - Successful';
    PRINT 'Completed at: ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT '===============================================';
END TRY
BEGIN CATCH
    SELECT @ErrorMessage = ERROR_MESSAGE();
    PRINT '===============================================';
    PRINT 'WinStore Database Deployment - FAILED';
    PRINT 'Error: ' + @ErrorMessage;
    PRINT 'Completed with errors at: ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT '===============================================';
    SET @Error = ERROR_NUMBER();
END CATCH

-- Return error code for calling scripts
RETURN @Error;
GO
