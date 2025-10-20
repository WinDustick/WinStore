-- === Начало компактного скрипта генерации RAM (English Version) ===

BEGIN TRANSACTION; -- Use transaction for atomicity

-- 1. Ensure Category exists (Using ID 4 for RAM as specified)
DECLARE @RamCategoryID INT = 4;

-- 2. Ensure Vendor "Generic Brand" exists
DECLARE @GenericVendorID INT;
SELECT @GenericVendorID = ven_ID FROM Vendors WHERE ven_NAME = N'Generic Brand';
IF @GenericVendorID IS NULL
BEGIN
    INSERT INTO Vendors (ven_NAME, ven_COUNTRY, ven_DESCRIPT)
    VALUES (N'Generic Brand', N'N/A', N'Generic brand for standard components');
    SET @GenericVendorID = SCOPE_IDENTITY();
    PRINT N'Vendor "Generic Brand" (ID=' + CAST(@GenericVendorID AS NVARCHAR) + ') added.';
END
ELSE PRINT N'Vendor "Generic Brand" (ID=' + CAST(@GenericVendorID AS NVARCHAR) + ') already exists.';

-- 3. Ensure required RAM Attributes exist using MERGE
DECLARE @AttrDDRTypeID INT, @AttrSpeedID INT, @AttrTimingsID INT,
        @AttrVoltageID INT, @AttrProfileID INT, @AttrCapacityID INT;

PRINT N'Ensuring required RAM attributes exist...';
MERGE INTO Attributes AS Target
USING (VALUES
    (N'Memory Type'),   -- Текстовый: DDR3, DDR4, DDR5
    (N'Speed (MT/s)'), -- Числовой: 1333, 3200, 6000...
    (N'Timings'),      -- Текстовый: 9-9-9-24, 16-18-18-36...
    (N'Voltage (V)'),  -- Числовой (или текст): 1.2, 1.35...
    (N'Capacity (GB)'),-- Числовой: 8, 16, 32...
    (N'Profile Type')  -- Текстовый: JEDEC, XMP, EXPO
) AS Source (att_NAME)
ON Target.att_NAME = Source.att_NAME
WHEN NOT MATCHED BY TARGET THEN
    INSERT (att_NAME) VALUES (Source.att_NAME); -- Insert if attribute doesn't exist
-- No UPDATE needed, just ensure they exist

-- Get Attribute IDs after MERGE
SELECT @AttrDDRTypeID = att_ID FROM Attributes WHERE att_NAME = N'Memory Type';
SELECT @AttrSpeedID = att_ID FROM Attributes WHERE att_NAME = N'Speed (MT/s)';
SELECT @AttrTimingsID = att_ID FROM Attributes WHERE att_NAME = N'Timings';
SELECT @AttrVoltageID = att_ID FROM Attributes WHERE att_NAME = N'Voltage (V)';
SELECT @AttrCapacityID = att_ID FROM Attributes WHERE att_NAME = N'Capacity (GB)';
SELECT @AttrProfileID = att_ID FROM Attributes WHERE att_NAME = N'Profile Type';

-- Verify all IDs were found
IF @AttrDDRTypeID IS NULL OR @AttrSpeedID IS NULL OR @AttrTimingsID IS NULL OR @AttrVoltageID IS NULL OR @AttrCapacityID IS NULL OR @AttrProfileID IS NULL
BEGIN
    PRINT N'Error: Could not find or create all required RAM attributes after MERGE.';
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; RETURN; -- Abort on error
END
ELSE PRINT N'Attribute check/creation complete. IDs retrieved.';


-- === Steps 4 & 5: Loop-based generation of Products and their Attributes ===
PRINT N'Starting cyclical generation of RAM products...';

-- Generation Parameters
DECLARE @Counter INT = 0;
DECLARE @MaxProductsToGenerate INT = 75; -- How many generation attempts to make

-- Variables for generated data
DECLARE @ProductID INT;
DECLARE @ProductName NVARCHAR(255);
DECLARE @ProductDesc NVARCHAR(1000);
DECLARE @ProductPrice DECIMAL(10, 2);
DECLARE @ProductStock INT;
DECLARE @DDRType NVARCHAR(10);
DECLARE @Speed INT;
DECLARE @SpeedStr NVARCHAR(10);
DECLARE @Timings NVARCHAR(50);
DECLARE @Voltage NVARCHAR(10); -- Store as text for consistency with 'N/A' or specific values
DECLARE @ProfileType NVARCHAR(50);
DECLARE @Capacity INT;
DECLARE @CapacityStr NVARCHAR(10);
DECLARE @IsXMP BIT;

