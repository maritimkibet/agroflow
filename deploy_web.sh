#!/bin/bash

echo "🚀 AgroFlow - Web Deployment Script"
echo "===================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

echo "✅ Flutter and Firebase CLI found"

# Clean and get dependencies
echo "🧹 Cleaning and getting dependencies..."
flutter clean
flutter pub get

# Generate code for Hive models
echo "🔧 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Enable web support
echo "🌐 Ensuring web support is enabled..."
flutter config --enable-web

# Build for web
echo "🏗️ Building Flutter web app..."
flutter build web --release --web-renderer html

# Check if build was successful
if [ ! -d "build/web" ]; then
    echo "❌ Flutter web build failed"
    exit 1
fi

echo "✅ Flutter web build completed successfully"

# Login to Firebase (if not already logged in)
echo "🔐 Checking Firebase authentication..."
firebase login --no-localhost

# Deploy to Firebase Hosting
echo "🚀 Deploying to Firebase Hosting..."
firebase deploy --only hosting:agroflow-8227b-2b4a5

echo ""
echo "🎉 Deployment completed!"
echo "📱 Your AgroFlow app is now live at:"
echo "   https://agroflow-8227b-2b4a5.web.app"
echo ""
echo "✅ Features deployed:"
echo "   🌾 Complete farming management system"
echo "   🛒 Global marketplace with real-time updates"
echo "   💰 Multi-currency support (40+ currencies)"
echo "   📊 Offline-capable analytics"
echo "   🔄 Role switching (Farmer/Buyer/Both)"
echo "   🤖 AI-powered farming insights"
echo "   📱 Responsive design for all devices"