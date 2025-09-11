import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import '../models/user.dart';
import '../models/product.dart';
import 'admin_setup_service.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();



  AdminUser? _currentAdmin;
  AdminUser? get currentAdmin => _currentAdmin;

  // Admin Authentication
  Future<bool> authenticateAdmin(String email, String password) async {
    try {
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
    ];
  }

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      return {
        'totalUsers': 150,
        'activeThisWeek': 120,
        'activeThisMonth': 140,
        'farmers': 100,
        'buyers': 50,
        'growth': 15.5,
      };
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return {};
    }
  }

  Future<bool> suspendUser(String userId, String reason) async {
    try {
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
      return _getMockSupportTickets();
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
        description: 'Having trouble uploading images',
        status: TicketStatus.open,
        priority: TicketPriority.medium,
        category: 'Technical Issue',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        assignedTo: null,
        tags: ['upload', 'images'],
        metadata: {'browser': 'Chrome'},
      ),
    ];
  }

  Future<bool> updateTicketStatus(String ticketId, TicketStatus status) async {
    try {
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
        name: 'Organic Tomatoes',
        type: ProductType.crop,
        listingType: ListingType.sell,
        description: 'Fresh organic tomatoes',
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
    ];
  }

  Future<bool> moderateProduct(String productId, bool approve, String reason) async {
    try {
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

  // Analytics
  Future<Map<String, dynamic>> getAppAnalytics() async {
    try {
      return {
        'users': {'totalActivities': 1247, 'uniqueUsers': 342},
        'products': {'newProducts': 28},
        'messages': {'totalMessages': 856},
        'errors': {'totalErrors': 12},
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting app analytics: $e');
      return {};
    }
  }

  Future<List<UserActivity>> getUserActivity(String userId, {int limit = 20}) async {
    try {
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
        details: 'User logged in',
        timestamp: now.subtract(const Duration(hours: 2)),
        metadata: {'browser': 'Chrome'},
      ),
    ];
  }

  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      return {
        'status': 'healthy',
        'errorCount': 8,
        'activeUsers': 156,
        'responseTime': 245.0,
        'storageUsage': {'used': '2.5GB', 'total': '10GB', 'percentage': 25.0},
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting system health: $e');
      return {'status': 'unknown'};
    }
  }

  Future<void> _logAdminAction(String action, Map<String, dynamic> details) async {
    if (_currentAdmin == null) return;
    // Log admin action
  }

  // Logout
  void logout() {
    _currentAdmin = null;
  }
}