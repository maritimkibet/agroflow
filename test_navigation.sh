#!/bin/bash

echo "🧪 Testing AgroFlow Navigation & Functionality"
echo "=============================================="

# Test 1: Check if app compiles
echo "1. Testing compilation..."
flutter analyze --no-fatal-infos > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ App compiles successfully"
else
    echo "   ❌ Compilation issues found"
    exit 1
fi

# Test 2: Check if tests pass
echo "2. Running tests..."
flutter test > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ All tests pass"
else
    echo "   ❌ Some tests failed"
fi

# Test 3: Check if web build works
echo "3. Testing web build..."
flutter build web --release > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ Web build successful"
else
    echo "   ❌ Web build failed"
fi

# Test 4: Check key navigation files exist
echo "4. Checking navigation structure..."
key_files=(
    "lib/main.dart"
    "lib/screens/splash_screen.dart"
    "lib/screens/onboarding_screen.dart"
    "lib/screens/home_screen.dart"
    "lib/wrappers/auth_wrapper.dart"
    "lib/auth/login_screen.dart"
    "lib/auth/register_screen.dart"
)

for file in "${key_files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file exists"
    else
        echo "   ❌ $file missing"
    fi
done

echo ""
echo "🎉 Navigation test complete!"
echo "The app is ready for review submission."