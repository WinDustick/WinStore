# Gemini Project: WinStore

## Project Overview

This project is a high-performance, elegantly designed e-commerce platform specialized in PC hardware components and accessories. It follows the "Absurdly Ideal Code" philosophy, focusing on reliability, performance, and simplicity.

The tech stack includes:

*   **Database**: Microsoft SQL Server or Oracle
*   **Backend**: Python 3.10+, Django 4.2+, Django REST Framework
*   **Admin CMS**: Directus (connected directly to the database)
*   **Frontend**: HTML/CSS/JavaScript with a planned React/Next.js implementation
*   **Infrastructure**: Docker, Docker Compose, Nginx

The project is structured with a clear separation of concerns: a `backend` Django application, a `frontend` with static files, `sql` scripts for database setup, and `docker-compose.yml` for service orchestration.

## Building and Running

To build and run the project, you need Docker and Docker Compose installed.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/WinDustick/WinStore.git
    cd WinStore
    ```

2.  **Create a `.env` file:**
    ```bash
    cp .env.example .env
    ```
    You will need to edit the `.env` file with your desired settings for passwords and other environment variables.

3.  **Start the services:**
    ```bash
    docker-compose up -d
    ```

4.  **Access the applications:**
    *   Backend API: http://localhost:8000/api/
    *   Directus CMS: http://localhost:8055/
    *   Frontend: http://localhost:80/

## Development Conventions

*   **Database Schema Changes**: All database changes should follow the established patterns in the `sql` directory. Use the SQL style guide for consistency, add checks for object existence, group objects by type in appropriate files, and update the master deployment script.
*   **Business Logic**: Complex business logic, including calculations, promotions, and status management, is implemented in the backend application layer, not in the database as stored procedures or triggers.
*   **Status Management**: The system uses a declarative approach to manage statuses for orders, payments, and deliveries, with status transition tables defining the allowed state changes.
*   **Coding Style**: The project emphasizes clean, readable, and self-documenting code, following the "Absurdly Ideal Code" philosophy.
