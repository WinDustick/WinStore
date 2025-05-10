-- =====================================================================
-- WinStore - Core Database Schema
-- =====================================================================
-- Description: Creates the WinStore database, all core tables and 
--              constraints. This is the foundation of the database.
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-05-25
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: None - this is the first script to be executed
-- =====================================================================

-- =====================================================================
-- Create Database WinStore
-- =====================================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'WinStore')
BEGIN
    CREATE DATABASE WinStore
    ON PRIMARY
    (
        NAME = winstore_data,
        FILENAME = '/var/opt/mssql/data/winstore_data.mdf',
        SIZE = 200MB,
        MAXSIZE = 2048MB,
        FILEGROWTH = 64MB
    )
    LOG ON
    (
        NAME = winstore_log,
        FILENAME = '/var/opt/mssql/data/winstore_log.ldf',
        SIZE = 200MB,
        MAXSIZE = 2048MB,
        FILEGROWTH = 64MB
    );
    PRINT 'Database WinStore created successfully.';
END
ELSE
    PRINT 'Database WinStore already exists.';
GO

-- Switch context to the WinStore database
USE WinStore
GO

-- =====================================================================
-- Create Core Tables
-- =====================================================================

-- Users Table: Stores user information
CREATE TABLE dbo.Users (
    user_ID INT IDENTITY(1,1) PRIMARY KEY,
    user_NAME NVARCHAR(50) NOT NULL,
    user_PASS NVARCHAR(255) NOT NULL,
    user_EMAIL NVARCHAR(100) UNIQUE,
    user_PHONE NVARCHAR(20) NOT NULL,
    user_ROLE NVARCHAR(50) NOT NULL CHECK (user_ROLE IN ('Admin', 'Customer', 'Vendor')),
    created_AT DATETIME DEFAULT GETDATE(),
    last_login DATETIME NULL
);
GO

-- Categories Table: Stores product categories
CREATE TABLE dbo.Categories (
    category_ID INT IDENTITY(1,1) PRIMARY KEY,
    category_NAME NVARCHAR(100) NOT NULL UNIQUE,
    category_DESCRIPT NVARCHAR(500)
);
GO

-- Vendors Table: Stores information about product vendors/suppliers
CREATE TABLE dbo.Vendors (
    ven_ID INT IDENTITY(1,1) PRIMARY KEY,
    ven_NAME NVARCHAR(100) NOT NULL,
    ven_COUNTRY NVARCHAR(100) NOT NULL,
    ven_DESCRIPT NVARCHAR(500)
);
GO

-- Attributes Table: Stores potential product attributes
CREATE TABLE dbo.Attributes (
    att_ID INT IDENTITY(1,1) PRIMARY KEY,
    att_NAME NVARCHAR(255) NOT NULL UNIQUE
);
GO

-- Products Table: Stores product details
CREATE TABLE dbo.Products (
    product_ID INT IDENTITY(1,1) PRIMARY KEY,
    category_ID INT NOT NULL,
    product_NAME NVARCHAR(255) NOT NULL,
    product_DESCRIPT NVARCHAR(MAX) NOT NULL,
    product_PRICE DECIMAL(10,2) NOT NULL CHECK (product_PRICE >= 0),
    product_STOCK INT NOT NULL CHECK (product_STOCK >= 0),
    created_AT DATETIME DEFAULT GETDATE(),
    updated_AT DATETIME DEFAULT GETDATE(),
    is_featured BIT DEFAULT 0 NOT NULL,
    is_active BIT DEFAULT 1 NOT NULL,
    ven_ID INT NOT NULL,
    CONSTRAINT FK_Products_Categories FOREIGN KEY (category_ID) REFERENCES dbo.Categories(category_ID) ON DELETE NO ACTION,
    CONSTRAINT FK_Products_Vendors FOREIGN KEY (ven_ID) REFERENCES dbo.Vendors(ven_ID) ON DELETE NO ACTION
);
GO

