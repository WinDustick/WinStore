-- =====================================================================
-- WinStore - Core Database Schema (Oracle Version)
-- =====================================================================
-- Description: Creates the WinStore tablespace, all core tables and 
--              constraints. This is the foundation of the database.
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-09-28
-- Version:     1.0.0
-- =====================================================================
-- Dependencies: None - this is the first script to be executed
-- =====================================================================

-- =====================================================================
-- Create Tablespace for WinStore
-- =====================================================================
DECLARE
  v_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists FROM dba_tablespaces WHERE tablespace_name = 'WINSTORE_DATA';
  
  IF v_exists = 0 THEN
    EXECUTE IMMEDIATE '
      CREATE TABLESPACE WINSTORE_DATA
      DATAFILE ''/opt/oracle/oradata/ORCLCDB/ORCLPDB1/winstore_data01.dbf'' SIZE 200M
      AUTOEXTEND ON NEXT 64M MAXSIZE 2048M
    ';
    DBMS_OUTPUT.PUT_LINE('Tablespace WINSTORE_DATA created successfully.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Tablespace WINSTORE_DATA already exists.');
  END IF;
END;
/

-- =====================================================================
-- Create Sequences for Auto-Incrementing IDs
-- =====================================================================

-- Users Sequence
CREATE SEQUENCE SEQ_USERS_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Categories Sequence
CREATE SEQUENCE SEQ_CATEGORIES_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;
  
-- Vendors Sequence
CREATE SEQUENCE SEQ_VENDORS_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Attributes Sequence
CREATE SEQUENCE SEQ_ATTRIBUTES_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Products Sequence
CREATE SEQUENCE SEQ_PRODUCTS_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- ProductMedia Sequence
CREATE SEQUENCE SEQ_PRODUCTMEDIA_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Wishlist Sequence
CREATE SEQUENCE SEQ_WISHLIST_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Promotions Sequence
CREATE SEQUENCE SEQ_PROMOTIONS_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- PromotionApplications Sequence
CREATE SEQUENCE SEQ_PROMOTIONAPPS_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Orders Sequence
CREATE SEQUENCE SEQ_ORDERS_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- OrderItems Sequence
CREATE SEQUENCE SEQ_ORDERITEMS_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Payments Sequence
CREATE SEQUENCE SEQ_PAYMENTS_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- Reviews Sequence
CREATE SEQUENCE SEQ_REVIEWS_ID
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

-- =====================================================================
-- Create Core Tables
-- =====================================================================

-- Users Table: Stores user information
CREATE TABLE Users (
    user_ID NUMBER PRIMARY KEY,
    user_NAME NVARCHAR2(50) NOT NULL,
    user_PASS NVARCHAR2(255) NOT NULL,
    user_EMAIL NVARCHAR2(100) UNIQUE,
    user_PHONE NVARCHAR2(20) NOT NULL,
    user_ROLE NVARCHAR2(50) NOT NULL CHECK (user_ROLE IN ('Admin', 'Customer', 'Vendor')),
    created_AT TIMESTAMP DEFAULT SYSTIMESTAMP,
    last_login TIMESTAMP NULL
);

-- Categories Table: Stores product categories
CREATE TABLE Categories (
    category_ID NUMBER PRIMARY KEY,
    category_NAME NVARCHAR2(100) NOT NULL UNIQUE,
    category_DESCRIPT NVARCHAR2(500)
);

-- Vendors Table: Stores information about product vendors/suppliers
CREATE TABLE Vendors (
    ven_ID NUMBER PRIMARY KEY,
    ven_NAME NVARCHAR2(100) NOT NULL,
    ven_COUNTRY NVARCHAR2(100) NOT NULL,
    ven_DESCRIPT NVARCHAR2(500)
);

-- Attributes Table: Stores potential product attributes
CREATE TABLE Attributes (
    att_ID NUMBER PRIMARY KEY,
    att_NAME NVARCHAR2(255) NOT NULL UNIQUE
);

