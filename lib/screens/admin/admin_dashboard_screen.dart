import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

import 'user_management_screen.dart';
import 'support_tickets_screen.dart';
import 'content_moderation_screen.dart';
import 'analytics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  int _selectedIndex = 0;
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;

  final List<Widget> _screens = [
    const DashboardOverview(),
    const UserManagementScreen(),
    const SupportTicketsScreen(),
    const ContentModerationScreen(),
    const AdminAnalyticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _adminService.getUserStats(),
        _adminService.getSystemHealth(),
        _adminService.getAppAnalytics(),
      ]);
      
      final userStats = results[0];
      final systemHealth = results[1];
      final analytics = results[2];

      setState(() {
        _dashboardData = {
          'userStats': userStats,
          'systemHealth': systemHealth,
          'analytics': analytics,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = _adminService.currentAdmin;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroFlow Admin Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // System Health Indicator
          _buildSystemHealthIndicator(),
          const SizedBox(width: 16),
          
          // Admin Profile
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                admin?.name.substring(0, 1).toUpperCase() ?? 'A',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _showAdminProfile();
                  break;
                case 'settings':
                  _showAdminSettings();
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(admin?.name ?? 'Admin'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.grey.shade50,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outlined),
                selectedIcon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.support_agent_outlined),
                selectedIcon: Icon(Icons.support_agent),
                label: Text('Support'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shield_outlined),
                selectedIcon: Icon(Icons.shield),
                label: Text('Moderation'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Analytics'),
              ),
            ],
          ),
          
          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthIndicator() {
    final systemHealth = _dashboardData['systemHealth'] as Map<String, dynamic>?;
    final status = systemHealth?['status'] ?? 'unknown';
    
    Color color;
    IconData icon;
    
    switch (status) {
      case 'healthy':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'critical':
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Tooltip(
      message: 'System Status: ${status.toUpperCase()}',
      child: Icon(icon, color: color),
    );
  }

  void _showAdminProfile() {
    final admin = _adminService.currentAdmin;
    if (admin == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow('Name', admin.name),
            _buildProfileRow('Email', admin.email),
            _buildProfileRow('Role', admin.role.toString().split('.').last),
            _buildProfileRow('Last Login', _formatDateTime(admin.lastLogin)),
            _buildProfileRow('Status', admin.isActive ? 'Active' : 'Inactive'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showAdminSettings() {
    // Implement admin settings dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Settings'),
        content: const Text('Settings panel coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _adminService.logout();
              Navigator.pushReplacementNamed(context, '/admin_login');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick Stats Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Total Users',
                  '1,234',
                  Icons.people,
                  Colors.blue,
                  '+12% this month',
                ),
                _buildStatCard(
                  'Active Today',
                  '456',
                  Icons.online_prediction,
                  Colors.green,
                  '78% of total',
                ),
                _buildStatCard(
                  'Support Tickets',
                  '23',
                  Icons.support_agent,
                  Colors.orange,
                  '5 urgent',
                ),
                _buildStatCard(
                  'System Health',
                  'Good',
                  Icons.health_and_safety,
                  Colors.green,
                  '99.9% uptime',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}