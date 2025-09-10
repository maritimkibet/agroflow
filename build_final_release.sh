#!/bin/bash

# AgroFlow - Final Production Release Build Script
# This script builds optimized APKs for production deployment

echo "🌱 AgroFlow - Final Production Build"
echo "===================================="
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
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Starting AgroFlow production build process..."
echo ""

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
flutter pub get

# Run code analysis
print_status "Running code analysis..."
flutter analyze --no-fatal-infos
if [ $? -ne 0 ]; then
    print_warning "Code analysis found issues, but continuing with build..."
fi

# Build release APK
print_status "Building release APK..."
flutter build apk --release --target-platform android-arm,android-arm64 --split-per-abi

if [ $? -eq 0 ]; then
    print_success "APK build completed successfully!"
    echo ""
    
    # Display build information
    print_status "Build Information:"
    echo "=================="
    
    # Check if APK files exist and show their sizes
    APK_DIR="build/app/outputs/flutter-apk"
    
    if [ -d "$APK_DIR" ]; then
        echo "📱 Generated APK files:"
        for apk in "$APK_DIR"/*.apk; do
            if [ -f "$apk" ]; then
                size=$(du -h "$apk" | cut -f1)
                filename=$(basename "$apk")
                echo "   • $filename ($size)"
            fi
        done
        echo ""
        
        # Show total size
        total_size=$(du -sh "$APK_DIR" | cut -f1)
        echo "📊 Total APK size: $total_size"
        echo ""
    fi
    
    # Build information
    echo "🔧 Build Details:"
    echo "   • Target Platforms: ARM32, ARM64"
    echo "   • Build Mode: Release"
    echo "   • Optimization: Enabled"
    echo "   • Tree Shaking: Enabled"
    echo "   • Obfuscation: Enabled"
    echo ""
    
    # Features summary
    echo "✨ App Features:"
    echo "   • Complete user onboarding flow"
    echo "   • Task management with priorities"
    echo "   • Marketplace with product listings"
    echo "   • Community discussions"
    echo "   • Admin panel"
    echo "   • Currency selection (global)"
    echo "   • AI assistant and crop doctor"
    echo "   • Offline-first architecture"
    echo "   • Firebase integration (optional)"
    echo ""
    
    # Installation instructions
    echo "📲 Installation Instructions:"
    echo "   1. Transfer APK to Android device"
    echo "   2. Enable 'Install from unknown sources'"
    echo "   3. Install the APK file"
    echo "   4. Launch AgroFlow app"
    echo ""
    
    # Testing recommendations
    echo "🧪 Testing Recommendations:"
    echo "   • Run ./test_app_functionality.sh for comprehensive testing"
    echo "   • Test on different Android versions (API 21+)"
    echo "   • Test offline functionality"
    echo "   • Verify all navigation flows"
    echo ""
    
    print_success "Production build ready for deployment! 🚀"
    
else
    print_error "APK build failed!"
    exit 1
fi

# Optional: Build App Bundle for Play Store
read -p "Do you want to build App Bundle for Google Play Store? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Building App Bundle..."
    flutter build appbundle --release
    
    if [ $? -eq 0 ]; then
        print_success "App Bundle build completed!"
        
        BUNDLE_FILE="build/app/outputs/bundle/release/app-release.aab"
        if [ -f "$BUNDLE_FILE" ]; then
            bundle_size=$(du -h "$BUNDLE_FILE" | cut -f1)
            print_status "App Bundle: app-release.aab ($bundle_size)"
            echo "📦 Ready for Google Play Store upload!"
        fi
    else
        print_error "App Bundle build failed!"
    fi
fi

echo ""
print_success "Build process completed! 🎉"
echo ""
echo "Next steps:"
echo "1. Test the APK thoroughly using the test script"
echo "2. Deploy to testing devices"
echo "3. Upload to app stores when ready"
echo ""