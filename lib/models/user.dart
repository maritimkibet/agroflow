import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class User extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  UserRole role;

  @HiveField(3)
  String? location;

  @HiveField(4)
  String? email;

  @HiveField(5)
  String? phone;

  @HiveField(6)
  bool isActive;

  @HiveField(7)
  DateTime? createdAt;

  @HiveField(8)
  DateTime? lastActive;

  User({
    required this.id,
    required this.name,
    required this.role,
    this.location,
    this.email,
    this.phone,
    this.isActive = true,
    this.createdAt,
    this.lastActive,
  });

  List<String> get crops => [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role.toString().split('.').last,
        'location': location,
        'email': email,
        'phone': phone,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
        'lastActive': lastActive?.toIso8601String(),
      };

  factory User.fromMap(Map<String, dynamic> map, {String? id}) {
    return User(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      role: _parseUserRole(map['role']),
      location: map['location'],
      email: map['email'],
      phone: map['phone'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      lastActive: map['lastActive'] != null ? DateTime.tryParse(map['lastActive']) : null,
    );
  }

  factory User.fromFirestore(dynamic doc) {
    if (doc == null || !doc.exists) {
      return User(id: '', name: 'Unknown User', role: UserRole.farmer);
    }
    
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return User(
      id: doc.id,
      name: data['name'] ?? 'Unknown User',
      role: _parseUserRole(data['role']),
      location: data['location'],
      email: data['email'],
      phone: data['phone'],
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt']) : null,
      lastActive: data['lastActive'] != null ? DateTime.tryParse(data['lastActive']) : null,
    );
  }

  static UserRole _parseUserRole(dynamic role) {
    if (role == null) return UserRole.farmer;
    
    final roleString = role.toString().toLowerCase();
    switch (roleString) {
      case 'farmer':
        return UserRole.farmer;
      case 'buyer':
        return UserRole.buyer;
      case 'both':
        return UserRole.both;
      default:
        return UserRole.farmer;
    }
  }
}

@HiveType(typeId: 2)
enum UserRole {
  @HiveField(0)
  farmer,

  @HiveField(1)
  buyer,

  @HiveField(2)
  both,
}