-- Products Table: Stores product details
CREATE TABLE Products (
    product_ID NUMBER PRIMARY KEY,
    category_ID NUMBER NOT NULL,
    product_NAME NVARCHAR2(255) NOT NULL,
    product_DESCRIPT NCLOB NOT NULL,
    product_PRICE NUMBER(10,2) NOT NULL CHECK (product_PRICE >= 0),
    product_STOCK NUMBER NOT NULL CHECK (product_STOCK >= 0),
    created_AT TIMESTAMP DEFAULT SYSTIMESTAMP,
    updated_AT TIMESTAMP DEFAULT SYSTIMESTAMP,
    is_featured NUMBER(1) DEFAULT 0 NOT NULL,
    is_active NUMBER(1) DEFAULT 1 NOT NULL,
    ven_ID NUMBER NOT NULL,
    CONSTRAINT FK_Products_Categories FOREIGN KEY (category_ID) REFERENCES Categories(category_ID),
    CONSTRAINT FK_Products_Vendors FOREIGN KEY (ven_ID) REFERENCES Vendors(ven_ID)
);

-- Product Media Table: Stores links to product images and other media
CREATE TABLE ProductMedia (
    media_ID NUMBER PRIMARY KEY,
    product_ID NUMBER NOT NULL,
    media_URL NVARCHAR2(1000) NOT NULL,
    media_TYPE NVARCHAR2(50) DEFAULT 'image' NOT NULL,
    is_primary NUMBER(1) DEFAULT 0 NOT NULL,
    display_order NUMBER DEFAULT 0 NOT NULL,
    alt_text NVARCHAR2(255) NULL,
    created_AT TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_ProductMedia_Products FOREIGN KEY (product_ID) REFERENCES Products(product_ID) ON DELETE CASCADE
);

-- Product Attributes Table: Links products to their specific attributes and values
CREATE TABLE ProductAttributes (
    att_ID NUMBER NOT NULL,
    product_ID NUMBER NOT NULL,
    nominal NCLOB NOT NULL,
    unit_of_measurement NVARCHAR2(100),
    CONSTRAINT PK_ProductAttributes PRIMARY KEY (att_ID, product_ID),
    CONSTRAINT FK_ProductAttributes_Attributes FOREIGN KEY (att_ID) REFERENCES Attributes(att_ID) ON DELETE CASCADE,
    CONSTRAINT FK_ProductAttributes_Products FOREIGN KEY (product_ID) REFERENCES Products(product_ID) ON DELETE CASCADE
);

-- Wishlist Table: Stores user wishlist items
CREATE TABLE Wishlist (
    wishlist_ID NUMBER PRIMARY KEY,
    user_ID NUMBER NOT NULL,
    product_ID NUMBER NOT NULL,
    added_AT TIMESTAMP DEFAULT SYSTIMESTAMP,
    notes NVARCHAR2(500) NULL,
    CONSTRAINT FK_Wishlist_Users FOREIGN KEY (user_ID) REFERENCES Users(user_ID) ON DELETE CASCADE,
    CONSTRAINT FK_Wishlist_Products FOREIGN KEY (product_ID) REFERENCES Products(product_ID) ON DELETE CASCADE,
    CONSTRAINT UQ_Wishlist_User_Product UNIQUE (user_ID, product_ID)
);

-- Promotions Table: Stores promotion/coupon codes and details
CREATE TABLE Promotions (
    promo_ID NUMBER PRIMARY KEY,
    promo_CODE NVARCHAR2(50) NOT NULL UNIQUE,
    promo_NAME NVARCHAR2(100) NOT NULL,
    promo_DESCRIPT NVARCHAR2(500) NULL,
    discount_TYPE NVARCHAR2(10) NOT NULL CHECK (discount_TYPE IN ('percentage', 'fixed', 'shipping')),
    discount_VALUE NUMBER(10,2) NOT NULL CHECK (discount_VALUE >= 0),
    min_purchase NUMBER(10,2) DEFAULT 0 NOT NULL,
    valid_FROM TIMESTAMP NOT NULL,
    valid_TO TIMESTAMP NOT NULL,
    max_USES NUMBER NULL,
    current_USES NUMBER DEFAULT 0 NOT NULL,
    is_ACTIVE NUMBER(1) DEFAULT 1 NOT NULL,
    created_AT TIMESTAMP DEFAULT SYSTIMESTAMP,
    created_BY NUMBER NULL,
    CONSTRAINT CHK_Promotions_ValidDates CHECK (valid_TO > valid_FROM),
    CONSTRAINT FK_Promotions_Users FOREIGN KEY (created_BY) REFERENCES Users(user_ID) ON DELETE SET NULL
);

