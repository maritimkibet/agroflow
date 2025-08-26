#!/bin/bash

echo "🚀 Building AgroFlow for Production..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Generate code (for Hive adapters, etc.)
echo "🔧 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Build release APK
echo "📱 Building release APK..."
flutter build apk --release --split-per-abi

# Build release App Bundle (for Play Store)
echo "📦 Building release App Bundle..."
flutter build appbundle --release

echo "✅ Production build completed!"
echo "📁 APK files are in: build/app/outputs/flutter-apk/"
echo "📁 App Bundle is in: build/app/outputs/bundle/release/"

# Show file sizes
echo "📊 Build sizes:"
ls -lh build/app/outputs/flutter-apk/*.apk
ls -lh build/app/outputs/bundle/release/*.aab