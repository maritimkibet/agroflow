import 'package:flutter/foundation.dart';
import 'package:agroflow/config/secrets.dart';

class AppConfig {
  // App Information
  static const String appName = 'AgroFlow';
  static const String appTagline = 'You plant, we maintain.';
  static const String version = '1.0.0';
  
  // Environment Configuration
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static bool get isDebug => kDebugMode;
  static const bool enableLogging = !isProduction;
  
  // API Configuration
  static String get baseUrl => isProduction 
    ? 'https://api.agroflow.com' 
    : 'https://dev-api.agroflow.com';
  static const int timeoutDuration = 30; // seconds
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  // Secure API access
  static String get openAIKey => Secrets.openAIKey;
  static String get firebaseKey => Secrets.firebaseKey;
  static String get metaApiKey => Secrets.metaApiKey;
  static String get makeWebhookUrl => Secrets.makeWebhookUrl;
  
  // Feature flags - Production ready
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableAutomation = true;
  static const bool enableSocialMedia = true;
  static const bool enableMarketplace = true;
  static const bool enableMessaging = true;
  static const bool enableCropDoctor = true;
  static const bool enableTraceability = true;
  static const bool enableClimateAdaptation = true;
  
  // Storage Configuration
  static const int maxImageSizeMB = 5;
  static const int imageQuality = 70;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  
  // Cache configuration
  static const int cacheExpirationHours = 24;
  static const int maxCacheSize = 50; // MB - optimized for production
  static const Duration cacheExpiry = Duration(hours: 24);
  
  // Validation Limits
  static const int maxProductNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int minPasswordLength = 6;
  static const int maxTaskTitleLength = 100;
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(milliseconds: 1200);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Location Configuration
  static const double defaultLocationAccuracy = 100.0;
  static const Duration locationTimeout = Duration(seconds: 10);
  
  // Automation Configuration
  static const Duration webhookTimeout = Duration(seconds: 15);
  static const int maxAutomationRetries = 2;
  
  // Supported Data
  static const List<String> supportedCrops = [
    'Tomatoes', 'Potatoes', 'Onions', 'Carrots', 'Lettuce', 'Spinach',
    'Cabbage', 'Broccoli', 'Cauliflower', 'Peppers', 'Cucumbers',
    'Beans', 'Peas', 'Corn', 'Wheat', 'Rice', 'Barley', 'Oats',
    'Soybeans', 'Sunflowers', 'Other'
  ];
  
  static const List<String> taskCategories = [
    'Planting', 'Watering', 'Fertilizing', 'Weeding', 'Harvesting',
    'Pest Control', 'Soil Preparation', 'Equipment Maintenance', 'Other'
  ];
  
  static const List<String> units = [
    'kg', 'lbs', 'tons', 'bags', 'boxes', 'pieces', 'liters', 'gallons'
  ];
  
  static const List<String> priorityLevels = ['Low', 'Medium', 'High', 'Urgent'];
  
  // Helper Methods
  static String getApiUrl(String endpoint) => '$baseUrl/$endpoint';
  
  static bool isFeatureEnabled(String feature) {
    switch (feature.toLowerCase()) {
      case 'automation': return enableAutomation;
      case 'social_media': return enableSocialMedia;
      case 'marketplace': return enableMarketplace;
      case 'messaging': return enableMessaging;
      case 'analytics': return enableAnalytics;
      case 'crop_doctor': return enableCropDoctor;
      case 'traceability': return enableTraceability;
      case 'climate_adaptation': return enableClimateAdaptation;
      default: return false;
    }
  }
}