-- Generation Loop
WHILE @Counter < @MaxProductsToGenerate
BEGIN
    -- 1. Randomly select DDR Type (Weighted towards DDR4/DDR5)
    DECLARE @RandomDDRSelector INT = ABS(CHECKSUM(NEWID())) % 10; -- 0-1: DDR3 (20%), 2-5: DDR4 (40%), 6-9: DDR5 (40%)

    -- 2. Randomly select Speed & Capacity based on DDR Type
    SET @IsXMP = 0; -- Default to JEDEC

    IF @RandomDDRSelector <= 1 -- DDR3
    BEGIN
        SET @DDRType = N'DDR3';
        DECLARE @RandomDDR3Speed INT = ABS(CHECKSUM(NEWID())) % 2; -- 0: 1333, 1: 1600
        SET @Speed = CASE @RandomDDR3Speed WHEN 0 THEN 1333 ELSE 1600 END;
        DECLARE @RandomDDR3Cap INT = ABS(CHECKSUM(NEWID())) % 2; -- 0: 4GB, 1: 8GB
        SET @Capacity = CASE @RandomDDR3Cap WHEN 0 THEN 4 ELSE 8 END;
    END
    ELSE IF @RandomDDRSelector <= 5 -- DDR4
    BEGIN
        SET @DDRType = N'DDR4';
        DECLARE @RandomDDR4Speed INT = ABS(CHECKSUM(NEWID())) % 4; -- 0: 2666J, 1: 3200J, 2: 3200XMP, 3: 3600XMP
        SET @Speed = CASE @RandomDDR4Speed WHEN 0 THEN 2666 WHEN 1 THEN 3200 WHEN 2 THEN 3200 WHEN 3 THEN 3600 ELSE 2666 END;
        IF @RandomDDR4Speed >= 2 SET @IsXMP = 1;
        DECLARE @RandomDDR4Cap INT = ABS(CHECKSUM(NEWID())) % 3; -- 0: 8GB, 1: 16GB, 2: 32GB
        SET @Capacity = CASE @RandomDDR4Cap WHEN 0 THEN 8 WHEN 1 THEN 16 ELSE 32 END;
    END
    ELSE -- DDR5
    BEGIN
        SET @DDRType = N'DDR5';
        DECLARE @RandomDDR5Speed INT = ABS(CHECKSUM(NEWID())) % 5; -- 0: 4800J, 1: 5600J, 2: 6000XMP(CL36), 3: 6000XMP(CL30), 4: 6400XMP(CL32)
        SET @Speed = CASE @RandomDDR5Speed WHEN 0 THEN 4800 WHEN 1 THEN 5600 WHEN 2 THEN 6000 WHEN 3 THEN 6000 WHEN 4 THEN 6400 ELSE 4800 END;
        IF @RandomDDR5Speed >= 2 SET @IsXMP = 1;
        DECLARE @RandomDDR5Cap INT = ABS(CHECKSUM(NEWID())) % 2; -- 0: 16GB, 1: 32GB
        SET @Capacity = CASE @RandomDDR5Cap WHEN 0 THEN 16 ELSE 32 END;
    END

    -- 3. Determine Timings, Voltage, ProfileType based on generated combination
    SET @SpeedStr = CAST(@Speed AS NVARCHAR);
    SET @CapacityStr = CAST(@Capacity AS NVARCHAR);
    SET @Timings = N'N/A'; SET @Voltage = N'N/A'; SET @ProfileType = N'N/A'; -- Reset defaults

    -- Logic based on generated values
    IF @DDRType = N'DDR3' BEGIN
        SET @ProfileType = N'JEDEC'; SET @Voltage = N'1.5';
        IF @Speed = 1333 SET @Timings = N'9-9-9-24'; ELSE SET @Timings = N'11-11-11-28'; -- Speed = 1600
    END
    ELSE IF @DDRType = N'DDR4' BEGIN
        IF @IsXMP = 0 BEGIN -- JEDEC
            SET @ProfileType = N'JEDEC'; SET @Voltage = N'1.2';
            IF @Speed = 2666 SET @Timings = N'19-19-19-43'; ELSE SET @Timings = N'22-22-22-52'; -- Speed=3200
        END ELSE BEGIN -- XMP
            SET @ProfileType = N'XMP/EXPO'; SET @Voltage = N'1.35';
            IF @Speed = 3200 SET @Timings = N'16-18-18-36'; ELSE SET @Timings = N'18-22-22-42'; -- Speed=3600
        END
    END
    ELSE IF @DDRType = N'DDR5' BEGIN
        IF @IsXMP = 0 BEGIN -- JEDEC
            SET @ProfileType = N'JEDEC'; SET @Voltage = N'1.1';
            IF @Speed = 4800 SET @Timings = N'40-40-40-77'; ELSE SET @Timings = N'46-46-46-89'; -- Speed=5600
        END ELSE BEGIN -- XMP
            SET @ProfileType = N'XMP/EXPO';
            IF @Speed = 6000 BEGIN
                 IF EXISTS(SELECT 1 WHERE @RandomDDR5Speed = 2) BEGIN SET @Timings = N'36-36-36-76'; SET @Voltage = N'1.3'; END -- CL36 Index=2
                 ELSE BEGIN SET @Timings = N'30-38-38-76'; SET @Voltage = N'1.35'; END -- CL30 Index=3
            END ELSE BEGIN -- Speed = 6400 Index=4
                 SET @Timings = N'32-39-39-80'; SET @Voltage = N'1.4';
            END
        END
    END

    -- 4. Construct Product Name (English)
    SET @ProductName = N'Generic ' + @DDRType + N' ' + @SpeedStr + N'MT/s';
    -- Add CL marker for common XMP types to make names more unique
    IF @DDRType = N'DDR4' AND @IsXMP = 1 AND @Speed = 3200 SET @ProductName += N' CL16';
    IF @DDRType = N'DDR5' AND @IsXMP = 1 AND @Speed = 6000 AND @Timings LIKE N'30-%' SET @ProductName += N' CL30';
    IF @DDRType = N'DDR5' AND @IsXMP = 1 AND @Speed = 6000 AND @Timings LIKE N'36-%' SET @ProductName += N' CL36';
    IF @DDRType = N'DDR5' AND @IsXMP = 1 AND @Speed = 6400 SET @ProductName += N' CL32';
    SET @ProductName += N' ' + @CapacityStr + N'GB';

    -- 5. Check Existence and Insert if Not Found
    IF NOT EXISTS (SELECT 1 FROM Products WHERE product_NAME = @ProductName AND category_ID = @RamCategoryID AND ven_ID = @GenericVendorID)
    BEGIN
        -- Construct Description, Price, Stock (Example values)
        SET @ProductDesc = N'RAM Module ' + @ProductName + N'. Profile Type: ' + @ProfileType + N', Timings: ' + @Timings + N', Voltage: ' + @Voltage + N'V.';
        -- Basic price calculation logic
        SET @ProductPrice = (@Capacity * 5.0) + (@Speed / 100.0) + (CASE WHEN @IsXMP = 1 THEN 25.0 ELSE 0 END) + (CASE @DDRType WHEN 'DDR3' THEN 0 WHEN 'DDR4' THEN 15 WHEN 'DDR5' THEN 45 ELSE 0 END);
        SET @ProductStock = 15 + (ABS(CHECKSUM(NEWID())) % 86); -- Random stock between 15 and 100

        -- Insert product
        INSERT INTO Products (category_ID, product_NAME, product_DESCRIPT, product_PRICE, product_STOCK, created_AT, ven_ID)
        VALUES (@RamCategoryID, @ProductName, @ProductDesc, @ProductPrice, @ProductStock, GETDATE(), @GenericVendorID); -- Use GETDATE() per insert
        SET @ProductID = SCOPE_IDENTITY();

        -- Insert product attributes
        INSERT INTO ProductAttributes (att_ID, product_ID, nominal, unit_of_measurement) VALUES
            (@AttrDDRTypeID, @ProductID, @DDRType, NULL),
            (@AttrSpeedID, @ProductID, @SpeedStr, N'MT/s'),
            (@AttrTimingsID, @ProductID, @Timings, NULL),
            (@AttrVoltageID, @ProductID, @Voltage, N'V'), -- Storing voltage as text nominal
            (@AttrProfileID, @ProductID, @ProfileType, NULL),
            (@AttrCapacityID, @ProductID, @CapacityStr, N'GB');

         PRINT N'Added: ' + @ProductName;
    END
    -- ELSE -- Optional: uncomment to see skipped products
    -- BEGIN
    --     PRINT N'Skipped (already exists): ' + @ProductName;
    -- END

    SET @Counter = @Counter + 1; -- Increment loop counter
END -- End WHILE loop

PRINT N'Cyclical generation of RAM products finished. Attempts made: ' + CAST(@Counter AS NVARCHAR);

-- Commit transaction if everything was successful
IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
PRINT N'Transaction committed successfully.';

SELECT * FROM Attributes