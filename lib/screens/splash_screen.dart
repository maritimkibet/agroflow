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
      duration: const Duration(milliseconds: 800), // Reduced from 2 seconds
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startAnimationAndNavigate();
  }

  Future<void> _startAnimationAndNavigate() async {
    // Start animation and navigation concurrently
    final animationFuture = _animationController.forward();
    final navigationFuture = _prepareAndNavigate();
    
    // Wait for both to complete, but ensure minimum 1 second total
    await Future.wait([
      animationFuture,
      Future.delayed(const Duration(seconds: 1)), // Exactly 1 second total
    ]);
    
    await navigationFuture;
  }

  Future<void> _prepareAndNavigate() async {
    // Log startup in background without blocking navigation
    _logStartupInBackground();
    
    await Future.delayed(const Duration(milliseconds: 1200)); // Show splash for 1.2 seconds
    if (!mounted) return;
    
    // Navigate to AuthWrapper which will handle the complete flow
    Navigator.pushReplacementNamed(context, '/auth');
  }

  void _logStartupInBackground() {
    // Run Firebase logging in background without awaiting
    widget.databaseRef.child('splashCheck').set({'status': 'App started'}).catchError((e) {
      debugPrint('Firebase write failed: $e');
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
