// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/hive_service.dart';
import '../services/app_state_service.dart';
import '../services/error_handler_service.dart';
import 'package:firebase_database/firebase_database.dart';

class SplashScreen extends StatefulWidget {
  final DatabaseReference? databaseRef;

  const SplashScreen({super.key, this.databaseRef});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  final HiveService _hiveService = HiveService();
  final AppStateService _appStateService = AppStateService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Reduced from 2 seconds
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startAnimationAndNavigate();
  }

  Future<void> _startAnimationAndNavigate() async {
    try {
      // Start animation immediately
      _animationController.forward();
      
      // Log startup in background without blocking
      _logStartupInBackground();
      
      // Ensure minimum splash time of 2 seconds for better UX
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (!mounted) return;
      
      // Check app state to determine next route
      final nextRoute = await _appStateService.getNextRoute();
      Navigator.pushReplacementNamed(context, nextRoute);
    } catch (e) {
      if (mounted) {
        // Fallback to onboarding on error
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  void _logStartupInBackground() {
    // Run Firebase logging in background without awaiting
    widget.databaseRef?.child('splashCheck').set({'status': 'App started'}).catchError((e) {
      // Firebase write failed - handled silently in production
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use a more efficient icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AgroFlow',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You plant, we maintain.',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.brown.shade600,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
