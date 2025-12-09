# Backend Setup Guide

## Prerequisites
- Python 3.10+
- PostgreSQL (Production) / SQLite (Dev)
- Redis (optional, for Channels)

## Local Development
1. **Clone Repository**
   ```bash
   git clone <repo_url>
   cd backend
   ```

2. **Create Virtual Environment**
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # Linux/Mac
   .venv\Scripts\activate     # Windows
   ```

3. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Environment Variables**
   Create a `.env` file in `backend/` directory:
   ```env
   DEBUG=True
   SECRET_KEY=dev_secret_key
   ALLOWED_HOSTS=*
   DATABASE_URL=sqlite:///db.sqlite3
   ```

5. **Migrations & Run**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   python manage.py runserver 0.0.0.0:8000
   ```

## Production Setup (Manual)
For automated setup, see `deploy_vps.py`.

1. **Database**: Install PostgreSQL and create a DB + User.
2. **Gunicorn**: Install `gunicorn` and run:
   ```bash
   gunicorn core.wsgi:application --bind 0.0.0.0:8000
   ```
3. **Nginx**: Configure Nginx as a reverse proxy to port 8000 and serve `/static/` and `/media/`.
4. **Daphne**: For WebSockets, run `daphne -b 0.0.0.0 -p 8001 core.asgi:application` and proxy `/ws/` to port 8001.
