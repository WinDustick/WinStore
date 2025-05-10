-- =====================================================================
-- WinStore - Payment Procedures
-- =====================================================================
-- Description: Creates stored procedures for payment processing 
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
-- Create Payment Procedure
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_CreatePayment
    @OrderID INT,
    @PaymentMethod NVARCHAR(50),
    @PaymentAmount DECIMAL(10, 2),
    @Currency NCHAR(3),
    @TransactionID NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        INSERT INTO dbo.Payments (
            order_ID,
            payment_DATE,
            payment_METHOD,
            payment_STATUS_ID,  -- Default to Pending (1)
            payment_AMOUNT,
            currency,
            transaction_ID
        )
        VALUES (
            @OrderID,
            GETDATE(),
            @PaymentMethod,
            1,  -- Pending status
            @PaymentAmount,
            @Currency,
            @TransactionID
        );
        
        DECLARE @PaymentID INT = SCOPE_IDENTITY();
        
        -- Return the new payment ID
        SELECT @PaymentID AS PaymentID;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =====================================================================
-- Update Payment Status Procedure
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_UpdatePaymentStatus
    @PaymentID INT,
    @NewStatusID INT,
    @TransactionID NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        UPDATE dbo.Payments
        SET 
            payment_STATUS_ID = @NewStatusID,
            transaction_ID = ISNULL(@TransactionID, transaction_ID),
            updated_at = GETDATE()
        WHERE 
            payment_ID = @PaymentID;
        
        -- Note: Business logic for validation and order status updates 
        -- will be handled in the application
        
        COMMIT TRANSACTION;
        
        SELECT 'Payment status updated successfully' AS Result;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =====================================================================
-- Payment Status Transition Validation Procedure
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_ValidatePaymentStatusTransition
    @FromStatusID INT,
    @ToStatusID INT,
    @IsValid BIT OUTPUT,
    @TransitionName NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        @IsValid = is_allowed,
        @TransitionName = transition_name
    FROM 
        dbo.PaymentStatusTransitions
    WHERE 
        from_status_ID = @FromStatusID 
        AND to_status_ID = @ToStatusID;
    
    -- If no transition found, it's not allowed
    IF @IsValid IS NULL
        SET @IsValid = 0;
END;
GO

-- =====================================================================
-- Get Available Payment Status Transitions
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetAvailablePaymentStatusTransitions
    @CurrentStatusID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.to_status_ID,
        d.status_KEY,
        d.status_NAME_RU,
        d.status_NAME_EN,
        t.transition_name
    FROM 
        dbo.PaymentStatusTransitions t
    JOIN
        dbo.PaymentStatusTypes d ON t.to_status_ID = d.status_ID
    WHERE 
        t.from_status_ID = @CurrentStatusID
        AND t.is_allowed = 1
    ORDER BY 
        d.display_ORDER;
END;
GO

PRINT 'Payment procedures created successfully.';
GO
