// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crop_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CropDataAdapter extends TypeAdapter<CropData> {
  @override
  final int typeId = 6;

  @override
  CropData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CropData(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      wateringScheduleByRegion:
          (fields[3] as Map).cast<String, WateringSchedule>(),
      growthDurationDays: fields[4] as int,
      imageUrl: fields[5] as String?,
      tips: (fields[6] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CropData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.wateringScheduleByRegion)
      ..writeByte(4)
      ..write(obj.growthDurationDays)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.tips);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WateringScheduleAdapter extends TypeAdapter<WateringSchedule> {
  @override
  final int typeId = 7;

  @override
  WateringSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WateringSchedule(
      frequencyDays: fields[0] as int,
      amountLiters: fields[1] as double,
      notes: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WateringSchedule obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.frequencyDays)
      ..writeByte(1)
      ..write(obj.amountLiters)
      ..writeByte(2)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WateringScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
