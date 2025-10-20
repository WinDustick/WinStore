## Восстановление WINSTORE из бэкапа — минимально и надёжно

Цель: быстро восстановить схему `WINSTORE_ADMIN` и связанных пользователей из дампа Data Pump. Следуем принципу: reset → bootstrap → import → verify.

Подразумевается: Oracle XE, сервис XEPDB1, дамп лежит в контейнере по пути `/opt/oracle/full_backups/winstore_full_backup.dmp`.

### 1) Подключение под SYSDBA

```fish
sqlcl sys/0r4c13_53rV3r@localhost:1521/XEPDB1 as sysdba
```

### 2) Жёсткий reset (без остаточных сессий)

```sql
@reset.sql
```

Скрипт завершит активные сессии и удалит пользователей `WINSTORE_*` с CASCADE.

### 3) Bootstrap для импорта (создание пользователей и DIRECTORY)

```sql
@recovery.sql
```

Скрипт создаст `WINSTORE_ADMIN` и остальных пользователей с минимальными правами и настроит DIRECTORY `WINSTORE_DUMP` (путь по умолчанию: `/opt/oracle/full_backups`) с правами для `WINSTORE_ADMIN` и `SYSTEM`.

Опционально можно переопределить пароли и путь перед запуском:

```sql
DEFINE ADMIN_PASS = 'AdminPass';
DEFINE DIRECTORY_PATH = '/opt/oracle/full_backups';
@recovery.sql
```

### 4) Импорт схемы (выполнять как SYS/SYSTEM)

Рекомендуется запускать импорт как `SYS` или `SYSTEM`, чтобы импорту хватало прав на выдачу GRANT-ов и создание зависимостей.

```fish
impdp sys/0r4c13_53rV3r@localhost:1521/XEPDB1 \
  SCHEMAS=WINSTORE_ADMIN \
  DIRECTORY=WINSTORE_DUMP \
  DUMPFILE=winstore_full_backup.dmp \
  LOGFILE=winstore_full_restore.log \
  TABLE_EXISTS_ACTION=REPLACE \
  CONTENT=ALL \
  EXCLUDE=STATISTICS
```

Примечания:
- INCLUDE не требуется — по умолчанию импортирует всё из схемы; EXCLUDE=STATISTICS ускоряет процесс.
- Если дамп в другом месте, измените DIRECTORY_PATH в recovery.sql или создайте другой DIRECTORY.

### 5) Быстрая проверка после импорта

Подключаемся под `WINSTORE_ADMIN` для проверки статуса объектов.

```fish
sqlcl WINSTORE_ADMIN/AdminPass@localhost:1521/XEPDB1
```

Проверяем INVALID и компилируем при необходимости:

```sql
SELECT object_name, object_type FROM user_objects WHERE status='INVALID';
BEGIN UTL_RECOMP.RECOMP_SERIAL('WINSTORE_ADMIN'); END; /
```

Проверяем, что ключевые таблицы заполнены:

```sql
SELECT COUNT(*) AS products FROM products;
SELECT COUNT(*) AS categories FROM categories;
```

Последовательности (обычно корректны, вмешательство не требуется). Если нужно — точечно синхронизируйте:

```sql
-- пример для PRODUCTS_SEQ
DECLARE
  v_target NUMBER;
  v_curr   NUMBER;
BEGIN
  SELECT NVL(MAX(product_id),0)+1 INTO v_target FROM products;
  SELECT last_number INTO v_curr FROM user_sequences WHERE sequence_name='PRODUCTS_SEQ';
  IF v_curr <> v_target THEN
    EXECUTE IMMEDIATE 'ALTER SEQUENCE PRODUCTS_SEQ INCREMENT BY '||(v_target - v_curr)||' NOCACHE';
    EXECUTE IMMEDIATE 'SELECT PRODUCTS_SEQ.NEXTVAL FROM DUAL';
    EXECUTE IMMEDIATE 'ALTER SEQUENCE PRODUCTS_SEQ INCREMENT BY 1 NOCACHE';
  END IF;
END;
/
```

### Итоговый чек-лист

- [ ] Выполнен reset.sql (сессии убиты, пользователи удалены)
- [ ] Выполнен recovery.sql (созданы пользователи и DIRECTORY)
- [ ] Выполнен impdp схемы WINSTORE_ADMIN как SYS/SYSTEM
- [ ] Нет INVALID объектов или они перекомпилированы
- [ ] Данные на месте, последовательности корректны

Это всё. Минимум шагов, максимум надёжности.

