import pyodbc
import os
import random
from datetime import datetime, timedelta
import hashlib
import uuid

# Function to hash passwords
def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

# Database connection configuration
SERVER = os.environ.get('DB_SERVER', 'localhost')
DATABASE = os.environ.get('DB_NAME', 'WinStore')
USERNAME = os.environ.get('DB_USER', 'sa')
PASSWORD = os.environ.get('DB_PASSWORD', 'Sq1_53rv3r')

# Connect to database
conn_string = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};UID={USERNAME};PWD={PASSWORD}'

try:
    conn = pyodbc.connect(conn_string)
    cursor = conn.cursor()
    print("Connected to the database successfully")

    # Insert sample data

    # 1. Categories
    categories = [
        (1, 'GPU', 'Graphics Processing Units'),
        (2, 'CPU', 'Central Processing Units'),
        (3, 'Motherboards', 'Computer Motherboards'),
        (4, 'RAM', 'Random Access Memory'),
        (5, 'Storage', 'SSDs and HDDs'),
        (6, 'PSU', 'Power Supply Units'),
        (7, 'Cases', 'Computer Cases'),
        (8, 'Cooling', 'CPU and System Cooling')
    ]
    
    for cat_id, cat_name, cat_desc in categories:
        cursor.execute("""
        IF NOT EXISTS (SELECT 1 FROM Categories WHERE category_ID = ?)
        BEGIN
            SET IDENTITY_INSERT Categories ON;
            INSERT INTO Categories (category_ID, category_NAME, category_DESCRIPT)
            VALUES (?, ?, ?);
            SET IDENTITY_INSERT Categories OFF;
        END
        """, cat_id, cat_id, cat_name, cat_desc)

    # 2. Vendors
    vendors = [
        (1, 'NVIDIA', 'USA', 'Graphics and AI computing company'),
        (2, 'AMD', 'USA', 'Semiconductor company'),
        (3, 'Intel', 'USA', 'Semiconductor chip manufacturer'),
        (4, 'ASUS', 'Taiwan', 'Computer and phone hardware company'),
        (5, 'MSI', 'Taiwan', 'Computer hardware company'),
        (6, 'Gigabyte', 'Taiwan', 'Computer hardware manufacturer'),
        (7, 'Corsair', 'USA', 'Computer peripherals and hardware'),
        (8, 'Kingston', 'USA', 'Memory and storage products'),
        (9, 'Western Digital', 'USA', 'Data storage company'),
        (10, 'Samsung', 'South Korea', 'Electronics company')
    ]
    
    for ven_id, ven_name, ven_country, ven_desc in vendors:
        cursor.execute("""
        IF NOT EXISTS (SELECT 1 FROM Vendors WHERE ven_ID = ?)
        BEGIN
            SET IDENTITY_INSERT Vendors ON;
            INSERT INTO Vendors (ven_ID, ven_NAME, ven_COUNTRY, ven_DESCRIPT)
            VALUES (?, ?, ?, ?);
            SET IDENTITY_INSERT Vendors OFF;
        END
        """, ven_id, ven_id, ven_name, ven_country, ven_desc)

    # 3. Users
    users = [
        ('admin', hash_password('admin123'), 'admin@winstore.com', '+1234567890', 'Admin'),
        ('manager', hash_password('manager123'), 'manager@winstore.com', '+1987654321', 'Vendor'),
        ('customer1', hash_password('customer123'), 'customer1@example.com', '+7777777777', 'Customer'),
        ('customer2', hash_password('customer456'), 'customer2@example.com', '+8888888888', 'Customer')
    ]
    
    for username, pwd, email, phone, role in users:
        cursor.execute("""
        IF NOT EXISTS (SELECT 1 FROM Users WHERE user_EMAIL = ?)
        INSERT INTO Users (user_NAME, user_PASS, user_EMAIL, user_PHONE, user_ROLE)
        VALUES (?, ?, ?, ?, ?)
        """, email, username, pwd, email, phone, role)

    # 4. Attributes
    gpu_attributes = [
        'GPU Name', 'Architecture', 'Foundry', 'Process Size', 'Transistors', 
        'Die Size', 'Release Date', 'Generation', 'Launch Price', 'GPU Clock', 
        'Memory Clock', 'Memory Size', 'Memory Type', 'Memory Bus', 'Bandwidth', 
        'Shading Units', 'TMUs', 'ROPs', 'RT Cores', 'Tensor Cores', 'TDP', 
        'Outputs', 'DirectX', 'OpenGL', 'Vulkan', 'Shader Model', 
        'Bus Interface', 'Power Connectors', 'Suggested PSU'
    ]
    
    cpu_attributes = [
        'Codename', 'Architecture', 'Foundry', 'Process Size', 'Transistors', 
        'Die Size', 'Release Date', 'Generation', 'Launch Price', '# of Cores', 
        '# of Threads', 'Base Clock', 'Boost Clock', 'Cache L1', 'Cache L2', 
        'Cache L3', 'TDP', 'Socket', 'Integrated Graphics', 'Memory Support', 
        'PCI-Express', 'Multiplier Unlocked', 'SMT', 'SSE4.2', 'AVX2', 
        'AES', 'AMD-V', 'VT-x'
    ]
    
    ram_attributes = [
        'Memory Type', 'Speed (MT/s)', 'Timings', 'Voltage (V)', 
        'Capacity (GB)', 'Profile Type'
    ]
    
    # Combine all attributes
    all_attributes = list(set(gpu_attributes + cpu_attributes + ram_attributes))
    
    for att_name in all_attributes:
        cursor.execute("""
        IF NOT EXISTS (SELECT 1 FROM Attributes WHERE att_NAME = ?)
        INSERT INTO Attributes (att_NAME)
        VALUES (?)
        """, att_name, att_name)

    # 5. Sample Products
    # GPUs
    gpu_products = [
        (1, 'NVIDIA GeForce RTX 4090', 'NVIDIA\'s flagship gaming GPU with DLSS 3.0 and ray tracing', 1599.99, 15, 1),
        (1, 'NVIDIA GeForce RTX 4080', 'High-end gaming GPU with excellent performance', 1199.99, 25, 1),
        (1, 'NVIDIA GeForce RTX 4070 Ti', 'Great 1440p and entry 4K gaming performance', 799.99, 30, 1),
        (1, 'AMD Radeon RX 7900 XTX', 'AMD\'s flagship GPU with RDNA 3 architecture', 999.99, 20, 2),
        (1, 'AMD Radeon RX 7900 XT', 'High-performance GPU with great price/performance', 899.99, 25, 2),
        (1, 'AMD Radeon RX 7800 XT', 'Excellent 1440p gaming performance', 499.99, 35, 2)
    ]
    
    for cat_id, name, desc, price, stock, ven_id in gpu_products:
        cursor.execute("""
        IF NOT EXISTS (SELECT 1 FROM Products WHERE product_NAME = ?)
        INSERT INTO Products (category_ID, product_NAME, product_DESCRIPT, product_PRICE, product_STOCK, ven_ID)
        VALUES (?, ?, ?, ?, ?, ?)
        """, name, cat_id, name, desc, price, stock, ven_id)
    
    # CPUs
    cpu_products = [
        (2, 'Intel Core i9-13900K', '24-core (8P+16E) flagship CPU with high performance', 589.99, 20, 3),
        (2, 'Intel Core i7-13700K', '16-core (8P+8E) CPU with great gaming performance', 409.99, 30, 3),
        (2, 'Intel Core i5-13600K', '14-core (6P+8E) CPU with excellent price/performance', 319.99, 40, 3),
        (2, 'AMD Ryzen 9 7950X', '16-core, 32-thread flagship CPU with high multicore performance', 699.99, 15, 2),
        (2, 'AMD Ryzen 7 7700X', '8-core, 16-thread CPU with great gaming performance', 399.99, 25, 2),
        (2, 'AMD Ryzen 5 7600X', '6-core, 12-thread CPU with excellent value', 299.99, 35, 2)
    ]
    
    for cat_id, name, desc, price, stock, ven_id in cpu_products:
        cursor.execute("""
        IF NOT EXISTS (SELECT 1 FROM Products WHERE product_NAME = ?)
        INSERT INTO Products (category_ID, product_NAME, product_DESCRIPT, product_PRICE, product_STOCK, ven_ID)
        VALUES (?, ?, ?, ?, ?, ?)
        """, name, cat_id, name, desc, price, stock, ven_id)
    
    # RAM
    ram_products = [
        (4, 'Corsair Vengeance RGB DDR5-6000 32GB', 'High-performance DDR5 memory with RGB lighting', 159.99, 40, 7),
        (4, 'G.Skill Trident Z5 RGB DDR5-6400 32GB', 'Premium DDR5 memory with tight timings', 189.99, 25, 6),
        (4, 'Kingston Fury Beast DDR5-5200 64GB', 'High-capacity DDR5 memory kit', 279.99, 15, 8),
        (4, 'Corsair Vengeance LPX DDR4-3600 32GB', 'Reliable DDR4 memory with good performance', 99.99, 50, 7),
        (4, 'G.Skill Ripjaws V DDR4-3200 16GB', 'Value DDR4 memory with solid performance', 54.99, 60, 6)
    ]
    
    for cat_id, name, desc, price, stock, ven_id in ram_products:
        cursor.execute("""
        IF NOT EXISTS (SELECT 1 FROM Products WHERE product_NAME = ?)
        INSERT INTO Products (category_ID, product_NAME, product_DESCRIPT, product_PRICE, product_STOCK, ven_ID)
        VALUES (?, ?, ?, ?, ?, ?)
        """, name, cat_id, name, desc, price, stock, ven_id)

    # 6. Product Attributes
    # First, get product IDs for each product we inserted
    cursor.execute("SELECT product_ID, product_NAME, category_ID FROM Products")
    products = cursor.fetchall()
    
    # Get attribute IDs
    cursor.execute("SELECT att_ID, att_NAME FROM Attributes")
    attributes = {att_name: att_id for att_id, att_name in cursor.fetchall()}
    
    # Sample attribute values for GPUs
    gpu_attribute_values = {
        'NVIDIA GeForce RTX 4090': {
            'GPU Name': 'AD102',
            'Architecture': 'Ada Lovelace',
            'Process Size': '4 nm',
            'Memory Size': '24 GB',
            'Memory Type': 'GDDR6X',
            'Memory Bus': '384 bit',
            'TDP': '450W'
        },
        'AMD Radeon RX 7900 XTX': {
            'GPU Name': 'Navi 31',
            'Architecture': 'RDNA 3',
            'Process Size': '5 nm',
            'Memory Size': '24 GB',
            'Memory Type': 'GDDR6',
            'Memory Bus': '384 bit',
            'TDP': '355W'
        }
    }
    
    # Sample attribute values for CPUs
    cpu_attribute_values = {
        'Intel Core i9-13900K': {
            'Architecture': 'Raptor Lake',
            'Process Size': '10 nm',
            '# of Cores': '24',
            '# of Threads': '32',
            'Base Clock': '3.0 GHz',
            'Boost Clock': '5.8 GHz',
            'TDP': '125W',
            'Socket': 'LGA 1700'
        },
        'AMD Ryzen 9 7950X': {
            'Architecture': 'Zen 4',
            'Process Size': '5 nm',
            '# of Cores': '16',
            '# of Threads': '32',
            'Base Clock': '4.5 GHz',
            'Boost Clock': '5.7 GHz',
            'TDP': '170W',
            'Socket': 'AM5'
        }
    }
    
    # Sample attribute values for RAM
    ram_attribute_values = {
        'Corsair Vengeance RGB DDR5-6000 32GB': {
            'Memory Type': 'DDR5',
            'Speed (MT/s)': '6000',
            'Capacity (GB)': '32',
            'Timings': '36-36-36-76',
            'Voltage (V)': '1.35'
        },
        'Corsair Vengeance LPX DDR4-3600 32GB': {
            'Memory Type': 'DDR4',
            'Speed (MT/s)': '3600',
            'Capacity (GB)': '32',
            'Timings': '18-22-22-42',
            'Voltage (V)': '1.35'
        }
    }
    
    # Combine all attribute values
    all_attribute_values = {}
    all_attribute_values.update(gpu_attribute_values)
    all_attribute_values.update(cpu_attribute_values)
    all_attribute_values.update(ram_attribute_values)
    
    # Insert attribute values for products
    for product_id, product_name, category_id in products:
        if product_name in all_attribute_values:
            for att_name, att_value in all_attribute_values[product_name].items():
                if att_name in attributes:
                    cursor.execute("""
                    IF NOT EXISTS (SELECT 1 FROM ProductAttributes WHERE product_ID = ? AND att_ID = ?)
                    INSERT INTO ProductAttributes (product_ID, att_ID, nominal)
                    VALUES (?, ?, ?)
                    """, product_id, attributes[att_name], product_id, attributes[att_name], att_value)

    # 7. Sample Orders and OrderItems
    # Get user IDs for customers
    cursor.execute("SELECT user_ID FROM Users WHERE user_ROLE = 'Customer'")
    customer_ids = [row[0] for row in cursor.fetchall()]
    
    if customer_ids:
        # Create sample orders
        for customer_id in customer_ids:
            # Create a completed order for each customer
            order_date = datetime.now() - timedelta(days=random.randint(1, 30))
            
            cursor.execute("""
            INSERT INTO Orders (user_ID, order_DATE, order_STATUS, order_AMOUNT)
            VALUES (?, ?, ?, ?)
            """, customer_id, order_date, 'Delivered', 0)  # Amount will be updated by trigger
            
            order_id = cursor.execute("SELECT @@IDENTITY").fetchval()
            
            # Add 2-4 random products to each order
            product_count = random.randint(2, 4)
            cursor.execute("SELECT TOP (?) product_ID, product_PRICE FROM Products ORDER BY NEWID()", product_count)
            order_products = cursor.fetchall()
            
            for product_id, price in order_products:
                quantity = random.randint(1, 2)
                cursor.execute("""
                INSERT INTO OrderItems (order_ID, product_ID, quantity, price)
                VALUES (?, ?, ?, ?)
                """, order_id, product_id, quantity, price)
                
                # The order amount will be updated automatically by the trigger
                
                # Get the OrderItems_ID for delivery
                order_item_id = cursor.execute("SELECT @@IDENTITY").fetchval()
                
                # Add delivery information
                ship_date = order_date + timedelta(days=1)
                delivery_date = ship_date + timedelta(days=2)
                
                cursor.execute("""
                INSERT INTO Delivery (OrderItems_ID, delivery_ADDRESS, delivery_DATE, shipped_DATE, delivery_STATUS, delivery_NAME)
                VALUES (?, ?, ?, ?, ?, ?)
                """, order_item_id, '123 Customer St, City', delivery_date, ship_date, 'Delivered', 'Fast Shipping')
            
            # Add payment information
            cursor.execute("SELECT order_AMOUNT FROM Orders WHERE order_ID = ?", order_id)
            order_amount = cursor.fetchval()
            
            cursor.execute("""
            INSERT INTO Payments (order_ID, user_ID, payment_DATE, payment_METHOD, payment_STATUS, payment_AMOUNT, currency, transaction_ID)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, order_id, customer_id, order_date, 'Credit Card', 'Completed', order_amount, 'USD', str(uuid.uuid4()))
            
            # Create a cart (pending order) for each customer
            cursor.execute("""
            INSERT INTO Orders (user_ID, order_STATUS, order_AMOUNT)
            VALUES (?, ?, ?)
            """, customer_id, 'Cart', 0)
            
            cart_id = cursor.execute("SELECT @@IDENTITY").fetchval()
            
            # Add 1-2 random products to each cart
            cart_product_count = random.randint(1, 2)
            cursor.execute("SELECT TOP (?) product_ID, product_PRICE FROM Products ORDER BY NEWID()", cart_product_count)
            cart_products = cursor.fetchall()
            
            for product_id, price in cart_products:
                quantity = random.randint(1, 2)
                cursor.execute("""
                INSERT INTO OrderItems (order_ID, product_ID, quantity, price)
                VALUES (?, ?, ?, ?)
                """, cart_id, product_id, quantity, price)
                # The cart amount will be updated automatically by the trigger

    # 8. Sample Reviews
    # Add reviews for some products
    if customer_ids:
        cursor.execute("SELECT product_ID FROM Products")
        product_ids = [row[0] for row in cursor.fetchall()]
        
        for i in range(min(20, len(product_ids))):
            product_id = random.choice(product_ids)
            user_id = random.choice(customer_ids)
            rating = random.randint(3, 5)  # Mostly positive reviews
            review_date = datetime.now() - timedelta(days=random.randint(1, 60))
            
            # Check if this user already reviewed this product
            cursor.execute("""
            IF NOT EXISTS (SELECT 1 FROM Review WHERE user_ID = ? AND product_ID = ?)
            INSERT INTO Review (user_ID, product_ID, rew_RATING, rew_DATE, rew_COMMENT)
            VALUES (?, ?, ?, ?, ?)
            """, user_id, product_id, user_id, product_id, rating, review_date, f"This is a sample review with {rating} stars.")

    # Commit all changes
    conn.commit()
    print("Sample data inserted successfully!")

except Exception as e:
    print(f"Error: {e}")
finally:
    # Close the connection
    if 'conn' in locals():
        conn.close()
        print("Database connection closed")