-- PromotionApplications Table: Maps where promotions can be applied
CREATE TABLE PromotionApplications (
    app_ID NUMBER PRIMARY KEY,
    promo_ID NUMBER NOT NULL,
    target_TYPE NVARCHAR2(10) NOT NULL CHECK (target_TYPE IN ('product', 'category', 'all')),
    target_ID NUMBER NULL,
    CONSTRAINT FK_PromotionApplications_Promotions FOREIGN KEY (promo_ID) REFERENCES Promotions(promo_ID) ON DELETE CASCADE,
    CONSTRAINT UQ_PromotionApplications UNIQUE (promo_ID, target_TYPE, target_ID)
);

-- Orders Table: Stores customer orders
CREATE TABLE Orders (
    order_ID NUMBER PRIMARY KEY,
    user_ID NUMBER NOT NULL,
    order_DATE TIMESTAMP DEFAULT SYSTIMESTAMP,
    order_STATUS_ID NUMBER NULL,
    order_AMOUNT NUMBER(10,2) NOT NULL CHECK (order_AMOUNT >= 0),
    promo_ID NUMBER NULL,
    promo_SAVINGS NUMBER(10,2) DEFAULT 0 NOT NULL,
    -- Delivery Information (simplified system)
    delivery_ADDRESS NVARCHAR2(500) NULL,
    shipped_DATE TIMESTAMP NULL,
    estimated_delivery_DATE TIMESTAMP NULL,
    actual_delivery_DATE TIMESTAMP NULL,
    delivery_STATUS_ID NUMBER NULL,
    shipping_carrier_NAME NVARCHAR2(255) NULL,
    tracking_NUMBER NVARCHAR2(100) NULL,
    CONSTRAINT FK_Orders_Users FOREIGN KEY (user_ID) REFERENCES Users(user_ID),
    CONSTRAINT FK_Orders_Promotions FOREIGN KEY (promo_ID) REFERENCES Promotions(promo_ID)
    -- Foreign keys to status tables will be added after those tables are created
);

-- Order Items Table: Stores individual items within an order
CREATE TABLE OrderItems (
    OrderItems_ID NUMBER PRIMARY KEY,
    order_ID NUMBER NOT NULL,
    product_ID NUMBER NOT NULL,
    quantity NUMBER NOT NULL CHECK (quantity > 0),
    price NUMBER(10,2) NOT NULL CHECK (price >= 0),
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (order_ID) REFERENCES Orders(order_ID) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItems_Products FOREIGN KEY (product_ID) REFERENCES Products(product_ID)
);

