# VPS Setup & Testing Guide

This guide details how to deploy the Lunr backend to a Linux VPS (Ubuntu/Debian) and verify it using `curl`.

## Part 1: Server Setup

### 1. Connect to VPS
SSH into your server:
```bash
ssh root@your-server-ip
```

### 2. Prepare the Deployment Script
1.  **Clone the repository**:
    ```bash
    git clone https://github.com/stanlley-locke/lunr.git
    cd lunr/backend
    ```
2.  **Configuration**:
    The script defaults to **IP-based access** (wildcard domain). 
    - If you are using a domain, edit `deploy_vps.py` and set `DOMAIN = "your-domain.com"`.
    - If you are using an IP, no changes are needed.

### 3. Run Automated Deployment
Execute the deployment script to install dependencies (Nginx, Postgres, Redis, Gunicorn, Daphne), set up the virtual environment, and configure systemd services:
```bash
python3 deploy_vps.py
```
> **Note**: This script sets up the infrastructure but requires manual configuration for secrets and database initialization.

### 4. Configure Environment
1.  **Create `.env` file**:
    ```bash
    nano /opt/lunr/backend/.env
    ```
2.  **Add Production Variables**:
    ```env
    DEBUG=False
    SECRET_KEY=your-secure-random-key-here
    ALLOWED_HOSTS=your-domain.com,your-server-ip
    DATABASE_URL=postgres://lunr_user:password@localhost:5432/lunr
    REDIS_URL=redis://127.0.0.1:6379/0
    ```
    *(Replace `lunr_user` and `password` with the credentials you set up below)*

### 5. Finalize Database Setup
1.  **Create Postgres User/DB** (if not done by script):
    ```bash
    sudo -u postgres psql
    ```
    ```sql
    CREATE DATABASE lunr;
    CREATE USER lunr_user WITH PASSWORD 'strongpassword';
    GRANT ALL PRIVILEGES ON DATABASE lunr TO lunr_user;
    \q
    ```
2.  **Run Migrations**:
    ```bash
    cd /opt/lunr/backend
    source ../venv/bin/activate
    python manage.py makemigrations
    python manage.py migrate
    ```
3.  **Create Admin User**:
    ```bash
    python manage.py createsuperuser
    ```

### 6. Restart Services
Apply changes:
```bash
systemctl restart gunicorn
systemctl restart nginx
```

---

## Part 2: Testing with cURL

### Important: Port Usage
- **Production (Nginx)**: Use **Port 80** (e.g., `http://194.36.88.236/api/...`). Nginx forwards requests to the backend.
- **Debug (Runserver)**: If you manually run `python manage.py runserver`, it defaults to `127.0.0.1` (localhost only). To access it remotely, you MUST use `0.0.0.0`:
  ```bash
  python manage.py runserver 0.0.0.0:8000
  ```
  *(Make sure Port 8000 is allowed in your VPS Firewall)*

### 1. Health Check (List Rooms)
Try to access a protected endpoint.
**Using Nginx (Recommended)**:
```bash
curl -v http://<your-ip>/api/rooms/
```
**Using Manual Runserver**:
```bash
curl -v http://<your-ip>:8000/api/rooms/
```
*Expected: `401 Unauthorized`*

### 2. Register a User
Create a new account (Example using Nginx/Port 80):
```bash
curl -X POST http://<your-ip>/api/auth/register/ \
     -H "Content-Type: application/json" \
     -d '{"username": "testuser", "password": "password123"}'
```
*Expected: `201 Created` with tokens.*

### 3. Login
Get an access token:
```bash
curl -X POST http://<your-ip>/api/auth/login/ \
     -H "Content-Type: application/json" \
     -d '{"username": "testuser", "password": "password123"}'
```
*Response:*
```json
{
    "refresh": "eyJ0...",
    "access": "eyJ0..."
}
```

### 4. Test Authenticated Request
Save the access token from the previous step and use it here:
```bash
export TOKEN="your_access_token_here"

curl -X GET http://localhost:8000/api/rooms/ \
     -H "Authorization: Bearer $TOKEN"
```
*Expected: `200 OK` (Empty list `[]` initially)*

### 5. Archive a Chat (Test New Feature)
1.  **Create a Room** (you need a room ID first, or create one via Django Admin):
    *Using API to create room (needs another user usually, or create group)*
    ```bash
    # Create simple group
    curl -X POST http://localhost:8000/api/rooms/ \
         -H "Authorization: Bearer $TOKEN" \
         -H "Content-Type: application/json" \
         -d '{"name": "Test Group", "is_private": false, "members": []}'
    ```
    *Response will contain `"id": "uuid..."`*

2.  **Archive the Room**:
    ```bash
    export ROOM_ID="uuid_from_previous_step"
    
    curl -X POST http://localhost:8000/api/rooms/$ROOM_ID/archive/ \
         -H "Authorization: Bearer $TOKEN"
    ```
    *Expected: `200 OK` `{"status": "success", "is_archived": true}`*

3.  **Unarchive**:
    Run the same command again.
    *Expected: `200 OK` `{"status": "success", "is_archived": false}`*
