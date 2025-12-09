# Backend Security Audit

## Overview
This document analyzes the security posture of the Lunr backend (Django + Django Rest Framework).

## Authentication & Authorization
- **JWT Authentication**: Uses `rest_framework_simplejwt`. Access tokens are short-lived.
- **Permissions**: Most endpoints are protected with `IsAuthenticated`.
- **Password Hashing**: Uses Django's default PBKDF2 password hasher (industry best practice).

## Data Protection
- **Database**: PostgreSQL (recommended for production). SQLite used in dev.
- **Media Files**: Currently served locally. For production, `nginx` should serve `MEDIA_ROOT`.
- **Sensitive Data**: Passwords are hashed. No PII is stored in plain text other than user-provided bio/phone.

## Network Security
- **CORS**: `django-cors-headers` is installed. Currently configured to allow specific origins (or all in dev).
    > **Action Item**: Restrict `CORS_ALLOWED_ORIGINS` in production settings.
- **SSL/TLS**: Not enforced at application level. Must be handled by Nginx reverse proxy.

## Input Validation
- **Serializers**: DRF serializers validate all incoming JSON data.
- **File Uploads**: `ImageField` validates image integrity. No explicit file type whitelist beyond image formats properly enforced yet for generic files.

## Potential Vulnerabilities
1.  **Rate Limiting**: Not explicitly configured in DRF. vulnerable to brute force or DoS.
    > **Recommendation**: Configure `DEFAULT_THROTTLE_CLASSES` in `settings.py`.
2.  **Debug Mode**: `DEBUG=True` in production leaks stack traces.
    > **Recommendation**: Ensure `DEBUG=False` in production `deploy_vps.py`.
3.  **Secret Key**: Hardcoded or `.env` dependent.
    > **Recommendation**: Rotate `SECRET_KEY` on production deploy.
