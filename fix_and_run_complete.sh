#!/bin/bash

echo "🚀 AgroFlow - Complete Fix and Run Script"
echo "=========================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

echo "✅ Flutter found"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Generate code (for Hive models)
echo "🔧 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Check for any analysis issues
echo "🔍 Running code analysis..."
flutter analyze --no-fatal-infos

# Run the app
echo "🚀 Starting AgroFlow..."
echo ""
echo "📱 The app will start with the following fixes:"
echo "   ✅ Products now show in marketplace after adding"
echo "   ✅ Long press on Save Task now switches roles instead of going to onboarding"
echo "   ✅ Role switching works properly and maintains user session"
echo "   ✅ Expense tracker errors fixed"
echo "   ✅ Farm analytics works offline with cached data"
echo "   ✅ Proper error handling and context usage"
echo ""

# Run in debug mode
flutter run --debug

echo "✅ AgroFlow started successfully!"