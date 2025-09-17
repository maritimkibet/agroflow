# AgroFlow - Smart Agricultural Assistant

AI-powered farming companion with marketplace integration and offline-first design.

## Overview

AgroFlow is a mobile application designed to help farmers manage their agricultural activities, connect with buyers, and access AI-powered farming advice. The app works offline and syncs when connected to the internet.

## Features

- **Task Management**: Calendar-based task tracking with reminders
- **AI Assistant**: Agricultural advice and crop recommendations
- **Marketplace**: Buy and sell agricultural products
- **Real-time Chat**: In-app messaging between users
- **Weather Integration**: Location-based weather and farming tips
- **Offline Support**: Works without internet connection
- **Multi-role Support**: Farmer, buyer, or both roles

## Installation

### For Users
1. Download the latest APK from releases
2. Install on Android device
3. Create account and start using

### For Developers
```bash
git clone https://github.com/maritimkibet/agroflow.git
cd agroflow
flutter pub get
dart run build_runner build
flutter run
```

## Technology Stack

- **Flutter**: Cross-platform mobile development
- **Firebase**: Authentication, Firestore, Realtime Database
- **Hive**: Local database for offline support
- **Material Design**: Modern UI components

## License

MIT License - see LICENSE file for details.
