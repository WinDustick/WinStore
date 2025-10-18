-- =====================================================================
-- WinStore - User Procedures (Oracle version)
-- =====================================================================
-- Description: Creates stored procedures for user management
-- Author:      WinStore Development Team
-- Created:     2025-05-25
-- Modified:    2025-10-02
-- Version:     1.0.0 (Oracle)
-- =====================================================================
-- Dependencies: 01_schema/01_core_schema.sql
-- =====================================================================

-- Create package for user related operations
CREATE OR REPLACE PACKAGE pkg_user AS
    -- Create User
    PROCEDURE sp_CreateUser(
        p_user_NAME IN VARCHAR2,
        p_user_EMAIL IN VARCHAR2,
        p_user_PHONE IN VARCHAR2,
        p_user_PASSWORD IN VARCHAR2,
        p_user_ID OUT NUMBER
    );
    
    -- Update User
    PROCEDURE sp_UpdateUser(
        p_user_ID IN NUMBER,
        p_user_NAME IN VARCHAR2,
        p_user_EMAIL IN VARCHAR2,
        p_user_PHONE IN VARCHAR2
    );
    
    -- Update User Password
    PROCEDURE sp_UpdateUserPassword(
        p_user_ID IN NUMBER,
        p_new_PASSWORD IN VARCHAR2
    );
    
    -- Delete User
    PROCEDURE sp_DeleteUser(
        p_user_ID IN NUMBER
    );
    
    -- Authenticate User
    PROCEDURE sp_AuthenticateUser(
        p_user_EMAIL IN VARCHAR2,
        p_user_PASSWORD IN VARCHAR2,
        p_cursor OUT SYS_REFCURSOR
    );
    
    -- Get User By ID
    PROCEDURE sp_GetUserByID(
        p_user_ID IN NUMBER,
        p_cursor OUT SYS_REFCURSOR
    );
    
    -- Get User By Email
    PROCEDURE sp_GetUserByEmail(
        p_user_EMAIL IN VARCHAR2,
        p_cursor OUT SYS_REFCURSOR
    );
    
    -- Search Users
    PROCEDURE sp_SearchUsers(
        p_search_TERM IN VARCHAR2,
        p_page_NUMBER IN NUMBER DEFAULT 1,
        p_page_SIZE IN NUMBER DEFAULT 20,
        p_cursor OUT SYS_REFCURSOR
    );
END pkg_user;
/

