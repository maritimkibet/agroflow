// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'automation_response.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AutomationResponseAdapter extends TypeAdapter<AutomationResponse> {
  @override
  final int typeId = 10;

  @override
  AutomationResponse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AutomationResponse(
      id: fields[0] as String,
      type: fields[1] as String,
      timestamp: fields[2] as DateTime,
      data: (fields[3] as Map).cast<String, dynamic>(),
      isProcessed: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AutomationResponse obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.isProcessed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutomationResponseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PricingSuggestionAdapter extends TypeAdapter<PricingSuggestion> {
  @override
  final int typeId = 11;

  @override
  PricingSuggestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PricingSuggestion(
      productId: fields[0] as String,
      suggestedPrice: fields[1] as double,
      currentPrice: fields[2] as double,
      reasoning: fields[3] as String,
      confidence: fields[4] as double,
      timestamp: fields[5] as DateTime,
      marketData: (fields[6] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, PricingSuggestion obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.suggestedPrice)
      ..writeByte(2)
      ..write(obj.currentPrice)
      ..writeByte(3)
      ..write(obj.reasoning)
      ..writeByte(4)
      ..write(obj.confidence)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.marketData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PricingSuggestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SmartScheduleSuggestionAdapter
    extends TypeAdapter<SmartScheduleSuggestion> {
  @override
  final int typeId = 12;

  @override
  SmartScheduleSuggestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmartScheduleSuggestion(
      taskId: fields[0] as String,
      suggestedDate: fields[1] as DateTime,
      originalDate: fields[2] as DateTime,
      reasoning: fields[3] as String,
      priority: fields[4] as String,
      timestamp: fields[5] as DateTime,
      weatherContext: (fields[6] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, SmartScheduleSuggestion obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.taskId)
      ..writeByte(1)
      ..write(obj.suggestedDate)
      ..writeByte(2)
      ..write(obj.originalDate)
      ..writeByte(3)
      ..write(obj.reasoning)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.weatherContext);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartScheduleSuggestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
