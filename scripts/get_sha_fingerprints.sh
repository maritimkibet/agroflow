#!/bin/bash

# AgroFlow SHA Fingerprint Generator
# This script generates SHA-1 and SHA-256 fingerprints for your app

echo "🔍 AgroFlow SHA Fingerprint Generator"
echo "====================================="

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ Error: keytool not found. Please install Java JDK."
    exit 1
fi

# Function to get fingerprints from keystore
get_keystore_fingerprints() {
    local keystore_path=$1
    local alias=$2
    
    echo "📋 Keystore: $keystore_path"
    echo "🔑 Alias: $alias"
    echo ""
    
    # Get SHA-1
    echo "SHA-1 Fingerprint:"
    SHA1=$(keytool -list -v -keystore "$keystore_path" -alias "$alias" 2>/dev/null | grep "SHA1:" | cut -d' ' -f3)
    if [ -n "$SHA1" ]; then
        echo "  $SHA1"
    else
        echo "  ❌ Could not retrieve SHA-1"
    fi
    
    echo ""
    
    # Get SHA-256
    echo "SHA-256 Fingerprint:"
    SHA256=$(keytool -list -v -keystore "$keystore_path" -alias "$alias" 2>/dev/null | grep "SHA256:" | cut -d' ' -f3)
    if [ -n "$SHA256" ]; then
        echo "  $SHA256"
    else
        echo "  ❌ Could not retrieve SHA-256"
    fi
    
    echo ""
}

# Check for release keystore
RELEASE_KEYSTORE="android/app/agroflow-release-key.jks"
if [ -f "$RELEASE_KEYSTORE" ]; then
    echo "🎯 RELEASE KEYSTORE FINGERPRINTS"
    echo "================================"
    get_keystore_fingerprints "$RELEASE_KEYSTORE" "agroflow"
else
    echo "⚠️  Release keystore not found at: $RELEASE_KEYSTORE"
    echo "   Run ./scripts/generate_keystore.sh to create one"
    echo ""
fi

# Check for debug keystore (default Flutter/Android location)
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"
if [ -f "$DEBUG_KEYSTORE" ]; then
    echo "🔧 DEBUG KEYSTORE FINGERPRINTS"
    echo "=============================="
    get_keystore_fingerprints "$DEBUG_KEYSTORE" "androiddebugkey"
else
    echo "⚠️  Debug keystore not found at: $DEBUG_KEYSTORE"
    echo ""
fi

# Alternative debug keystore locations
ALT_DEBUG_KEYSTORE="android/app/debug.keystore"
if [ -f "$ALT_DEBUG_KEYSTORE" ]; then
    echo "🔧 LOCAL DEBUG KEYSTORE FINGERPRINTS"
    echo "===================================="
    get_keystore_fingerprints "$ALT_DEBUG_KEYSTORE" "androiddebugkey"
fi

echo "📝 Usage Instructions:"
echo "====================="
echo ""
echo "🔥 Firebase Console:"
echo "   - Go to Project Settings > General"
echo "   - Add your SHA-1 and SHA-256 fingerprints"
echo "   - Download updated google-services.json"
echo ""
echo "📱 Google Play Console:"
echo "   - Use SHA-256 for app signing"
echo "   - Add to App Integrity section"
echo ""
echo "🔐 Google APIs:"
echo "   - Use SHA-1 for Google Sign-In"
echo "   - Use SHA-256 for Google Maps API"
echo ""
echo "⚠️  Important Notes:"
echo "   - Use RELEASE fingerprints for production"
echo "   - Use DEBUG fingerprints for development/testing"
echo "   - Keep your release keystore secure and backed up"