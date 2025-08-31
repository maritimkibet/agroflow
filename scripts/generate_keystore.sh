#!/bin/bash

# AgroFlow Keystore Generation Script
# This script generates a keystore for signing your Android app

echo "🔐 AgroFlow Keystore Generation"
echo "================================"

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ Error: keytool not found. Please install Java JDK."
    exit 1
fi

# Create android/app directory if it doesn't exist
mkdir -p android/app

# Keystore configuration
KEYSTORE_PATH="android/app/agroflow-release-key.jks"
KEY_ALIAS="agroflow"
VALIDITY_DAYS=10000

echo "📝 Please provide the following information for your keystore:"
echo ""

# Collect keystore information
read -p "Enter your full name: " FULL_NAME
read -p "Enter your organization: " ORGANIZATION
read -p "Enter your city: " CITY
read -p "Enter your state/province: " STATE
read -p "Enter your country code (e.g., US, KE, IN): " COUNTRY

echo ""
echo "🔑 Creating keystore..."

# Generate the keystore
keytool -genkey -v \
    -keystore "$KEYSTORE_PATH" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity "$VALIDITY_DAYS" \
    -dname "CN=$FULL_NAME, OU=$ORGANIZATION, O=$ORGANIZATION, L=$CITY, S=$STATE, C=$COUNTRY"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore created successfully!"
    echo "📍 Location: $KEYSTORE_PATH"
    echo ""
    
    # Generate SHA fingerprints
    echo "🔍 Generating SHA fingerprints..."
    echo ""
    
    echo "SHA-1 Fingerprint:"
    keytool -list -v -keystore "$KEYSTORE_PATH" -alias "$KEY_ALIAS" | grep "SHA1:" | cut -d' ' -f3
    
    echo ""
    echo "SHA-256 Fingerprint:"
    keytool -list -v -keystore "$KEYSTORE_PATH" -alias "$KEY_ALIAS" | grep "SHA256:" | cut -d' ' -f3
    
    echo ""
    echo "📋 Next Steps:"
    echo "1. Update android/app/build.gradle.kts with signing configuration"
    echo "2. Add keystore password to android/key.properties"
    echo "3. Use the SHA fingerprints for Firebase, Google Play Console, etc."
    echo ""
    echo "⚠️  IMPORTANT: Keep your keystore file and passwords secure!"
    echo "   Store them in a safe location and never commit to version control."
    
else
    echo "❌ Failed to create keystore"
    exit 1
fi