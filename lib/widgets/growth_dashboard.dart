import 'package:flutter/material.dart';
import '../services/achievement_service.dart';
import '../services/referral_service.dart';
// import '../services/growth_analytics_service.dart';

class GrowthDashboard extends StatefulWidget {
  const GrowthDashboard({super.key});

  @override
  State<GrowthDashboard> createState() => _GrowthDashboardState();
}

class _GrowthDashboardState extends State<GrowthDashboard> {
  final AchievementService _achievementService = AchievementService();
  final ReferralService _referralService = ReferralService();
  // final GrowthAnalyticsService _analyticsService = GrowthAnalyticsService(); // Reserved for future analytics

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Your Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildProgressItem()),
                const SizedBox(width: 16),
                Expanded(child: _buildReferralItem()),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem() {
    final progress = _achievementService.getOverallProgress();
    final unlockedCount = _achievementService.getUnlockedAchievements().length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
        ),
        const SizedBox(height: 4),
        Text(
          '$unlockedCount unlocked',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReferralItem() {
    final referralCount = _referralService.referralCount;
    final hasRewards = _referralService.hasReferralRewards();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referrals',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '$referralCount',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            if (hasRewards)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        Text(
          hasRewards ? 'Premium unlocked!' : 'Invite ${3 - referralCount} more',
          style: TextStyle(
            fontSize: 12,
            color: hasRewards ? Colors.green : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/achievements');
            },
            icon: const Icon(Icons.emoji_events, size: 16),
            label: const Text('View All', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/referral');
            },
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Invite', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}