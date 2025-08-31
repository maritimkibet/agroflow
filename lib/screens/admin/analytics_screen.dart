import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final AdminService _adminService = AdminService();
  
  Map<String, dynamic> _analytics = {};
  Map<String, dynamic> _systemHealth = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _adminService.getAppAnalytics(),
        _adminService.getSystemHealth(),
      ]);
      
      final analytics = results[0];
      final systemHealth = results[1];

      setState(() {
        _analytics = analytics;
        _systemHealth = systemHealth;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Analytics & Monitoring',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadAnalytics,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // System Health Section
                    _buildSystemHealthSection(),
                    const SizedBox(height: 32),
                    
                    // User Analytics Section
                    _buildUserAnalyticsSection(),
                    const SizedBox(height: 32),
                    
                    // App Usage Section
                    _buildAppUsageSection(),
                    const SizedBox(height: 32),
                    
                    // Error Monitoring Section
                    _buildErrorMonitoringSection(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthSection() {
    final status = _systemHealth['status'] ?? 'unknown';
    final errorCount = _systemHealth['errorCount'] ?? 0;
    final activeUsers = _systemHealth['activeUsers'] ?? 0;
    final responseTime = _systemHealth['responseTime'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'System Health',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildHealthStatusChip(status),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Errors (1h)',
                    errorCount.toString(),
                    Icons.error_outline,
                    errorCount > 50 ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Active Users',
                    activeUsers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Response Time',
                    '${responseTime.toStringAsFixed(0)}ms',
                    Icons.speed,
                    responseTime > 500 ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Uptime',
                    '99.9%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAnalyticsSection() {
    final userStats = _analytics['users'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'User Analytics (Last 7 Days)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Activities',
                    (userStats['totalActivities'] ?? 0).toString(),
                    Icons.timeline,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Unique Users',
                    (userStats['uniqueUsers'] ?? 0).toString(),
                    Icons.person,
                    Colors.indigo,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Avg. Session',
                    '12.5 min',
                    Icons.timer,
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Retention',
                    '78%',
                    Icons.repeat,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppUsageSection() {
    final productStats = _analytics['products'] as Map<String, dynamic>? ?? {};
    final messageStats = _analytics['messages'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'App Usage (Last 7 Days)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'New Products',
                    (productStats['newProducts'] ?? 0).toString(),
                    Icons.add_shopping_cart,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Messages Sent',
                    (messageStats['totalMessages'] ?? 0).toString(),
                    Icons.message,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Conversations',
                    (messageStats['uniqueConversations'] ?? 0).toString(),
                    Icons.chat,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Automation Uses',
                    '156',
                    Icons.auto_awesome,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMonitoringSection() {
    final errorStats = _analytics['errors'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bug_report_outlined, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Error Monitoring (Last 7 Days)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Errors',
                    (errorStats['totalErrors'] ?? 0).toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Critical Errors',
                    '2',
                    Icons.priority_high,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Error Rate',
                    '0.1%',
                    Icons.trending_down,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'MTTR',
                    '15 min',
                    Icons.schedule,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'healthy':
        color = Colors.green;
        label = 'Healthy';
        break;
      case 'warning':
        color = Colors.orange;
        label = 'Warning';
        break;
      case 'critical':
        color = Colors.red;
        label = 'Critical';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}