-- Product Media Table: Stores links to product images and other media
CREATE TABLE dbo.ProductMedia (
    media_ID INT IDENTITY(1,1) PRIMARY KEY,
    product_ID INT NOT NULL,
    media_URL NVARCHAR(1000) NOT NULL,
    media_TYPE NVARCHAR(50) NOT NULL DEFAULT 'image',
    is_primary BIT DEFAULT 0 NOT NULL,
    display_order INT DEFAULT 0 NOT NULL,
    alt_text NVARCHAR(255) NULL,
    created_AT DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_ProductMedia_Products FOREIGN KEY (product_ID) REFERENCES dbo.Products(product_ID) ON DELETE CASCADE
);
GO

-- Product Attributes Table: Links products to their specific attributes and values
CREATE TABLE dbo.ProductAttributes (
    att_ID INT NOT NULL,
    product_ID INT NOT NULL,
    nominal NVARCHAR(MAX) NOT NULL,
    unit_of_measurement NVARCHAR(100),
    PRIMARY KEY (att_ID, product_ID),
    CONSTRAINT FK_ProductAttributes_Attributes FOREIGN KEY (att_ID) REFERENCES dbo.Attributes(att_ID) ON DELETE CASCADE,
    CONSTRAINT FK_ProductAttributes_Products FOREIGN KEY (product_ID) REFERENCES dbo.Products(product_ID) ON DELETE CASCADE
);
GO

-- Wishlist Table: Stores user wishlist items
CREATE TABLE dbo.Wishlist (
    wishlist_ID INT IDENTITY(1,1) PRIMARY KEY,
    user_ID INT NOT NULL,
    product_ID INT NOT NULL,
    added_AT DATETIME DEFAULT GETDATE(),
    notes NVARCHAR(500) NULL,
    CONSTRAINT FK_Wishlist_Users FOREIGN KEY (user_ID) REFERENCES dbo.Users(user_ID) ON DELETE CASCADE,
    CONSTRAINT FK_Wishlist_Products FOREIGN KEY (product_ID) REFERENCES dbo.Products(product_ID) ON DELETE CASCADE,
    CONSTRAINT UQ_Wishlist_User_Product UNIQUE (user_ID, product_ID)
);
GO

-- Promotions Table: Stores promotion/coupon codes and details
CREATE TABLE dbo.Promotions (
    promo_ID INT IDENTITY(1,1) PRIMARY KEY,
    promo_CODE NVARCHAR(50) NOT NULL UNIQUE,
    promo_NAME NVARCHAR(100) NOT NULL,
    promo_DESCRIPT NVARCHAR(500) NULL,
    discount_TYPE NVARCHAR(10) NOT NULL CHECK (discount_TYPE IN ('percentage', 'fixed', 'shipping')),
    discount_VALUE DECIMAL(10,2) NOT NULL CHECK (discount_VALUE >= 0),
    min_purchase DECIMAL(10,2) DEFAULT 0 NOT NULL,
    valid_FROM DATETIME NOT NULL,
    valid_TO DATETIME NOT NULL,
    max_USES INT NULL,
    current_USES INT DEFAULT 0 NOT NULL,
    is_ACTIVE BIT DEFAULT 1 NOT NULL,
    created_AT DATETIME DEFAULT GETDATE(),
    created_BY INT NULL,
    CONSTRAINT CHK_Promotions_ValidDates CHECK (valid_TO > valid_FROM),
    CONSTRAINT FK_Promotions_Users FOREIGN KEY (created_BY) REFERENCES dbo.Users(user_ID) ON DELETE SET NULL
);
GO

-- PromotionApplications Table: Maps where promotions can be applied
CREATE TABLE dbo.PromotionApplications (
    app_ID INT IDENTITY(1,1) PRIMARY KEY,
    promo_ID INT NOT NULL,
    target_TYPE NVARCHAR(10) NOT NULL CHECK (target_TYPE IN ('product', 'category', 'all')),
    target_ID INT NULL,
    CONSTRAINT FK_PromotionApplications_Promotions FOREIGN KEY (promo_ID) REFERENCES dbo.Promotions(promo_ID) ON DELETE CASCADE,
    CONSTRAINT UQ_PromotionApplications_Promo_Target UNIQUE (promo_ID, target_TYPE, target_ID)
);
GO

