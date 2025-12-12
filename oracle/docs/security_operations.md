# Руководство по эксплуатации подсистемы аудита и безопасности

## 1\. Обзор архитектуры аудита

Система WinStore реализует двухуровневую модель аудита для обеспечения как бизнес-прозрачности, так и технической безопасности.

1.  **Бизнес-аудит (Application-Level Audit):**

      * **Реализация:** Таблица `BusinessAuditLog` и триггеры `TRG_AUDIT_*`.
      * **Цель:** Отслеживание изменений данных (INSERT, UPDATE, DELETE) в контексте бизнес-логики (заказы, платежи).
      * **Доступность:** Работает во всех редакциях Oracle (XE/SE/EE).

2.  **Унифицированный аудит (Unified Auditing):**

      * **Реализация:** Политики Oracle Unified Audit (`WINSTORE_UNIFIED_AUDIT_POLICY`).
      * **Цель:** Отслеживание системных событий, DDL-операций, попыток несанкционированного доступа и изменений структуры БД.
      * **Ограничение:** Полная функциональность требует редакции Enterprise Edition (EE). В редакции XE (текущая среда) работает в режиме совместимости (Mixed Mode) или ограничена.

-----

## 2\. Интерпретация логов аудита

### 2.1. Таблица BusinessAuditLog

Основной журнал для анализа действий пользователей и истории изменений сущностей.

**Схема данных:**

| Поле | Тип данных | Описание и назначение |
| :--- | :--- | :--- |
| `audit_ID` | NUMBER | Уникальный идентификатор записи журнала (Sequence). |
| `audit_timestamp` | TIMESTAMP | Точное время события (серверное время UTC/Local). |
| `table_name` | NVARCHAR2 | Имя затронутой таблицы (например, `ORDERS`, `PAYMENTS`). |
| `operation` | NVARCHAR2 | Тип операции: `INSERT`, `UPDATE`, `DELETE`. |
| `record_ID` | NVARCHAR2 | Первичный ключ (ID) измененной записи. |
| `user_ID` | NUMBER | **ID пользователя приложения** (из таблицы `Users`). NULL для системных действий. |
| `username` | NVARCHAR2 | **Логин пользователя БД** (например, `WINSTORE_APP`). |
| `column_name` | NVARCHAR2 | Имя измененной колонки (заполняется только при `UPDATE`). |
| `old_value` | NCLOB | Значение *до* изменения (NULL для `INSERT`). |
| `new_value` | NCLOB | Значение *после* изменения (NULL для `DELETE`). |
| `business_context` | NVARCHAR2 | Описание контекста (например, "Order status change"). |
| `ip_address` | NVARCHAR2 | IP-адрес клиента, инициировавшего транзакцию. |

### 2.2. Идентификация источника действия

Для различения действий реального пользователя, приложения и администратора используется комбинация полей `user_ID` и `username`.

| Тип субъекта | `user_ID` | `username` | Описание |
| :--- | :--- | :--- | :--- |
| **Конечный пользователь** | `NOT NULL` (например, 105) | `WINSTORE_APP` | Действие совершено через веб-интерфейс авторизованным клиентом. |
| **Анонимный пользователь** | `NULL` | `WINSTORE_APP` | Действие совершено через приложение, но без авторизации (например, регистрация). |
| **Администратор БД** | `NULL` | `WINSTORE_ADMIN` | Прямое вмешательство в БД через SQL-консоль. |
| **Системный процесс** | `NULL` | `SYS` / `SYSTEM` | Фоновые процессы или регламентные работы. |

### 2.3. Unified Audit Trail (Системный уровень)

Для анализа DDL операций (создание/удаление таблиц) и ошибок доступа используется системное представление `UNIFIED_AUDIT_TRAIL`.

**Ключевые поля для мониторинга:**

  * `EVENT_TIMESTAMP`: Время события.
  * `DBUSERNAME`: Пользователь БД.
  * `ACTION_NAME`: Выполненная команда (например, `DROP TABLE`, `ALTER USER`).
  * `OBJECT_NAME`: Имя затронутого объекта.
  * `RETURN_CODE`: Код завершения (`0` — успех, остальные — коды ошибок, например, `ORA-01017` при неверном пароле).

-----

## 3\. Политика хранения и очистки (Retention Policy)

В связи с быстрым ростом объема логов (особенно `BusinessAuditLog` с полями `NCLOB`), применяется следующая политика удержания данных.

