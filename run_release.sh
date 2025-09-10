#!/bin/bash

echo "🚀 AgroFlow - Release Mode"
echo "=========================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

echo "✅ Flutter found"

# Clean and get dependencies
echo "🧹 Cleaning and getting dependencies..."
flutter clean
flutter pub get

# Generate code for Hive models
echo "🔧 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Enable web support
echo "🌐 Enabling web support..."
flutter config --enable-web

# Run in release mode on Chrome
echo "🚀 Starting AgroFlow in Release Mode..."
echo ""
echo "📱 Features:"
echo "   ✅ No debug banner"
echo "   ✅ Optimized performance"
echo "   ✅ Production-ready build"
echo "   ✅ Multi-currency support"
echo "   ✅ Role switching"
echo "   ✅ Offline capabilities"
echo ""

# Run in release mode
flutter run -d chrome --release

echo "✅ AgroFlow started in release mode!"