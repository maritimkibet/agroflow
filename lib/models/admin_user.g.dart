// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AdminUserAdapter extends TypeAdapter<AdminUser> {
  @override
  final int typeId = 14;

  @override
  AdminUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AdminUser(
      id: fields[0] as String,
      email: fields[1] as String,
      name: fields[2] as String,
      role: fields[3] as AdminRole,
      permissions: (fields[4] as List).cast<String>(),
      createdAt: fields[5] as DateTime,
      lastLogin: fields[6] as DateTime,
      isActive: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AdminUser obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.permissions)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastLogin)
      ..writeByte(7)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SupportTicketAdapter extends TypeAdapter<SupportTicket> {
  @override
  final int typeId = 15;

  @override
  SupportTicket read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SupportTicket(
      id: fields[0] as String,
      userId: fields[1] as String,
      userName: fields[2] as String,
      title: fields[3] as String,
      description: fields[4] as String,
      priority: fields[5] as TicketPriority,
      status: fields[6] as TicketStatus,
      category: fields[7] as String,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      assignedTo: fields[10] as String?,
      tags: (fields[11] as List).cast<String>(),
      metadata: (fields[12] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, SupportTicket obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.assignedTo)
      ..writeByte(11)
      ..write(obj.tags)
      ..writeByte(12)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupportTicketAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserActivityAdapter extends TypeAdapter<UserActivity> {
  @override
  final int typeId = 18;

  @override
  UserActivity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserActivity(
      id: fields[0] as String,
      userId: fields[1] as String,
      action: fields[2] as String,
      details: fields[3] as String,
      timestamp: fields[4] as DateTime,
      metadata: (fields[5] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserActivity obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.action)
      ..writeByte(3)
      ..write(obj.details)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserActivityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AdminRoleAdapter extends TypeAdapter<AdminRole> {
  @override
  final int typeId = 13;

  @override
  AdminRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AdminRole.superAdmin;
      case 1:
        return AdminRole.admin;
      case 2:
        return AdminRole.moderator;
      case 3:
        return AdminRole.support;
      default:
        return AdminRole.superAdmin;
    }
  }

  @override
  void write(BinaryWriter writer, AdminRole obj) {
    switch (obj) {
      case AdminRole.superAdmin:
        writer.writeByte(0);
        break;
      case AdminRole.admin:
        writer.writeByte(1);
        break;
      case AdminRole.moderator:
        writer.writeByte(2);
        break;
      case AdminRole.support:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TicketPriorityAdapter extends TypeAdapter<TicketPriority> {
  @override
  final int typeId = 16;

  @override
  TicketPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TicketPriority.low;
      case 1:
        return TicketPriority.medium;
      case 2:
        return TicketPriority.high;
      case 3:
        return TicketPriority.urgent;
      default:
        return TicketPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, TicketPriority obj) {
    switch (obj) {
      case TicketPriority.low:
        writer.writeByte(0);
        break;
      case TicketPriority.medium:
        writer.writeByte(1);
        break;
      case TicketPriority.high:
        writer.writeByte(2);
        break;
      case TicketPriority.urgent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TicketStatusAdapter extends TypeAdapter<TicketStatus> {
  @override
  final int typeId = 17;

  @override
  TicketStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TicketStatus.open;
      case 1:
        return TicketStatus.inProgress;
      case 2:
        return TicketStatus.resolved;
      case 3:
        return TicketStatus.closed;
      case 4:
        return TicketStatus.escalated;
      default:
        return TicketStatus.open;
    }
  }

  @override
  void write(BinaryWriter writer, TicketStatus obj) {
    switch (obj) {
      case TicketStatus.open:
        writer.writeByte(0);
        break;
      case TicketStatus.inProgress:
        writer.writeByte(1);
        break;
      case TicketStatus.resolved:
        writer.writeByte(2);
        break;
      case TicketStatus.closed:
        writer.writeByte(3);
        break;
      case TicketStatus.escalated:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
