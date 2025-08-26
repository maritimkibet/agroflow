class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final int requiredCount;
  final int currentCount;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    this.unlockedAt,
    this.isUnlocked = false,
    this.requiredCount = 1,
    this.currentCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'iconPath': iconPath,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'isUnlocked': isUnlocked,
    'requiredCount': requiredCount,
    'currentCount': currentCount,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    iconPath: json['iconPath'],
    unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
    isUnlocked: json['isUnlocked'] ?? false,
    requiredCount: json['requiredCount'] ?? 1,
    currentCount: json['currentCount'] ?? 0,
  );

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    DateTime? unlockedAt,
    bool? isUnlocked,
    int? requiredCount,
    int? currentCount,
  }) => Achievement(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    iconPath: iconPath ?? this.iconPath,
    unlockedAt: unlockedAt ?? this.unlockedAt,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    requiredCount: requiredCount ?? this.requiredCount,
    currentCount: currentCount ?? this.currentCount,
  );
}