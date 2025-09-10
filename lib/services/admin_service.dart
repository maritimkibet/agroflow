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
      // Return mock users for presentation
      return _getMockUsers();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  List<User> _getMockUsers() {
    final now = DateTime.now();
    return [
      User(
        id: '1',
        name: 'John Smith',
        email: 'john.smith@example.com',
        phone: '+1-555-0123',
        role: UserRole.farmer,
        location: 'California, USA',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 30)),
        lastActive: now.subtract(const Duration(hours: 2)),
      ),
      User(
        id: '2',
        name: 'Maria Rodriguez',
        email: 'maria.rodriguez@example.com',
        phone: '+1-555-0124',
        role: UserRole.farmer,
        location: 'Texas, USA',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 25)),
        lastActive: now.subtract(const Duration(hours: 5)),
      ),
      User(
        id: '3',
        name: 'David Chen',
        email: 'david.chen@example.com',
        phone: '+1-555-0125',
        role: UserRole.buyer,
        location: 'New York, USA',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 20)),
        lastActive: now.subtract(const Duration(minutes: 30)),
      ),
      User(
        id: '4',
        name: 'Sarah Johnson',
        email: 'sarah.johnson@example.com',
        phone: '+1-555-0126',
        role: UserRole.farmer,
        location: 'Iowa, USA',
        isActive: false,
        createdAt: now.subtract(const Duration(days: 15)),
        lastActive: now.subtract(const Duration(days: 3)),
      ),
      User(
        id: '5',
        name: 'Ahmed Hassan',
        email: 'ahmed.hassan@example.com',
        phone: '+1-555-0127',
        role: UserRole.farmer,
        location: 'Michigan, USA',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 10)),
        lastActive: now.subtract(const Duration(hours: 1)),
      ),
      User(
        id: '6',
        name: 'Emma Thompson',
        email: 'emma.thompson@example.com',
        phone: '+1-555-0128',
        role: UserRole.buyer,
        location: 'Oregon, USA',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 8)),
        lastActive: now.subtract(const Duration(hours: 4)),
      ),
    ];
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
      // Return mock support tickets for presentation
      final allTickets = _getMockSupportTickets();
      
      // Filter by status and priority
      var filtered = allTickets.where((ticket) {
        if (status != null && ticket.status != status) return false;
        if (priority != null && ticket.priority != priority) return false;
        return true;
      }).toList();
      
      return filtered.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching support tickets: $e');
      return [];
    }
  }

  List<SupportTicket> _getMockSupportTickets() {
    final now = DateTime.now();
    return [
      SupportTicket(
        id: 'ticket_1',
        userId: '1',
        userName: 'John Smith',
        title: 'Unable to upload product images',
        description: 'I\'m having trouble uploading images for my tomato products. The upload keeps failing after 50%',
        status: TicketStatus.open,
        priority: TicketPriority.medium,
        category: 'Technical Issue',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        assignedTo: null,
        tags: ['upload', 'images', 'products'],
        metadata: {'browser': 'Chrome', 'device': 'Desktop'},
      ),
      SupportTicket(
        id: 'ticket_2',
        userId: '2',
        userName: 'Maria Rodriguez',
        title: 'Payment not processed correctly',
        description: 'My payment for the premium subscription was charged but my account still shows as free tier.',
        status: TicketStatus.inProgress,
        priority: TicketPriority.high,
        category: 'Billing',
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        assignedTo: 'admin_1',
        tags: ['payment', 'subscription', 'billing'],
        metadata: {'amount': '29.99', 'transaction_id': 'TXN_12345'},
      ),
      SupportTicket(
        id: 'ticket_3',
        userId: '3',
        userName: 'David Chen',
        title: 'Account verification issues',
        description: 'I submitted my documents for account verification 3 days ago but haven\'t received any update.',
        status: TicketStatus.resolved,
        priority: TicketPriority.low,
        category: 'Account',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 12)),
        assignedTo: 'admin_2',
        tags: ['verification', 'documents', 'account'],
        metadata: {'documents_submitted': '3', 'verification_type': 'business'},
      ),
      SupportTicket(
        id: 'ticket_4',
        userId: '4',
        userName: 'Sarah Johnson',
        title: 'Suspicious activity on my account',
        description: 'I noticed some login attempts from unknown locations. Please help secure my account.',
        status: TicketStatus.escalated,
        priority: TicketPriority.urgent,
        category: 'Security',
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
        assignedTo: 'admin_1',
        tags: ['security', 'login', 'suspicious'],
        metadata: {'failed_attempts': '5', 'locations': 'Unknown IP addresses'},
      ),
      SupportTicket(
        id: 'ticket_5',
        userId: '5',
        userName: 'Ahmed Hassan',
        title: 'Feature request: Bulk product upload',
        description: 'It would be great to have a feature to upload multiple products at once using CSV or Excel files.',
        status: TicketStatus.open,
        priority: TicketPriority.low,
        category: 'Feature Request',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        assignedTo: null,
        tags: ['feature', 'bulk-upload', 'products'],
        metadata: {'product_count': '50+', 'file_format': 'CSV preferred'},
      ),
    ];
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
      // Return mock flagged products for presentation
      return _getMockFlaggedProducts();
    } catch (e) {
      debugPrint('Error fetching flagged products: $e');
      return [];
    }
  }

  List<Product> _getMockFlaggedProducts() {
    final now = DateTime.now();
    return [
      Product(
        id: 'flagged_1',
        name: 'Organic Tomatoes - Premium Quality',
        type: ProductType.crop,
        listingType: ListingType.sell,
        description: 'Fresh organic tomatoes grown without pesticides',
        price: 4.99,
        category: 'Vegetables',
        sellerId: '1',
        tags: [],
        sellerName: 'John Smith',
        imageUrl: null,
        isAvailable: true,
        quantity: 100,
        unit: 'kg',
        location: 'California, USA',
        harvestDate: now.subtract(const Duration(days: 2)),
        expiryDate: now.add(const Duration(days: 7)),
        isOrganic: true,
        certifications: ['USDA Organic'],
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
      Product(
        id: 'flagged_2',
        name: 'Fresh Corn - Sweet Variety',
        type: ProductType.crop,
        listingType: ListingType.sell,
        description: 'Locally grown sweet corn, perfect for grilling',
        price: 2.50,
        category: 'Vegetables',
        sellerId: '2',
        tags: [],
        sellerName: 'Maria Rodriguez',
        imageUrl: null,
        isAvailable: true,
        quantity: 200,
        unit: 'pieces',
        location: 'Texas, USA',
        harvestDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.add(const Duration(days: 5)),
        isOrganic: false,
        certifications: [],
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
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
      
      // Return mock analytics data for presentation
      return {
        'users': {
          'totalActivities': 1247,
          'uniqueUsers': 342,
        },
        'products': {
          'newProducts': 28,
          'categories': {
            'Vegetables': 15,
            'Fruits': 8,
            'Grains': 5,
          },
        },
        'messages': {
          'totalMessages': 856,
          'uniqueConversations': 124,
        },
        'errors': {
          'totalErrors': 12,
          'errorTypes': {
            'Network': 7,
            'Validation': 3,
            'Database': 2,
          },
        },
        'timestamp': now.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting app analytics: $e');
      return {};
    }
  }

  Future<List<UserActivity>> getUserActivity(String userId, {int limit = 20}) async {
    try {
      // Return mock user activity for presentation
      return _getMockUserActivity(userId);
    } catch (e) {
      debugPrint('Error fetching user activity: $e');
      return [];
    }
  }

  List<UserActivity> _getMockUserActivity(String userId) {
    final now = DateTime.now();
    return [
      UserActivity(
        id: 'activity_1',
        userId: userId,
        action: 'login',
        details: 'User logged in from Chrome browser',
        timestamp: now.subtract(const Duration(hours: 2)),
        metadata: {'browser': 'Chrome', 'ip': '192.168.1.1'},
      ),
      UserActivity(
        id: 'activity_2',
        userId: userId,
        action: 'create_product',
        details: 'Created new product: Organic Tomatoes',
        timestamp: now.subtract(const Duration(hours: 4)),
        metadata: {'product_id': 'prod_123', 'category': 'Vegetables'},
      ),
      UserActivity(
        id: 'activity_3',
        userId: userId,
        action: 'send_message',
        details: 'Sent message to buyer about product inquiry',
        timestamp: now.subtract(const Duration(hours: 6)),
        metadata: {'recipient_id': 'user_456', 'message_type': 'inquiry_response'},
      ),
      UserActivity(
        id: 'activity_4',
        userId: userId,
        action: 'update_profile',
        details: 'Updated profile information',
        timestamp: now.subtract(const Duration(days: 1)),
        metadata: {'fields_updated': ['phone', 'location']},
      ),
      UserActivity(
        id: 'activity_5',
        userId: userId,
        action: 'logout',
        details: 'User logged out',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        metadata: {'session_duration': '3h 45m'},
      ),
    ];
  }

  // System Health Monitoring
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final now = DateTime.now();
      
      // Return mock system health data for presentation
      return {
        'status': 'healthy',
        'errorCount': 8,
        'activeUsers': 156,
        'responseTime': 245.0,
        'storageUsage': {
          'used': '2.5GB',
          'total': '10GB',
          'percentage': 25.0,
        },
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

  // Advanced Admin Features
  Future<bool> bulkUserAction(List<String> userIds, String action, {String? reason}) async {
    try {
      final batch = _firestore.batch();
      
      for (String userId in userIds) {
        final userRef = _firestore.collection('users').doc(userId);
        
        switch (action) {
          case 'suspend':
            batch.update(userRef, {
              'isActive': false,
              'suspendedAt': DateTime.now().toIso8601String(),
              'suspensionReason': reason ?? 'Bulk suspension',
            });
            break;
          case 'activate':
            batch.update(userRef, {
              'isActive': true,
              'suspendedAt': firestore.FieldValue.delete(),
              'suspensionReason': firestore.FieldValue.delete(),
            });
            break;
          case 'delete':
            batch.delete(userRef);
            break;
        }
      }
      
      await batch.commit();
      await _logAdminAction('bulk_user_action', {
        'action': action,
        'userCount': userIds.length,
        'reason': reason,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error performing bulk user action: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getAdvancedAnalytics() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Get comprehensive analytics
      final results = await Future.wait([
        _getRevenueAnalytics(monthAgo),
        _getUserEngagementAnalytics(weekAgo),
        _getPerformanceMetrics(),
        _getSecurityMetrics(weekAgo),
      ]);

      return {
        'revenue': results[0],
        'engagement': results[1],
        'performance': results[2],
        'security': results[3],
        'timestamp': now.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting advanced analytics: $e');
      return {};
    }
  }

  Future<bool> configureSystemSettings(Map<String, dynamic> settings) async {
    try {
      await _firestore.collection('system_config').doc('main').set(settings, firestore.SetOptions(merge: true));
      
      await _logAdminAction('update_system_settings', settings);
      return true;
    } catch (e) {
      debugPrint('Error configuring system settings: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSystemLogs({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection('system_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching system logs: $e');
      return [];
    }
  }

  Future<bool> sendBulkNotification(String title, String message, {
    List<String>? userIds,
    String? userRole,
  }) async {
    try {
      final notification = {
        'title': title,
        'message': message,
        'sentBy': _currentAdmin?.id,
        'sentAt': DateTime.now().toIso8601String(),
        'type': 'admin_broadcast',
      };

      if (userIds != null) {
        // Send to specific users
        final batch = _firestore.batch();
        for (String userId in userIds) {
          final notificationRef = _firestore.collection('notifications').doc();
          batch.set(notificationRef, {
            ...notification,
            'userId': userId,
          });
        }
        await batch.commit();
      } else {
        // Send to all users or specific role
        firestore.Query query = _firestore.collection('users');
        if (userRole != null) {
          query = query.where('role', isEqualTo: userRole);
        }
        
        final usersSnapshot = await query.get();
        final batch = _firestore.batch();
        
        for (var userDoc in usersSnapshot.docs) {
          final notificationRef = _firestore.collection('notifications').doc();
          batch.set(notificationRef, {
            ...notification,
            'userId': userDoc.id,
          });
        }
        await batch.commit();
      }

      await _logAdminAction('send_bulk_notification', {
        'title': title,
        'recipientCount': userIds?.length ?? 'all_users',
        'userRole': userRole,
      });

      return true;
    } catch (e) {
      debugPrint('Error sending bulk notification: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final collections = ['users', 'products', 'messages', 'notifications', 'support_tickets'];
      final stats = <String, int>{};
      
      for (String collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        stats[collection] = snapshot.docs.length;
      }
      
      return {
        'collections': stats,
        'totalDocuments': stats.values.reduce((a, b) => a + b),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting database stats: $e');
      return {};
    }
  }

  Future<bool> backupDatabase() async {
    try {
      // In a real implementation, this would trigger a database backup
      await _logAdminAction('database_backup', {
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'manual',
      });
      
      // Simulate backup process
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      debugPrint('Error backing up database: $e');
      return false;
    }
  }

  Future<bool> manageFeatureFlags(Map<String, bool> flags) async {
    try {
      await _firestore.collection('feature_flags').doc('main').set(flags, firestore.SetOptions(merge: true));
      
      await _logAdminAction('update_feature_flags', flags);
      return true;
    } catch (e) {
      debugPrint('Error managing feature flags: $e');
      return false;
    }
  }

  // Helper methods for advanced analytics
  Future<Map<String, dynamic>> _getRevenueAnalytics(DateTime since) async {
    // Simulate revenue analytics
    return {
      'totalRevenue': 125000.0,
      'monthlyGrowth': 12.5,
      'averageOrderValue': 85.50,
      'topProducts': ['Tomatoes', 'Corn', 'Wheat'],
    };
  }

  Future<Map<String, dynamic>> _getUserEngagementAnalytics(DateTime since) async {
    // Simulate user engagement analytics
    return {
      'dailyActiveUsers': 1250,
      'weeklyActiveUsers': 3500,
      'averageSessionDuration': 18.5, // minutes
      'bounceRate': 25.3, // percentage
    };
  }

  Future<Map<String, dynamic>> _getPerformanceMetrics() async {
    // Simulate performance metrics
    return {
      'averageResponseTime': 245.0, // milliseconds
      'uptime': 99.9, // percentage
      'errorRate': 0.1, // percentage
      'throughput': 1500, // requests per minute
    };
  }

  Future<Map<String, dynamic>> _getSecurityMetrics(DateTime since) async {
    // Simulate security metrics
    return {
      'blockedAttacks': 15,
      'suspiciousActivities': 5,
      'failedLoginAttempts': 23,
      'securityScore': 95, // out of 100
    };
  }

  // Logout
  void logout() {
    _currentAdmin = null;
  }
}

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
      // Return mock users for presentation
      return _getMockUsers();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  List<User> _getMockUsers() {
    final now = DateTime.now();
    return [
      User(
        id: '1',
        name: 'John Smith',
        email: 'john.smith@example.com',
        phone: '+1-555-0123',
        role: UserRole.farmer,
        location: 'California, USA',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 30)),
        lastActive: now.subtract(const Duration(hours: 2)),
      ),
      User(
        id: '2',
        name: 'Maria Rodriguez',
        email: 'maria.rodriguez@example.com',
        phone: '+1-555-0124',
        role: UserRole.farmer,
        location: 'Texas, USA',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 25)),
        lastActive: now.subtract(const Duration(hours: 5)),
      ),
      User(
        id: '3',
        name: 'David Chen',
        email: 'david.chen@example.com',
        phone: '+1-555-0125',
        role: UserRole.buyer,
        location: 'New York, USA',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 20)),
        lastActive: now.subtract(const Duration(minutes: 30)),
      ),
      User(
        id: '4',
        name: 'Sarah Johnson',
        email: 'sarah.johnson@example.com',
        phone: '+1-555-0126',
        role: UserRole.farmer,
        location: 'Iowa, USA',
        isActive: false,
        createdAt: now.subtract(const Duration(days: 15)),
        lastActive: now.subtract(const Duration(days: 3)),
      ),
      User(
        id: '5',
        name: 'Ahmed Hassan',
        email: 'ahmed.hassan@example.com',
        phone: '+1-555-0127',
        role: UserRole.farmer,
        location: 'Michigan, USA',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 10)),
        lastActive: now.subtract(const Duration(hours: 1)),
      ),
      User(
        id: '6',
        name: 'Emma Thompson',
        email: 'emma.thompson@example.com',
        phone: '+1-555-0128',
        role: UserRole.buyer,
        location: 'Oregon, USA',
        isActive: true,
        createdAt: now.subtract(const Duration(days: 8)),
        lastActive: now.subtract(const Duration(hours: 4)),
      ),
    ];
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
      // Return mock support tickets for presentation
      final allTickets = _getMockSupportTickets();
      
      // Filter by status and priority
      var filtered = allTickets.where((ticket) {
        if (status != null && ticket.status != status) return false;
        if (priority != null && ticket.priority != priority) return false;
        return true;
      }).toList();
      
      return filtered.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching support tickets: $e');
      return [];
    }
  }

  List<SupportTicket> _getMockSupportTickets() {
    final now = DateTime.now();
    return [
      SupportTicket(
        id: 'ticket_1',
        userId: '1',
        userName: 'John Smith',
        title: 'Unable to upload product images',
        description: 'I\'m having trouble uploading images for my tomato products. The upload keeps failing after 50%',
        status: TicketStatus.open,
        priority: TicketPriority.medium,
        category: 'Technical Issue',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        assignedTo: null,
        tags: ['upload', 'images', 'products'],
        metadata: {'browser': 'Chrome', 'device': 'Desktop'},
      ),
      SupportTicket(
        id: 'ticket_2',
        userId: '2',
        userName: 'Maria Rodriguez',
        title: 'Payment not processed correctly',
        description: 'My payment for the premium subscription was charged but my account still shows as free tier.',
        status: TicketStatus.inProgress,
        priority: TicketPriority.high,
        category: 'Billing',
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        assignedTo: 'admin_1',
        tags: ['payment', 'subscription', 'billing'],
        metadata: {'amount': '29.99', 'transaction_id': 'TXN_12345'},
      ),
      SupportTicket(
        id: 'ticket_3',
        userId: '3',
        userName: 'David Chen',
        title: 'Account verification issues',
        description: 'I submitted my documents for account verification 3 days ago but haven\'t received any update.',
        status: TicketStatus.resolved,
        priority: TicketPriority.low,
        category: 'Account',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 12)),
        assignedTo: 'admin_2',
        tags: ['verification', 'documents', 'account'],
        metadata: {'documents_submitted': '3', 'verification_type': 'business'},
      ),
      SupportTicket(
        id: 'ticket_4',
        userId: '4',
        userName: 'Sarah Johnson',
        title: 'Suspicious activity on my account',
        description: 'I noticed some login attempts from unknown locations. Please help secure my account.',
        status: TicketStatus.escalated,
        priority: TicketPriority.urgent,
        category: 'Security',
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
        assignedTo: 'admin_1',
        tags: ['security', 'login', 'suspicious'],
        metadata: {'failed_attempts': '5', 'locations': 'Unknown IP addresses'},
      ),
      SupportTicket(
        id: 'ticket_5',
        userId: '5',
        userName: 'Ahmed Hassan',
        title: 'Feature request: Bulk product upload',
        description: 'It would be great to have a feature to upload multiple products at once using CSV or Excel files.',
        status: TicketStatus.open,
        priority: TicketPriority.low,
        category: 'Feature Request',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        assignedTo: null,
        tags: ['feature', 'bulk-upload', 'products'],
        metadata: {'product_count': '50+', 'file_format': 'CSV preferred'},
      ),
    ];
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
      // Return mock flagged products for presentation
      return _getMockFlaggedProducts();
    } catch (e) {
      debugPrint('Error fetching flagged products: $e');
      return [];
    }
  }

  List<Product> _getMockFlaggedProducts() {
    final now = DateTime.now();
    return [
      Product(
        id: 'flagged_1',
        name: 'Organic Tomatoes - Premium Quality',
        type: ProductType.crop,
        listingType: ListingType.sell,
        description: 'Fresh organic tomatoes grown without pesticides',
        price: 4.99,
        category: 'Vegetables',
        sellerId: '1',
        tags: [],
        sellerName: 'John Smith',
        imageUrl: null,
        isAvailable: true,
        quantity: 100,
        unit: 'kg',
        location: 'California, USA',
        harvestDate: now.subtract(const Duration(days: 2)),
        expiryDate: now.add(const Duration(days: 7)),
        isOrganic: true,
        certifications: ['USDA Organic'],
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
      Product(
        id: 'flagged_2',
        name: 'Fresh Corn - Sweet Variety',
        type: ProductType.crop,
        listingType: ListingType.sell,
        description: 'Locally grown sweet corn, perfect for grilling',
        price: 2.50,
        category: 'Vegetables',
        sellerId: '2',
        tags: [],
        sellerName: 'Maria Rodriguez',
        imageUrl: null,
        isAvailable: true,
        quantity: 200,
        unit: 'pieces',
        location: 'Texas, USA',
        harvestDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.add(const Duration(days: 5)),
        isOrganic: false,
        certifications: [],
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
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
      
      // Return mock analytics data for presentation
      return {
        'users': {
          'totalActivities': 1247,
          'uniqueUsers': 342,
        },
        'products': {
          'newProducts': 28,
          'categories': {
            'Vegetables': 15,
            'Fruits': 8,
            'Grains': 5,
          },
        },
        'messages': {
          'totalMessages': 856,
          'uniqueConversations': 124,
        },
        'errors': {
          'totalErrors': 12,
          'errorTypes': {
            'Network': 7,
            'Validation': 3,
            'Database': 2,
          },
        },
        'timestamp': now.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting app analytics: $e');
      return {};
    }
  }

  Future<List<UserActivity>> getUserActivity(String userId, {int limit = 20}) async {
    try {
      // Return mock user activity for presentation
      return _getMockUserActivity(userId);
    } catch (e) {
      debugPrint('Error fetching user activity: $e');
      return [];
    }
  }

  List<UserActivity> _getMockUserActivity(String userId) {
    final now = DateTime.now();
    return [
      UserActivity(
        id: 'activity_1',
        userId: userId,
        action: 'login',
        details: 'User logged in from Chrome browser',
        timestamp: now.subtract(const Duration(hours: 2)),
        metadata: {'browser': 'Chrome', 'ip': '192.168.1.1'},
      ),
      UserActivity(
        id: 'activity_2',
        userId: userId,
        action: 'create_product',
        details: 'Created new product: Organic Tomatoes',
        timestamp: now.subtract(const Duration(hours: 4)),
        metadata: {'product_id': 'prod_123', 'category': 'Vegetables'},
      ),
      UserActivity(
        id: 'activity_3',
        userId: userId,
        action: 'send_message',
        details: 'Sent message to buyer about product inquiry',
        timestamp: now.subtract(const Duration(hours: 6)),
        metadata: {'recipient_id': 'user_456', 'message_type': 'inquiry_response'},
      ),
      UserActivity(
        id: 'activity_4',
        userId: userId,
        action: 'update_profile',
        details: 'Updated profile information',
        timestamp: now.subtract(const Duration(days: 1)),
        metadata: {'fields_updated': ['phone', 'location']},
      ),
      UserActivity(
        id: 'activity_5',
        userId: userId,
        action: 'logout',
        details: 'User logged out',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        metadata: {'session_duration': '3h 45m'},
      ),
    ];
  }

  // System Health Monitoring
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final now = DateTime.now();
      
      // Return mock system health data for presentation
      return {
        'status': 'healthy',
        'errorCount': 8,
        'activeUsers': 156,
        'responseTime': 245.0,
        'storageUsage': {
          'used': '2.5GB',
          'total': '10GB',
          'percentage': 25.0,
        },
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

  // Advanced Admin Features
  Future<bool> bulkUserAction(List<String> userIds, String action, {String? reason}) async {
    try {
      final batch = _firestore.batch();
      
      for (String userId in userIds) {
        final userRef = _firestore.collection('users').doc(userId);
        
        switch (action) {
          case 'suspend':
            batch.update(userRef, {
              'isActive': false,
              'suspendedAt': DateTime.now().toIso8601String(),
              'suspensionReason': reason ?? 'Bulk suspension',
            });
            break;
          case 'activate':
            batch.update(userRef, {
              'isActive': true,
              'suspendedAt': firestore.FieldValue.delete(),
              'suspensionReason': firestore.FieldValue.delete(),
            });
            break;
          case 'delete':
            batch.delete(userRef);
            break;
        }
      }
      
      await batch.commit();
      await _logAdminAction('bulk_user_action', {
        'action': action,
        'userCount': userIds.length,
        'reason': reason,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error performing bulk user action: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getAdvancedAnalytics() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Get comprehensive analytics
      final results = await Future.wait([
        _getRevenueAnalytics(monthAgo),
        _getUserEngagementAnalytics(weekAgo),
        _getPerformanceMetrics(),
        _getSecurityMetrics(weekAgo),
      ]);

      return {
        'revenue': results[0],
        'engagement': results[1],
        'performance': results[2],
        'security': results[3],
        'timestamp': now.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting advanced analytics: $e');
      return {};
    }
  }

  Future<bool> configureSystemSettings(Map<String, dynamic> settings) async {
    try {
      await _firestore.collection('system_config').doc('main').set(settings, firestore.SetOptions(merge: true));
      
      await _logAdminAction('update_system_settings', settings);
      return true;
    } catch (e) {
      debugPrint('Error configuring system settings: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSystemLogs({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection('system_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching system logs: $e');
      return [];
    }
  }

  Future<bool> sendBulkNotification(String title, String message, {
    List<String>? userIds,
    String? userRole,
  }) async {
    try {
      final notification = {
        'title': title,
        'message': message,
        'sentBy': _currentAdmin?.id,
        'sentAt': DateTime.now().toIso8601String(),
        'type': 'admin_broadcast',
      };

      if (userIds != null) {
        // Send to specific users
        final batch = _firestore.batch();
        for (String userId in userIds) {
          final notificationRef = _firestore.collection('notifications').doc();
          batch.set(notificationRef, {
            ...notification,
            'userId': userId,
          });
        }
        await batch.commit();
      } else {
        // Send to all users or specific role
        firestore.Query query = _firestore.collection('users');
        if (userRole != null) {
          query = query.where('role', isEqualTo: userRole);
        }
        
        final usersSnapshot = await query.get();
        final batch = _firestore.batch();
        
        for (var userDoc in usersSnapshot.docs) {
          final notificationRef = _firestore.collection('notifications').doc();
          batch.set(notificationRef, {
            ...notification,
            'userId': userDoc.id,
          });
        }
        await batch.commit();
      }

      await _logAdminAction('send_bulk_notification', {
        'title': title,
        'recipientCount': userIds?.length ?? 'all_users',
        'userRole': userRole,
      });

      return true;
    } catch (e) {
      debugPrint('Error sending bulk notification: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final collections = ['users', 'products', 'messages', 'notifications', 'support_tickets'];
      final stats = <String, int>{};
      
      for (String collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        stats[collection] = snapshot.docs.length;
      }
      
      return {
        'collections': stats,
        'totalDocuments': stats.values.reduce((a, b) => a + b),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting database stats: $e');
      return {};
    }
  }

  Future<bool> backupDatabase() async {
    try {
      // In a real implementation, this would trigger a database backup
      await _logAdminAction('database_backup', {
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'manual',
      });
      
      // Simulate backup process
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      debugPrint('Error backing up database: $e');
      return false;
    }
  }

  Future<bool> manageFeatureFlags(Map<String, bool> flags) async {
    try {
      await _firestore.collection('feature_flags').doc('main').set(flags, firestore.SetOptions(merge: true));
      
      await _logAdminAction('update_feature_flags', flags);
      return true;
    } catch (e) {
      debugPrint('Error managing feature flags: $e');
      return false;
    }
  }

  // Helper methods for advanced analytics
  Future<Map<String, dynamic>> _getRevenueAnalytics(DateTime since) async {
    // Simulate revenue analytics
    return {
      'totalRevenue': 125000.0,
      'monthlyGrowth': 12.5,
      'averageOrderValue': 85.50,
      'topProducts': ['Tomatoes', 'Corn', 'Wheat'],
    };
  }

  Future<Map<String, dynamic>> _getUserEngagementAnalytics(DateTime since) async {
    // Simulate user engagement analytics
    return {
      'dailyActiveUsers': 1250,
      'weeklyActiveUsers': 3500,
      'averageSessionDuration': 18.5, // minutes
      'bounceRate': 25.3, // percentage
    };
  }

  Future<Map<String, dynamic>> _getPerformanceMetrics() async {
    // Simulate performance metrics
    return {
      'averageResponseTime': 245.0, // milliseconds
      'uptime': 99.9, // percentage
      'errorRate': 0.1, // percentage
      'throughput': 1500, // requests per minute
    };
  }

  Future<Map<String, dynamic>> _getSecurityMetrics(DateTime since) async {
    // Simulate security metrics
    return {
      'blockedAttacks': 15,
      'suspiciousActivities': 5,
      'failedLoginAttempts': 23,
      'securityScore': 95, // out of 100
    };
  }

  // Logout
  void logout() {
    _currentAdmin = null;
}
