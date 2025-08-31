import 'package:hive/hive.dart';

part 'admin_user.g.dart';

@HiveType(typeId: 13)
enum AdminRole {
  @HiveField(0)
  superAdmin,
  @HiveField(1)
  admin,
  @HiveField(2)
  moderator,
  @HiveField(3)
  support,
}

@HiveType(typeId: 14)
class AdminUser extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final AdminRole role;

  @HiveField(4)
  final List<String> permissions;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime lastLogin;

  @HiveField(7)
  final bool isActive;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
  });

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: AdminRole.values.firstWhere(
        (r) => r.toString().split('.').last == map['role'],
        orElse: () => AdminRole.support,
      ),
      permissions: List<String>.from(map['permissions'] ?? []),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      lastLogin: DateTime.tryParse(map['lastLogin'] ?? '') ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'permissions': permissions,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'isActive': isActive,
    };
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission) || role == AdminRole.superAdmin;
  }
}

@HiveType(typeId: 15)
class SupportTicket extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String userName;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final TicketPriority priority;

  @HiveField(6)
  final TicketStatus status;

  @HiveField(7)
  final String category;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final String? assignedTo;

  @HiveField(11)
  final List<String> tags;

  @HiveField(12)
  final Map<String, dynamic> metadata;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.assignedTo,
    required this.tags,
    required this.metadata,
  });

  factory SupportTicket.fromMap(Map<String, dynamic> map) {
    return SupportTicket(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: TicketPriority.values.firstWhere(
        (p) => p.toString().split('.').last == map['priority'],
        orElse: () => TicketPriority.medium,
      ),
      status: TicketStatus.values.firstWhere(
        (s) => s.toString().split('.').last == map['status'],
        orElse: () => TicketStatus.open,
      ),
      category: map['category'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      assignedTo: map['assignedTo'],
      tags: List<String>.from(map['tags'] ?? []),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'title': title,
      'description': description,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'assignedTo': assignedTo,
      'tags': tags,
      'metadata': metadata,
    };
  }
}

@HiveType(typeId: 16)
enum TicketPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  urgent,
}

@HiveType(typeId: 17)
enum TicketStatus {
  @HiveField(0)
  open,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  resolved,
  @HiveField(3)
  closed,
  @HiveField(4)
  escalated,
}

@HiveType(typeId: 18)
class UserActivity extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String action;

  @HiveField(3)
  final String details;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final Map<String, dynamic> metadata;

  UserActivity({
    required this.id,
    required this.userId,
    required this.action,
    required this.details,
    required this.timestamp,
    required this.metadata,
  });

  factory UserActivity.fromMap(Map<String, dynamic> map) {
    return UserActivity(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      action: map['action'] ?? '',
      details: map['details'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}