import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/onboarding_screen.dart';
import '../services/app_state_service.dart';
import '../services/error_handler_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _determineNextRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        final route = snapshot.data ?? '/onboarding';
        
        switch (route) {
          case '/onboarding':
            return const OnboardingScreen();
          case '/profile_setup':
            return const ProfileSetupScreen();
          case '/home':
            return const HomeScreen();
          default:
            return const OnboardingScreen();
        }
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 16),
            Text(
              'Loading AgroFlow...',
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _determineNextRoute() async {
    try {
      final appStateService = AppStateService();
      return await appStateService.getNextRoute();
    } catch (e) {
      debugPrint('Error determining app state: $e');
      final errorHandler = ErrorHandlerService();
      // Log error but don't show to user during startup
      errorHandler.logError('auth_wrapper_error', e.toString());
      // Default to onboarding on error
      return '/onboarding';
    }
  }
}
