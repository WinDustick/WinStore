import requests
from bs4 import BeautifulSoup
import pyodbc
import time
import random

# Конфигурация БД
DB_CONFIG = {
    'driver': 'ODBC Driver 17 for SQL Server',
    'server': '172.28.112.114',
    'database': 'WinStore',
    'username': 'sa',
    'password': 'adilet_228'
}

# Конфигурация User-Agent
USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36'
]

MIN_DELAY = 4
MAX_DELAY = 8
MAX_RETRIES = 3

def get_db_connection():
    """Создает подключение к SQL Server"""
    connection = pyodbc.connect(
        f'DRIVER={DB_CONFIG["driver"]};'
        f'SERVER={DB_CONFIG["server"]};'
        f'DATABASE={DB_CONFIG["database"]};'
        f'UID={DB_CONFIG["username"]};'
        f'PWD={DB_CONFIG["password"]}'
    )
    return connection

def parse_cpu_data(url):
    """Парсит страницу CPU и возвращает данные"""
    try:
        headers = {
            'User-Agent': random.choice(USER_AGENTS)
        }
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Парсинг названия
        name = None
        og_title = soup.find('meta', property='og:title')
        if og_title:
            name = og_title['content'].strip()
        else:
            header = soup.find('h1', class_='prodheader')
            name = header.text.strip() if header else None
        
        # Парсинг характеристик
        all_data = {}
        details_sections = soup.find_all('section', class_='details')
        for section in details_sections:
            title_element = section.find('h1') or section.find('h2')
            section_title = title_element.text.strip() if title_element else "Untitled Section"
            
            # Парсинг таблиц
            table = section.find('table')
            if table and section_title != "Features":
                table_data = []
                tbody = table.find('tbody')
                if tbody:
                    rows = tbody.find_all('tr')
                else:
                    rows = table.find_all('tr')
                
                for row in rows:
                    th = row.find('th')
                    td = row.find('td')
                    if th and td:
                        key = th.text.strip().rstrip(':')
                        value = td.text.strip().replace('<br />', ' ')
                        table_data.append({key: value})
                
                if table_data:
                    all_data[section_title] = table_data
            
            # Парсинг раздела Features
            if section_title == "Features":
                features = []
                features_list = section.find('ul', class_='clearfix features')
                if features_list:
                    features = [li.text.strip() for li in features_list.find_all('li')]
                else:
                    features_table = section.find('table')
                    if features_table:
                        features = [row.find('td').text.strip() for row in features_table.find_all('tr')]
                all_data[section_title] = features
        
        return {
            'name': name,
            'specs': all_data
        }
    
    except Exception as e:
        print(f"Ошибка при парсинге {url}: {str(e)}")
        return None

def insert_cpu_product(connection, product_data):
    """Вставляет CPU в БД"""
    cursor = connection.cursor()
    
    # Проверка существования продукта
    cursor.execute("SELECT product_ID FROM Products WHERE product_NAME = ?", product_data['name'])
    existing_product = cursor.fetchone()
    
    if existing_product:
        product_id = existing_product[0]
        print(f"Продукт {product_data['name']} уже существует. ID: {product_id}")
    else:
        # Вставка продукта
        cursor.execute(
            """
            INSERT INTO Products (
                category_ID, 
                product_NAME, 
                product_DESCRIPT, 
                product_PRICE, 
                product_STOCK, 
                ven_ID
            )
            OUTPUT INSERTED.product_ID
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            2,  # category_ID для CPU
            product_data['name'],
            "CPU description",  # Добавьте описание
            0.0,  # product_PRICE
            20,    # product_STOCK
            3      # ven_ID
        )
        product_id = cursor.fetchone()[0]
    
    # Вставка атрибутов
    for section, data in product_data['specs'].items():
        if section == "Features":
            for feature in data:
                cursor.execute(
                    """
                    INSERT INTO Attributes (att_NAME)
                    SELECT ? 
                    WHERE NOT EXISTS (SELECT 1 FROM Attributes WHERE att_NAME = ?)
                    """,
                    feature, feature
                )
                cursor.execute("SELECT att_ID FROM Attributes WHERE att_NAME = ?", feature)
                att_id_row = cursor.fetchone()
                if att_id_row:
                    att_id = att_id_row[0]
                    cursor.execute(
                        """
                        INSERT INTO ProductAttributes (
                            att_ID, 
                            product_ID, 
                            nominal
                        )
                        VALUES (?, ?, ?)
                        """,
                        att_id,
                        product_id,
                        feature
                    )
        else:
            for row in data:
                for key, value in row.items():
                    attribute_name = key
                    attribute_value = value
                    
                    # Вставка атрибута
                    cursor.execute(
                        """
                        INSERT INTO Attributes (att_NAME)
                        SELECT ? 
                        WHERE NOT EXISTS (SELECT 1 FROM Attributes WHERE att_NAME = ?)
                        """,
                        attribute_name, attribute_name
                    )
                    cursor.execute("SELECT att_ID FROM Attributes WHERE att_NAME = ?", attribute_name)
                    att_id_row = cursor.fetchone()
                    if att_id_row:
                        att_id = att_id_row[0]
                    else:
                        continue
                    
                    # Разделение на nominal и unit_of_measurement
                    if ' ' in attribute_value:
                        nominal, unit = attribute_value.split(' ', 1)
                    else:
                        nominal = attribute_value
                        unit = None
                    
                    cursor.execute(
                        """
                        INSERT INTO ProductAttributes (
                            att_ID, 
                            product_ID, 
                            nominal, 
                            unit_of_measurement
                        )
                        VALUES (?, ?, ?, ?)
                        """,
                        att_id,
                        product_id,
                        nominal,
                        unit
                    )
    
    connection.commit()
    cursor.close()

def process_cpu_url(url, connection):
    """Обрабатывает URL CPU и вставляет данные в БД"""
    print(f"Обработка: {url}")
    time.sleep(random.uniform(MIN_DELAY, MAX_DELAY))
    
    data = parse_cpu_data(url)
    if not data:
        return
    
    try:
        insert_cpu_product(connection, data)
        print(f"Данные для {url} успешно вставлены!")
    except Exception as e:
        print(f"Ошибка при вставке {url}: {str(e)}")

def main():
    try:
        with open('F:/Aues/6 sem/ОБД/сpu_links_2022_Intel.txt', 'r') as f:
            urls = [line.strip() for line in f if line.strip()]
        
        connection = get_db_connection()
        
        for url in urls:
            process_cpu_url(url, connection)
        
        connection.close()
    
    except Exception as e:
        print(f"Критическая ошибка: {str(e)}")

if __name__ == "__main__":
    main()