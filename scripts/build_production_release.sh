#!/bin/bash

# AgroFlow Production Build Script
# This script builds the app for production release

set -e

echo "🌾 AgroFlow Production Build Script"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter version:"
flutter --version

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Run code generation for Hive adapters
print_status "Running code generation..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Analyze code for issues
print_status "Analyzing code..."
if ! flutter analyze --no-fatal-infos; then
    print_warning "Code analysis found issues. Continuing with build..."
fi

# Run tests
print_status "Running tests..."
if ! flutter test; then
    print_warning "Some tests failed. Continuing with build..."
fi

# Build for Android (APK)
print_status "Building Android APK..."
flutter build apk --release --split-per-abi

# Build for Android (App Bundle)
print_status "Building Android App Bundle..."
flutter build appbundle --release

# Build for Web
print_status "Building for Web..."
flutter build web --release

# Build for iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Building for iOS..."
    flutter build ios --release --no-codesign
else
    print_warning "Skipping iOS build (not on macOS)"
fi

# Build for Windows (if on Windows or Linux)
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "linux-gnu"* ]]; then
    print_status "Building for Windows..."
    flutter build windows --release
fi

# Build for Linux (if on Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    print_status "Building for Linux..."
    flutter build linux --release
fi

# Build for macOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Building for macOS..."
    flutter build macos --release
fi

print_success "Build completed successfully!"

# Show build outputs
echo ""
echo "📦 Build Outputs:"
echo "=================="

if [ -f "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" ]; then
    echo "✅ Android APK (ARM64): build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
fi

if [ -f "build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" ]; then
    echo "✅ Android APK (ARM32): build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk"
fi

if [ -f "build/app/outputs/flutter-apk/app-x86_64-release.apk" ]; then
    echo "✅ Android APK (x64): build/app/outputs/flutter-apk/app-x86_64-release.apk"
fi

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    echo "✅ Android App Bundle: build/app/outputs/bundle/release/app-release.aab"
fi

if [ -d "build/web" ]; then
    echo "✅ Web Build: build/web/"
fi

if [ -d "build/ios/iphoneos/Runner.app" ]; then
    echo "✅ iOS Build: build/ios/iphoneos/Runner.app"
fi

if [ -d "build/windows/x64/runner/Release" ]; then
    echo "✅ Windows Build: build/windows/x64/runner/Release/"
fi

if [ -d "build/linux/x64/release/bundle" ]; then
    echo "✅ Linux Build: build/linux/x64/release/bundle/"
fi

if [ -d "build/macos/Build/Products/Release/agroflow.app" ]; then
    echo "✅ macOS Build: build/macos/Build/Products/Release/agroflow.app"
fi

echo ""
print_success "🎉 AgroFlow production build completed!"
print_status "Ready for deployment to app stores and web hosting."

# Calculate build sizes
echo ""
echo "📊 Build Sizes:"
echo "==============="

if [ -f "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" ]; then
    size=$(du -h "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" | cut -f1)
    echo "Android APK (ARM64): $size"
fi

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    size=$(du -h "build/app/outputs/bundle/release/app-release.aab" | cut -f1)
    echo "Android App Bundle: $size"
fi

if [ -d "build/web" ]; then
    size=$(du -sh "build/web" | cut -f1)
    echo "Web Build: $size"
fi

echo ""
print_status "Build script completed at $(date)"