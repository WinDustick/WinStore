-- =====================================================================
-- WinStore - Product Procedures
-- =====================================================================
-- Description: Creates stored procedures for product management and
--              related operations
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
-- Table Type for Product Attributes
-- =====================================================================
IF TYPE_ID('dbo.ProductAttributeType') IS NULL
BEGIN
    CREATE TYPE dbo.ProductAttributeType AS TABLE (
        att_NAME            NVARCHAR(255) NOT NULL PRIMARY KEY,
        nominal             NVARCHAR(MAX) NULL,
        unit_of_measurement NVARCHAR(100) NULL
    );
    PRINT N'Table type dbo.ProductAttributeType created.';
END
ELSE
BEGIN
    PRINT N'Table type dbo.ProductAttributeType already exists.';
END
GO

-- =====================================================================
-- Stored Procedure for inserting product with attributes
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_InsertProductWithAttributes
    @CategoryID INT,
    @VendorID INT,
    @ProductName NVARCHAR(255),
    @ProductDesc NVARCHAR(MAX),
    @ProductPrice DECIMAL(10,2) = 0.0,
    @ProductStock INT = 20,
    @Attributes dbo.ProductAttributeType READONLY
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @InsertedProductID INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.Products (category_ID, product_NAME, product_DESCRIPT, product_PRICE, product_STOCK, ven_ID)
        VALUES (@CategoryID, @ProductName, @ProductDesc, @ProductPrice, @ProductStock, @VendorID);
        SET @InsertedProductID = SCOPE_IDENTITY();

        IF @InsertedProductID IS NULL
        BEGIN
            RAISERROR(N'Failed to get inserted product ID.', 16, 1);
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM @Attributes)
        BEGIN
            INSERT INTO dbo.ProductAttributes (att_ID, product_ID, nominal, unit_of_measurement)
            SELECT
                a.att_ID,
                @InsertedProductID,
                tvp.nominal,
                tvp.unit_of_measurement
            FROM @Attributes AS tvp
            INNER JOIN dbo.Attributes AS a ON tvp.att_NAME = a.att_NAME
            WHERE a.att_ID IS NOT NULL;

            DECLARE @tvpCount INT = (SELECT COUNT(*) FROM @Attributes);
            DECLARE @insertedAttrCount INT = (SELECT COUNT(*) FROM dbo.ProductAttributes WHERE product_ID = @InsertedProductID);
            IF @tvpCount <> @insertedAttrCount
            BEGIN
                 PRINT N'Warning: Not all attributes for product ID ' + CAST(@InsertedProductID AS NVARCHAR(10)) + N' were found in Attributes table. Inserted ' + CAST(@insertedAttrCount AS NVARCHAR(10)) + N' of ' + CAST(@tvpCount AS NVARCHAR(10));
            END;
        END;
        COMMIT TRANSACTION;
        PRINT N'Product "' + @ProductName + N'" (ID: ' + CAST(@InsertedProductID AS NVARCHAR(10)) + N') and its attributes successfully added.';
        SELECT @InsertedProductID AS InsertedProductID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT N'Error inserting product "' + @ProductName + N'". Transaction rolled back.';
        THROW; -- Re-throw the error to be caught by the caller
    END CATCH
END;
GO

-- =====================================================================
-- Stored Procedure for adding product media
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_AddProductMedia
    @ProductID INT,
    @MediaURL NVARCHAR(1000),
    @MediaType NVARCHAR(50) = 'image',
    @IsPrimary BIT = 0,
    @DisplayOrder INT = 0,
    @AltText NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @IsPrimary = 1
        BEGIN
            UPDATE dbo.ProductMedia
            SET is_primary = 0
            WHERE product_ID = @ProductID AND is_primary = 1 AND media_URL <> @MediaURL; -- only reset others if new primary is different
        END

        INSERT INTO dbo.ProductMedia (product_ID, media_URL, media_TYPE, is_primary, display_order, alt_text)
        VALUES (@ProductID, @MediaURL, @MediaType, @IsPrimary, @DisplayOrder, @AltText);
        COMMIT TRANSACTION;
        SELECT SCOPE_IDENTITY() AS MediaID, 'Media added successfully.' AS Result;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =====================================================================
-- Procedure for retrieving product information
-- =====================================================================
CREATE OR ALTER PROCEDURE dbo.sp_GetProductDetails
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Get main product information
    SELECT 
        p.product_ID,
        p.product_NAME,
        p.product_DESCRIPT,
        p.product_PRICE,
        p.product_STOCK,
        p.created_AT,
        p.updated_AT,
        p.is_featured,
        p.is_active,
        c.category_ID,
        c.category_NAME,
        v.ven_ID,
        v.ven_NAME AS vendor_name
    FROM 
        dbo.Products p
    JOIN 
        dbo.Categories c ON p.category_ID = c.category_ID
    JOIN 
        dbo.Vendors v ON p.ven_ID = v.ven_ID
    WHERE 
        p.product_ID = @ProductID;

    -- Get product attributes
    SELECT 
        a.att_ID,
        a.att_NAME,
        pa.nominal,
        pa.unit_of_measurement
    FROM 
        dbo.ProductAttributes pa
    JOIN 
        dbo.Attributes a ON pa.att_ID = a.att_ID
    WHERE 
        pa.product_ID = @ProductID;

    -- Get product media
    SELECT 
        media_ID,
        media_URL,
        media_TYPE,
        is_primary,
        display_order,
        alt_text,
        created_AT
    FROM 
        dbo.ProductMedia
    WHERE 
        product_ID = @ProductID
    ORDER BY 
        is_primary DESC, display_order ASC;
        
    -- Get product reviews
    SELECT 
        r.rew_ID,
        r.user_ID,
        u.user_NAME,
        r.rew_RATING,
        r.rew_COMMENT,
        r.rew_DATE
    FROM 
        dbo.Review r
    JOIN 
        dbo.Users u ON r.user_ID = u.user_ID
    WHERE 
        r.product_ID = @ProductID
    ORDER BY 
        r.rew_DATE DESC;
END;
GO

PRINT 'Product procedures created successfully.';
GO
