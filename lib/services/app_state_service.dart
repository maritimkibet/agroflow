import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hybrid_storage_service.dart';

class AppStateService {
  static final AppStateService _instance = AppStateService._internal();
  factory AppStateService() => _instance;
  AppStateService._internal();

  final HybridStorageService _storage = HybridStorageService();

  // Check if this is the first app launch
  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLaunched = prefs.getBool('app_launched_before') ?? false;
      return !hasLaunched;
    } catch (e) {
      debugPrint('Error checking first launch: $e');
      return true;
    }
  }

  // Mark app as launched
  Future<void> markAppAsLaunched() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_launched_before', true);
    } catch (e) {
      debugPrint('Error marking app as launched: $e');
    }
  }

  // Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('onboarding_complete') ?? false;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      return false;
    }
  }

  // Mark onboarding as complete
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
    }
  }

  // Check if profile is complete
  Future<bool> isProfileComplete() async {
    try {
      final user = _storage.getCurrentUser();
      return user?.name.isNotEmpty == true && user?.role != null;
    } catch (e) {
      debugPrint('Error checking profile status: $e');
      return false;
    }
  }

  // Reset app state (for testing or troubleshooting)
  Future<void> resetAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Clear user data - implement this method in HybridStorageService
      // await _storage.clearAllData();
    } catch (e) {
      debugPrint('Error resetting app state: $e');
    }
  }

  // Get next screen based on app state
  Future<String> getNextRoute() async {
    try {
      final isFirstTime = await isFirstLaunch();
      if (isFirstTime) {
        await markAppAsLaunched();
        return '/onboarding';
      }

      final onboardingComplete = await isOnboardingComplete();
      if (!onboardingComplete) {
        return '/onboarding';
      }

      final profileComplete = await isProfileComplete();
      if (!profileComplete) {
        return '/profile_setup';
      }

      return '/home';
    } catch (e) {
      debugPrint('Error determining next route: $e');
      return '/onboarding'; // Safe default
    }
  }
}