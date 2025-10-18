# Руководство по стилю SQL для проекта WinStore

Это руководство определяет стандарты форматирования и написания SQL-кода для проекта WinStore. Соблюдение этих стандартов обеспечивает согласованность, читаемость и поддерживаемость всей кодовой базы SQL.

## Заголовки файлов

Каждый SQL-файл должен начинаться со стандартного заголовка:

```sql
-- =====================================================================
-- WinStore - [Название компонента]
-- =====================================================================
-- Description: [Краткое описание содержимого файла]
-- Author:      WinStore Development Team
-- Created:     [Дата создания в формате YYYY-MM-DD]
-- Modified:    [Дата последнего изменения в формате YYYY-MM-DD]
-- Version:     [Версия в формате X.Y.Z]
-- =====================================================================
-- Dependencies: [Список файлов, от которых зависит данный файл]
-- =====================================================================
```

## Именование объектов

### Таблицы
- **Имя**: Существительное во множественном числе с PascalCase (например, `Users`, `OrderItems`)
- **Первичный ключ**: `[сущность в единственном числе]_ID` (например, `user_ID`, `order_ID`)
- **Внешний ключ**: `[связанная сущность]_ID` (например, `category_ID` в таблице `Products`)

### Представления (Views)
- Префикс `view_` или `vw_` с описательным именем в нижнем регистре с подчеркиваниями (например, `view_gpu_details`, `vw_order_summary`)

### Хранимые процедуры
- Префикс `sp_` с глаголом и существительным в формате CamelCase (например, `sp_GetProductDetails`, `sp_CreateOrder`)

### Триггеры
- Префикс `TR_` с именем таблицы и действием (например, `TR_Products_UpdateTimestamp`)

### Индексы
- Префикс `IX_` с именем таблицы и столбцов (например, `IX_Products_CategoryID`, `IX_Orders_UserID_StatusID`)

### Ограничения (Constraints)
- **Первичный ключ**: `PK_[имя таблицы]` (например, `PK_Users`)
- **Внешний ключ**: `FK_[исходная таблица]_[целевая таблица]` (например, `FK_Products_Categories`)
- **Уникальный ключ**: `UQ_[имя таблицы]_[столбцы]` (например, `UQ_Users_Email`)
- **Проверка**: `CHK_[имя таблицы]_[условие]` (например, `CHK_Products_Price`)

## Форматирование SQL

### Отступы и выравнивание
- Используйте 4 пробела для отступов (не табуляции)
- Ключевые слова SQL пишите ПРОПИСНЫМИ буквами
- Поля и столбцы выравнивайте для лучшей читаемости

```sql
SELECT
    p.product_ID,
    p.product_NAME,
    c.category_NAME,
    v.ven_NAME AS vendor_name
FROM
    dbo.Products p
JOIN
    dbo.Categories c ON p.category_ID = c.category_ID
WHERE
    p.is_active = 1
    AND p.product_PRICE > 1000
ORDER BY
    p.product_NAME;
```

### Псевдонимы таблиц
- Используйте короткие, но понятные псевдонимы таблиц
- Предпочтительно использовать первую букву или несколько букв из имени таблицы
- Используйте AS для явного задания псевдонимов столбцов

```sql
SELECT 
    u.user_NAME AS UserName,
    o.order_DATE AS OrderDate,
    p.product_NAME AS ProductName
FROM 
    dbo.Users AS u
JOIN 
    dbo.Orders AS o ON u.user_ID = o.user_ID
JOIN 
    dbo.OrderItems AS oi ON o.order_ID = oi.order_ID
JOIN 
    dbo.Products AS p ON oi.product_ID = p.product_ID;
```

## Структура запросов

### SELECT запросы
- Каждое ключевое слово (SELECT, FROM, WHERE и т.д.) пишите на новой строке
- Столбцы и соединения располагайте на отдельных строках с отступом
- Условия в WHERE и HAVING пишите каждое с новой строки с отступом и операторами (AND, OR) в начале строки для лучшей видимости

### INSERT запросы
- Явно указывайте столбцы для вставки
- Выравнивайте значения для лучшей читаемости

```sql
INSERT INTO dbo.Users (
    user_NAME,
    user_PASS,
    user_EMAIL,
    user_PHONE,
    user_ROLE,
    created_AT
)
VALUES (
    @UserName,
    @UserPass,
    @UserEmail,
    @UserPhone,
    @UserRole,
    GETDATE()
);
```

### UPDATE запросы
- Выравнивайте значения столбцов для лучшей читаемости

```sql
UPDATE dbo.Products
SET 
    product_NAME = @ProductName,
    product_PRICE = @ProductPrice,
    updated_AT = GETDATE()
WHERE 
    product_ID = @ProductID;
```

### DELETE запросы
- Всегда указывайте условие WHERE (кроме случаев, когда нужно очистить всю таблицу)

```sql
DELETE FROM dbo.OrderItems
WHERE order_ID = @OrderID;
```

## Хранимые процедуры

### Структура процедуры
- Используйте `SET NOCOUNT ON;` в начале процедуры
- Используйте `SET XACT_ABORT ON;` для транзакций
- Всегда включайте блоки TRY-CATCH для обработки ошибок
- Правильно управляйте транзакциями (BEGIN/COMMIT/ROLLBACK)

```sql
CREATE OR ALTER PROCEDURE dbo.sp_ExampleProcedure
    @Param1 INT,
    @Param2 NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    -- Валидация параметров
    IF @Param1 IS NULL OR @Param1 <= 0
    BEGIN
        RAISERROR('Parameter @Param1 must be positive', 16, 1);
        RETURN;
    END
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Основная логика процедуры
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        -- Логирование ошибки
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
```

### Валидация параметров
- Всегда проверяйте входные параметры на NULL и валидность
- Используйте RAISERROR или THROW для генерации понятных ошибок

## Безопасность

### Схемы
- Всегда указывайте схему при обращении к объектам (`dbo.TableName`)

### Параметры
- Используйте параметризованные запросы для предотвращения SQL-инъекций
- Не используйте динамический SQL, если это не абсолютно необходимо

## Производительность

### Индексы
- Создавайте индексы для столбцов, используемых в JOIN, WHERE, ORDER BY
- Используйте покрывающие индексы для часто выполняемых запросов

### Транзакции
- Минимизируйте время жизни транзакций
- Не выполняйте длительные операции в рамках транзакций

## Комментарии и документация

### Блоки комментариев
- Используйте блоки комментариев для документирования секций кода

```sql
-- =====================================================================
-- Секция обработки заказов
-- =====================================================================
```

### Inline-комментарии
- Добавляйте комментарии для объяснения сложной логики
- Не добавляйте очевидные комментарии

## Проверка объектов

Всегда проверяйте существование объектов перед их созданием:

```sql
IF OBJECT_ID('dbo.TableName', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TableName (
        -- определение таблицы
    );
END
GO

IF OBJECT_ID('dbo.sp_ProcedureName', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ProcedureName;
GO
CREATE PROCEDURE dbo.sp_ProcedureName
    -- определение процедуры
GO
```

## Заключение

Соблюдение этих стандартов поможет поддерживать SQL код проекта WinStore в чистом, понятном и поддерживаемом состоянии. Стандарты разработаны с учетом принципов "Absurdly Ideal Code" и направлены на максимизацию простоты, надежности и производительности SQL кода.
