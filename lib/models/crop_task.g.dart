// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crop_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CropTaskAdapter extends TypeAdapter<CropTask> {
  @override
  final int typeId = 0;

  @override
  CropTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CropTask(
      id: fields[0] as String?,
      cropName: fields[1] as String,
      taskDescription: fields[2] as String,
      date: fields[3] as DateTime,
      isCompleted: fields[4] as bool,
      imagePath: fields[5] as String?,
      priority: fields[6] as String?,
      notes: fields[7] as String?,
      taskType: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CropTask obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cropName)
      ..writeByte(2)
      ..write(obj.taskDescription)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.imagePath)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.taskType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
