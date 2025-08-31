import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  // Global error handler
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError('Flutter Error', details.exception, details.stack);
    };
  }

  // Log errors for debugging and analytics
  static void _logError(String type, dynamic error, StackTrace? stackTrace) {
    if (kDebugMode) {
      debugPrint('=== $type ===');
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
      debugPrint('================');
    }
    
    // In production, you would send this to crash analytics
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  // Handle and display user-friendly error messages
  static void handleError(BuildContext context, dynamic error, {String? customMessage}) {
    String message = customMessage ?? _getErrorMessage(error);
    
    _logError('User Error', error, null);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  // Show success messages
  static void showSuccess(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Show info messages
  static void showInfo(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Convert technical errors to user-friendly messages
  static String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    }
    
    // Firebase Auth errors
    if (errorString.contains('user-not-found')) {
      return 'No account found with this email address.';
    }
    if (errorString.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    }
    if (errorString.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (errorString.contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password.';
    }
    if (errorString.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (errorString.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    
    // Firestore errors
    if (errorString.contains('permission-denied')) {
      return 'You don\'t have permission to perform this action.';
    }
    if (errorString.contains('unavailable')) {
      return 'Service temporarily unavailable. Please try again.';
    }
    
    // Storage errors
    if (errorString.contains('storage')) {
      return 'Failed to upload file. Please try again.';
    }
    
    // Location errors
    if (errorString.contains('location')) {
      return 'Unable to access location. Please check permissions.';
    }
    
    // Generic errors
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    // Default message for unknown errors
    return 'Something went wrong. Please try again.';
  }

  // Show loading dialog
  static void showLoading(BuildContext context, {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  // Hide loading dialog
  static void hideLoading(BuildContext context) {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // Show confirmation dialog
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  // Retry mechanism for failed operations
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(delay * attempts);
      }
    }
    
    throw Exception('Max retries exceeded');
  }
}