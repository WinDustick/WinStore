# WinStore — Setup / Быстрый старт

## Требования

- Docker (для Oracle XE контейнера) или доступ к совместимой Oracle БД
- Python 3.10+ и виртуальная среда
- Пакеты из `backend/requirements.txt` (добавлен Faker)

## Установка зависимостей (fish)

```fish
python -m venv venv
source venv/bin/activate.fish
pip install -r backend/requirements.txt
```

## Переменные окружения

```fish
set -x ORACLE_DB_USER WINSTORE_ADMIN
set -x ORACLE_ADMIN_PASSWORD 123
set -x ORACLE_DB_HOST localhost
set -x ORACLE_DB_PORT 1521
set -x ORACLE_DB_SERVICE XEPDB1
```

## Инициализация данных

```fish
python scripts/data_generation/01_populate_base_entities.py
```

## Генерация товаров

```fish
# CPU (live parsing, останавливается на 429)
python scripts/data_generation/products/generate_cpu.py

# NVIDIA GTX/RTX (Rule-Based + URL seed)
python scripts/data_generation/products/generate_gpu_nvidia.py

# NVIDIA GT (Rule-Based + URL seed только GT)
python scripts/data_generation/products/generate_gpu_nvidia_gt.py
```

## Примечания

- Если используете представления с CLOB/NCLOB, убедитесь в `GRANT EXECUTE ON DBMS_LOB` и используйте `TO_NCHAR` для объединения строковых значений.
- Для Docker Oracle: подключайтесь к сервису `XEPDB1` (EZCONNECT `host:port/service`).
