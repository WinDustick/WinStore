# WinStore — Руководство по генерации данных

Этот документ описывает актуальную стратегию и инструменты генерации данных в проекте, включая последние нововведения: утилиты, транзакционные паттерны, генераторы CPU и NVIDIA (разделённые GTX/RTX и GT), поведение URL seed и рекомендации по эксплуатации.

## Обзор

- База: Oracle XE (PDB `XEPDB1`), Python (`oracledb`, `requests`, `beautifulsoup4`, `Faker`).
- Архитектура генерации: модульная, каждый шаг — отдельный скрипт, работающий транзакционно и пакетно.
- Идентификаторы: после шага базовых сущностей сохраняются JSON с мапами (`scripts/data_generation/generated_ids/`).

## Утилиты

- Файл: `scripts/data_generation/utils.py`
  - `get_db_connection()`: подключение к Oracle с использованием переменных окружения (`ORACLE_DB_USER`, `ORACLE_ADMIN_PASSWORD`, `ORACLE_DB_HOST`, `ORACLE_DB_PORT`, `ORACLE_DB_SERVICE`).
  - `batch_insert(conn, sql, data, batch_size=100, commit_now=True)`: пакетная вставка с опциональным контролем коммита.
  - `save_ids(name, data)` / `load_ids(name)`: сохранение/чтение JSON с ID и словарями.

## Шаги генерации

### 1) Базовые сущности — `scripts/data_generation/01_populate_base_entities.py`
- Что делает:
  - Vendors: парсит списки производителей (`*.txt`, `gpu_vendors.csv`) + добавляет Intel/AMD/NVIDIA.
  - Categories: CPU/GPU/Motherboard/RAM/Storage/PSU/Cooling.
  - Attributes: полный перечень атрибутов (CPU+GPU и др.).
  - Users: ~200 пользователей `Faker` с нормализацией телефона (11 символов, безопасный fallback).
- Транзакционность: вставка всех блоков с единым `conn.commit()` в конце. В случае ошибки — `rollback`.
- Результат: сохраняет `vendors.json`, `categories.json`, `attributes.json`, `users.json`.

### 2) CPU — `scripts/data_generation/products/generate_cpu.py`
- Подход: live parsing с TechPowerUp (осторожно с 429; добавлено немедленное завершение при 429).
- Режимы ввода:
  - Директория `../cpu_links` — обработка всех `.txt` файлов поочередно (батчами по 50).
  - Один файл `../cpu_urls.txt` — резервный вариант.
- Обработка:
  - Робастный парсинг имени и спецификаций; пропуск нереализованных моделей.
  - Дедупликация по `(product_NAME, ven_ID)`, парсинг цены, склад.
  - Нормализация номиналов атрибутов (исключены пустые/«N/A») — предотвращает `ORA-01400`.
  - Транзакции: один коммит на батч; при ошибке — откат.

### 3) NVIDIA GTX/RTX — `scripts/data_generation/products/generate_gpu_nvidia.py`
- Подход: Rule-Based + URL seed (без сетевых запросов).
- Покрытие: GTX 9x0/10x0/16x0; RTX 20x0/30x0/40x0/50x0.
- Партнеры: MSI, Asus, Gigabyte Technology, EVGA, Zotac, Palit, PNY, Gainward, KFA2, Colorful, Inno3D (+ NVIDIA FE, если есть в Vendors).
- Классы (1–7): влияют на цену (база по поколению ±15%), VRAM, шину, TDP, PSU, габариты, частоты.
- URL seed поведение:
  - При наличии `scripts/data_generation/gpu_links/gpu_nvidia.txt` скрипт парсит только GTX/RTX модели с четырёхзначными номерами, оканчивающимися на 50/60/70/80/90.
  - Игнорирует GT и TITAN — эти модели не генерируются в данном скрипте.
- Атрибуты: NVIDIA-специфичные (CUDA/NVENC/NVDEC; для RTX — RT/Tensor Cores). Без AMD-атрибутов.
- Дедупликация/транзакции: как у CPU генератора.

### 4) NVIDIA GT — `scripts/data_generation/products/generate_gpu_nvidia_gt.py`
- Подход: Rule-Based + URL seed, сфокусирован на GT 610/710/720/730/740/1010/1030.
- URL seed поведение:
  - Фильтрует только `geforce-gt-*` из того же файла.
  - Нормализует номера и принимает только перечисленные GT модели. Если ничего не найдено — встроенный набор.
- Особенности:
  - Низкая мощность, DDR3/DDR4/GDDR5 по модели, 64/128-bit шина, чаще без разъёма питания (кроме некоторых 740).
  - NVENC/NVDEC = Yes только для GT 10xx; RT/Tensor = No.
- Дедупликация/транзакции: аналогично.

### 5) Прочие категории
- RAM/PSU/Storage — по аналогии (Rule/Data-Driven), добавляются по мере необходимости.

## Переменные окружения

- ORACLE_DB_USER (по умолчанию: `WINSTORE_ADMIN`)
- ORACLE_ADMIN_PASSWORD (по умолчанию: `123`)
- ORACLE_DB_HOST (по умолчанию: `localhost`)
- ORACLE_DB_PORT (по умолчанию: `1521`)
- ORACLE_DB_SERVICE (по умолчанию: `XEPDB1`)

## Как запускать (fish)

- База:
```fish
python scripts/data_generation/01_populate_base_entities.py
```
- CPU:
```fish
python scripts/data_generation/products/generate_cpu.py
```
- NVIDIA GTX/RTX:
```fish
python scripts/data_generation/products/generate_gpu_nvidia.py
```
- NVIDIA GT:
```fish
python scripts/data_generation/products/generate_gpu_nvidia_gt.py
```

## Транзакции и дедупликация

- Все вставки выполняются батчами (`executemany`) в рамках одной транзакции на логический батч.
- Дубликаты предотвращаются проверкой `(product_NAME, ven_ID)` до вставки.
- Номиналы атрибутов нормализуются и пропускаются, если пустые/«N/A», чтобы исключить `ORA-01400`.

## Траблшутинг

- HTTP 429 при CPU-парсинге: скрипт прекращает работу с кодом `2`; подождите и перезапустите.
- Кодировки/NCLOB в представлениях: используйте `TO_NCHAR` и `DBMS_LOB.SUBSTR` (см. `oracle/03_views/product_views.sql`). Нужен `GRANT EXECUTE ON DBMS_LOB` для схемы.
- Подключение к PDB: убедитесь, что используете сервис `XEPDB1` (EZCONNECT `host:port/service`).

## Состояние документации

- Обновлено: `scripts/data_generation/README.md` — добавлены разделы про GTX/RTX и GT генераторы, команды запуска и поведение URL seed.
- Этот документ — агрегированный гайд по генерации данных (актуален на дату последнего коммита).
- Пустые ранее файлы в `docs/` (api-docs.md, setup.md) — см. ниже раздел Setup для наполнения.
