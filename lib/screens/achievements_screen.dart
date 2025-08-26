import 'package:flutter/material.dart';
import '../services/achievement_service.dart';
import '../models/achievement.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementService _achievementService = AchievementService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildProgressHeader(),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Unlocked'),
                      Tab(text: 'Locked'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildAchievementsList(_achievementService.getUnlockedAchievements()),
                        _buildAchievementsList(_achievementService.getLockedAchievements()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    final progress = _achievementService.getOverallProgress();
    final unlockedCount = _achievementService.getUnlockedAchievements().length;
    final totalCount = _achievementService.achievements.length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green.shade50,
      child: Column(
        children: [
          Text(
            'Overall Progress',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 8),
          Text('$unlockedCount / $totalCount achievements unlocked'),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(List<Achievement> achievements) {
    if (achievements.isEmpty) {
      return const Center(
        child: Text('No achievements yet'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementCard(achievement);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: achievement.isUnlocked ? Colors.green : Colors.grey,
          child: Text(
            achievement.iconPath,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          achievement.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: achievement.isUnlocked ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            if (!achievement.isUnlocked) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: achievement.currentCount / achievement.requiredCount,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 2),
              Text(
                '${achievement.currentCount} / ${achievement.requiredCount}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Unlocked: ${achievement.unlockedAt!.day}/${achievement.unlockedAt!.month}/${achievement.unlockedAt!.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ],
        ),
        trailing: achievement.isUnlocked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.lock, color: Colors.grey),
      ),
    );
  }
}