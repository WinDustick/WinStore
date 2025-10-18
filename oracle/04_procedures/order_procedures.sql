-- =====================================================================
-- WinStore - Order Procedures (Oracle version)
-- =====================================================================
-- Description: Creates stored procedures for order management
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-10-02
-- Version:     1.0.0 (Oracle)
-- =====================================================================
-- Dependencies: 01_schema/01_core_schema.sql
-- =====================================================================

-- Create Type for Order Items (Oracle equivalent of Table Type)
CREATE OR REPLACE TYPE OrderItemType AS OBJECT (
    product_ID NUMBER,
    quantity NUMBER
);
/

CREATE OR REPLACE TYPE OrderItemTypeList AS TABLE OF OrderItemType;
/

-- Create package for order related operations
CREATE OR REPLACE PACKAGE pkg_order AS
    -- Create Order
    PROCEDURE sp_CreateOrder(
        p_UserID IN NUMBER,
        p_Items IN OrderItemTypeList,
        p_DeliveryAddress IN VARCHAR2,
        p_OrderStatusID IN NUMBER DEFAULT 1, -- Default to Cart
        p_OrderID OUT NUMBER
    );
    
    -- Update Order Status
    PROCEDURE sp_UpdateOrderStatus(
        p_OrderID IN NUMBER,
        p_NewStatusID IN NUMBER
    );
    
    -- Validate Order Status Transition
    PROCEDURE sp_ValidateOrderStatusTransition(
        p_FromStatusID IN NUMBER,
        p_ToStatusID IN NUMBER,
        p_IsValid OUT NUMBER, -- Oracle uses NUMBER instead of BIT (0=false, 1=true)
        p_TransitionName OUT VARCHAR2
    );
    
    -- Get Available Order Status Transitions
    PROCEDURE sp_GetAvailableOrderStatusTransitions(
        p_CurrentStatusID IN NUMBER,
        p_cursor OUT SYS_REFCURSOR
    );
    
    -- Generate Order Invoice
    PROCEDURE sp_GenerateOrderInvoice(
        p_OrderID IN NUMBER,
        p_order_details OUT SYS_REFCURSOR,
        p_order_items OUT SYS_REFCURSOR,
        p_payment_info OUT SYS_REFCURSOR
    );
END pkg_order;
/