-- Payments Table: Stores payment information for orders
CREATE TABLE Payments (
    payment_ID NUMBER PRIMARY KEY,
    order_ID NUMBER NOT NULL,
    payment_DATE TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    payment_METHOD NVARCHAR2(50) NOT NULL,
    payment_STATUS_ID NUMBER NULL,
    payment_AMOUNT NUMBER(10,2) NOT NULL,
    currency NCHAR(3) NOT NULL CONSTRAINT CHK_Payments_CurrencyLength CHECK (LENGTH(currency)=3),
    transaction_ID NVARCHAR2(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT FK_Payments_Orders FOREIGN KEY (order_ID) REFERENCES Orders(order_ID)
    -- Foreign key to payment status table will be added after that table is created
);

-- Reviews Table: Stores user reviews for products
CREATE TABLE Review (
    rew_ID NUMBER PRIMARY KEY,
    user_ID NUMBER NOT NULL,
    product_ID NUMBER NOT NULL,
    rew_RATING NUMBER NOT NULL CHECK (rew_RATING BETWEEN 1 AND 5),
    rew_COMMENT NVARCHAR2(1000),
    rew_DATE TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT FK_Review_Users FOREIGN KEY (user_ID) REFERENCES Users(user_ID) ON DELETE CASCADE,
    CONSTRAINT FK_Review_Products FOREIGN KEY (product_ID) REFERENCES Products(product_ID) ON DELETE CASCADE,
    CONSTRAINT UQ_Review_User_Product UNIQUE (user_ID, product_ID)
);

-- Create unique constraint for Orders
ALTER TABLE Orders
ADD CONSTRAINT UQ_Orders_Order_User UNIQUE(order_ID, user_ID);

-- =====================================================================
-- Create triggers for auto-incrementing IDs (replacing IDENTITY)
-- =====================================================================

CREATE OR REPLACE TRIGGER TRG_USERS_BI
BEFORE INSERT ON Users
FOR EACH ROW
BEGIN
  SELECT SEQ_USERS_ID.NEXTVAL INTO :NEW.user_ID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER TRG_CATEGORIES_BI
BEFORE INSERT ON Categories
FOR EACH ROW
BEGIN
  SELECT SEQ_CATEGORIES_ID.NEXTVAL INTO :NEW.category_ID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER TRG_VENDORS_BI
BEFORE INSERT ON Vendors
FOR EACH ROW
BEGIN
  SELECT SEQ_VENDORS_ID.NEXTVAL INTO :NEW.ven_ID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER TRG_ATTRIBUTES_BI
BEFORE INSERT ON Attributes
FOR EACH ROW
BEGIN
  SELECT SEQ_ATTRIBUTES_ID.NEXTVAL INTO :NEW.att_ID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER TRG_PRODUCTS_BI
BEFORE INSERT ON Products
FOR EACH ROW
BEGIN
  SELECT SEQ_PRODUCTS_ID.NEXTVAL INTO :NEW.product_ID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER TRG_PRODUCTMEDIA_BI
BEFORE INSERT ON ProductMedia
FOR EACH ROW
BEGIN
  SELECT SEQ_PRODUCTMEDIA_ID.NEXTVAL INTO :NEW.media_ID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER TRG_WISHLIST_BI
BEFORE INSERT ON Wishlist
FOR EACH ROW
BEGIN
  SELECT SEQ_WISHLIST_ID.NEXTVAL INTO :NEW.wishlist_ID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER TRG_PROMOTIONS_BI
BEFORE INSERT ON Promotions
FOR EACH ROW
BEGIN
  SELECT SEQ_PROMOTIONS_ID.NEXTVAL INTO :NEW.promo_ID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER TRG_PROMOTIONAPPS_BI
BEFORE INSERT ON PromotionApplications
FOR EACH ROW
BEGIN
  SELECT SEQ_PROMOTIONAPPS_ID.NEXTVAL INTO :NEW.app_ID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER TRG_ORDERS_BI
BEFORE INSERT ON Orders
FOR EACH ROW
BEGIN
  SELECT SEQ_ORDERS_ID.NEXTVAL INTO :NEW.order_ID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER TRG_ORDERITEMS_BI
BEFORE INSERT ON OrderItems
FOR EACH ROW
BEGIN
  SELECT SEQ_ORDERITEMS_ID.NEXTVAL INTO :NEW.OrderItems_ID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER TRG_PAYMENTS_BI
BEFORE INSERT ON Payments
FOR EACH ROW
BEGIN
  SELECT SEQ_PAYMENTS_ID.NEXTVAL INTO :NEW.payment_ID FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER TRG_REVIEWS_BI
BEFORE INSERT ON Review
FOR EACH ROW
BEGIN
  SELECT SEQ_REVIEWS_ID.NEXTVAL INTO :NEW.rew_ID FROM DUAL;
END;
/

COMMIT;

PROMPT Core database schema created successfully.;

