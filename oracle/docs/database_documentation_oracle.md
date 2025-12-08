# WinStore: Oracle Database Documentation

Версия: 2025-10-01

## Цель и философия

Этот документ — единственный источник истины по Oracle-схеме WinStore. Он самодостаточен и лаконичен, следует принципам AIC (Absurdly Ideal Code):
- Максимальная простота (KISS)
- Экстремальная надёжность (чёткие ограничения, предсказуемые ошибки)
- Пиковая производительность (правильные типы, индексы, минимальные триггеры)

## Область

Описывает только Oracle-реализацию: типы данных, таблицы, ключи, индексы, представления/MV, последовательности/триггеры, статусы и развёртывание. Никаких ссылок на другие СУБД.

## Ключевые свойства Oracle-схемы

- Типы: NVARCHAR2/NCHAR, NUMBER, TIMESTAMP, NCLOB
- Авто-ID: SEQUENCE `SEQ_*` + триггеры `TRG_*_BI` (BEFORE INSERT)
- EAV-хранилище характеристик: `ProductAttributes`
- Большие тексты (NCLOB): для выборок по части — `DBMS_LOB.SUBSTR`
- Материализованные представления для сводных данных

## Схема данных (сводка)

- Users
  - PK: user_ID (NUMBER, авто через TRG_USERS_BI/SEQ_USERS_ID)
  - user_NAME NVARCHAR2(50), user_PASS NVARCHAR2(255), user_EMAIL NVARCHAR2(100) UNIQUE, user_PHONE NVARCHAR2(20)
  - user_ROLE NVARCHAR2(50) CHECK in ('Admin','Customer','Vendor')
  - created_AT TIMESTAMP, last_login TIMESTAMP NULL

- Categories
  - PK: category_ID; category_NAME UNIQUE; category_DESCRIPT NVARCHAR2(500)

- Vendors
  - PK: ven_ID; ven_NAME; ven_COUNTRY; ven_DESCRIPT NVARCHAR2(500)

- Attributes
  - PK: att_ID; att_NAME NVARCHAR2(255) UNIQUE

- Products
  - PK: product_ID; FK: category_ID -> Categories, ven_ID -> Vendors
  - product_NAME NVARCHAR2(255), product_DESCRIPT NCLOB, product_PRICE NUMBER(10,2) CHECK >= 0
  - product_STOCK NUMBER CHECK >= 0, created_AT, updated_AT TIMESTAMP
  - is_featured NUMBER(1) default 0, is_active NUMBER(1) default 1

- ProductMedia
  - PK: media_ID; FK: product_ID -> Products ON DELETE CASCADE
  - media_URL NVARCHAR2(1000), media_TYPE NVARCHAR2(50) default 'image'
  - is_primary NUMBER(1) default 0, display_order NUMBER default 0, alt_text NVARCHAR2(255)

- ProductAttributes (EAV)
  - PK: (att_ID, product_ID)
  - FK: att_ID -> Attributes ON DELETE CASCADE, product_ID -> Products ON DELETE CASCADE
  - nominal NCLOB NOT NULL, unit_of_measurement NVARCHAR2(100) NULL

- Wishlist
  - PK: wishlist_ID; FK: user_ID -> Users ON DELETE CASCADE, product_ID -> Products ON DELETE CASCADE
  - UQ: (user_ID, product_ID)

- Promotions
  - PK: promo_ID; promo_CODE UNIQUE; promo_NAME; promo_DESCRIPT
  - discount_TYPE CHECK in ('percentage','fixed','shipping'); discount_VALUE NUMBER(10,2) CHECK >= 0
  - min_purchase NUMBER(10,2) default 0
  - valid_FROM/valid_TO TIMESTAMP; CHK(valid_TO > valid_FROM)
  - max_USES NUMBER NULL, current_USES NUMBER default 0, is_ACTIVE NUMBER(1) default 1
  - created_AT TIMESTAMP, created_BY -> Users(user_ID) ON DELETE SET NULL

