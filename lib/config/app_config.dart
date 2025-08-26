import 'secrets.dart';

class AppConfig {
  static const String appName = 'AgroFlow';
  static const String version = '1.0.0';
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const bool enableLogging = !isProduction;
  
  // API Configuration - obfuscated in release
  static String get baseUrl => isProduction 
    ? 'https://api.agroflow.com' 
    : 'https://dev-api.agroflow.com';
  static const int timeoutDuration = 30; // seconds
  
  // Secure API access
  static String get openAIKey => Secrets.openAIKey;
  static String get firebaseKey => Secrets.firebaseKey;
  static String get metaApiKey => Secrets.metaApiKey;
  
  // Feature flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePerformanceMonitoring = true;
  
  // Cache configuration
  static const int cacheExpirationHours = 24;
  static const int maxCacheSize = 50; // MB - reduced for smaller footprint
}