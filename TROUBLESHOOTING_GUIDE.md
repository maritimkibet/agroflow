# AgroFlow - Troubleshooting Guide

## Common Terminal Errors and Solutions

### 1. **Flutter Not Found Error**
```bash
zsh: command not found: flutter
```

**Solution:**
```bash
# Install Flutter SDK
# Download from: https://flutter.dev/docs/get-started/install

# Add Flutter to PATH (add to ~/.zshrc or ~/.bashrc)
export PATH="$PATH:/path/to/flutter/bin"

# Reload shell
source ~/.zshrc  # or source ~/.bashrc
```

### 2. **Dependencies Issues**
```bash
# Clean and get dependencies
flutter clean
flutter pub get
```

### 3. **Build Errors**
```bash
# For Android build issues
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

### 4. **Firebase Configuration Missing**
If you see Firebase errors:
```bash
# Make sure you have firebase configuration files:
# - android/app/google-services.json
# - ios/Runner/GoogleService-Info.plist
```

### 5. **Hive Database Issues**
```bash
# Clear Hive boxes if needed
flutter clean
# Remove app data from device/emulator
flutter run
```

## Quick Fix Commands

### Step 1: Clean Everything
```bash
flutter clean
flutter pub get
```

### Step 2: Check Flutter Setup
```bash
flutter doctor
flutter doctor --android-licenses  # Accept Android licenses
```

### Step 3: Run the App
```bash
# For development
flutter run

# For release (better performance)
flutter run --release

# For specific device
flutter run -d chrome      # Web
flutter run -d android     # Android
flutter run -d ios         # iOS (macOS only)
```

## Device-Specific Instructions

### Android
```bash
# Make sure Android SDK is installed
flutter doctor

# If emulator issues:
flutter emulators
flutter emulators --launch <emulator_name>
```

### iOS (macOS only)
```bash
# Install Xcode from App Store
# Install CocoaPods
sudo gem install cocoapods

# Navigate to iOS folder and install pods
cd ios
pod install
cd ..
```

### Web
```bash
# Enable web support
flutter config --enable-web
flutter run -d chrome
```

## Common Fixes for Specific Errors

### 1. **Gradle Build Failed**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### 2. **CocoaPods Issues (iOS)**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

### 3. **Firebase Auth Issues**
- Ensure Firebase project is set up
- Check google-services.json (Android) and GoogleService-Info.plist (iOS)
- Enable Authentication in Firebase Console

### 4. **Hive Type Adapter Issues**
```bash
# Regenerate Hive adapters
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## Environment Setup Checklist

- ✅ Flutter SDK installed and in PATH
- ✅ Android Studio/Xcode installed
- ✅ Device/Emulator connected
- ✅ Firebase project configured
- ✅ Dependencies up to date

## Demo Mode (No Firebase Required)

The app is configured to work in demo mode with mock data. If you're having Firebase issues, the app will still run with:
- Mock expense/income data
- Mock AI responses
- Mock community posts
- Local data storage only

## Performance Tips

1. **Use Release Mode for Demos:**
   ```bash
   flutter run --release
   ```

2. **Clear Cache if Slow:**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Check Device Performance:**
   ```bash
   flutter run --profile  # For performance analysis
   ```

## Getting Help

If you're still having issues:

1. **Check Flutter Doctor:**
   ```bash
   flutter doctor -v
   ```

2. **Check Device Connection:**
   ```bash
   flutter devices
   ```

3. **Run with Verbose Output:**
   ```bash
   flutter run -v
   ```

4. **Check Logs:**
   ```bash
   flutter logs
   ```

## Quick Start (Minimal Setup)

If you just want to run the app quickly:

```bash
# 1. Ensure Flutter is installed
flutter --version

# 2. Get dependencies
flutter pub get

# 3. Run on any available device
flutter run --release
```

The app is designed to work out of the box with mock data for presentation purposes!