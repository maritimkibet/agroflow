#!/bin/bash

# AgroFlow Release Script
# Usage: ./scripts/release.sh 1.0.1 "Release notes here"

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if version is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Version number required${NC}"
    echo "Usage: ./scripts/release.sh 1.0.1 \"Release notes\""
    exit 1
fi

VERSION=$1
RELEASE_NOTES=${2:-"Bug fixes and improvements"}

echo -e "${BLUE}🚀 AgroFlow Release Script${NC}"
echo -e "${BLUE}=========================${NC}"
echo ""
echo -e "${YELLOW}📋 Release Details:${NC}"
echo -e "   Version: ${GREEN}v$VERSION${NC}"
echo -e "   Notes: ${GREEN}$RELEASE_NOTES${NC}"
echo ""

# Confirm release
read -p "Continue with release? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⏹️  Release cancelled${NC}"
    exit 0
fi

echo -e "${BLUE}🔍 Running pre-release checks...${NC}"

# Run tests
echo -e "${YELLOW}   Running tests...${NC}"
if ! flutter test; then
    echo -e "${RED}❌ Tests failed! Fix issues before release.${NC}"
    exit 1
fi

# Run analysis
echo -e "${YELLOW}   Running analysis...${NC}"
if ! flutter analyze; then
    echo -e "${RED}❌ Analysis failed! Fix issues before release.${NC}"
    exit 1
fi

# Build APK to verify
echo -e "${YELLOW}   Building APK...${NC}"
if ! flutter build apk --release; then
    echo -e "${RED}❌ Build failed! Fix issues before release.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All checks passed!${NC}"
echo ""

# Update pubspec.yaml version
echo -e "${BLUE}📝 Updating version in pubspec.yaml...${NC}"
# This is a simple sed replacement - you might want to make it more robust
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^version: .*/version: $VERSION+$(date +%s)/" pubspec.yaml
else
    # Linux
    sed -i "s/^version: .*/version: $VERSION+$(date +%s)/" pubspec.yaml
fi

# Commit changes
echo -e "${BLUE}📦 Committing changes...${NC}"
git add .
git commit -m "Release v$VERSION: $RELEASE_NOTES"

# Create and push tag
echo -e "${BLUE}🏷️  Creating and pushing tag...${NC}"
git tag "v$VERSION"
git push origin main
git push origin "v$VERSION"

echo ""
echo -e "${GREEN}🎉 Release v$VERSION created successfully!${NC}"
echo ""
echo -e "${BLUE}📋 What happens next:${NC}"
echo -e "   1. GitHub Actions will build the APK"
echo -e "   2. A new release will be created automatically"
echo -e "   3. Users will be notified of the update"
echo ""
echo -e "${BLUE}🔗 Monitor progress:${NC}"
echo -e "   GitHub Actions: ${YELLOW}https://github.com/maritimkibet/agroflow/actions${NC}"
echo -e "   Releases: ${YELLOW}https://github.com/maritimkibet/agroflow/releases${NC}"
echo ""
echo -e "${GREEN}✨ Release complete!${NC}"