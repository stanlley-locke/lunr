
import os
import subprocess
import sys

# Configuration
REPO_URL = "https://github.com/stanlley-locke/lunr.git"
PROJECT_DIR = "/opt/lunr"
BACKEND_DIR = os.path.join(PROJECT_DIR, "backend")
VENV_DIR = os.path.join(PROJECT_DIR, ".venv")

# Use "_" as a wildcard to accept all connections (IP-based access)
DOMAIN = "_"
USER = "root"

def run_command(command):
    print(f"Running: {command}")
    subprocess.check_call(command, shell=True)

def install_system_dependencies():
    print("Installing system dependencies...")
    run_command("apt-get update")
    run_command("apt-get install -y python3-pip python3-venv postgresql postgresql-contrib nginx git supervisor redis-server")

def setup_project():
    print("Setting up project...")
    if not os.path.exists(PROJECT_DIR):
        run_command(f"git clone {REPO_URL} {PROJECT_DIR}")
    else:
        run_command(f"cd {PROJECT_DIR} && git pull")

    if not os.path.exists(VENV_DIR):
        run_command(f"python3 -m venv {VENV_DIR}")

    run_command(f"{VENV_DIR}/bin/pip install -r {BACKEND_DIR}/requirements.txt")
    run_command(f"{VENV_DIR}/bin/pip install gunicorn daphne")

def configure_database():
    print("Configuring database... (Manual step: Ensure DB 'lunr' and user 'lunr_user' exist)")
    # run_command("sudo -u postgres psql -c \"CREATE DATABASE lunr;\"")
    # run_command("sudo -u postgres psql -c \"CREATE USER lunr_user WITH PASSWORD 'password';\"")
    # run_command("sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE lunr TO lunr_user;\"")
    pass

def configure_gunicorn():
    print("Configuring Gunicorn...")
    service_content = f"""
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User={USER}
Group=www-data
WorkingDirectory={BACKEND_DIR}
ExecStart={VENV_DIR}/bin/gunicorn --access-logfile - --workers 3 --bind unix:/run/gunicorn.sock core.wsgi:application

[Install]
WantedBy=multi-user.target
    """
    with open("/etc/systemd/system/gunicorn.service", "w") as f:
        f.write(service_content)

    run_command("systemctl start gunicorn")
    run_command("systemctl enable gunicorn")

def configure_daphne():
    print("Configuring Daphne (WebSockets)...")
    service_content = f"""
[Unit]
Description=daphne daemon (WebSockets)
After=network.target

[Service]
User={USER}
Group=www-data
WorkingDirectory={BACKEND_DIR}
ExecStart={VENV_DIR}/bin/daphne -b 0.0.0.0 -p 8001 core.asgi:application

[Install]
WantedBy=multi-user.target
    """
    with open("/etc/systemd/system/daphne.service", "w") as f:
        f.write(service_content)

    run_command("systemctl start daphne")
    run_command("systemctl enable daphne")

def configure_nginx():
    print("Configuring Nginx...")
    # Use "default" as filename for IP-based catch-all
    site_name = "default"
    
    nginx_config = f"""
server {{
    listen 80 default_server;
    server_name _;

    location = /favicon.ico {{ access_log off; log_not_found off; }}
    
    location /static/ {{
        root {BACKEND_DIR};
    }}

    location /media/ {{
        root {BACKEND_DIR};
    }}

    # Socket.IO Proxy (for Flutter/JS clients using socket.io-client)
    location /socket.io/ {{
        proxy_pass http://0.0.0.0:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_redirect off;
    }}

    # WebSocket Proxy (for native Django Channels)
    location /ws/ {{
        proxy_pass http://0.0.0.0:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_redirect off;
    }}

    # HTTP/REST API Proxy
    location / {{
        include proxy_params;
        proxy_pass http://unix:/run/gunicorn.sock;
    }}
}}
    """
    with open(f"/etc/nginx/sites-available/{site_name}", "w") as f:
        f.write(nginx_config)

    # Remove default Nginx welcome page if it exists
    if os.path.exists("/etc/nginx/sites-enabled/default"):
        os.remove("/etc/nginx/sites-enabled/default")

    if not os.path.exists(f"/etc/nginx/sites-enabled/{site_name}"):
        run_command(f"ln -s /etc/nginx/sites-available/{site_name} /etc/nginx/sites-enabled")
    
    run_command("nginx -t")
    run_command("systemctl restart nginx")

def main():
    if os.geteuid() != 0:
        print("This script must be run as root.")
        sys.exit(1)

    install_system_dependencies()
    setup_project()
    configure_database()
    configure_gunicorn()
    configure_daphne()
    configure_nginx()
    
    print("Deployment Setup Complete!")
    print("Next Steps:")
    print("1. Update .env file in backend directory")
    print("2. Run migrations: ./venv/bin/python manage.py migrate")
    print(f"3. Your app should be accessible at http://<your-ip>/")

if __name__ == "__main__":
    main()
