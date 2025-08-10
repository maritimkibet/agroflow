import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../screens/home_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../auth/login_screen.dart';
import '../services/hybrid_storage_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Check loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is not logged in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // If user is logged in, check if profile is complete
        return FutureBuilder(
          future: _checkProfileComplete(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final isProfileComplete = profileSnapshot.data ?? false;
            
            if (isProfileComplete) {
              return const HomeScreen();
            } else {
              return const ProfileSetupScreen();
            }
          },
        );
      },
    );
  }

  Future<bool> _checkProfileComplete() async {
    try {
      final storageService = HybridStorageService();
      final user = storageService.getCurrentUser();
      return user != null && user.name.isNotEmpty;
    } catch (e) {
      debugPrint('Profile check error: $e');
      return false;
    }
  }
}
