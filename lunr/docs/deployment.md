# Frontend Deployment Guide

## Build Setup
Ensure you have the Flutter SDK (3.x+) installed.

### Android
1. **KeyStore**: Generate a production keystore file (`.jks`).
   ```bash
   keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
   ```
2. **Properties**: Configure `android/key.properties` (do not commit this file).
3. **Build APK**:
   ```bash
   flutter build apk --release --obfuscate --split-debug-info=/<project-name>/<directory>
   ```
4. **Build App Bundle** (Google Play):
   ```bash
   flutter build appbundle --release
   ```

### iOS
1. **Certificates**: Ensure you have a valid Apple Developer Account and signing certificates.
2. **Build Archive**:
   ```bash
   flutter build ipa --release
   ```
3. **Upload**: Use XCode or Transporter to upload to App Store Connect.

## Environment Configuration
- The app uses `flutter_dotenv`.
- Create a `.env` file in the root `lunr/` folder:
    ```env
    BASE_URL=https://your-domain.com/api
    SOCKET_URL=https://your-domain.com
    ```
- Ensure this file is included in assets via `pubspec.yaml`.

## Release Checklist
- [ ] Update version in `pubspec.yaml`.
- [ ] Run `flutter test`.
- [ ] Update `BASE_URL` to production endpoint.
- [ ] Build release binaries.
