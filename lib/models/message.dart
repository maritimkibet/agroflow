import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'message.g.dart';

@HiveType(typeId: 6)
class Message extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String senderId;

  @HiveField(2)
  final String receiverId;

  @HiveField(3)
  final String productId;

  @HiveField(4)
  String content;

  @HiveField(5)
  DateTime timestamp;

  @HiveField(6)
  bool isRead;

  @HiveField(7)
  MessageType type;

  Message({
    String? id,
    required this.senderId,
    required this.receiverId,
    required this.productId,
    required this.content,
    DateTime? timestamp,
    this.isRead = false,
    this.type = MessageType.text,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'productId': productId,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'type': type.index,
      };

  static Message fromMap(Map<String, dynamic> data, {required String id}) => Message(
        id: id,
        senderId: data['senderId'] ?? '',
        receiverId: data['receiverId'] ?? '',
        productId: data['productId'] ?? '',
        content: data['content'] ?? '',
        timestamp: data['timestamp'] != null
            ? DateTime.tryParse(data['timestamp']) ?? DateTime.now()
            : DateTime.now(),
        isRead: data['isRead'] ?? false,
        type: MessageType.values[(data['type'] ?? 0).clamp(0, MessageType.values.length - 1)],
      );
}

@HiveType(typeId: 7)
enum MessageType {
  @HiveField(0)
  text,
  @HiveField(1)
  image,
  @HiveField(2)
  system,
}