-- Orders Table: Stores customer orders
CREATE TABLE dbo.Orders (
    order_ID INT IDENTITY(1,1) PRIMARY KEY,
    user_ID INT NOT NULL,
    order_DATE DATETIME DEFAULT GETDATE(),
    order_STATUS_ID INT NULL,
    order_AMOUNT DECIMAL(10,2) NOT NULL CHECK (order_AMOUNT >= 0),
    promo_ID INT NULL,
    promo_SAVINGS DECIMAL(10,2) DEFAULT 0 NOT NULL,
    -- Delivery Information (simplified system)
    delivery_ADDRESS NVARCHAR(500) NULL,
    shipped_DATE DATETIME NULL,
    estimated_delivery_DATE DATETIME NULL,
    actual_delivery_DATE DATETIME NULL,
    delivery_STATUS_ID INT NULL,
    shipping_carrier_NAME NVARCHAR(255) NULL,
    tracking_NUMBER NVARCHAR(100) NULL,
    CONSTRAINT FK_Orders_Users FOREIGN KEY (user_ID) REFERENCES dbo.Users(user_ID) ON DELETE NO ACTION,
    CONSTRAINT FK_Orders_Promotions FOREIGN KEY (promo_ID) REFERENCES dbo.Promotions(promo_ID) ON DELETE NO ACTION
    -- Foreign keys to status tables will be added after those tables are created
);
GO

-- Order Items Table: Stores individual items within an order
CREATE TABLE dbo.OrderItems (
    OrderItems_ID INT IDENTITY(1,1) PRIMARY KEY,
    order_ID INT NOT NULL,
    product_ID INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (order_ID) REFERENCES dbo.Orders(order_ID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItems_Products FOREIGN KEY (product_ID) REFERENCES dbo.Products(product_ID) ON DELETE NO ACTION
);
GO

-- Payments Table: Stores payment information for orders
CREATE TABLE dbo.Payments (
    payment_ID INT IDENTITY(1,1) PRIMARY KEY,
    order_ID INT NOT NULL,
    payment_DATE DATETIME NOT NULL DEFAULT GETDATE(),
    payment_METHOD NVARCHAR(50) NOT NULL,
    payment_STATUS_ID INT NULL,
    payment_AMOUNT DECIMAL(10,2) NOT NULL,
    currency NCHAR(3) NOT NULL CONSTRAINT CHK_Payments_CurrencyLength CHECK (LEN(currency)=3),
    transaction_ID NVARCHAR(100) NOT NULL UNIQUE,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Payments_Orders FOREIGN KEY (order_ID) REFERENCES dbo.Orders(order_ID) ON DELETE NO ACTION
    -- Foreign key to payment status table will be added after that table is created
);
GO

-- Reviews Table: Stores user reviews for products
CREATE TABLE dbo.Review (
    rew_ID INT IDENTITY(1,1) PRIMARY KEY,
    user_ID INT NOT NULL,
    product_ID INT NOT NULL,
    rew_RATING INT NOT NULL CHECK (rew_RATING BETWEEN 1 AND 5),
    rew_COMMENT NVARCHAR(1000),
    rew_DATE DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Review_Users FOREIGN KEY (user_ID) REFERENCES dbo.Users(user_ID) ON DELETE CASCADE,
    CONSTRAINT FK_Review_Products FOREIGN KEY (product_ID) REFERENCES dbo.Products(product_ID) ON DELETE CASCADE,
    CONSTRAINT UQ_Review_User_Product UNIQUE (user_ID, product_ID)
);
GO

-- Create unique constraint for Orders
ALTER TABLE dbo.Orders
ADD CONSTRAINT UQ_Orders_Order_User UNIQUE(order_ID, user_ID);
GO

PRINT 'Core database schema created successfully.';
GO
