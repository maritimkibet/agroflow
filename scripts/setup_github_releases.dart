import 'dart:io';
import 'package:yaml/yaml.dart';

/// Script to help set up GitHub Releases for AgroFlow updates
void main() async {
  print('🚀 AgroFlow GitHub Releases Setup');
  print('=====================================\n');
  
  // Read current version from pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    final pubspecContent = await pubspecFile.readAsString();
    final pubspec = loadYaml(pubspecContent);
    final currentVersion = pubspec['version'] as String;
    
    print('📱 Current app version: $currentVersion');
    print('');
  }
  
  print('📋 Setup Instructions:');
  print('======================');
  print('');
  print('1. 🔧 Update UpdateService configuration:');
  print('   - Open lib/services/update_service.dart');
  print('   - Replace "your-username" with your GitHub username');
  print('   - Replace "agroflow" with your repository name');
  print('');
  print('2. 📁 Create GitHub Actions workflow:');
  print('   - Create .github/workflows/release.yml');
  print('   - Copy the workflow template below');
  print('');
  print('3. 🏷️ Create releases:');
  print('   - Tag your commits: git tag v1.0.1');
  print('   - Push tags: git push origin v1.0.1');
  print('   - GitHub Actions will build and create release automatically');
  print('');
  print('4. 📦 Manual release (alternative):');
  print('   - Go to GitHub → Releases → Create new release');
  print('   - Upload your APK file');
  print('   - Add release notes');
  print('');
  
  await _createGitHubWorkflow();
  await _createReleaseTemplate();
  
  print('✅ Setup complete!');
  print('');
  print('🔄 To release updates:');
  print('1. Update version in pubspec.yaml');
  print('2. Commit changes');
  print('3. Create and push tag: git tag v1.0.1 && git push origin v1.0.1');
  print('4. GitHub Actions will build APK and create release');
  print('5. Users will be notified automatically');
}

Future<void> _createGitHubWorkflow() async {
  final workflowDir = Directory('.github/workflows');
  await workflowDir.create(recursive: true);
  
  final workflowFile = File('.github/workflows/release.yml');
  
  const workflowContent = '''name: Build and Release APK

on:
  push:
    tags:
      - 'v*'  # Triggers on version tags like v1.0.1

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'zulu'
        java-version: '17'
        
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        
    - name: Get dependencies
      run: flutter pub get
      
    - name: Generate code
      run: flutter packages pub run build_runner build --delete-conflicting-outputs
      
    - name: Build APK
      run: flutter build apk --release
      
    - name: Get version from tag
      id: get_version
      run: echo "VERSION=\${GITHUB_REF#refs/tags/}" >> \$GITHUB_OUTPUT
      
    - name: Create Release
      id: create_release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: \${{ steps.get_version.outputs.VERSION }}
        release_name: AgroFlow \${{ steps.get_version.outputs.VERSION }}
        body: |
          🌱 AgroFlow \${{ steps.get_version.outputs.VERSION }}
          
          ## What's New
          - Bug fixes and improvements
          - Enhanced performance
          
          ## Installation
          1. Download the APK file below
          2. Enable "Install from unknown sources" in Android settings
          3. Install the APK
        draft: false
        prerelease: false
        
    - name: Upload APK to Release
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: \${{ steps.create_release.outputs.upload_url }}
        asset_path: build/app/outputs/flutter-apk/app-release.apk
        asset_name: agroflow-\${{ steps.get_version.outputs.VERSION }}.apk
        asset_content_type: application/vnd.android.package-archive''';

  await workflowFile.writeAsString(workflowContent);
  print('✅ Created GitHub Actions workflow: .github/workflows/release.yml');
}

Future<void> _createReleaseTemplate() async {
  final templateFile = File('RELEASE_TEMPLATE.md');
  
  const templateContent = '''# AgroFlow Release Template

## Release Title Format
AgroFlow v1.0.1

## Release Notes Template

🌱 **AgroFlow v1.0.1**

### ✨ New Features
- Feature 1 description
- Feature 2 description

### 🐛 Bug Fixes
- Fixed issue with task synchronization
- Improved marketplace loading

### 🔧 Improvements
- Better offline performance
- Enhanced AI responses
- UI/UX improvements

### 📱 Installation
1. Download the APK file below
2. Enable "Install from unknown sources" in Android settings
3. Install the APK file

### 🔄 Upgrade Notes
- This version is compatible with all previous versions
- Your data will be preserved during upgrade''';

  await templateFile.writeAsString(templateContent);
  print('✅ Created release template: RELEASE_TEMPLATE.md');
}