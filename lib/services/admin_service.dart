import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/admin_user.dart';
import '../models/user.dart';
import '../models/product.dart';
import 'admin_setup_service.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  // final DatabaseReference _database = FirebaseDatabase.instance.ref(); // Reserved for future use
  // final HybridStorageService _storage = HybridStorageService(); // Reserved for future use

  AdminUser? _currentAdmin;
  AdminUser? get currentAdmin => _currentAdmin;

  // Admin Authentication
  Future<bool> authenticateAdmin(String email, String password) async {
    try {
      // Use AdminSetupService for authentication
      final adminSetupService = AdminSetupService();
      final adminData = await adminSetupService.verifyAdminCredentials(email, password);
      
      if (adminData != null) {
        _currentAdmin = AdminUser(
          id: adminData['id'] ?? '',
          email: adminData['email'] ?? '',
          name: adminData['name'] ?? '',
          role: AdminRole.values.firstWhere(
            (role) => role.toString().split('.').last == adminData['role'],
            orElse: () => AdminRole.admin,
          ),
          permissions: List<String>.from(adminData['permissions'] ?? []),
          isActive: adminData['isActive'] ?? false,
          createdAt: DateTime.tryParse(adminData['createdAt'] ?? '') ?? DateTime.now(),
          lastLogin: DateTime.tryParse(adminData['lastLogin'] ?? '') ?? DateTime.now(),
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Admin authentication error: $e');
      return false;
    }
  }

  // User Management
  Future<List<User>> getAllUsers({int limit = 100}) async {
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .limit(limit)
          .orderBy('createdAt', descending: true)
          .get();

      return usersSnapshot.docs
          .map((doc) => User.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      int totalUsers = usersSnapshot.docs.length;
      int activeThisWeek = 0;
      int activeThisMonth = 0;
      int farmers = 0;
      int buyers = 0;

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final lastActive = DateTime.tryParse(userData['lastActive'] ?? '');
        final role = userData['role'] ?? 'farmer';

        if (lastActive != null) {
          if (lastActive.isAfter(weekAgo)) {
            activeThisWeek++;
          }
          if (lastActive.isAfter(monthAgo)) {
            activeThisMonth++;
          }
        }

        if (role == 'farmer') {
          farmers++;
        }
        if (role == 'buyer') {
          buyers++;
        }
      }

      return {
        'totalUsers': totalUsers,
        'activeThisWeek': activeThisWeek,
        'activeThisMonth': activeThisMonth,
        'farmers': farmers,
        'buyers': buyers,
        'growth': _calculateGrowthRate(usersSnapshot.docs),
      };
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return {};
    }
  }

  Future<bool> suspendUser(String userId, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
        'suspendedAt': DateTime.now().toIso8601String(),
        'suspensionReason': reason,
      });

      await _logAdminAction('suspend_user', {
        'userId': userId,
        'reason': reason,
      });

      return true;
    } catch (e) {
      debugPrint('Error suspending user: $e');
      return false;
    }
  }

  Future<bool> reactivateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': true,
        'suspendedAt': firestore.FieldValue.delete(),
        'suspensionReason': firestore.FieldValue.delete(),
        'reactivatedAt': DateTime.now().toIso8601String(),
      });

      await _logAdminAction('reactivate_user', {'userId': userId});
      return true;
    } catch (e) {
      debugPrint('Error reactivating user: $e');
      return false;
    }
  }

  // Support Ticket Management
  Future<List<SupportTicket>> getSupportTickets({
    TicketStatus? status,
    TicketPriority? priority,
    int limit = 50,
  }) async {
    try {
      firestore.Query query = _firestore
          .collection('support_tickets')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toString().split('.').last);
      }

      if (priority != null) {
        query = query.where('priority', isEqualTo: priority.toString().split('.').last);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return SupportTicket(
              id: doc.id,
              userId: data?['userId'] ?? '',
              userName: data?['userName'] ?? '',
              title: data?['title'] ?? '',
              description: data?['description'] ?? '',
              status: TicketStatus.values.firstWhere(
                (s) => s.toString().split('.').last == data?['status'],
                orElse: () => TicketStatus.open,
              ),
              priority: TicketPriority.values.firstWhere(
                (p) => p.toString().split('.').last == data?['priority'],
                orElse: () => TicketPriority.medium,
              ),
              category: data?['category'] ?? 'General',
              createdAt: DateTime.tryParse(data?['createdAt'] ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(data?['updatedAt'] ?? '') ?? DateTime.now(),
              assignedTo: data?['assignedTo'],
              tags: List<String>.from(data?['tags'] ?? []),
              metadata: Map<String, dynamic>.from(data?['metadata'] ?? {}),
            );
          })
          .toList();
    } catch (e) {
      debugPrint('Error fetching support tickets: $e');
      return [];
    }
  }

  Future<bool> updateTicketStatus(String ticketId, TicketStatus status) async {
    try {
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'status': status.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
        'assignedTo': _currentAdmin?.id,
      });

      await _logAdminAction('update_ticket', {
        'ticketId': ticketId,
        'status': status.toString().split('.').last,
      });

      return true;
    } catch (e) {
      debugPrint('Error updating ticket status: $e');
      return false;
    }
  }

  Future<bool> assignTicket(String ticketId, String adminId) async {
    try {
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'assignedTo': adminId,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await _logAdminAction('assign_ticket', {
        'ticketId': ticketId,
        'assignedTo': adminId,
      });

      return true;
    } catch (e) {
      debugPrint('Error assigning ticket: $e');
      return false;
    }
  }

  // Content Moderation
  Future<List<Product>> getFlaggedProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isFlagged', isEqualTo: true)
          .orderBy('flaggedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching flagged products: $e');
      return [];
    }
  }

  Future<bool> moderateProduct(String productId, bool approve, String reason) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isApproved': approve,
        'moderatedAt': DateTime.now().toIso8601String(),
        'moderationReason': reason,
        'moderatedBy': _currentAdmin?.id,
        'isFlagged': false,
      });

      await _logAdminAction('moderate_product', {
        'productId': productId,
        'approved': approve,
        'reason': reason,
      });

      return true;
    } catch (e) {
      debugPrint('Error moderating product: $e');
      return false;
    }
  }

  // Analytics and Monitoring
  Future<Map<String, dynamic>> getAppAnalytics() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      // Get various metrics
      final results = await Future.wait([
        _getUserAnalytics(weekAgo),
        _getProductAnalytics(weekAgo),
        _getMessageAnalytics(weekAgo),
        _getErrorAnalytics(weekAgo),
      ]);
      
      final userStats = results[0];
      final productStats = results[1];
      final messageStats = results[2];
      final errorStats = results[3];

      return {
        'users': userStats,
        'products': productStats,
        'messages': messageStats,
        'errors': errorStats,
        'timestamp': now.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting app analytics: $e');
      return {};
    }
  }

  Future<List<UserActivity>> getUserActivity(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add the document ID to the data
            return UserActivity.fromMap(data);
          })
          .toList();
    } catch (e) {
      debugPrint('Error fetching user activity: $e');
      return [];
    }
  }

  // System Health Monitoring
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final now = DateTime.now();
      final hourAgo = now.subtract(const Duration(hours: 1));

      // Check various system metrics
      final errorCount = await _getErrorCount(hourAgo);
      final activeUsers = await _getActiveUserCount(hourAgo);
      final responseTime = await _getAverageResponseTime();
      final storageUsage = await _getStorageUsage();

      return {
        'status': _determineSystemStatus(errorCount, responseTime),
        'errorCount': errorCount,
        'activeUsers': activeUsers,
        'responseTime': responseTime,
        'storageUsage': storageUsage,
        'lastChecked': now.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting system health: $e');
      return {'status': 'unknown'};
    }
  }

  // Helper Methods
  // Future<void> _updateLastLogin(String adminId) async {
  //   await _firestore.collection('admins').doc(adminId).update({
  //     'lastLogin': DateTime.now().toIso8601String(),
  //   });
  // }

  Future<void> _logAdminAction(String action, Map<String, dynamic> details) async {
    if (_currentAdmin == null) return;

    await _firestore.collection('admin_logs').add({
      'adminId': _currentAdmin!.id,
      'adminName': _currentAdmin!.name,
      'action': action,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // String _hashPassword(String password) {
  //   // In production, use proper password hashing like bcrypt
  //   return password; // Simplified for demo
  // }

  double _calculateGrowthRate(List<firestore.QueryDocumentSnapshot> docs) {
    // Calculate user growth rate over the last month
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    final twoMonthsAgo = now.subtract(const Duration(days: 60));

    int thisMonth = 0;
    int lastMonth = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      final createdAt = DateTime.tryParse(data?['createdAt'] ?? '');
      if (createdAt != null) {
        if (createdAt.isAfter(monthAgo)) {
          thisMonth++;
        } else if (createdAt.isAfter(twoMonthsAgo)) {
          lastMonth++;
        }
      }
    }

    if (lastMonth == 0) return 0.0;
    return ((thisMonth - lastMonth) / lastMonth) * 100;
  }

  Future<Map<String, dynamic>> _getUserAnalytics(DateTime since) async {
    final snapshot = await _firestore
        .collection('user_activities')
        .where('timestamp', isGreaterThan: since.toIso8601String())
        .get();

    return {
      'totalActivities': snapshot.docs.length,
      'uniqueUsers': snapshot.docs.map((doc) => doc.data()['userId']).toSet().length,
    };
  }

  Future<Map<String, dynamic>> _getProductAnalytics(DateTime since) async {
    final snapshot = await _firestore
        .collection('products')
        .where('createdAt', isGreaterThan: since.toIso8601String())
        .get();

    return {
      'newProducts': snapshot.docs.length,
      'categories': _getProductCategories(snapshot.docs),
    };
  }

  Future<Map<String, dynamic>> _getMessageAnalytics(DateTime since) async {
    final snapshot = await _firestore
        .collection('messages')
        .where('timestamp', isGreaterThan: since.toIso8601String())
        .get();

    return {
      'totalMessages': snapshot.docs.length,
      'uniqueConversations': _getUniqueConversations(snapshot.docs),
    };
  }

  Future<Map<String, dynamic>> _getErrorAnalytics(DateTime since) async {
    final snapshot = await _firestore
        .collection('error_logs')
        .where('timestamp', isGreaterThan: since.toIso8601String())
        .get();

    return {
      'totalErrors': snapshot.docs.length,
      'errorTypes': _getErrorTypes(snapshot.docs),
    };
  }

  Future<int> _getErrorCount(DateTime since) async {
    final snapshot = await _firestore
        .collection('error_logs')
        .where('timestamp', isGreaterThan: since.toIso8601String())
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getActiveUserCount(DateTime since) async {
    final snapshot = await _firestore
        .collection('user_activities')
        .where('timestamp', isGreaterThan: since.toIso8601String())
        .get();
    return snapshot.docs.map((doc) => doc.data()['userId']).toSet().length;
  }

  Future<double> _getAverageResponseTime() async {
    // This would typically come from your server monitoring
    return 250.0; // milliseconds
  }

  Future<Map<String, dynamic>> _getStorageUsage() async {
    // This would typically come from Firebase or your storage provider
    return {
      'used': '2.5GB',
      'total': '10GB',
      'percentage': 25.0,
    };
  }

  String _determineSystemStatus(int errorCount, double responseTime) {
    if (errorCount > 100 || responseTime > 1000) return 'critical';
    if (errorCount > 50 || responseTime > 500) return 'warning';
    return 'healthy';
  }

  Map<String, int> _getProductCategories(List<firestore.QueryDocumentSnapshot> docs) {
    final categories = <String, int>{};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      final category = data?['category'] ?? 'Other';
      categories[category] = (categories[category] ?? 0) + 1;
    }
    return categories;
  }

  int _getUniqueConversations(List<firestore.QueryDocumentSnapshot> docs) {
    final conversations = <String>{};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      final conversation = '${data?['senderId']}_${data?['receiverId']}';
      conversations.add(conversation);
    }
    return conversations.length;
  }

  Map<String, int> _getErrorTypes(List<firestore.QueryDocumentSnapshot> docs) {
    final errorTypes = <String, int>{};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      final errorType = data?['type'] ?? 'Unknown';
      errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;
    }
    return errorTypes;
  }

  // Logout
  void logout() {
    _currentAdmin = null;
  }
}