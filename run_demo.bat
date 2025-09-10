@echo off
title AgroFlow Demo Runner

echo 🌾 AgroFlow - AI-Powered Farming Assistant
echo ==========================================
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed or not in PATH
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo ✅ Flutter found
flutter --version | findstr "Flutter"
echo.

REM Get dependencies
echo 📦 Getting dependencies...
flutter pub get
echo.

REM Check for connected devices
echo 📱 Available devices:
flutter devices
echo.

REM Ask user which device to use
echo 🚀 Choose how to run the demo:
echo 1) Android device/emulator
echo 2) Chrome web browser
echo 3) Desktop app
echo 4) Let Flutter choose automatically
echo.

set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" (
    echo 🤖 Running on Android...
    flutter run -d android --release
) else if "%choice%"=="2" (
    echo 🌐 Running in Chrome...
    flutter run -d chrome --release
) else if "%choice%"=="3" (
    echo 🖥️ Running desktop app...
    flutter run -d windows --release
) else (
    echo 🎯 Auto-selecting device...
    flutter run --release
)

echo.
echo 🎉 Demo completed!
echo Thank you for trying AgroFlow!
pause