-- Create package body for order related operations
CREATE OR REPLACE PACKAGE BODY pkg_order AS
    -- Create Order
    PROCEDURE sp_CreateOrder(
        p_UserID IN NUMBER,
        p_Items IN OrderItemTypeList,
        p_DeliveryAddress IN VARCHAR2,
        p_OrderStatusID IN NUMBER DEFAULT 1, -- Default to Cart
        p_OrderID OUT NUMBER
    ) IS
    BEGIN
        -- Insert the order record
        INSERT INTO Orders (
            user_ID,
            order_STATUS_ID,
            order_AMOUNT,  -- This will be calculated and updated by the application
            delivery_ADDRESS
        )
        VALUES (
            p_UserID,
            p_OrderStatusID,
            0,  -- Initial amount set to 0, will be calculated and updated by application
            p_DeliveryAddress
        )
        RETURNING order_ID INTO p_OrderID;

        -- Insert order items
        FOR i IN 1..p_Items.COUNT LOOP
            INSERT INTO OrderItems (
                order_ID, 
                product_ID, 
                quantity, 
                price  -- Current price from Products table
            )
            SELECT 
                p_OrderID, 
                p_Items(i).product_ID, 
                p_Items(i).quantity, 
                product_PRICE
            FROM 
                Products
            WHERE 
                product_ID = p_Items(i).product_ID;
        END LOOP;

        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END sp_CreateOrder;
    
    -- Update Order Status
    PROCEDURE sp_UpdateOrderStatus(
        p_OrderID IN NUMBER,
        p_NewStatusID IN NUMBER
    ) IS
    BEGIN
        UPDATE Orders
        SET 
            order_STATUS_ID = p_NewStatusID
        WHERE 
            order_ID = p_OrderID;
        
        -- Note: Business logic for validation will be in the application
        -- This procedure only performs the data update
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END sp_UpdateOrderStatus;
    
    -- Validate Order Status Transition
    PROCEDURE sp_ValidateOrderStatusTransition(
        p_FromStatusID IN NUMBER,
        p_ToStatusID IN NUMBER,
        p_IsValid OUT NUMBER, -- Oracle uses NUMBER instead of BIT (0=false, 1=true)
        p_TransitionName OUT VARCHAR2
    ) IS
    BEGIN
        SELECT 
            CASE WHEN is_allowed = 1 THEN 1 ELSE 0 END,
            transition_name
        INTO 
            p_IsValid,
            p_TransitionName
        FROM 
            OrderStatusTransitions
        WHERE 
            from_status_ID = p_FromStatusID 
            AND to_status_ID = p_ToStatusID;
        
    EXCEPTION
        -- If no transition found, it's not allowed
        WHEN NO_DATA_FOUND THEN
            p_IsValid := 0;
            p_TransitionName := NULL;
    END sp_ValidateOrderStatusTransition;
    
    -- Get Available Order Status Transitions
    PROCEDURE sp_GetAvailableOrderStatusTransitions(
        p_CurrentStatusID IN NUMBER,
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
        SELECT 
            t.to_status_ID,
            d.status_KEY,
            d.status_NAME_RU,
            d.status_NAME_EN,
            t.transition_name
        FROM 
            OrderStatusTransitions t
        JOIN
            OrderStatusTypes d ON t.to_status_ID = d.status_ID
        WHERE 
            t.from_status_ID = p_CurrentStatusID
            AND t.is_allowed = 1
        ORDER BY 
            d.display_ORDER;
            
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END sp_GetAvailableOrderStatusTransitions;
    
    -- Generate Order Invoice
    PROCEDURE sp_GenerateOrderInvoice(
        p_OrderID IN NUMBER,
        p_order_details OUT SYS_REFCURSOR,
        p_order_items OUT SYS_REFCURSOR,
        p_payment_info OUT SYS_REFCURSOR
    ) IS
    BEGIN
        -- Order header information
        OPEN p_order_details FOR
        SELECT
            o.order_ID,
            o.order_DATE,
            o.order_AMOUNT,
            o.promo_SAVINGS,
            (o.order_AMOUNT - NVL(o.promo_SAVINGS, 0)) AS total_amount,
            os.status_NAME_RU AS order_status,
            u.user_ID,
            u.user_NAME,
            u.user_EMAIL,
            u.user_PHONE,
            o.delivery_ADDRESS
        FROM
            Orders o
        JOIN
            Users u ON o.user_ID = u.user_ID
        LEFT JOIN
            OrderStatusTypes os ON o.order_STATUS_ID = os.status_ID
        WHERE
            o.order_ID = p_OrderID;
        
        -- Order items
        OPEN p_order_items FOR
        SELECT
            oi.OrderItems_ID,
            oi.product_ID,
            p.product_NAME,
            oi.quantity,
            oi.price,
            (oi.quantity * oi.price) AS line_total
        FROM
            OrderItems oi
        JOIN
            Products p ON oi.product_ID = p.product_ID
        WHERE
            oi.order_ID = p_OrderID;
        
        -- Payment information
        OPEN p_payment_info FOR
        SELECT
            p.payment_ID,
            p.payment_DATE,
            p.payment_METHOD,
            ps.status_NAME_RU AS payment_status,
            p.payment_AMOUNT,
            p.currency,
            p.transaction_ID
        FROM
            Payments p
        LEFT JOIN
            PaymentStatusTypes ps ON p.payment_STATUS_ID = ps.status_ID
        WHERE
            p.order_ID = p_OrderID;
            
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END sp_GenerateOrderInvoice;
    
END pkg_order;
/

-- Grant execution privileges on the package
GRANT EXECUTE ON pkg_order TO WINSTORE_APP;
GRANT EXECUTE ON OrderItemType TO WINSTORE_APP;
GRANT EXECUTE ON OrderItemTypeList TO WINSTORE_APP;

-- Provide feedback on creation
BEGIN
    DBMS_OUTPUT.PUT_LINE('Order procedures created successfully.');
END;
/
