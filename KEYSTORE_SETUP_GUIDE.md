# AgroFlow Keystore & SHA Fingerprint Setup Guide

## Overview
This guide helps you set up app signing and generate SHA-1 and SHA-256 fingerprints for your AgroFlow app.

## Prerequisites
- Java JDK installed (for keytool command)
- Android development environment set up

## Step 1: Generate Release Keystore

### Option A: Using Our Script (Recommended)
```bash
./scripts/generate_keystore.sh
```

### Option B: Manual Generation
```bash
keytool -genkey -v \
    -keystore android/app/agroflow-release-key.jks \
    -alias agroflow \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000
```

## Step 2: Configure Key Properties

1. Copy the template:
```bash
cp android/key.properties.template android/key.properties
```

2. Edit `android/key.properties` with your actual values:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=agroflow
storeFile=agroflow-release-key.jks
```

⚠️ **Important**: Never commit `key.properties` to version control!

## Step 3: Get SHA Fingerprints

### Using Our Script (Recommended)
```bash
./scripts/get_sha_fingerprints.sh
```

### Manual Method
```bash
# For release keystore
keytool -list -v -keystore android/app/agroflow-release-key.jks -alias agroflow

# For debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey
```

## Step 4: Configure Services

### Firebase Console
1. Go to Project Settings > General
2. Add your Android app if not already added
3. Add SHA-1 and SHA-256 fingerprints
4. Download updated `google-services.json`
5. Replace the file in `android/app/`

### Google Play Console
1. Go to App Integrity
2. Add SHA-256 fingerprint for app signing
3. Configure Play App Signing if needed

### Google APIs (if using)
- **Google Sign-In**: Requires SHA-1 fingerprint
- **Google Maps**: Requires SHA-256 fingerprint
- **Google Drive API**: Requires SHA-1 fingerprint

## Step 5: Build Signed APK

### Debug Build
```bash
flutter build apk --debug
```

### Release Build
```bash
flutter build apk --release
```

### App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

## Fingerprint Examples

### SHA-1 Format
```
12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78
```

### SHA-256 Format
```
12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78
```

## Security Best Practices

### Keystore Security
- Store keystore file in a secure location
- Use strong passwords (minimum 8 characters)
- Keep multiple backups in different locations
- Never share keystore passwords in plain text
- Use environment variables for CI/CD

### Version Control
Add to `.gitignore`:
```
android/key.properties
android/app/*.jks
android/app/*.keystore
```

## Troubleshooting

### Common Issues

1. **"keytool not found"**
   - Install Java JDK
   - Add Java bin directory to PATH

2. **"Keystore was tampered with"**
   - Check password is correct
   - Verify keystore file integrity

3. **"Alias does not exist"**
   - List aliases: `keytool -list -keystore your-keystore.jks`
   - Use correct alias name

4. **Firebase authentication fails**
   - Verify SHA fingerprints are added to Firebase
   - Check package name matches
   - Ensure google-services.json is updated

### Verification Commands

```bash
# List keystore contents
keytool -list -v -keystore android/app/agroflow-release-key.jks

# Verify APK signature
jarsigner -verify -verbose -certs app-release.apk

# Check APK fingerprint
unzip -p app-release.apk META-INF/CERT.RSA | keytool -printcert
```

## Environment Variables (CI/CD)

For automated builds, use environment variables:

```bash
export KEYSTORE_PASSWORD="your_password"
export KEY_PASSWORD="your_key_password"
export KEY_ALIAS="agroflow"
export KEYSTORE_FILE="path/to/keystore.jks"
```

## Quick Reference

| Service | Required Fingerprint | Purpose |
|---------|---------------------|---------|
| Firebase Auth | SHA-1 | Authentication |
| Google Play | SHA-256 | App Signing |
| Google Maps | SHA-256 | API Access |
| Google Sign-In | SHA-1 | OAuth |
| Facebook Login | SHA-1 | Social Auth |

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all prerequisites are installed
3. Ensure file paths are correct
4. Check permissions on keystore files

For additional help, refer to:
- [Android App Signing Documentation](https://developer.android.com/studio/publish/app-signing)
- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment/android)