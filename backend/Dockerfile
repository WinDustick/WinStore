FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Install system dependencies
# Установка базовых зависимостей, включая libaio1 для Oracle
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    build-essential \
    curl \
    gnupg \
    unixodbc-dev \
    libaio1t64 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Добавление GPG ключа Microsoft и репозитория
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
 && chmod a+r /usr/share/keyrings/microsoft-prod.gpg \
 && curl -fsSL https://packages.microsoft.com/config/debian/12/prod.list > /etc/apt/sources.list.d/mssql-release.list

# Обновление списка пакетов и установка драйвера MS ODBC
RUN apt-get update \
 && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql17 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# --- Установка Oracle Instant Client из локальной копии ---
# Создание директории для клиента и копирование файлов
RUN mkdir -p /opt/oracle/instantclient
COPY instantclient-basic-linux.x64-21.19.0.0.0dbru/instantclient_21_19 /opt/oracle/instantclient

# Добавление пути к библиотекам в конфигурацию динамического компоновщика
RUN echo /opt/oracle/instantclient > /etc/ld.so.conf.d/oracle-instantclient.conf && ldconfig
# --- Конец установки Oracle ---

# Set work directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip && \
    pip install -r requirements.txt --no-cache-dir

# Copy project
COPY . /app/

# Make scripts executable
RUN chmod +x /app/wait_for_db.py

# Expose port
EXPOSE 8000

# Create non-root user
RUN useradd -m django
RUN chown -R django:django /app
USER django

# Command will be specified in docker-compose.yml
