-- =====================================================================
-- WinStore - Database Triggers
-- =====================================================================
-- Description: Creates database triggers for automatic timestamp updates
--              and other simple operations that don't involve complex
--              business logic.
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-05-25
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: 01_schema/01_core_schema.sql
-- =====================================================================

USE WinStore
GO

-- =====================================================================
-- Timestamp Update Triggers
-- =====================================================================

-- Trigger for updating Products.updated_AT
CREATE OR ALTER TRIGGER TR_Products_UpdateTimestamp
ON dbo.Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(updated_AT) RETURN; -- Avoid recursive calls
    
    UPDATE p
    SET updated_AT = GETDATE()
    FROM dbo.Products p
    INNER JOIN inserted i ON p.product_ID = i.product_ID;
END;
GO

-- Trigger for updating Payments.updated_at
CREATE OR ALTER TRIGGER TR_Payments_UpdateTimestamp
ON dbo.Payments
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(updated_at) RETURN; -- Avoid recursive calls
    
    UPDATE pa
    SET updated_at = GETDATE()
    FROM dbo.Payments pa
    INNER JOIN inserted i ON pa.payment_ID = i.payment_ID;
END;
GO

PRINT 'Database triggers created successfully.';
GO
