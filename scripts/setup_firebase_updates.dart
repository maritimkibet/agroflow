import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to set up Firebase for app updates
/// Run this once to initialize the version info in Firebase
void main() async {
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  
  // Set up initial version info
  await firestore.collection('app_config').doc('version_info').set({
    'latest_version': '1.0.0',
    'latest_build_number': 1,
    'download_url': 'https://your-server.com/downloads/agroflow-latest.apk',
    'release_notes': '''
🌱 AgroFlow v1.0.0 - Initial Release

✅ Hybrid Storage System
- Firebase for marketplace (real-time)
- Hive for personal tasks (offline)

✅ Smart Features
- Location-aware AI assistant
- Role-based user experience
- Enhanced calendar with marked dates
- 1-second splash screen

✅ Marketplace
- Real-time product listings
- Image upload and display
- Global visibility

✅ Farming Tools
- Offline task management
- Smart sync when online
- Weather integration
    ''',
    'force_update': false,
    'min_supported_version': '1.0.0',
    'updated_at': FieldValue.serverTimestamp(),
  });
  
  print('✅ Firebase version info initialized successfully!');
  print('📱 Users will now receive update notifications');
  print('🔄 To push an update:');
  print('   1. Update the version info in Firebase');
  print('   2. Upload new APK to your server');
  print('   3. Users will be notified automatically');
}

/// Example of how to push an update
/// Call this function when you want to release a new version
Future<void> pushUpdate({
  required String version,
  required int buildNumber,
  required String downloadUrl,
  required String releaseNotes,
  bool forceUpdate = false,
  String? minSupportedVersion,
}) async {
  final firestore = FirebaseFirestore.instance;
  
  await firestore.collection('app_config').doc('version_info').update({
    'latest_version': version,
    'latest_build_number': buildNumber,
    'download_url': downloadUrl,
    'release_notes': releaseNotes,
    'force_update': forceUpdate,
    'min_supported_version': minSupportedVersion ?? version,
    'updated_at': FieldValue.serverTimestamp(),
  });
  
  print('✅ Update pushed successfully!');
  print('📱 Version: $version (Build $buildNumber)');
  print('🔄 Users will be notified on next app launch');
}

/// Example usage:
/// 
/// await pushUpdate(
///   version: '1.1.0',
///   buildNumber: 2,
///   downloadUrl: 'https://your-server.com/downloads/agroflow-v1.1.0.apk',
///   releaseNotes: '''
/// 🚀 AgroFlow v1.1.0 - New Features
/// 
/// ✅ New Features:
/// - Enhanced AI assistant
/// - Better offline sync
/// - Performance improvements
/// 
/// 🐛 Bug Fixes:
/// - Fixed calendar issues
/// - Improved image loading
/// ''',
///   forceUpdate: false,
/// );