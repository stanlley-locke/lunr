# Frontend Security Audit

## Overview
This document analyzes the security posture of the Lunr Flutter application.

## Data Storage
- **Local Storage**: `sqflite` stores chat history and contacts. `SharedPreferences` stores tokens.
    - **Risk**: Data on rooted/jailbroken devices can be accessed by other apps or users.
    - **Mitigation**: Use `flutter_secure_storage` for sensitive tokens (currently `SharedPreferences` is used for tokens, which is less secure).
    - **Action Item**: Migrate token storage to `flutter_secure_storage`.

## Network Communication
- **Transport**: All traffic uses HTTPS/WSS (when pointed to production).
    - **Certificate Pinning**: Not currently implemented. Vulnerable to MITM if user installs malicious CA.
- **API Keys**: No hardcoded API keys in source (Base URL via `dotenv`).

## Input Validation
- **Forms**: Basic validation exists for email/password fields.
- **XSS**: Flutter renders text as UI widgets, mitigating traditional XSS risks found in web apps.

## Media Handling
- **Downloads**: Images are cached by `cached_network_image`.
- **Uploads**: `image_picker` used. No client-side malware scanning (handled by backend or not at all).

## Recommendations
1.  **Secure Storage**: Move Auth Tokens to encrypted storage.
2.  **Obfuscation**: Use `--obfuscate` when building release APKs to hinder reverse engineering.
3.  **Biometrics**: Implement App Lock using local auth for an extra layer of privacy.
