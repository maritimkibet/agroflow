import 'package:flutter/material.dart';
import '../services/growth_analytics_service.dart';
import '../services/achievement_service.dart';
import '../services/referral_service.dart';
import '../services/hybrid_storage_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final GrowthAnalyticsService _analyticsService = GrowthAnalyticsService();
  final AchievementService _achievementService = AchievementService();
  final ReferralService _referralService = ReferralService();
  final HybridStorageService _storageService = HybridStorageService();

  Map<String, int> _eventCounts = {};
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final eventCounts = await _analyticsService.getEventCounts();
      if (mounted) {
        setState(() {
          _eventCounts = eventCounts;
          _isLoading = false;
          _isOffline = false;
        });
      }
    } catch (e) {
      // Load offline data
      await _loadOfflineAnalytics();
    }
  }

  Future<void> _loadOfflineAnalytics() async {
    try {
      // Get offline analytics from local storage
      final tasks = _storageService.getAllTasks();
      final completedTasks = tasks.where((task) => task.isCompleted).length;
      
      if (mounted) {
        setState(() {
          _eventCounts = {
            'task_added': tasks.length,
            'task_completed': completedTasks,
            'product_listed': 0, // Would need to store this locally
            'ai_assistant_used': 0,
            'message_sent': 0,
            'marketplace_viewed': 0,
          };
          _isLoading = false;
          _isOffline = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _eventCounts = {};
          _isLoading = false;
          _isOffline = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your AgroFlow Stats'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isOffline)
            IconButton(
              icon: const Icon(Icons.cloud_off),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offline mode - showing cached data'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isOffline)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_off, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Offline Mode - Showing cached data',
                                style: TextStyle(color: Colors.orange.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
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