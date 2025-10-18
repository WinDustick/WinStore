-- =====================================================================
-- WinStore - Payment Procedures (Oracle version)
-- =====================================================================
-- Description: Creates stored procedures for payment processing
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-10-02
-- Version:     1.0.0 (Oracle)
-- =====================================================================
-- Dependencies: 01_schema/01_core_schema.sql
-- =====================================================================

-- Create package for payment related operations
CREATE OR REPLACE PACKAGE pkg_payment AS
    -- Create Payment
    PROCEDURE sp_CreatePayment(
        p_OrderID IN NUMBER,
        p_PaymentMethod IN VARCHAR2,
        p_PaymentAmount IN NUMBER,
        p_Currency IN CHAR,
        p_TransactionID IN VARCHAR2,
        p_PaymentID OUT NUMBER
    );
    
    -- Update Payment Status
    PROCEDURE sp_UpdatePaymentStatus(
        p_PaymentID IN NUMBER,
        p_NewStatusID IN NUMBER,
        p_TransactionID IN VARCHAR2 DEFAULT NULL
    );
    
    -- Payment Status Transition Validation
    PROCEDURE sp_ValidatePaymentStatusTransition(
        p_FromStatusID IN NUMBER,
        p_ToStatusID IN NUMBER,
        p_IsValid OUT NUMBER, -- Oracle uses NUMBER instead of BIT (0=false, 1=true)
        p_TransitionName OUT VARCHAR2
    );
    
    -- Get Available Payment Status Transitions
    PROCEDURE sp_GetAvailablePaymentStatusTransitions(
        p_CurrentStatusID IN NUMBER,
        p_cursor OUT SYS_REFCURSOR
    );
END pkg_payment;
/

-- Create package body for payment related operations
CREATE OR REPLACE PACKAGE BODY pkg_payment AS
    -- Create Payment
    PROCEDURE sp_CreatePayment(
        p_OrderID IN NUMBER,
        p_PaymentMethod IN VARCHAR2,
        p_PaymentAmount IN NUMBER,
        p_Currency IN CHAR,
        p_TransactionID IN VARCHAR2,
        p_PaymentID OUT NUMBER
    ) IS
    BEGIN
        INSERT INTO Payments (
            order_ID,
            payment_DATE,
            payment_METHOD,
            payment_STATUS_ID,  -- Default to Pending (1)
            payment_AMOUNT,
            currency,
            transaction_ID,
            created_at,
            updated_at
        )
        VALUES (
            p_OrderID,
            SYSDATE,
            p_PaymentMethod,
            1,  -- Pending status
            p_PaymentAmount,
            p_Currency,
            p_TransactionID,
            SYSDATE,
            SYSDATE
        )
        RETURNING payment_ID INTO p_PaymentID;
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END sp_CreatePayment;
    
    -- Update Payment Status
    PROCEDURE sp_UpdatePaymentStatus(
        p_PaymentID IN NUMBER,
        p_NewStatusID IN NUMBER,
        p_TransactionID IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        UPDATE Payments
        SET 
            payment_STATUS_ID = p_NewStatusID,
            transaction_ID = NVL(p_TransactionID, transaction_ID),
            updated_at = SYSDATE
        WHERE 
            payment_ID = p_PaymentID;
        
        -- Note: Business logic for validation and order status updates 
        -- will be handled in the application
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END sp_UpdatePaymentStatus;
    
    -- Payment Status Transition Validation
    PROCEDURE sp_ValidatePaymentStatusTransition(
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
            PaymentStatusTransitions
        WHERE 
            from_status_ID = p_FromStatusID 
            AND to_status_ID = p_ToStatusID;
        
    EXCEPTION
        -- If no transition found, it's not allowed
        WHEN NO_DATA_FOUND THEN
            p_IsValid := 0;
            p_TransitionName := NULL;
    END sp_ValidatePaymentStatusTransition;
    
    -- Get Available Payment Status Transitions
    PROCEDURE sp_GetAvailablePaymentStatusTransitions(
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
            PaymentStatusTransitions t
        JOIN
            PaymentStatusTypes d ON t.to_status_ID = d.status_ID
        WHERE 
            t.from_status_ID = p_CurrentStatusID
            AND t.is_allowed = 1
        ORDER BY 
            d.display_ORDER;
            
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END sp_GetAvailablePaymentStatusTransitions;
    
END pkg_payment;
/

-- Grant execution privileges on the package
GRANT EXECUTE ON pkg_payment TO WINSTORE_APP;

-- Provide feedback on creation
BEGIN
    DBMS_OUTPUT.PUT_LINE('Payment procedures created successfully.');
END;
/