- PromotionApplications
  - PK: app_ID; FK: promo_ID -> Promotions ON DELETE CASCADE
  - target_TYPE CHECK in ('product','category','all'); target_ID NUMBER NULL
  - UQ: (promo_ID, target_TYPE, target_ID)

- Orders
  - PK: order_ID; FK: user_ID -> Users; promo_ID -> Promotions
  - order_DATE TIMESTAMP, order_STATUS_ID NUMBER NULL
  - order_AMOUNT NUMBER(10,2) CHECK >= 0, promo_SAVINGS NUMBER(10,2) default 0
  - Доставка: delivery_ADDRESS, shipped_DATE, estimated_delivery_DATE, actual_delivery_DATE,
    delivery_STATUS_ID NUMBER NULL, shipping_carrier_NAME, tracking_NUMBER
  - UQ: (order_ID, user_ID)

- OrderItems
  - PK: OrderItems_ID; FK: order_ID -> Orders ON DELETE CASCADE, product_ID -> Products
  - quantity NUMBER CHECK > 0; price NUMBER(10,2) CHECK >= 0

- Payments
  - PK: payment_ID; FK: order_ID -> Orders
  - payment_DATE TIMESTAMP, payment_METHOD NVARCHAR2(50)
  - payment_STATUS_ID NUMBER NULL, payment_AMOUNT NUMBER(10,2), currency NCHAR(3) CHECK LENGTH=3
  - transaction_ID NVARCHAR2(100) UNIQUE
  - created_at TIMESTAMP, updated_at TIMESTAMP

- Review
  - PK: rew_ID; FK: user_ID -> Users ON DELETE CASCADE, product_ID -> Products ON DELETE CASCADE
  - rew_RATING NUMBER CHECK 1..5; rew_COMMENT NVARCHAR2(1000); rew_DATE TIMESTAMP
  - UQ: (user_ID, product_ID)

## Статусы и переходы

- Справочники: OrderStatusTypes, PaymentStatusTypes, DeliveryStatusTypes (создаются в 02_reference_data.sql).
- Таблицы переходов: OrderStatusTransitions, PaymentStatusTransitions, DeliveryStatusTransitions (03_status_transitions.sql).
- Хелперы: функции `get_order_status_id`, `get_payment_status_id`, `get_delivery_status_id`.

## Последовательности и триггеры

- Последовательности `SEQ_*_ID` для каждой таблицы с PK NUMBER:
  - SEQ_USERS_ID, SEQ_CATEGORIES_ID, SEQ_VENDORS_ID, SEQ_ATTRIBUTES_ID,
    SEQ_PRODUCTS_ID, SEQ_PRODUCTMEDIA_ID, SEQ_WISHLIST_ID, SEQ_PROMOTIONS_ID,
    SEQ_PROMOTIONAPPS_ID, SEQ_ORDERS_ID, SEQ_ORDERITEMS_ID, SEQ_PAYMENTS_ID, SEQ_REVIEWS_ID,
    SEQ_ORDERSTATUSTYPES_ID, SEQ_PAYMENTSTATUSTYPES_ID, SEQ_DELIVERYSTATUSTYPES_ID,
    SEQ_BUSINESSAUDITLOG_ID
- BEFORE INSERT триггеры `TRG_*_BI` устанавливают ID из соответствующей последовательности:
  - TRG_USERS_BI, TRG_CATEGORIES_BI, TRG_VENDORS_BI, TRG_ATTRIBUTES_BI,
    TRG_PRODUCTS_BI, TRG_PRODUCTMEDIA_BI, TRG_WISHLIST_BI, TRG_PROMOTIONS_BI,
    TRG_PROMOTIONAPPS_BI, TRG_ORDERS_BI, TRG_ORDERITEMS_BI, TRG_PAYMENTS_BI, TRG_REVIEWS_BI

## Представления и MVs

