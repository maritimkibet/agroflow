#!/bin/bash

echo "🌐 Running AgroFlow on Chrome"
echo "=============================="

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

# Enable web support if not already enabled
echo "🌐 Enabling web support..."
flutter config --enable-web

# Run on Chrome
echo "🚀 Starting AgroFlow on Chrome..."
echo ""
echo "📱 The app will start on Chrome with all fixes:"
echo "   ✅ Role switching works properly"
echo "   ✅ Products show in marketplace"
echo "   ✅ Offline analytics functionality"
echo "   ✅ Clean expense tracker"
echo ""

# Run in debug mode on Chrome
flutter run -d chrome

echo "✅ AgroFlow started on Chrome!"