-- =====================================================================
-- WinStore - Order Procedures
-- =====================================================================
-- Description: Creates stored procedures for order management
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
-- Table Type for Order Items
-- =====================================================================
IF TYPE_ID('dbo.OrderItemType') IS NULL
BEGIN
    CREATE TYPE dbo.OrderItemType AS TABLE
    (
        product_ID INT NOT NULL,
        quantity   INT NOT NULL CHECK (quantity > 0)
    );
    PRINT 'Table type dbo.OrderItemType created.';
END
GO

-- =====================================================================
-- Create Order Procedure
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_CreateOrder
    @UserID          INT,
    @Items           dbo.OrderItemType READONLY,
    @DeliveryAddress NVARCHAR(500),
    @OrderStatusID   INT = 1 -- Default to Cart
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Insert the order record
        INSERT INTO dbo.Orders (
            user_ID, 
            order_STATUS_ID, 
            order_AMOUNT,  -- This will be calculated and updated by the application
            delivery_ADDRESS
        )
        VALUES (
            @UserID, 
            @OrderStatusID, 
            0,  -- Initial amount set to 0, will be calculated and updated by application
            @DeliveryAddress
        );

        DECLARE @OrderID INT = SCOPE_IDENTITY();

        -- Insert order items
        INSERT INTO dbo.OrderItems (
            order_ID, 
            product_ID, 
            quantity, 
            price  -- Current price from Products table
        )
        SELECT 
            @OrderID, 
            i.product_ID, 
            i.quantity, 
            p.product_PRICE
        FROM 
            @Items AS i
        JOIN 
            dbo.Products AS p ON p.product_ID = i.product_ID;

        -- Return the created order ID
        SELECT @OrderID AS OrderID;

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
-- Update Order Status Procedure
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_UpdateOrderStatus
    @OrderID INT,
    @NewStatusID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        UPDATE dbo.Orders
        SET order_STATUS_ID = @NewStatusID
        WHERE order_ID = @OrderID;
        
        -- Note: Business logic for validation will be in the application
        -- This procedure only performs the data update
        
        COMMIT TRANSACTION;
        
        SELECT 'Order status updated successfully' AS Result;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =====================================================================
-- Order Status Transition Validation Procedures
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_ValidateOrderStatusTransition
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
        dbo.OrderStatusTransitions
    WHERE 
        from_status_ID = @FromStatusID 
        AND to_status_ID = @ToStatusID;
    
    -- If no transition found, it's not allowed
    IF @IsValid IS NULL
        SET @IsValid = 0;
END;
GO

-- =====================================================================
-- Get Available Order Status Transitions
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetAvailableOrderStatusTransitions
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
        dbo.OrderStatusTransitions t
    JOIN
        dbo.OrderStatusTypes d ON t.to_status_ID = d.status_ID
    WHERE 
        t.from_status_ID = @CurrentStatusID
        AND t.is_allowed = 1
    ORDER BY 
        d.display_ORDER;
END;
GO

-- =====================================================================
-- Generate Order Invoice
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_GenerateOrderInvoice
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Order header information
    SELECT
        o.order_ID,
        o.order_DATE,
        o.order_AMOUNT,
        o.promo_SAVINGS,
        (o.order_AMOUNT - ISNULL(o.promo_SAVINGS, 0)) AS total_amount,
        os.status_NAME_RU AS order_status,
        u.user_ID,
        u.user_NAME,
        u.user_EMAIL,
        u.user_PHONE,
        o.delivery_ADDRESS
    FROM
        dbo.Orders o
    JOIN
        dbo.Users u ON o.user_ID = u.user_ID
    LEFT JOIN
        dbo.OrderStatusTypes os ON o.order_STATUS_ID = os.status_ID
    WHERE
        o.order_ID = @OrderID;
    
    -- Order items
    SELECT
        oi.OrderItems_ID,
        oi.product_ID,
        p.product_NAME,
        oi.quantity,
        oi.price,
        (oi.quantity * oi.price) AS line_total
    FROM
        dbo.OrderItems oi
    JOIN
        dbo.Products p ON oi.product_ID = p.product_ID
    WHERE
        oi.order_ID = @OrderID;
    
    -- Payment information
    SELECT
        p.payment_ID,
        p.payment_DATE,
        p.payment_METHOD,
        ps.status_NAME_RU AS payment_status,
        p.payment_AMOUNT,
        p.currency,
        p.transaction_ID
    FROM
        dbo.Payments p
    LEFT JOIN
        dbo.PaymentStatusTypes ps ON p.payment_STATUS_ID = ps.status_ID
    WHERE
        p.order_ID = @OrderID;
END;
GO

PRINT 'Order procedures created successfully.';
GO