- Представления:
  - view_gpu_details, view_cpu_details, view_ram_details
  - view_product_attributes_list, view_product_summary
  - vw_AuditSummary
- Материализованные представления:
  - mv_product_summary (BUILD IMMEDIATE, REFRESH COMPLETE ON DEMAND, ENABLE QUERY REWRITE)
- Замечания:
  - EAV-атрибуты транспонируются через `MAX(DECODE(...))`
  - NCLOB в выражениях только через `DBMS_LOB.SUBSTR(..., 2000, 1)`

## Индексы (ключевые)

- См. `01_schema/04_indexes.sql`. Ключевые примеры (не исчерпывающий список):
  - Products: IX_Products_CategoryID, IX_Products_VendorID, IX_Products_Featured_Active,
    IX_Products_Name_Category_Price, IX_Products_Name_Upper
  - Orders/OrderItems: IX_Orders_UserID, IX_Orders_OrderStatusID, IX_OrderItems_OrderID
  - Payments: IX_Payments_OrderID, IX_Payments_PaymentStatusID, IX_Payments_StatusID_OrderID
  - Wishlist/ProductMedia/Promotions/Applications: индексы по часто используемым колонкам

## Бизнес-логика и триггеры

- Сложная бизнес-логика (расчет суммы заказа, применение промо, корректировка складских остатков) выполняется на уровне приложения.
- База данных использует триггеры только для:
  - авто-генерации PK через SEQUENCE в BEFORE INSERT (TRG_*_BI),
  - обновления полей updated_at/updated_AT в BEFORE UPDATE,
  - аудита (через процедуры и/или Unified Auditing).
- Триггеры пересчета Orders.order_AMOUNT и корректировки Products.product_STOCK в БД отсутствуют по умолчанию.

## Аудит и безопасность

- Аудит: `02_audit/audit_setup.sql` — BusinessAuditLog, процедуры, триггеры на Orders/Payments,
  Unified Auditing (идемпотентно) или традиционный AUDIT для старых версий.
- Пользователи и роли: `01_schema/05_users.sql` — роли, пользователи, явные GRANT'ы и EXECUTE на пакеты.

## Развёртывание, сброс и восстановление

- Развёртывание: запустите `oracle/deploy.sql`. Лог пишется в `oracle/logs/oracle_deploy_YYYYMMDD_HH24MISSlog.lst`.
- Порядок внутри мастера: 01_schema → 02_audit → 03_views → 04_procedures → 04_indexes.
- Сброс: используйте `oracle/reset.sql` (убивает сессии, удаляет пользователей/объекты WinStore).
- Бутстрап восстановления: `oracle/recovery.sql` (создаёт пользователей/роли/директории, минимально необходимое).
- Импорт из дампа: Data Pump (impdp) с созданной DIRECTORY (см. recovery.sql).
- Проверка: выборки по `Products`, `ProductAttributes`, справочникам статусов, наличие представлений и MV.

## Табличное пространство

- Табличное пространство `WINSTORE_DATA` создается при необходимости (см. `01_core_schema.sql`).

## Совместимость и ограничения

- Лимит длины имен объектов: 30 символов.
- Unified Auditing может различаться по версиям — скрипт обрабатывает существующие политики.

## Рекомендации по применению EAV

- Старайтесь хранить инвариантные свойства как обычные столбцы в `Products`.
- В `ProductAttributes` переносите только вариативные характеристики.
- Для отчётов используйте представления, транспонируя EAV через `MAX(DECODE(...))`.
- Избегайте дублирования пар (product_ID, att_ID) — PK это предотвращает.

## Ссылки

- `oracle/01_schema/01_core_schema.sql`
- `oracle/01_schema/02_reference_data.sql`
- `oracle/01_schema/03_status_transitions.sql`
- `oracle/01_schema/04_indexes.sql`
- `oracle/03_views/product_views.sql`, `oracle/03_views/system_views.sql`
- `oracle/04_procedures/*.sql`
- `oracle/02_audit/audit_setup.sql`
