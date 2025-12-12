# Руководство по настройке Transparent Data Encryption (TDE)

**Версия Oracle:** 21c XE (Docker)
**Архитектура:** Multitenant (CDB/PDB)
**Метод:** `WALLET_ROOT` (Современный стандарт Oracle 19c+)

## 1. Подготовка окружения (OS Level)

Перед настройкой базы данных необходимо подготовить файловую систему. Oracle требует строгой структуры каталогов при использовании параметра `WALLET_ROOT`.

**Требование:** Ключи должны храниться на персистентном томе, чтобы пережить пересоздание контейнера. В нашей конфигурации это `/opt/oracle/oradata`.

**Команда (в терминале хоста):**
```bash
docker exec winstore_oracle mkdir -p /opt/oracle/oradata/wallet/tde
```

*Важно: Подпапка `/tde` обязательна. Oracle не позволит создать кошелек в корне `WALLET_ROOT`.*

## 2\. Настройка системных параметров (CDB Level)

Настройка выполняется в корневом контейнере (`CDB$ROOT`). Параметры применяются в SPFILE и требуют перезагрузки инстанса.

**Скрипт:** `oracle/07_security/00_pre_configure_tde.sql`

```sql
-- 1. Переключение в корневой контейнер
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- 2. Указание корневой директории
ALTER SYSTEM SET WALLET_ROOT = '/opt/oracle/oradata/wallet' SCOPE=SPFILE;

-- 3. Активация файлового хранилища ключей
-- Примечание: Этот параметр может не примениться, пока не активен WALLET_ROOT.
-- Если возникает ошибка ORA-32017/ORA-46693, требуется промежуточная перезагрузка.
ALTER SYSTEM SET TDE_CONFIGURATION = 'KEYSTORE_CONFIGURATION=FILE' SCOPE=SPFILE;
```

```bash
docker restart winstore_oracle
```

```sql
-- 1. Переключение в корневой контейнер
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- 3. Активация файлового хранилища ключей
-- Примечание: Этот параметр может не примениться, пока не активен WALLET_ROOT.
-- Если возникает ошибка ORA-32017/ORA-46693, требуется промежуточная перезагрузка.
ALTER SYSTEM SET TDE_CONFIGURATION = 'KEYSTORE_CONFIGURATION=FILE' SCOPE=SPFILE;
```

## 3\. Перезагрузка инстанса (Docker Restart)

Чтобы параметры `WALLET_ROOT` и `TDE_CONFIGURATION` вступили в силу, необходимо перезапустить процесс базы данных.

**Команда (в терминале хоста):**

```bash
docker restart winstore_oracle
```

*Проверка:* После рестарта запрос `SELECT * FROM v$parameter WHERE name='wallet_root'` должен возвращать путь.

## 4\. Создание и инициализация Keystore (CDB Level)

После применения параметров база данных знает, где хранить ключи. Необходимо создать хранилище (Keystore) и сгенерировать Мастер-ключ.

**Скрипт:** `oracle/07_security/01_tde_setup.sql`

```sql
-- ВАЖНО: Выполняется в CDB$ROOT
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- 1. Создание кошелька (Путь указывать НЕ НАДО, Oracle берет его из WALLET_ROOT)
ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY "StrongPassword123";

-- 2. Открытие кошелька
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "StrongPassword123" CONTAINER=ALL;

-- 3. Установка/Ротация Мастер-ключа (Активация TDE)
ADMINISTER KEY MANAGEMENT SET KEY IDENTIFIED BY "StrongPassword123" WITH BACKUP CONTAINER=ALL;

-- 4. Настройка Auto-Login (Опционально, для удобства в Docker)
ADMINISTER KEY MANAGEMENT CREATE AUTO_LOGIN KEYSTORE FROM KEYSTORE IDENTIFIED BY "StrongPassword123";
```

## 5\. Использование шифрования (PDB Level)

После настройки на уровне сервера можно шифровать данные в рабочих базах (PDB).

### Шифрование табличного пространства (Рекомендуемый метод)

Создается новое Tablespace с флагом шифрования. Все таблицы в нем будут защищены автоматически.

```sql
CREATE TABLESPACE SECURE_TS 
    DATAFILE '/opt/oracle/oradata/secure01.dbf' SIZE 100M 
    ENCRYPTION USING 'AES256' DEFAULT STORAGE(ENCRYPT);
```

### Шифрование отдельных колонок

Используется для точечной защиты в существующих таблицах.

```sql
ALTER TABLE Users MODIFY (USER_PASS ENCRYPT USING 'AES192' SALT);
```

-----

## Чек-лист устранения неполадок

1.  **Ошибка `ORA-28368: cannot auto-create wallet`**:

      * Проверьте, существует ли папка `/opt/oracle/oradata/wallet/tde`.
      * Проверьте, задан ли параметр `WALLET_ROOT`.

2.  **Ошибка `ORA-46693: The WALLET_ROOT location is missing or invalid`**:

      * Вы пытаетесь задать `TDE_CONFIGURATION` до перезагрузки. Сначала перезагрузите контейнер, чтобы применился `WALLET_ROOT`.

3.  **Параметры пусты при проверке**:

      * Убедитесь, что проверяете их из `CDB$ROOT`, а не из `XEPDB1`. Используйте `ALTER SESSION SET CONTAINER = CDB$ROOT`.