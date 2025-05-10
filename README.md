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

- **Database**: Microsoft SQL Server - Optimized schema with strategic indexing
- **Backend**: Python 3.10+, Django 4.2+, Django REST Framework
- **Admin CMS**: Directus (connected directly to MS SQL)
- **Frontend**: HTML/CSS/JavaScript with planned React/Next.js implementation
- **Infrastructure**: Docker, Docker Compose, Nginx

## Project Structure

```
WinStore/
├── .github/                    # GitHub-specific files and documentation
│   ├── copilot-instructions/   # Guidelines for GitHub Copilot
│   └── copilot_memory_bank/    # Project context and documentation
├── sql/                        # SQL scripts for database setup
│   ├── deploy.sql              # Master deployment script
│   ├── 01_schema/              # Database structure definitions
│   ├── 02_audit/               # Audit system configuration
│   ├── 03_views/               # Database views
│   ├── 04_procedures/          # Stored procedures
│   └── 05_triggers/            # Database triggers
├── backend/                    # Django application
│   ├── apps/                   # Django apps (accounts, orders, products, etc.)
│   ├── config/                 # Django settings and configuration
│   └── directus/               # Directus CMS extensions
├── frontend/                   # Frontend static files
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

4. Access the applications:
   - Backend API: http://localhost:8000/api/
   - Directus CMS: http://localhost:8055/
   - Frontend: http://localhost:80/

## Documentation

Detailed documentation is available in the `.github/copilot_memory_bank/` directory:

- `database_documentation.md` - Database schema and design philosophy
- `system_statuses.md` - Status management system documentation
- `SQL_style_guide.md` - SQL coding standards
- `productContext.md` - Product overview and business context

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