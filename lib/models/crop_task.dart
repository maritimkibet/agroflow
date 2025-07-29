import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'crop_task.g.dart';

@HiveType(typeId: 0)
class CropTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String cropName;

  @HiveField(2)
  String taskDescription;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  String? imagePath;

  @HiveField(6)
  String? priority;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  String? taskType;  // <-- New field for task type like 'weeding', 'spraying', etc.

  CropTask({
    String? id,
    required this.cropName,
    required this.taskDescription,
    required this.date,
    this.isCompleted = false,
    this.imagePath,
    this.priority,
    this.notes,
    this.taskType,  // <-- add to constructor
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'cropName': cropName,
        'taskDescription': taskDescription,
        'date': date.toIso8601String(),
        'isCompleted': isCompleted,
        'imagePath': imagePath,
        'priority': priority,
        'notes': notes,
        'taskType': taskType,  // <-- serialize new field
      };

  factory CropTask.fromJson(Map<String, dynamic> json) {
    return CropTask(
      id: json['id'],
      cropName: json['cropName'] ?? '',
      taskDescription: json['taskDescription'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      isCompleted: json['isCompleted'] ?? false,
      imagePath: json['imagePath'],
      priority: json['priority'],
      notes: json['notes'],
      taskType: json['taskType'],  // <-- deserialize new field
    );
  }
}