### 3.1. Стандарты хранения

  * **Оперативные данные (Hot Data):** 90 дней. Хранятся в основной таблице для быстрого доступа и поддержки клиентов.
  * **Архивные данные (Cold Data):** От 90 дней до 3 лет. Должны быть выгружены (Data Pump Export) и сохранены на внешнем носителе перед удалением.
  * **Удаление:** Данные старше установленного срока подлежат физическому удалению.

### 3.2. Регламент очистки (Maintenance Procedure)

Для автоматической очистки таблицы `BusinessAuditLog` используется процедура `sp_PurgeAuditLog`.

**Алгоритм ручной очистки (при отсутствии автоматизации Job):**

```sql
-- Очистка записей старше 90 дней
BEGIN
  -- Шаг 1: Удаление
  DELETE FROM BusinessAuditLog 
  WHERE audit_timestamp < SYSTIMESTAMP - 90;
  
  -- Шаг 2: Фиксация транзакции
  COMMIT;
  
  -- Шаг 3: (Опционально) Освобождение пространства
  -- Требует прав администратора и блокировки таблицы
  -- EXECUTE IMMEDIATE 'ALTER TABLE BusinessAuditLog ENABLE ROW MOVEMENT';
  -- EXECUTE IMMEDIATE 'ALTER TABLE BusinessAuditLog SHRINK SPACE';
END;
/
```

*Примечание: В промышленной среде (EE) рекомендуется использовать механизм Partitioning (Range Partitioning по `audit_timestamp`) для мгновенного удаления старых данных через `DROP PARTITION`.*

-----

## 4\. Матрица управления доступом (RBAC)

Система безопасности WinStore построена на ролевой модели доступа (Role-Based Access Control). Прямая выдача грантов пользователям запрещена; права назначаются только через роли.

### 4.1. Роли базы данных

| Роль | Назначение | Уровень доступа |
| :--- | :--- | :--- |
| `WINSTORE_ADMIN_ROLE` | Полное администрирование схемы. Владелец объектов. | **DDL:** Full<br>**DML:** Full<br>**Exec:** All Procedures |
| `WINSTORE_APP_ROLE` | Роль для подключения бэкенд-приложения. | **DDL:** None<br>**DML:** CRUD (Orders, Users, Wishlist, Reviews), Read-Only (Products, Categories)<br>**Exec:** Public Packages (`pkg_order`, `pkg_auth`) |
| `WINSTORE_MANAGER_ROLE` | Роль для сотрудников управления контентом. | **DDL:** None<br>**DML:** CRUD (Products, Categories, Vendors)<br>**Read:** Orders, Users |
| `WINSTORE_READONLY_ROLE` | Аудиторы, аналитики, BI-системы. | **DDL:** None<br>**DML:** None<br>**Read:** SELECT on all tables/views |

### 4.2. Детальная матрица прав (Permission Mapping)

| Объект БД | Тип | APP\_ROLE | MANAGER\_ROLE | READONLY\_ROLE |
| :--- | :--- | :--- | :--- | :--- |
| `Orders` | Table | INSERT, UPDATE (Status only) | SELECT | SELECT |
| `Products` | Table | SELECT | INSERT, UPDATE | SELECT |
| `Users` | Table | INSERT, UPDATE (Self) | SELECT (No Auth Data) | SELECT (No Auth Data) |
| `BusinessAuditLog` | Table | INSERT (via API) | SELECT | SELECT |
| `pkg_order` | Package | EXECUTE | EXECUTE | - |
| `pkg_product` | Package | EXECUTE | EXECUTE | - |
| `pkg_admin` | Package | - | EXECUTE | - |
| `vw_ProductSummary` | View | SELECT | SELECT | SELECT |

### 4.3. Управление пользователями

Создание новых пользователей и назначение ролей выполняется администратором через скрипт `oracle/01_schema/05_users.sql` или вручную:

```sql
-- Пример создания аналитика
CREATE USER analyst_john IDENTIFIED BY "SecureP@ss123";
GRANT CREATE SESSION TO analyst_john;
GRANT WINSTORE_READONLY_ROLE TO analyst_john;
```

-----

## 5\. Прозрачное шифрование данных (TDE)

В проекте предусмотрена конфигурация TDE (`oracle/07_security/01_tde_setup.sql`) для шифрования табличных пространств (Tablespace Encryption).

  * **Цель:** Защита файлов данных (`.dbf`) от чтения в случае кражи физического носителя.
  * **Статус в XE:** Oracle XE имеет ограничения на использование расширенных опций безопасности. Скрипты настройки TDE являются эталонными (Reference Implementation) и активны только при наличии лицензии Oracle Advanced Security.
  * **Проверка статуса:**
    ```sql
    SELECT * FROM V$ENCRYPTED_TABLESPACES;
    ```