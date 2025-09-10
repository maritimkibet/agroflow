@echo off
title AgroFlow Fix and Run Script
color 0A

echo 🔧 AgroFlow Fix and Run Script
echo ==============================
echo.

REM Check if Flutter is installed
echo [INFO] Checking Flutter installation...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter is not installed or not in PATH
    echo.
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    echo Then add it to your PATH and run this script again.
    pause
    exit /b 1
)

echo [SUCCESS] Flutter found
flutter --version | findstr "Flutter"
echo.

REM Check Flutter doctor
echo [INFO] Running Flutter doctor...
flutter doctor
echo.

REM Clean previous builds
echo [INFO] Cleaning previous builds...
flutter clean
if %errorlevel% equ 0 (
    echo [SUCCESS] Clean completed
) else (
    echo [ERROR] Clean failed
    pause
    exit /b 1
)
echo.

REM Get dependencies
echo [INFO] Getting dependencies...
flutter pub get
if %errorlevel% equ 0 (
    echo [SUCCESS] Dependencies installed successfully
) else (
    echo [ERROR] Failed to get dependencies
    pause
    exit /b 1
)
echo.

REM Generate Hive adapters if needed
echo [INFO] Checking for Hive type adapters...
if exist "lib\models\automation_response.g.dart" (
    echo [SUCCESS] Hive adapters found
) else (
    echo [WARNING] Generating Hive adapters...
    flutter packages pub run build_runner build --delete-conflicting-outputs
)
echo.

REM Check for connected devices
echo [INFO] Checking for connected devices...
flutter devices
echo.

REM Check for Firebase configuration
echo [INFO] Checking Firebase configuration...
if exist "android\app\google-services.json" (
    echo [SUCCESS] Android Firebase config found
) else (
    echo [WARNING] Android Firebase config missing ^(app will run in demo mode^)
)

if exist "ios\Runner\GoogleService-Info.plist" (
    echo [SUCCESS] iOS Firebase config found
) else (
    echo [WARNING] iOS Firebase config missing ^(app will run in demo mode^)
)
echo.

REM Fix common Android issues
echo [INFO] Fixing common Android issues...
if exist "android" (
    cd android
    if exist "gradlew.bat" (
        call gradlew.bat clean >nul 2>&1
        echo [SUCCESS] Android Gradle cleaned
    )
    cd ..
)
echo.

echo [SUCCESS] All fixes applied successfully!
echo.

REM Ask user how to run the app
echo 🚀 Choose how to run AgroFlow:
echo 1^) Android device/emulator
echo 2^) Chrome web browser
echo 3^) Windows desktop app
echo 4^) Auto-select best device
echo 5^) Just check setup ^(don't run^)
echo.

set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" (
    echo [INFO] Running on Android...
    flutter run -d android --release
) else if "%choice%"=="2" (
    echo [INFO] Running in Chrome...
    flutter run -d chrome --release
) else if "%choice%"=="3" (
    echo [INFO] Running Windows desktop app...
    flutter run -d windows --release
) else if "%choice%"=="4" (
    echo [INFO] Auto-selecting device...
    flutter run --release
) else if "%choice%"=="5" (
    echo [SUCCESS] Setup check completed!
    echo.
    echo To run the app manually, use:
    echo   flutter run --release
    goto end
) else (
    echo [WARNING] Invalid choice. Auto-selecting device...
    flutter run --release
)

echo.
echo [SUCCESS] AgroFlow demo completed!
echo Thank you for using AgroFlow! 🌾

:end
pause