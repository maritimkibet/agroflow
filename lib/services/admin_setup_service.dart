import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminSetupService {
  static final AdminSetupService _instance = AdminSetupService._internal();
  factory AdminSetupService() => _instance;
  AdminSetupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize default admin accounts
  Future<void> initializeDefaultAdmins() async {
    try {
      // Check if admin setup is already done
      final prefs = await SharedPreferences.getInstance();
      final isSetup = prefs.getBool('admin_setup_complete') ?? false;
      
      if (isSetup) {
        debugPrint('Admin setup already completed');
        return;
      }

      final admins = [
        {
          'id': 'admin_brian_001',
          'email': 'devbrian01@gmail.com',
          'name': 'Brian Vocaldo',
          'role': 'superAdmin',
          'password': 'brianvocaldo', // Will be hashed when first login
          'permissions': [
            'user_management',
            'content_moderation',
            'system_admin',
            'analytics_view',
            'support_tickets',
          ],
          'createdAt': DateTime.now().toIso8601String(),
          'lastLogin': null,
          'isActive': true,
          'mustChangePassword': true, // Force password change on first login
        },
      ];

      for (final admin in admins) {
        try {
          // Check if admin already exists
          final existingAdmin = await _firestore
              .collection('admins')
              .where('email', isEqualTo: admin['email'])
              .get();

          if (existingAdmin.docs.isEmpty) {
            await _firestore.collection('admins').doc(admin['id'] as String).set(admin);
            debugPrint('Created admin: ${admin['email']}');
          } else {
            debugPrint('Admin already exists: ${admin['email']}');
          }
        } catch (e) {
          debugPrint('Error creating admin ${admin['email']}: $e');
        }
      }
      
      // Mark admin setup as complete
      await prefs.setBool('admin_setup_complete', true);
      debugPrint('Admin setup completed successfully');
    } catch (e) {
      debugPrint('Error initializing admins: $e');
    }
  }

  // Verify admin credentials
  Future<Map<String, dynamic>?> verifyAdminCredentials(String email, String password) async {
    try {
      final adminQuery = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .where('isActive', isEqualTo: true)
          .get();

      if (adminQuery.docs.isEmpty) {
        return null;
      }

      final adminDoc = adminQuery.docs.first;
      final adminData = adminDoc.data();
      
      // Simple password check (in production, use proper hashing)
      if (adminData['password'] == password) {
        // Update last login
        await adminDoc.reference.update({
          'lastLogin': DateTime.now().toIso8601String(),
        });
        
        return adminData;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error verifying admin credentials: $e');
      return null;
    }
  }

  // Update admin password
  Future<bool> updateAdminPassword(String adminId, String newPassword) async {
    try {
      await _firestore.collection('admins').doc(adminId).update({
        'password': newPassword, // In production, hash this
        'mustChangePassword': false,
        'lastPasswordChange': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating admin password: $e');
      return false;
    }
  }
}