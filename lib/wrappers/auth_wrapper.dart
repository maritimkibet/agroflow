import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/home_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/onboarding_screen.dart';
import '../services/hybrid_storage_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Check profile and onboarding status
    return FutureBuilder<Map<String, bool>>(
      future: _checkUserStatus(),
      builder: (context, statusSnapshot) {
        if (statusSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.green.shade50,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final status = statusSnapshot.data ?? {'profile': false, 'onboarding': false};
        final isProfileComplete = status['profile'] ?? false;
        final isOnboardingComplete = status['onboarding'] ?? false;
        
        if (!isProfileComplete) {
          return const ProfileSetupScreen();
        } else if (!isOnboardingComplete) {
          return const OnboardingScreen();
        } else {
          return const HomeScreen();
        }
      },
    );
  }

  Future<Map<String, bool>> _checkUserStatus() async {
    try {
      final storageService = HybridStorageService();
      final user = storageService.getCurrentUser();
      final isProfileComplete = user != null && user.name.isNotEmpty;
      
      final prefs = await SharedPreferences.getInstance();
      final isOnboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      
      return {
        'profile': isProfileComplete,
        'onboarding': isOnboardingComplete,
      };
    } catch (e) {
      debugPrint('Status check error: $e');
      return {'profile': false, 'onboarding': false};
    }
  }
}
