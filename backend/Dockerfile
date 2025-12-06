# backend/Dockerfile
FROM python:3.11-slim

# Prevent Python from writing pyc files
ENV PYTHONDONTWRITEBYTECODE=1
# Prevent Python from buffering stdout/stderr
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies (needed for psycopg2)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project code
COPY . .

# Collect static files (for Django admin, if used)
RUN python manage.py collectstatic --noinput

# Expose port (documentation only — Leapcell uses $PORT)
EXPOSE 8000

# Start ASGI server (supports WebSockets via Channels)
CMD gunicorn --bind 0.0.0.0:$PORT core.asgi:application \
    --worker-class uvicorn.workers.UvicornWorker \
    --workers 2 \
    --timeout 120 \
    --keep-alive 5