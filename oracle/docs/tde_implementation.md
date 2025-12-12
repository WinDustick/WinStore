# Руководство по внедрению Transparent Data Encryption (TDE)

**Контекст:** Oracle Database 21c XE (Docker)
**Архитектура:** Multitenant (CDB/PDB)
**Статус:** Внедрено

## 1\. Теоретические основы и ограничения

Внедрение шифрования в архитектуре Multitenant имеет специфические особенности:

1.  **Иерархия ключей:** PDB (Pluggable Database) не может использовать шифрование, пока не открыт и не настроен кошелек (Keystore) в корневом контейнере (`CDB$ROOT`).
2.  **Режимы кошелька:**
      * **PASSWORD (Read-Write):** Открывается вручную паролем. Необходим для **установки и ротации мастер-ключей**.
      * **AUTOLOGIN (Read-Only):** Открывается автоматически при старте БД (файл `cwallet.sso`). В этом режиме **нельзя** менять мастер-ключи.
3.  **Изоляция PDB:** Открытие кошелька в корне не открывает его автоматически в PDB. Требуется явная команда открытия внутри каждой PDB.

## 2\. Алгоритм первичной настройки (Happy Path)

Для корректной настройки "с нуля" должна соблюдаться строгая последовательность действий.

### Этап 1: Подготовка окружения (OS Level)

Настройка выполняется один раз. Требуется для указания Oracle места хранения ключей.

1.  Создание директории (внутри Docker volume):
    ```bash
    mkdir -p /opt/oracle/oradata/wallet/tde
    ```
2.  Настройка параметров `SPFILE` (из `CDB$ROOT`):
    ```sql
    ALTER SYSTEM SET WALLET_ROOT = '/opt/oracle/oradata/wallet' SCOPE=SPFILE;
    ALTER SYSTEM SET TDE_CONFIGURATION = 'KEYSTORE_CONFIGURATION=FILE' SCOPE=SPFILE;
    ```
3.  **Перезагрузка контейнера** (`docker restart`). Без этого параметры не вступят в силу.

### Этап 2: Инициализация ключей (SQL Level)

Выполняется скриптом `oracle/07_security/01_tde_setup.sql`.

1.  **В `CDB$ROOT`:** Создать кошелек $\rightarrow$ Открыть (Password) $\rightarrow$ Установить Root Master Key.
2.  **В `XEPDB1` (PDB):** Открыть кошелек (Password) $\rightarrow$ Установить PDB Master Key.
3.  **В `CDB$ROOT`:** (Только в конце\!) Создать Auto-Login (`cwallet.sso`) для удобства перезагрузок.

-----

## 3\. Устранение неполадок и конфликтов (Troubleshooting)

В процессе эксплуатации часто возникает ситуация блокировки управления ключами.

### Проблема: `ORA-28417: password-based keystore is not open`

**Симптомы:**

  * При попытке установить мастер-ключ в PDB возникает ошибка `ORA-28417`.
  * Статус кошелька в `v$encryption_wallet` показывает `WALLET_TYPE: AUTOLOGIN`.

**Причина:**
В директории кошелька присутствует файл `cwallet.sso` (Auto-Login). При его наличии Oracle открывает кошелек в режиме "Только чтение", блокируя любые административные команды (`SET KEY`).

**Алгоритм решения (Fix Workflow):**

1.  **Удаление блокировки (OS Level):**
    Временно удалить файл авто-входа.

    ```bash
    docker exec winstore_oracle rm /opt/oracle/oradata/wallet/tde/cwallet.sso
    ```

2.  **Принудительное открытие (SQL Level):**
    Переключить кошелек в режим записи.

    ```sql
    -- В ROOT
    ALTER SESSION SET CONTAINER = CDB$ROOT;
    ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN FORCE KEYSTORE IDENTIFIED BY "password" CONTAINER=ALL;

    -- В PDB
    ALTER SESSION SET CONTAINER = XEPDB1;
    ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN FORCE KEYSTORE IDENTIFIED BY "password" CONTAINER=CURRENT;
    ```

3.  **Выполнение операций:**
    Теперь можно устанавливать ключи и создавать зашифрованные Tablespace.

    ```sql
    ADMINISTER KEY MANAGEMENT SET KEY ...;
    ```

4.  **Восстановление Авто-входа:**
    Вернуть удобный режим работы.

    ```sql
    ALTER SESSION SET CONTAINER = CDB$ROOT;
    ADMINISTER KEY MANAGEMENT CREATE AUTO_LOGIN KEYSTORE FROM KEYSTORE IDENTIFIED BY "password";
    ```

-----

## 4\. Демонстрация работы (Verification)

Для проверки работоспособности шифрования используются следующие запросы:

**Статус кошелька:**

```sql
SELECT con_id, status, wallet_type FROM v$encryption_wallet;
-- Ожидается: STATUS='OPEN', WALLET_TYPE='AUTOLOGIN' (в штатном режиме)
```

**Зашифрованные пространства:**

```sql
SELECT tablespace_name, encrypted FROM dba_tablespaces WHERE encrypted='YES';
-- Ожидается: WINSTORE_SECURE_TS
```

**Зашифрованные колонки:**

```sql
SELECT table_name, column_name, encryption_alg 
FROM all_encrypted_columns 
WHERE owner = 'WINSTORE_ADMIN';
```

-----

*Документация составлена на основе практического опыта устранения конфликтов Auto-Login в среде Docker.*