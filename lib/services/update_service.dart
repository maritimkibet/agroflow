import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateService {
  // GitHub repository info - UPDATE THESE WITH YOUR REPO DETAILS
  static const String _githubOwner = 'https://github.com/maritimkibet'; // Replace with your GitHub username
  static const String _githubRepo = 'ahttps://github.com/maritimkibet/agroflow'; // Replace with your repository name
  static const String _githubApiUrl = 'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';
  
  static const String _lastUpdateCheckKey = 'last_update_check';
  static const String _skipVersionKey = 'skip_version';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check for app updates
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.parse(packageInfo.buildNumber);

      // Check GitHub Releases first (primary)
      final updateInfo = await _checkGitHubReleases(currentVersion, currentBuildNumber);
      if (updateInfo != null) return updateInfo;

      // Fallback to Firebase if GitHub fails
      return await _checkFirebaseForUpdates(currentVersion, currentBuildNumber);
    } catch (e) {
      debugPrint('Update check failed: $e');
      return null;
    }
  }

  /// Check for updates from Firebase
  Future<UpdateInfo?> _checkFirebaseForUpdates(String currentVersion, int currentBuildNumber) async {
    try {
      final doc = await _firestore.collection('app_config').doc('version_info').get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      final latestVersion = data['latest_version'] as String;
      final latestBuildNumber = data['latest_build_number'] as int;
      final downloadUrl = data['download_url'] as String;
      final releaseNotes = data['release_notes'] as String? ?? '';
      final forceUpdate = data['force_update'] as bool? ?? false;
      final minSupportedVersion = data['min_supported_version'] as String?;

      // Check if update is needed
      if (latestBuildNumber > currentBuildNumber) {
        return UpdateInfo(
          latestVersion: latestVersion,
          currentVersion: currentVersion,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes,
          isForceUpdate: forceUpdate || _isVersionBelowMinimum(currentVersion, minSupportedVersion),
          buildNumber: latestBuildNumber,
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Firebase update check failed: $e');
      return null;
    }
  }

  /// Check for updates from GitHub Releases (primary method)
  Future<UpdateInfo?> _checkGitHubReleases(String currentVersion, int currentBuildNumber) async {
    try {
      final response = await http.get(
        Uri.parse(_githubApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'AgroFlow-App',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Parse GitHub release data
        final tagName = data['tag_name'] as String; // e.g., "v1.1.0"
        final releaseName = data['name'] as String? ?? tagName;
        final releaseBody = data['body'] as String? ?? '';
        final isDraft = data['draft'] as bool? ?? false;
        final isPrerelease = data['prerelease'] as bool? ?? false;
        
        // Skip draft or prerelease versions
        if (isDraft || isPrerelease) return null;
        
        // Extract version from tag (remove 'v' prefix if present)
        final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;
        
        // Find APK download URL from assets
        final assets = data['assets'] as List<dynamic>? ?? [];
        String? downloadUrl;
        
        for (final asset in assets) {
          final assetName = asset['name'] as String;
          if (assetName.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String;
            break;
          }
        }
        
        if (downloadUrl == null) {
          debugPrint('No APK found in GitHub release assets');
          return null;
        }
        
        // Parse version to build number for comparison
        final latestBuildNumber = _versionToBuildNumber(latestVersion);
        
        if (latestBuildNumber > currentBuildNumber) {
          return UpdateInfo(
            latestVersion: latestVersion,
            currentVersion: currentVersion,
            downloadUrl: downloadUrl,
            releaseNotes: _formatReleaseNotes(releaseName, releaseBody),
            isForceUpdate: false, // GitHub releases are typically optional
            buildNumber: latestBuildNumber,
          );
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('GitHub releases check failed: $e');
      return null;
    }
  }

  /// Convert version string to build number for comparison
  int _versionToBuildNumber(String version) {
    try {
      final parts = version.split('.');
      if (parts.length >= 3) {
        final major = int.parse(parts[0]);
        final minor = int.parse(parts[1]);
        final patch = int.parse(parts[2]);
        // Convert to single number: 1.2.3 -> 10203
        return major * 10000 + minor * 100 + patch;
      }
    } catch (e) {
      debugPrint('Failed to parse version: $version');
    }
    return 0;
  }

  /// Format GitHub release notes for display
  String _formatReleaseNotes(String releaseName, String releaseBody) {
    final buffer = StringBuffer();
    
    if (releaseName.isNotEmpty) {
      buffer.writeln('🚀 $releaseName\n');
    }
    
    if (releaseBody.isNotEmpty) {
      // Clean up markdown formatting for better display
      String cleanBody = releaseBody
          .replaceAll('##', '•')
          .replaceAll('#', '•')
          .replaceAll('**', '')
          .replaceAll('*', '•');
      
      buffer.write(cleanBody);
    } else {
      buffer.write('New version available with improvements and bug fixes.');
    }
    
    return buffer.toString().trim();
  }

  /// Check if current version is below minimum supported
  bool _isVersionBelowMinimum(String currentVersion, String? minVersion) {
    if (minVersion == null) return false;
    
    final current = _parseVersion(currentVersion);
    final minimum = _parseVersion(minVersion);
    
    for (int i = 0; i < 3; i++) {
      if (current[i] < minimum[i]) return true;
      if (current[i] > minimum[i]) return false;
    }
    
    return false;
  }

  /// Parse version string to list of integers
  List<int> _parseVersion(String version) {
    return version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }

  /// Show update dialog
  Future<void> showUpdateDialog(BuildContext context, UpdateInfo updateInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final skippedVersion = prefs.getString(_skipVersionKey);
    
    // Don't show if user skipped this version (unless force update)
    if (!updateInfo.isForceUpdate && skippedVersion == updateInfo.latestVersion) {
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        onUpdate: () => _downloadUpdate(updateInfo.downloadUrl),
        onSkip: updateInfo.isForceUpdate ? null : () => _skipVersion(updateInfo.latestVersion),
      ),
    );
  }

  /// Download and install update
  Future<void> _downloadUpdate(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to launch download URL: $e');
    }
  }

  /// Skip this version
  Future<void> _skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skipVersionKey, version);
  }

  /// Check if should check for updates (rate limiting)
  Future<bool> shouldCheckForUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastUpdateCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Check at most once every 6 hours
    const checkInterval = 6 * 60 * 60 * 1000; // 6 hours in milliseconds
    
    if (now - lastCheck > checkInterval) {
      await prefs.setInt(_lastUpdateCheckKey, now);
      return true;
    }
    
    return false;
  }

  /// Force check for updates (manual)
  Future<UpdateInfo?> forceCheckForUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastUpdateCheckKey, DateTime.now().millisecondsSinceEpoch);
    return await checkForUpdates();
  }

  /// Initialize Firebase version info (call this once to set up)
  Future<void> initializeVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      await _firestore.collection('app_config').doc('version_info').set({
        'latest_version': packageInfo.version,
        'latest_build_number': int.parse(packageInfo.buildNumber),
        'download_url': 'https://your-download-link.com/agroflow.apk', // Update this
        'release_notes': 'Initial release with hybrid storage and location-aware AI',
        'force_update': false,
        'min_supported_version': packageInfo.version,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Version info initialized in Firebase');
    } catch (e) {
      debugPrint('Failed to initialize version info: $e');
    }
  }
}

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isForceUpdate;
  final int buildNumber;

  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isForceUpdate,
    required this.buildNumber,
  });
}

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback onUpdate;
  final VoidCallback? onSkip;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onUpdate,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            updateInfo.isForceUpdate ? Icons.warning : Icons.system_update,
            color: updateInfo.isForceUpdate ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(updateInfo.isForceUpdate ? 'Update Required' : 'Update Available'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A new version of AgroFlow is available!',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Current: ${updateInfo.currentVersion}'),
              const SizedBox(width: 16),
              Text('Latest: ${updateInfo.latestVersion}'),
            ],
          ),
          if (updateInfo.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'What\'s New:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                updateInfo.releaseNotes,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          if (updateInfo.isForceUpdate) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This update is required to continue using the app.',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!updateInfo.isForceUpdate && onSkip != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onSkip!();
            },
            child: const Text('Skip'),
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onUpdate();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: updateInfo.isForceUpdate ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text(updateInfo.isForceUpdate ? 'Update Now' : 'Download'),
        ),
      ],
    );
  }
}