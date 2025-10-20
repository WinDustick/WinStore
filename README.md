# WinStore - E-commerce Platform for PC Hardware

[![Built with Absurdly Ideal Code](https://img.shields.io/badge/Built%20with-Absurdly%20Ideal%20Code-blue)](https://github.com/WinDustick/WinStore)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A high-performance, elegantly designed e-commerce platform specialized in PC hardware components and accessories. Built following the "Absurdly Ideal Code" philosophy, focusing on reliability, performance, and simplicity.

## Features

- **Advanced Product Catalog** - Flexible attribute system for detailed technical specifications
- **Status-based Business Process Management** - Declarative workflow definition for orders, payments, and deliveries
- **High-performance Architecture** - Optimized database queries and efficient API endpoints
- **Comprehensive Admin Interface** - Feature-rich Directus CMS integration
- **Multi-layered Search and Filtering** - Powerful product search with technical parameter filtering

## Technology Stack

- **Database**: MS SQL Server & Oracle - Dual-support with optimized, database-specific schemas.
- **Backend**: Python 3.10+, Django 4.2+, Django REST Framework
- **Admin CMS**: Directus (connected directly to MS SQL)
- **Frontend**: HTML/CSS/JavaScript with planned React/Next.js implementation
- **Infrastructure**: Docker, Docker Compose, Nginx

## Project Structure

```
WinStore/
├── .github/                    # GitHub-specific files and documentation
├── docs/
│   └── aic_guide/              # Unified documentation entry point (Start Here)
├── sql/                        # MS SQL Server database scripts
├── oracle/                     # Oracle Database scripts
├── backend/                    # Django application (the core logic)
├── frontend/                   # Frontend static files
├── scripts/
│   └── data_generation/        # Scripts for populating the database with test data
├── nginx/                      # Nginx configuration
└── docker-compose.yml          # Docker Compose configuration
```

## Core Philosophy: "Absurdly Ideal Code"

WinStore is built following the "Absurdly Ideal Code" philosophy:

- **No Compromises**: Maximum reliability, performance, and simplicity simultaneously
- **Maximum Simplicity (KISS)**: The simplest possible solution that fully meets requirements
- **Extreme Reliability**: Robust, well-tested code with explicit error handling
- **Peak Performance**: Optimized for speed and efficiency at all levels
- **Elegance & Readability**: Clean, well-structured, and self-documenting code
- **Minimalism**: Minimal dependencies and abstractions to achieve goals

## Key Architectural Patterns

- **Separation of Concerns**: Database for storage and integrity, application layer for business logic
- **Status Transition Tables**: Declarative definition of allowed transitions between statuses
- **Entity-Attribute-Value (EAV)**: Flexible product attribute system with optimized views
- **Repository Pattern with Django ORM**: Clean data access abstraction
- **Domain Services**: Business logic encapsulation in specialized service classes

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Git

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/WinDustick/WinStore.git
   cd WinStore
   ```

2. Create `.env` file from the example:
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. Start the services:
   ```bash
   docker-compose up -d
   ```

4. (Optional) Populate the database with data:
   The project includes powerful scripts for generating realistic test data. For detailed instructions, see the documentation in `docs/data-generation.md`.

5. Access the applications:
   - Backend API: http://localhost:8000/api/
   - Directus CMS: http://localhost:8055/
   - Frontend: http://localhost:80/

## Documentation

This project is documented following the "Absurdly Ideal Code" philosophy, emphasizing clarity and a top-down approach to understanding the architecture.

**The primary entry point for all documentation is the [AIC Guide](./docs/aic_guide/index.md).**

This guide provides a high-level overview of the project's philosophy, architecture, and processes, with links to more detailed documents. We strongly recommend starting there to gain a comprehensive understanding of the project.

## Development

### Database Schema Changes

All database changes should follow the established patterns:
- Use the SQL style guide for consistency
- Add checks for object existence
- Group objects by type in appropriate files
- Update the master deployment script

### Adding New Features

1. Document the feature requirements and design decisions
2. Update database schema if needed
3. Implement backend logic following the service pattern
4. Create or update API endpoints
5. Implement frontend components
6. Write comprehensive tests
7. Update documentation

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- The WinStore Development Team
- Contributors to the open-source libraries used in this project

---

# WinStore - E-commerce платформа для комплектующих ПК

[![Построено на Абсурдно Идеальном Коде](https://img.shields.io/badge/Built%20with-Absurdly%20Ideal%20Code-blue)](https://github.com/WinDustick/WinStore)
[![Лицензия: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Высокопроизводительная и элегантно спроектированная e-commerce платформа, специализирующаяся на компонентах и аксессуарах для ПК. Создана в соответствии с философией "Абсурдно Идеального Кода", с фокусом на надежность, производительность и простоту.

## Особенности

- **Продвинутый каталог продуктов** - Гибкая система атрибутов для детальных технических характеристик.
- **Управление бизнес-процессами на основе статусов** - Декларативное определение рабочих процессов для заказов, платежей и доставок.
- **Высокопроизводительная архитектура** - Оптимизированные запросы к базе данных и эффективные API.
- **Комплексный интерфейс администратора** - Многофункциональная интеграция с Directus CMS.
- **Многоуровневый поиск и фильтрация** - Мощный поиск по продуктам с фильтрацией по техническим параметрам.

## Технологический стек

- **База данных**: MS SQL Server и Oracle - Поддержка обеих СУБД с оптимизированными, специфичными для каждой БД схемами.
- **Бэкенд**: Python 3.10+, Django 4.2+, Django REST Framework
- **CMS администратора**: Directus (подключен напрямую к MS SQL)
- **Фронтенд**: HTML/CSS/JavaScript с планируемой реализацией на React/Next.js.
- **Инфраструктура**: Docker, Docker Compose, Nginx

## Структура проекта

```
WinStore/
├── .github/                    # Файлы и документация для GitHub
├── docs/
│   └── aic_guide/              # Единая точка входа в документацию (Начать отсюда)
├── sql/                        # Скрипты для базы данных MS SQL Server
├── oracle/                     # Скрипты для базы данных Oracle
├── backend/                    # Приложение Django (основная логика)
├── frontend/                   # Статические файлы фронтенда
├── scripts/
│   └── data_generation/        # Скрипты для наполнения БД тестовыми данными
├── nginx/                      # Конфигурация Nginx
└── docker-compose.yml          # Конфигурация Docker Compose
```

## Ключевая философия: "Абсурдно Идеальный Код"

WinStore построен в соответствии с философией "Абсурдно Идеального Кода":

- **Без компромиссов**: Максимальная надежность, производительность и простота одновременно.
- **Максимальная простота (KISS)**: Простейшее возможное решение, полностью отвечающее требованиям.
- **Экстремальная надежность**: Надежный, хорошо протестированный код с явной обработкой ошибок.
- **Пиковая производительность**: Оптимизация для скорости и эффективности на всех уровнях.
- **Элегантность и читаемость**: Чистый, хорошо структурированный и самодокументируемый код.
- **Минимализм**: Минимальное количество зависимостей и абстракций для достижения цели.

## Ключевые архитектурные паттерны

- **Разделение ответственности**: База данных для хранения и целостности, прикладной уровень для бизнес-логики.
- **Таблицы переходов состояний**: Декларативное определение разрешенных переходов между статусами.
- **Entity-Attribute-Value (EAV)**: Гибкая система атрибутов продуктов с оптимизированными представлениями.
- **Паттерн Репозиторий с Django ORM**: Чистая абстракция доступа к данным.
- **Доменные сервисы**: Инкапсуляция бизнес-логики в специализированных сервисных классах.

## Начало работы

### Предварительные требования

- Docker и Docker Compose
- Git

### Установка

1. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/WinDustick/WinStore.git
   cd WinStore
   ```

2. Создайте файл `.env` из примера:
   ```bash
   cp .env.example .env
   # Отредактируйте .env своими настройками
   ```

3. Запустите сервисы:
   ```bash
   docker-compose up -d
   ```

4. (Опционально) Наполните базу данных данными:
   Проект включает мощные скрипты для генерации реалистичных тестовых данных. Подробные инструкции смотрите в документации `docs/data-generation.md`.

5. Доступ к приложениям:
   - Backend API: http://localhost:8000/api/
   - Directus CMS: http://localhost:8055/
   - Frontend: http://localhost:80/

## Документация

Этот проект документирован в соответствии с философией "Абсурдно Идеального Кода", с акцентом на ясность и нисходящий подход к пониманию архитектуры.

**Основной точкой входа для всей документации является [Руководство AIC](./docs/aic_guide/index.md).**

Это руководство представляет собой высокоуровневый обзор философии, архитектуры и процессов проекта, со ссылками на более подробные документы. Мы настоятельно рекомендуем начать с него, чтобы получить полное представление о проекте.

## Разработка

### Изменения схемы базы данных

Все изменения в базе данных должны соответствовать установленным паттернам:
- Используйте руководство по стилю SQL для консистентности.
- Добавляйте проверки на существование объектов.
- Группируйте объекты по типам в соответствующих файлах.
- Обновляйте главный скрипт развертывания.

### Добавление новых функций

1. Документируйте требования и проектные решения.
2. При необходимости обновите схему базы данных.
3. Реализуйте логику бэкенда, следуя сервисному паттерну.
4. Создайте или обновите конечные точки API.
5. Реализуйте компоненты фронтенда.
6. Напишите исчерпывающие тесты.
7. Обновите документацию.

## Лицензия

Этот проект лицензирован под лицензией MIT - подробности см. в файле LICENSE.

## Благодарности

- Команда разработчиков WinStore
- Участники проектов с открытым исходным кодом, используемых в этом проекте
