import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../widgets/achievement_notification.dart';
import 'achievement_service.dart';

class AchievementNotificationService {
  static final AchievementNotificationService _instance = AchievementNotificationService._internal();
  factory AchievementNotificationService() => _instance;
  AchievementNotificationService._internal();

  final AchievementService _achievementService = AchievementService();
  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> checkAndShowAchievement(String achievementId, {int increment = 1}) async {
    if (_context == null) return;

    final unlockedAchievement = await _achievementService.updateProgress(
      achievementId,
      increment: increment,
    );

    if (unlockedAchievement != null) {
      AchievementNotification.show(_context!, unlockedAchievement);
    }
  }

  // Convenience methods for common achievements
  Future<void> trackTaskAdded() async {
    await checkAndShowAchievement('first_task');
    await checkAndShowAchievement('task_streak_7'); // This would need proper streak tracking
  }

  Future<void> trackProductListed() async {
    await checkAndShowAchievement('first_product');
    await checkAndShowAchievement('marketplace_seller');
  }

  Future<void> trackAIUsage() async {
    await checkAndShowAchievement('ai_helper');
  }

  Future<void> trackMessageSent() async {
    await checkAndShowAchievement('community_helper');
  }

  // Get achievement progress for UI display
  Future<Map<String, double>> getAchievementProgress() async {
    final achievements = _achievementService.achievements;
    final progress = <String, double>{};

    for (final achievement in achievements) {
      progress[achievement.id] = achievement.currentCount / achievement.requiredCount;
    }

    return progress;
  }

  // Get next achievement to unlock
  Achievement? getNextAchievement() {
    final lockedAchievements = _achievementService.getLockedAchievements();
    if (lockedAchievements.isEmpty) return null;

    // Sort by progress (closest to completion first)
    lockedAchievements.sort((a, b) {
      final progressA = a.currentCount / a.requiredCount;
      final progressB = b.currentCount / b.requiredCount;
      return progressB.compareTo(progressA);
    });

    return lockedAchievements.first;
  }
}