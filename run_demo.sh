#!/bin/bash

# AgroFlow Demo Runner Script
echo "🌾 AgroFlow - AI-Powered Farming Assistant"
echo "=========================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Check Flutter doctor
echo "🔍 Checking Flutter setup..."
flutter doctor --android-licenses > /dev/null 2>&1
echo ""

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get
echo ""

# Check for connected devices
echo "📱 Available devices:"
flutter devices
echo ""

# Ask user which device to use
echo "🚀 Choose how to run the demo:"
echo "1) Android device/emulator"
echo "2) iOS device/simulator (macOS only)"
echo "3) Chrome web browser"
echo "4) Desktop app"
echo "5) Let Flutter choose automatically"
echo ""

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo "🤖 Running on Android..."
        flutter run -d android --release
        ;;
    2)
        echo "🍎 Running on iOS..."
        flutter run -d ios --release
        ;;
    3)
        echo "🌐 Running in Chrome..."
        flutter run -d chrome --release
        ;;
    4)
        echo "🖥️ Running desktop app..."
        flutter run -d linux --release 2>/dev/null || flutter run -d macos --release 2>/dev/null || flutter run -d windows --release
        ;;
    5)
        echo "🎯 Auto-selecting device..."
        flutter run --release
        ;;
    *)
        echo "❌ Invalid choice. Running with auto-selection..."
        flutter run --release
        ;;
esac

echo ""
echo "🎉 Demo completed!"
echo "Thank you for trying AgroFlow!"