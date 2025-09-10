import 'package:hive/hive.dart';

part 'automation_response.g.dart';

@HiveType(typeId: 10)
class AutomationResponse extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final Map<String, dynamic> data;

  @HiveField(4)
  final bool isProcessed;

  AutomationResponse({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
    this.isProcessed = false,
  });

  factory AutomationResponse.fromMap(Map<String, dynamic> map) {
    return AutomationResponse(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      isProcessed: map['isProcessed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'isProcessed': isProcessed,
    };
  }
}

@HiveType(typeId: 11)
class PricingSuggestion extends HiveObject {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final double suggestedPrice;

  @HiveField(2)
  final double currentPrice;

  @HiveField(3)
  final String reasoning;

  @HiveField(4)
  final double confidence;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final Map<String, dynamic> marketData;

  PricingSuggestion({
    required this.productId,
    required this.suggestedPrice,
    required this.currentPrice,
    required this.reasoning,
    required this.confidence,
    required this.timestamp,
    required this.marketData,
  });

  factory PricingSuggestion.fromMap(Map<String, dynamic> map) {
    return PricingSuggestion(
      productId: map['productId'] ?? '',
      suggestedPrice: (map['suggestedPrice'] ?? 0.0).toDouble(),
      currentPrice: (map['currentPrice'] ?? 0.0).toDouble(),
      reasoning: map['reasoning'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      marketData: Map<String, dynamic>.from(map['marketData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'suggestedPrice': suggestedPrice,
      'currentPrice': currentPrice,
      'reasoning': reasoning,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'marketData': marketData,
    };
  }

  double get priceChange => suggestedPrice - currentPrice;
  double get priceChangePercent => (priceChange / currentPrice) * 100;
  bool get isIncrease => suggestedPrice > currentPrice;
}

@HiveType(typeId: 12)
class SmartScheduleSuggestion extends HiveObject {
  @HiveField(0)
  final String taskId;

  @HiveField(1)
  final DateTime suggestedDate;

  @HiveField(2)
  final DateTime originalDate;

  @HiveField(3)
  final String reasoning;

  @HiveField(4)
  final String priority;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final Map<String, dynamic> weatherContext;

  SmartScheduleSuggestion({
    required this.taskId,
    required this.suggestedDate,
    required this.originalDate,
    required this.reasoning,
    required this.priority,
    required this.timestamp,
    required this.weatherContext,
  });

  factory SmartScheduleSuggestion.fromMap(Map<String, dynamic> map) {
    return SmartScheduleSuggestion(
      taskId: map['taskId'] ?? '',
      suggestedDate: DateTime.tryParse(map['suggestedDate'] ?? '') ?? DateTime.now(),
      originalDate: DateTime.tryParse(map['originalDate'] ?? '') ?? DateTime.now(),
      reasoning: map['reasoning'] ?? '',
      priority: map['priority'] ?? 'medium',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      weatherContext: Map<String, dynamic>.from(map['weatherContext'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'suggestedDate': suggestedDate.toIso8601String(),
      'originalDate': originalDate.toIso8601String(),
      'reasoning': reasoning,
      'priority': priority,
      'timestamp': timestamp.toIso8601String(),
      'weatherContext': weatherContext,
    };
  }

  int get daysDifference => suggestedDate.difference(originalDate).inDays;
  bool get isDelayed => suggestedDate.isAfter(originalDate);
  bool get isUrgent => priority == 'high' || priority == 'urgent';
}