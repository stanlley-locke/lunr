
import os
import subprocess
import sys

# Configuration
REPO_URL = "https://github.com/stanlley-locke/lunr.git"  # Update this
PROJECT_DIR = "/opt/lunr"
BACKEND_DIR = os.path.join(PROJECT_DIR, "backend")
VENV_DIR = os.path.join(PROJECT_DIR, "venv")
DOMAIN = "your-domain.com"  # Update this
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

def configure_nginx():
    print("Configuring Nginx...")
    nginx_config = f"""
server {{
    listen 80;
    server_name {DOMAIN};

    location = /favicon.ico {{ access_log off; log_not_found off; }}
    location /static/ {{
        root {BACKEND_DIR};
    }}

    location / {{
        include proxy_params;
        proxy_pass http://unix:/run/gunicorn.sock;
    }}
}}
    """
    with open(f"/etc/nginx/sites-available/{DOMAIN}", "w") as f:
        f.write(nginx_config)

    if not os.path.exists(f"/etc/nginx/sites-enabled/{DOMAIN}"):
        run_command(f"ln -s /etc/nginx/sites-available/{DOMAIN} /etc/nginx/sites-enabled")
    
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
    configure_nginx()
    
    print("Deployment Setup Complete!")
    print("Next Steps:")
    print("1. Update .env file in backend directory")
    print("2. Run migrations: ./venv/bin/python manage.py migrate")
    print("3. Set up SSL with Cerbot")

if __name__ == "__main__":
    main()
