import '../models/achievement.dart';
import 'hive_service.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final HiveService _hiveService = HiveService();
  List<Achievement> _achievements = [];

  List<Achievement> get achievements => _achievements;

  Future<void> initialize() async {
    await _loadAchievements();
    _initializeDefaultAchievements();
  }

  Future<void> _loadAchievements() async {
    final data = await _hiveService.getData('achievements');
    if (data != null) {
      _achievements =
          (data as List).map((e) => Achievement.fromJson(e)).toList();
    }
  }

  void _initializeDefaultAchievements() {
    final defaultAchievements = [
      Achievement(
        id: 'first_task',
        title: 'Getting Started',
        description: 'Add your first farming task',
        iconPath: '🌱',
        requiredCount: 1,
      ),
      Achievement(
        id: 'first_product',
        title: 'First Sale',
        description: 'List your first product in marketplace',
        iconPath: '🛒',
        requiredCount: 1,
      ),
      Achievement(
        id: 'task_streak_7',
        title: 'Consistent Farmer',
        description: 'Complete tasks for 7 days straight',
        iconPath: '🔥',
        requiredCount: 7,
      ),
      Achievement(
        id: 'marketplace_seller',
        title: 'Active Seller',
        description: 'List 10 products in marketplace',
        iconPath: '💰',
        requiredCount: 10,
      ),
      Achievement(
        id: 'ai_helper',
        title: 'Smart Farmer',
        description: 'Use AI assistant 5 times',
        iconPath: '🤖',
        requiredCount: 5,
      ),
      Achievement(
        id: 'community_helper',
        title: 'Community Helper',
        description: 'Help 3 farmers through messaging',
        iconPath: '🤝',
        requiredCount: 3,
      ),
    ];

    for (final defaultAchievement in defaultAchievements) {
      if (!_achievements.any((a) => a.id == defaultAchievement.id)) {
        _achievements.add(defaultAchievement);
      }
    }
    _saveAchievements();
  }

  Future<void> _saveAchievements() async {
    await _hiveService.saveData(
      'achievements',
      _achievements.map((e) => e.toJson()).toList(),
    );
  }

  Future<Achievement?> updateProgress(
    String achievementId, {
    int increment = 1,
  }) async {
    final index = _achievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return null;

    final achievement = _achievements[index];
    if (achievement.isUnlocked) return null;

    final newCount = achievement.currentCount + increment;
    final isNowUnlocked = newCount >= achievement.requiredCount;

    _achievements[index] = achievement.copyWith(
      currentCount: newCount,
      isUnlocked: isNowUnlocked,
      unlockedAt: isNowUnlocked ? DateTime.now() : null,
    );

    await _saveAchievements();
    return isNowUnlocked ? _achievements[index] : null;
  }

  List<Achievement> getUnlockedAchievements() {
    return _achievements.where((a) => a.isUnlocked).toList();
  }

  List<Achievement> getLockedAchievements() {
    return _achievements.where((a) => !a.isUnlocked).toList();
  }

  double getOverallProgress() {
    if (_achievements.isEmpty) return 0.0;
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    return unlockedCount / _achievements.length;
  }
}
