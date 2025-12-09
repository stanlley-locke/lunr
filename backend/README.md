# Lunr Backend

A Django-based backend for the Lunr chat application, featuring real-time WebSockets, REST API, and media handling.

## Quick Start
1.  **Install Requirements**
    ```bash
    pip install -r requirements.txt
    ```
2.  **Run Migrations**
    ```bash
    python manage.py makemigrations && python manage.py migrate
    ```
3.  **Start Server**
    ```bash
    python manage.py runserver
    ```

## Documentation
Comprehensive documentation is available in the `docs/` folder:
- [API Reference](docs/api_reference.md)
- [Setup Guide](docs/setup_guide.md)
- [Security Audit](docs/security_audit.md)

## Deployment
Automated deployment script for Ubuntu VPS is available:
- `deploy_vps.py`: Automates sysadmin tasks for a production setup.