-- Create package body for user related operations
CREATE OR REPLACE PACKAGE BODY pkg_user AS
    -- Create User
    PROCEDURE sp_CreateUser(
        p_user_NAME IN VARCHAR2,
        p_user_EMAIL IN VARCHAR2,
        p_user_PHONE IN VARCHAR2,
        p_user_PASSWORD IN VARCHAR2,
        p_user_ID OUT NUMBER
    ) IS
        v_email_exists NUMBER;
    BEGIN
        -- Check if email already exists
        SELECT COUNT(*)
        INTO v_email_exists
        FROM Users
        WHERE UPPER(user_EMAIL) = UPPER(p_user_EMAIL);
        
        IF v_email_exists > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Email address already registered.');
        END IF;
        
        -- Insert the user record and get the ID from the trigger/sequence
        INSERT INTO Users (
            user_NAME,
            user_EMAIL,
            user_PHONE,
            user_PASS,
            user_ROLE,
            created_AT
        )
        VALUES (
            p_user_NAME,
            p_user_EMAIL,
            p_user_PHONE,
            p_user_PASSWORD,  -- In real app, hash this value
            'User', -- Default role
            SYSTIMESTAMP
        )
        RETURNING user_ID INTO p_user_ID;
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END sp_CreateUser;
    
    -- Update User
    PROCEDURE sp_UpdateUser(
        p_user_ID IN NUMBER,
        p_user_NAME IN VARCHAR2,
        p_user_EMAIL IN VARCHAR2,
        p_user_PHONE IN VARCHAR2
    ) IS
        v_email_exists NUMBER;
    BEGIN
        -- Check if email already exists for another user
        SELECT COUNT(*)
        INTO v_email_exists
        FROM Users
        WHERE UPPER(user_EMAIL) = UPPER(p_user_EMAIL)
        AND user_ID != p_user_ID;
        
        IF v_email_exists > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Email address already registered by another user.');
        END IF;
        
        UPDATE Users
        SET 
            user_NAME = p_user_NAME,
            user_EMAIL = p_user_EMAIL,
            user_PHONE = p_user_PHONE
        WHERE 
            user_ID = p_user_ID;
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END sp_UpdateUser;
    
    -- Update User Password
    PROCEDURE sp_UpdateUserPassword(
        p_user_ID IN NUMBER,
        p_new_PASSWORD IN VARCHAR2
    ) IS
    BEGIN
        UPDATE Users
        SET 
            user_PASS = p_new_PASSWORD  -- In real app, hash properly
        WHERE 
            user_ID = p_user_ID;
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END sp_UpdateUserPassword;
    
    -- Delete User
    PROCEDURE sp_DeleteUser(
        p_user_ID IN NUMBER
    ) IS
    BEGIN
        DELETE FROM Users
        WHERE user_ID = p_user_ID;
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END sp_DeleteUser;
    
    -- Authenticate User
    PROCEDURE sp_AuthenticateUser(
        p_user_EMAIL IN VARCHAR2,
        p_user_PASSWORD IN VARCHAR2,
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
        SELECT 
            user_ID,
            user_NAME,
            user_EMAIL,
            user_PHONE,
            user_ROLE,
            created_AT
        FROM 
            Users
        WHERE 
            UPPER(user_EMAIL) = UPPER(p_user_EMAIL)
            AND user_PASS = p_user_PASSWORD;
            
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END sp_AuthenticateUser;
    
    -- Get User By ID
    PROCEDURE sp_GetUserByID(
        p_user_ID IN NUMBER,
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
        SELECT 
            user_ID,
            user_NAME,
            user_EMAIL,
            user_PHONE,
            user_ROLE,
            created_AT
        FROM 
            Users
        WHERE 
            user_ID = p_user_ID;
            
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END sp_GetUserByID;
    
    -- Get User By Email
    PROCEDURE sp_GetUserByEmail(
        p_user_EMAIL IN VARCHAR2,
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
        SELECT 
            user_ID,
            user_NAME,
            user_EMAIL,
            user_PHONE,
            user_ROLE,
            created_AT
        FROM 
            Users
        WHERE 
            UPPER(user_EMAIL) = UPPER(p_user_EMAIL);
            
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END sp_GetUserByEmail;
    
    -- Search Users
    PROCEDURE sp_SearchUsers(
        p_search_TERM IN VARCHAR2,
        p_page_NUMBER IN NUMBER DEFAULT 1,
        p_page_SIZE IN NUMBER DEFAULT 20,
        p_cursor OUT SYS_REFCURSOR
    ) IS
        v_offset NUMBER := (p_page_NUMBER - 1) * p_page_SIZE;
    BEGIN
        OPEN p_cursor FOR
        SELECT * FROM (
            SELECT 
                user_ID,
                user_NAME,
                user_EMAIL,
                user_PHONE,
                user_ROLE,
                created_AT,
                ROW_NUMBER() OVER (ORDER BY user_NAME) AS row_num
            FROM 
                Users
            WHERE 
                p_search_TERM IS NULL
                OR UPPER(user_NAME) LIKE '%' || UPPER(p_search_TERM) || '%'
                OR UPPER(user_EMAIL) LIKE '%' || UPPER(p_search_TERM) || '%'
                OR user_PHONE LIKE '%' || p_search_TERM || '%'
        )
        WHERE row_num BETWEEN v_offset + 1 AND v_offset + p_page_SIZE;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END sp_SearchUsers;
    
END pkg_user;
/

-- Grant execution privileges on the package
GRANT EXECUTE ON pkg_user TO WINSTORE_APP;

-- Provide feedback on creation
BEGIN
    DBMS_OUTPUT.PUT_LINE('User procedures created successfully.');
END;
/
