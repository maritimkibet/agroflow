#!/bin/bash

echo "🌾 AgroFlow - Release Web Server"
echo "================================"

# Check if the web build exists
if [ ! -d "build/web" ]; then
    echo "❌ Web build not found. Please run 'flutter build web --release' first."
    exit 1
fi

echo "✅ Web build found"

# Check if Python is available for serving
if command -v python3 &> /dev/null; then
    echo "🚀 Starting AgroFlow web server on http://localhost:8080"
    echo ""
    echo "📱 Features available in this release:"
    echo "   ✅ No debug banner"
    echo "   ✅ Optimized performance"
    echo "   ✅ Production-ready build"
    echo "   ✅ Multi-currency support"
    echo "   ✅ Role switching (Farmer/Admin)"
    echo "   ✅ Offline capabilities"
    echo "   ✅ AI Assistant"
    echo "   ✅ Marketplace"
    echo "   ✅ Community features"
    echo "   ✅ Expense tracking"
    echo "   ✅ Calendar & tasks"
    echo ""
    echo "🎥 Perfect for screen recording!"
    echo "📖 Open http://localhost:8080 in Chrome for best experience"
    echo ""
    echo "Press Ctrl+C to stop the server"
    echo ""
    
    cd build/web && python3 -m http.server 8080
elif command -v python &> /dev/null; then
    echo "🚀 Starting AgroFlow web server on http://localhost:8080"
    echo ""
    echo "📱 Features available in this release:"
    echo "   ✅ No debug banner"
    echo "   ✅ Optimized performance"
    echo "   ✅ Production-ready build"
    echo "   ✅ Multi-currency support"
    echo "   ✅ Role switching (Farmer/Admin)"
    echo "   ✅ Offline capabilities"
    echo "   ✅ AI Assistant"
    echo "   ✅ Marketplace"
    echo "   ✅ Community features"
    echo "   ✅ Expense tracking"
    echo "   ✅ Calendar & tasks"
    echo ""
    echo "🎥 Perfect for screen recording!"
    echo "📖 Open http://localhost:8080 in Chrome for best experience"
    echo ""
    echo "Press Ctrl+C to stop the server"
    echo ""
    
    cd build/web && python -m SimpleHTTPServer 8080
else
    echo "❌ Python not found. Please install Python to serve the web app."
    echo "Alternative: Use any web server to serve the 'build/web' directory"
    exit 1
fi