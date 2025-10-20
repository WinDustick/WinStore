-- Import the base database schema from the existing script
-- This script creates all tables, constraints, and indexes

-- Check if database exists, if not create it
IF NOT EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = 'WinStore')
BEGIN
    -- Database creation script already exists in WinStore_CreateScript.sql
    -- We'll just execute it externally
    PRINT 'WinStore database needs to be created using WinStore_CreateScript.sql first.'
    RETURN
END
GO

USE WinStore;
GO

-- Create views for Django integration
-- View for customer orders that filters by current user
CREATE OR ALTER VIEW vw_CustomerOrders AS
SELECT 
    o.order_ID,
    o.user_ID,
    o.order_DATE,
    o.order_STATUS,
    o.order_AMOUNT
FROM 
    Orders o
WHERE 
    o.user_ID = CONVERT(INT, SESSION_CONTEXT(N'current_user_id'));
GO

-- View for customer payments that filters by current user
CREATE OR ALTER VIEW vw_CustomerPayments AS
SELECT 
    p.payment_ID,
    p.order_ID,
    p.user_ID,
    p.payment_DATE,
    p.payment_METHOD,
    p.payment_STATUS,
    p.payment_AMOUNT,
    p.currency,
    p.transaction_ID
FROM 
    Payments p
WHERE 
    p.user_ID = CONVERT(INT, SESSION_CONTEXT(N'current_user_id'));
GO

-- Create stored procedure for cart operations
CREATE OR ALTER PROCEDURE sp_AddToCart
    @UserID INT,
    @ProductID INT,
    @Quantity INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CartOrderID INT;
    DECLARE @ExistingItemID INT;
    
    -- Check if user already has a cart (order with 'Cart' status)
    SELECT @CartOrderID = order_ID 
    FROM Orders 
    WHERE user_ID = @UserID AND order_STATUS = 'Cart';
    
    -- If no cart exists, create one
    IF @CartOrderID IS NULL
    BEGIN
        INSERT INTO Orders (user_ID, order_STATUS, order_AMOUNT)
        VALUES (@UserID, 'Cart', 0);
        
        SET @CartOrderID = SCOPE_IDENTITY();
    END
    
    -- Check if product already exists in cart
    SELECT @ExistingItemID = OrderItems_ID
    FROM OrderItems
    WHERE order_ID = @CartOrderID AND product_ID = @ProductID;
    
    -- Get current product price
    DECLARE @CurrentPrice DECIMAL(10,2);
    SELECT @CurrentPrice = product_PRICE
    FROM Products
    WHERE product_ID = @ProductID;
    
    -- If product exists in cart, update quantity
    IF @ExistingItemID IS NOT NULL
    BEGIN
        UPDATE OrderItems
        SET quantity = quantity + @Quantity
        WHERE OrderItems_ID = @ExistingItemID;
    END
    ELSE
    BEGIN
        -- Add new item to cart
        INSERT INTO OrderItems (order_ID, product_ID, quantity, price)
        VALUES (@CartOrderID, @ProductID, @Quantity, @CurrentPrice);
    END
    
    -- Return the cart order ID
    SELECT @CartOrderID AS CartOrderID;
END;
GO

-- Create stored procedure for removing items from cart
CREATE OR ALTER PROCEDURE sp_RemoveFromCart
    @UserID INT,
    @OrderItemID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CartOrderID INT;
    
    -- Find user's cart
    SELECT @CartOrderID = order_ID 
    FROM Orders 
    WHERE user_ID = @UserID AND order_STATUS = 'Cart';
    
    IF @CartOrderID IS NULL
        RETURN;
    
    -- Remove the item
    DELETE FROM OrderItems
    WHERE OrderItems_ID = @OrderItemID AND order_ID = @CartOrderID;
END;
GO

-- Create stored procedure for updating cart item quantity
CREATE OR ALTER PROCEDURE sp_UpdateCartQuantity
    @UserID INT,
    @OrderItemID INT,
    @NewQuantity INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CartOrderID INT;
    
    -- Find user's cart
    SELECT @CartOrderID = order_ID 
    FROM Orders 
    WHERE user_ID = @UserID AND order_STATUS = 'Cart';
    
    IF @CartOrderID IS NULL
        RETURN;
    
    -- Update the quantity
    UPDATE OrderItems
    SET quantity = @NewQuantity
    WHERE OrderItems_ID = @OrderItemID AND order_ID = @CartOrderID;
    
    -- If quantity is 0, remove the item
    DELETE FROM OrderItems
    WHERE OrderItems_ID = @OrderItemID AND quantity <= 0;
END;
GO

-- Create stored procedure for converting cart to order
CREATE OR ALTER PROCEDURE sp_ConvertCartToOrder
    @UserID INT,
    @DeliveryAddress NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @CartOrderID INT;
        
        -- Find user's cart
        SELECT @CartOrderID = order_ID 
        FROM Orders 
        WHERE user_ID = @UserID AND order_STATUS = 'Cart';
        
        IF @CartOrderID IS NULL
            THROW 50001, 'No cart found for this user', 1;
        
        -- Update order status to Pending
        UPDATE Orders
        SET order_STATUS = 'Pending'
        WHERE order_ID = @CartOrderID;
        
        -- Generate a unique transaction ID
        DECLARE @TransactionID NVARCHAR(100) = CONVERT(NVARCHAR(100), NEWID());
        
        -- Insert payment record
        INSERT INTO Payments (
            order_ID, 
            user_ID, 
            payment_METHOD, 
            payment_STATUS, 
            payment_AMOUNT, 
            currency, 
            transaction_ID
        )
        SELECT 
            @CartOrderID,
            @UserID,
            'Pending',
            'Pending',
            order_AMOUNT,
            'USD',
            @TransactionID
        FROM Orders
        WHERE order_ID = @CartOrderID;
        
        -- Set up delivery for each order item
        INSERT INTO Delivery (
            OrderItems_ID, 
            delivery_ADDRESS, 
            delivery_STATUS, 
            delivery_NAME
        )
        SELECT 
            oi.OrderItems_ID,
            @DeliveryAddress,
            'Preparing',
            'Standard Delivery'
        FROM OrderItems oi
        WHERE oi.order_ID = @CartOrderID;
        
        COMMIT TRANSACTION;
        
        -- Return the order ID
        SELECT @CartOrderID AS OrderID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END;
GO

-- Grant permissions to the CustomerRole
GRANT EXECUTE ON dbo.sp_AddToCart TO CustomerRole;
GRANT EXECUTE ON dbo.sp_RemoveFromCart TO CustomerRole;
GRANT EXECUTE ON dbo.sp_UpdateCartQuantity TO CustomerRole;
GRANT EXECUTE ON dbo.sp_ConvertCartToOrder TO CustomerRole;
GRANT SELECT ON dbo.vw_CustomerOrders TO CustomerRole;
GRANT SELECT ON dbo.vw_CustomerPayments TO CustomerRole;
GO

PRINT 'Database setup completed successfully';
