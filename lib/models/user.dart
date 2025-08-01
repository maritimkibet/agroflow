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

  User({
    required this.id,
    required this.name,
    required this.role,
    this.location,
  });

  Null get crops => null;
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