import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Log error to Firebase for admin monitoring
  Future<void> logError(String error, String context, {Map<String, dynamic>? metadata}) async {
    try {
      await _firestore.collection('error_logs').add({
        'error': error,
        'context': context,
        'metadata': metadata ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'severity': _determineSeverity(error),
      });
    } catch (e) {
      // Silent fail for error logging
      debugPrint('Failed to log error: $e');
    }
  }

  // Handle errors gracefully with user-friendly messages
  void handleError(BuildContext context, dynamic error, String errorContext) {
    final userMessage = _getUserFriendlyMessage(error);
    
    // Log error for admin
    logError(error.toString(), errorContext);
    
    // Show user-friendly message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          backgroundColor: Colors.red.shade600,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              // Could implement retry logic here
            },
          ),
        ),
      );
    }
  }

  String _getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection issue. Please check your internet and try again.';
    } else if (errorString.contains('permission')) {
      return 'Permission denied. Please check your account permissions.';
    } else if (errorString.contains('firebase') || errorString.contains('firestore')) {
      return 'Server connection issue. Please try again in a moment.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('not found')) {
      return 'Requested item not found.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  String _determineSeverity(String error) {
    final errorString = error.toLowerCase();
    
    if (errorString.contains('crash') || errorString.contains('fatal')) {
      return 'critical';
    } else if (errorString.contains('network') || errorString.contains('timeout')) {
      return 'warning';
    } else {
      return 'info';
    }
  }
}