import 'package:flutter/material.dart';
import '../services/growth_analytics_service.dart';
import '../services/achievement_service.dart';
import '../services/referral_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final GrowthAnalyticsService _analyticsService = GrowthAnalyticsService();
  final AchievementService _achievementService = AchievementService();
  final ReferralService _referralService = ReferralService();

  Map<String, int> _eventCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final eventCounts = await _analyticsService.getEventCounts();
    setState(() {
      _eventCounts = eventCounts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your AgroFlow Stats'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewCards(),
                  const SizedBox(height: 20),
                  _buildActivityChart(),
                  const SizedBox(height: 20),
                  _buildAchievementProgress(),
                  const SizedBox(height: 20),
                  _buildReferralStats(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Tasks Added',
            '${_eventCounts['task_added'] ?? 0}',
            Icons.task_alt,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Products Listed',
            '${_eventCounts['product_listed'] ?? 0}',
            Icons.shopping_cart,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    final activities = [
      {'name': 'AI Assistant Used', 'count': _eventCounts['ai_assistant_used'] ?? 0, 'color': Colors.purple},
      {'name': 'Messages Sent', 'count': _eventCounts['message_sent'] ?? 0, 'color': Colors.green},
      {'name': 'Marketplace Views', 'count': _eventCounts['marketplace_viewed'] ?? 0, 'color': Colors.blue},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...activities.map((activity) => _buildActivityItem(
              activity['name'] as String,
              activity['count'] as int,
              activity['color'] as Color,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String name, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementProgress() {
    final progress = _achievementService.getOverallProgress();
    final unlockedCount = _achievementService.getUnlockedAchievements().length;
    final totalCount = _achievementService.achievements.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Achievement Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 8),
            Text('$unlockedCount of $totalCount achievements unlocked'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/achievements');
              },
              child: const Text('View All Achievements'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralStats() {
    final referralCount = _referralService.referralCount;
    final hasRewards = _referralService.hasReferralRewards();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Referral Program',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.people, color: Colors.green),
                const SizedBox(width: 12),
                Text('$referralCount farmers referred'),
                const Spacer(),
                if (hasRewards)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Premium Unlocked',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_referralService.getReferralRewardText()),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/referral');
              },
              child: const Text('Invite More Farmers'),
            ),
          ],
        ),
      ),
    );
  }
}