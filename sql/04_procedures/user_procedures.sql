-- =====================================================================
-- WinStore - Optimized User Procedures (v1.1.0)
-- =====================================================================
USE WinStore;
GO

-- =====================================================================
-- Common Settings for All Procedures
--   - NOCOUNT and XACT_ABORT for predictable error/transaction behavior
-- =====================================================================
-- Apply at top of each proc:  SET NOCOUNT ON;
--                         SET XACT_ABORT ON;

-- =====================================================================
-- 1. Add to Wishlist Procedure
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_AddToWishlist
    @UserID    INT,
    @ProductID INT,
    @Notes     NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Declare variables
    DECLARE @WishlistID INT;
    DECLARE @AuditWishlistID NVARCHAR(50);

    -- Validate inputs
    IF @UserID IS NULL
       OR NOT EXISTS (SELECT 1 FROM dbo.Users WHERE user_ID = @UserID)
        THROW 50010, 'Invalid or non-existent user ID', 1;

    IF @ProductID IS NULL
       OR NOT EXISTS (SELECT 1 FROM dbo.Products WHERE product_ID = @ProductID)
        THROW 50020, 'Invalid or non-existent product ID', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (
            SELECT 1 FROM dbo.Wishlist
            WHERE user_ID = @UserID AND product_ID = @ProductID
        )
        BEGIN
            UPDATE dbo.Wishlist
            SET notes     = @Notes,
                added_AT  = GETDATE()
            WHERE user_ID    = @UserID
              AND product_ID = @ProductID;

            -- First get the wishlist ID
            SELECT @WishlistID = wishlist_ID
            FROM dbo.Wishlist
            WHERE user_ID = @UserID AND product_ID = @ProductID;

            -- Then return result separately
            SELECT 'Item notes updated in wishlist.' AS Result, @WishlistID AS WishlistID;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.Wishlist (user_ID, product_ID, notes)
            VALUES (@UserID, @ProductID, @Notes);

            SET @WishlistID = SCOPE_IDENTITY();

            SELECT 'Item added to wishlist.' AS Result, @WishlistID AS WishlistID;
        END;

        -- Audit
        SET @AuditWishlistID = CAST(@WishlistID AS NVARCHAR(50));

        EXEC dbo.sp_LogBusinessAuditEvent
            @UserID         = @UserID,
            @TableName      = 'Wishlist',
            @Operation      = 'UPSERT',
            @RecordID       = @AuditWishlistID,
            @BusinessContext= 'User wishlist management';

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- =====================================================================
-- 2. Get Wishlist Procedure
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetWishlist
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @UserID IS NULL
       OR NOT EXISTS (SELECT 1 FROM dbo.Users WHERE user_ID = @UserID)
        THROW 50010, 'Invalid or non-existent user ID', 1;

    SELECT
        w.wishlist_ID,
        w.product_ID,
        p.product_NAME,
        p.product_PRICE,
        pm.media_URL    AS primary_image,
        w.added_AT,
        w.notes
    FROM dbo.Wishlist AS w
    INNER JOIN dbo.Products AS p
        ON w.product_ID = p.product_ID
    LEFT JOIN dbo.ProductMedia AS pm
        ON p.product_ID = pm.product_ID
       AND pm.is_primary = 1
    WHERE w.user_ID = @UserID
    ORDER BY w.added_AT DESC;
END;
GO

-- =====================================================================
-- 3. Get User Orders Procedure
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetUserOrders
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @UserID IS NULL
       OR NOT EXISTS (SELECT 1 FROM dbo.Users WHERE user_ID = @UserID)
        THROW 50011, 'Invalid or non-existent user ID', 1;

    SELECT
        o.order_ID,
        o.order_DATE,
        os.status_NAME_RU AS order_status,
        o.order_AMOUNT,
        o.promo_SAVINGS,
        o.order_AMOUNT - ISNULL(o.promo_SAVINGS, 0) AS total_amount,
        o.delivery_ADDRESS,
        o.shipped_DATE,
        o.estimated_delivery_DATE,
        o.actual_delivery_DATE,
        ds.status_NAME_RU AS delivery_status,
        o.shipping_carrier_NAME,
        o.tracking_NUMBER,
        (SELECT COUNT(*)
         FROM dbo.OrderItems
         WHERE order_ID = o.order_ID)   AS item_count
    FROM dbo.Orders AS o
    LEFT JOIN dbo.OrderStatusTypes AS os
        ON o.order_STATUS_ID = os.status_ID
    LEFT JOIN dbo.DeliveryStatusTypes AS ds
        ON o.delivery_STATUS_ID = ds.status_ID
    WHERE o.user_ID = @UserID
    ORDER BY o.order_DATE DESC;
END;
GO

