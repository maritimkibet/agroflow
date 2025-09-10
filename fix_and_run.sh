#!/bin/bash

# AgroFlow - Fix and Run Script
echo "🔧 AgroFlow Fix and Run Script"
echo "=============================="
echo ""

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
print_status "Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    echo ""
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    echo "Then add it to your PATH and run this script again."
    exit 1
fi

print_success "Flutter found: $(flutter --version | head -n 1)"
echo ""

# Check Flutter doctor
print_status "Running Flutter doctor..."
flutter doctor
echo ""

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
print_success "Clean completed"
echo ""

# Get dependencies
print_status "Getting dependencies..."
flutter pub get
if [ $? -eq 0 ]; then
    print_success "Dependencies installed successfully"
else
    print_error "Failed to get dependencies"
    exit 1
fi
echo ""

# Generate Hive adapters if needed
print_status "Checking for Hive type adapters..."
if [ -f "lib/models/automation_response.g.dart" ]; then
    print_success "Hive adapters found"
else
    print_warning "Generating Hive adapters..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
fi
echo ""

# Check for connected devices
print_status "Checking for connected devices..."
flutter devices
echo ""

# Check for Firebase configuration (optional for demo)
print_status "Checking Firebase configuration..."
if [ -f "android/app/google-services.json" ]; then
    print_success "Android Firebase config found"
else
    print_warning "Android Firebase config missing (app will run in demo mode)"
fi

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    print_success "iOS Firebase config found"
else
    print_warning "iOS Firebase config missing (app will run in demo mode)"
fi
echo ""

# Fix common Android issues
print_status "Fixing common Android issues..."
if [ -d "android" ]; then
    cd android
    if [ -f "gradlew" ]; then
        ./gradlew clean > /dev/null 2>&1
        print_success "Android Gradle cleaned"
    fi
    cd ..
fi

# Fix common iOS issues (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Fixing common iOS issues..."
    if [ -d "ios" ]; then
        cd ios
        if command -v pod &> /dev/null; then
            pod install > /dev/null 2>&1
            print_success "iOS CocoaPods updated"
        else
            print_warning "CocoaPods not installed (iOS builds may fail)"
        fi
        cd ..
    fi
fi

echo ""
print_success "All fixes applied successfully!"
echo ""

# Ask user how to run the app
echo "🚀 Choose how to run AgroFlow:"
echo "1) Android device/emulator"
echo "2) iOS device/simulator (macOS only)"
echo "3) Chrome web browser"
echo "4) Desktop app"
echo "5) Auto-select best device"
echo "6) Just check setup (don't run)"
echo ""

read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        print_status "Running on Android..."
        flutter run -d android --release
        ;;
    2)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            print_status "Running on iOS..."
            flutter run -d ios --release
        else
            print_error "iOS development requires macOS"
            exit 1
        fi
        ;;
    3)
        print_status "Running in Chrome..."
        flutter run -d chrome --release
        ;;
    4)
        print_status "Running desktop app..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            flutter run -d linux --release
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            flutter run -d macos --release
        elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
            flutter run -d windows --release
        else
            print_error "Desktop platform not supported"
            exit 1
        fi
        ;;
    5)
        print_status "Auto-selecting device..."
        flutter run --release
        ;;
    6)
        print_success "Setup check completed!"
        echo ""
        echo "To run the app manually, use:"
        echo "  flutter run --release"
        exit 0
        ;;
    *)
        print_warning "Invalid choice. Auto-selecting device..."
        flutter run --release
        ;;
esac

echo ""
print_success "AgroFlow demo completed!"
echo "Thank you for using AgroFlow! 🌾"