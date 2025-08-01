// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/hive_service.dart';
import 'package:firebase_database/firebase_database.dart';

class SplashScreen extends StatefulWidget {
  final DatabaseReference databaseRef;

  const SplashScreen({super.key, required this.databaseRef});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  final HiveService _hiveService = HiveService();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _startAnimationAndNavigate();
  }

  Future<void> _startAnimationAndNavigate() async {
    await _animationController.forward();
    await Future.delayed(const Duration(seconds: 1)); // Total 3 seconds
    await _logStartupAndNavigate();
  }

  Future<void> _logStartupAndNavigate() async {
    try {
      await widget.databaseRef.child('splashCheck').set({'status': 'App started'});
    } catch (e) {
      debugPrint('Firebase write failed: $e');
    }

    // Continue to auth wrapper
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/auth');
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
              Icon(Icons.eco, size: 100, color: Colors.green.shade700),
              const SizedBox(height: 24),
              Text(
                'AgroFlow',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You plant, we maintain.',
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.brown.shade600,
                ),
              ),
              const SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