-- =====================================================================
-- 4. Add or Update Product Review Procedure
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_AddProductReview
    @UserID    INT,
    @ProductID INT,
    @Rating    INT,
    @Comment   NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @UserID IS NULL
       OR NOT EXISTS (SELECT 1 FROM dbo.Users WHERE user_ID = @UserID)
        THROW 50010, 'Invalid or non-existent user ID', 1;

    IF @ProductID IS NULL
       OR NOT EXISTS (SELECT 1 FROM dbo.Products WHERE product_ID = @ProductID)
        THROW 50020, 'Invalid or non-existent product ID', 1;

    IF @Rating IS NULL
       OR @Rating < 1 OR @Rating > 5
        THROW 50030, 'Rating must be between 1 and 5', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (
            SELECT 1 FROM dbo.Review
            WHERE user_ID = @UserID AND product_ID = @ProductID
        )
        BEGIN
            UPDATE dbo.Review
            SET
                rew_RATING  = @Rating,
                rew_COMMENT = @Comment,
                rew_DATE    = GETDATE()
            WHERE
                user_ID    = @UserID
                AND product_ID = @ProductID;

            SELECT 'Review updated successfully' AS Result;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.Review
                (user_ID, product_ID, rew_RATING, rew_COMMENT, rew_DATE)
            VALUES
                (@UserID, @ProductID, @Rating, @Comment, GETDATE());

            SELECT 'Review added successfully' AS Result;
        END;

        -- Audit
        DECLARE @AuditReviewID NVARCHAR(50) =
            CAST((SELECT TOP 1 rew_ID
                  FROM dbo.Review
                  WHERE user_ID = @UserID AND product_ID = @ProductID)
                 AS NVARCHAR(50));

        EXEC dbo.sp_LogBusinessAuditEvent
            @UserID          = @UserID,
            @TableName       = 'Review',
            @Operation       = 'UPSERT',
            @RecordID        = @AuditReviewID,
            @BusinessContext = 'Product review management';

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- =====================================================================
-- 5. Create User Procedure (with secure password hashing)
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_CreateUser
    @UserName  NVARCHAR(50),
    @UserPass  NVARCHAR(255),
    @UserEmail NVARCHAR(100),
    @UserPhone NVARCHAR(20),
    @UserRole  NVARCHAR(50)  = 'Customer'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF LEN(TRY_CAST(@UserName AS NVARCHAR(50))) = 0
        THROW 50001, 'User name cannot be empty', 1;

    IF LEN(@UserPass) < 8
        THROW 50002, 'Password must be at least 8 characters long', 1;

    IF @UserEmail NOT LIKE '%@%.%'
        THROW 50003, 'Invalid email format', 1;

    IF LEN(TRY_CAST(@UserPhone AS NVARCHAR(20))) = 0
        THROW 50004, 'Phone number cannot be null or empty', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM dbo.Users WHERE user_EMAIL = @UserEmail)
            THROW 50000, 'User with this email already exists', 1;

        INSERT INTO dbo.Users
            (user_NAME, user_PASS_HASH, user_EMAIL, user_PHONE, user_ROLE, created_AT)
        VALUES
            (@UserName,
             HASHBYTES('SHA2_256', @UserPass),
             @UserEmail,
             @UserPhone,
             @UserRole,
             GETDATE());

        DECLARE @NewUserID INT = SCOPE_IDENTITY();
        DECLARE @NewUserIDStr NVARCHAR(50) = CAST(@NewUserID AS NVARCHAR(50));

        COMMIT TRANSACTION;

        EXEC dbo.sp_LogBusinessAuditEvent
            @UserID = NULL,
            @UserName = 'SYSTEM',
            @TableName = 'Users',
            @Operation = 'INSERT',
            @RecordID = @NewUserIDStr,
            @BusinessContext = 'User registration';

        SELECT @NewUserID AS UserID, 'User created successfully' AS Result;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- =====================================================================
-- 6. Update User Last Login Procedure
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_UpdateUserLastLogin
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @UserID IS NULL
       OR NOT EXISTS (SELECT 1 FROM dbo.Users WHERE user_ID = @UserID)
        THROW 50010, 'Invalid or non-existent user ID', 1;

    BEGIN TRY
        UPDATE dbo.Users
        SET last_login = GETDATE()
        WHERE user_ID = @UserID;

        IF @@ROWCOUNT = 0
            THROW 50012, 'Failed to update last login', 1;

        -- Declare variables for the conversions
        DECLARE @RecordIDStr NVARCHAR(50) = CAST(@UserID AS NVARCHAR(50));
        DECLARE @NewValueStr NVARCHAR(50) = CONVERT(NVARCHAR(50), GETDATE(), 120);

        EXEC dbo.sp_LogBusinessAuditEvent
            @UserID = @UserID,
            @TableName = 'Users',
            @Operation = 'UPDATE',
            @RecordID = @RecordIDStr,
            @ColumnName = 'last_login',
            @NewValue = @NewValueStr,
            @BusinessContext = 'User login';

        SELECT 'Last login updated successfully' AS Result;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

PRINT 'Optimized user procedures created successfully.';
