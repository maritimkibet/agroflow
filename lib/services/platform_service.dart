import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformService {
  static PlatformService? _instance;
  
  static PlatformService get instance {
    _instance ??= PlatformService._internal();
    return _instance!;
  }
  
  PlatformService._internal();

  /// Get current platform information
  PlatformInfo get platformInfo {
    if (kIsWeb) {
      return const PlatformInfo(
        type: PlatformType.web,
        name: 'Web',
        supportsNotifications: false,
        supportsFileSystem: false,
        supportsCamera: true,
        supportsLocation: true,
      );
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const PlatformInfo(
          type: PlatformType.android,
          name: 'Android',
          supportsNotifications: true,
          supportsFileSystem: true,
          supportsCamera: true,
          supportsLocation: true,
        );
      case TargetPlatform.iOS:
        return const PlatformInfo(
          type: PlatformType.ios,
          name: 'iOS',
          supportsNotifications: true,
          supportsFileSystem: true,
          supportsCamera: true,
          supportsLocation: true,
        );
      case TargetPlatform.windows:
        return const PlatformInfo(
          type: PlatformType.windows,
          name: 'Windows',
          supportsNotifications: false,
          supportsFileSystem: true,
          supportsCamera: false,
          supportsLocation: false,
        );
      case TargetPlatform.macOS:
        return const PlatformInfo(
          type: PlatformType.macos,
          name: 'macOS',
          supportsNotifications: false,
          supportsFileSystem: true,
          supportsCamera: false,
          supportsLocation: false,
        );
      case TargetPlatform.linux:
        return const PlatformInfo(
          type: PlatformType.linux,
          name: 'Linux',
          supportsNotifications: false,
          supportsFileSystem: true,
          supportsCamera: false,
          supportsLocation: false,
        );
      default:
        return const PlatformInfo(
          type: PlatformType.unknown,
          name: 'Unknown',
          supportsNotifications: false,
          supportsFileSystem: false,
          supportsCamera: false,
          supportsLocation: false,
        );
    }
  }

  /// Check if current platform supports a specific feature
  bool supportsFeature(PlatformFeature feature) {
    final info = platformInfo;
    switch (feature) {
      case PlatformFeature.notifications:
        return info.supportsNotifications;
      case PlatformFeature.fileSystem:
        return info.supportsFileSystem;
      case PlatformFeature.camera:
        return info.supportsCamera;
      case PlatformFeature.location:
        return info.supportsLocation;
    }
  }

  /// Get platform-specific storage path
  String getStoragePath() {
    if (kIsWeb) {
      return 'web_storage';
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return 'mobile_storage';
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return 'desktop_storage';
      default:
        return 'default_storage';
    }
  }

  /// Show platform-appropriate error message
  String getPlatformErrorMessage(String feature) {
    final platformName = platformInfo.name;
    return '$feature is not supported on $platformName. Please use a mobile device for full functionality.';
  }

  /// Get platform-specific app title
  String getAppTitle() {
    if (kIsWeb) {
      return 'AgroFlow - Global Agricultural Assistant';
    }
    return 'AgroFlow';
  }

  /// Check if platform supports offline functionality
  bool get supportsOfflineMode {
    return !kIsWeb; // Web requires internet, others can work offline
  }

  /// Get platform-specific theme adjustments
  ThemeData getPlatformTheme(ThemeData baseTheme) {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      // Desktop/Web adjustments
      return baseTheme.copyWith(
        visualDensity: VisualDensity.standard,
        // Larger touch targets for desktop
        materialTapTargetSize: MaterialTapTargetSize.padded,
      );
    }
    
    // Mobile adjustments
    return baseTheme.copyWith(
      visualDensity: VisualDensity.comfortable,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

enum PlatformType {
  android,
  ios,
  web,
  windows,
  macos,
  linux,
  unknown,
}

enum PlatformFeature {
  notifications,
  fileSystem,
  camera,
  location,
}

class PlatformInfo {
  final PlatformType type;
  final String name;
  final bool supportsNotifications;
  final bool supportsFileSystem;
  final bool supportsCamera;
  final bool supportsLocation;

  const PlatformInfo({
    required this.type,
    required this.name,
    required this.supportsNotifications,
    required this.supportsFileSystem,
    required this.supportsCamera,
    required this.supportsLocation,
  });
}