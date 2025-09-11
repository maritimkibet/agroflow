import 'package:flutter/material.dart';

class SecurityManagementScreen extends StatefulWidget {
  const SecurityManagementScreen({super.key});

  @override
  State<SecurityManagementScreen> createState() => _SecurityManagementScreenState();
}

class _SecurityManagementScreenState extends State<SecurityManagementScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _securityData = {};

  @override
  void initState() {
    super.initState();
    _loadSecurityData();
  }

  Future<void> _loadSecurityData() async {
    setState(() => _isLoading = true);
    try {
      // Simulate security data loading
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _securityData = {
          'activeThreats': 0,
          'blockedIPs': 15,
          'failedLogins': 23,
          'suspiciousActivity': 5,
          'lastSecurityScan': DateTime.now().subtract(const Duration(hours: 2)),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading security data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Management',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Security Status Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildSecurityCard(
                        'Active Threats',
                        '${_securityData['activeThreats'] ?? 0}',
                        Icons.security,
                        _securityData['activeThreats'] == 0 ? Colors.green : Colors.red,
                        'System secure',
                      ),
                      _buildSecurityCard(
                        'Blocked IPs',
                        '${_securityData['blockedIPs'] ?? 0}',
                        Icons.block,
                        Colors.orange,
                        'Auto-blocked',
                      ),
                      _buildSecurityCard(
                        'Failed Logins',
                        '${_securityData['failedLogins'] ?? 0}',
                        Icons.login,
                        Colors.red,
                        'Last 24h',
                      ),
                      _buildSecurityCard(
                        'Suspicious Activity',
                        '${_securityData['suspiciousActivity'] ?? 0}',
                        Icons.warning,
                        Colors.amber,
                        'Under review',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      // Security Actions
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Security Actions',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildActionButton(
                                  'Run Security Scan',
                                  Icons.scanner,
                                  Colors.blue,
                                  _runSecurityScan,
                                ),
                                const SizedBox(height: 8),
                                _buildActionButton(
                                  'Update Firewall Rules',
                                  Icons.security,
                                  Colors.orange,
                                  _updateFirewallRules,
                                ),
                                const SizedBox(height: 8),
                                _buildActionButton(
                                  'Force Password Reset',
                                  Icons.password,
                                  Colors.red,
                                  _forcePasswordReset,
                                ),
                                const SizedBox(height: 8),
                                _buildActionButton(
                                  'Enable 2FA for All',
                                  Icons.security,
                                  Colors.green,
                                  _enable2FAForAll,
                                ),
                                const SizedBox(height: 8),
                                _buildActionButton(
                                  'Audit Logs',
                                  Icons.history,
                                  Colors.purple,
                                  _viewAuditLogs,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Security Settings
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Security Settings',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildSecuritySetting(
                                  'Auto-block suspicious IPs',
                                  true,
                                  (value) => _toggleSetting('autoBlock', value),
                                ),
                                _buildSecuritySetting(
                                  'Require 2FA for admins',
                                  true,
                                  (value) => _toggleSetting('require2FA', value),
                                ),
                                _buildSecuritySetting(
                                  'Email security alerts',
                                  true,
                                  (value) => _toggleSetting('emailAlerts', value),
                                ),
                                _buildSecuritySetting(
                                  'Log all admin actions',
                                  true,
                                  (value) => _toggleSetting('logActions', value),
                                ),
                                _buildSecuritySetting(
                                  'Rate limiting',
                                  true,
                                  (value) => _toggleSetting('rateLimiting', value),
                                ),
                                const SizedBox(height: 16),
                                _buildSecurityInfo(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Recent Security Events
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Security Events',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSecurityEventsList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSecurityCard(
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

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Widget _buildSecuritySetting(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Security Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Last scan: 2 hours ago',
            style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
          ),
          Text(
            'SSL Certificate: Valid until Dec 2024',
            style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
          ),
          Text(
            'Firewall: Active',
            style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityEventsList() {
    final events = [
      {
        'type': 'Blocked IP',
        'description': 'Suspicious login attempts from 192.168.1.100',
        'time': '2 minutes ago',
        'severity': 'high'
      },
      {
        'type': 'Failed Login',
        'description': 'Multiple failed login attempts for admin@example.com',
        'time': '15 minutes ago',
        'severity': 'medium'
      },
      {
        'type': 'Security Scan',
        'description': 'Automated security scan completed successfully',
        'time': '2 hours ago',
        'severity': 'low'
      },
      {
        'type': 'Password Reset',
        'description': 'Admin password reset for security@agroflow.com',
        'time': '1 day ago',
        'severity': 'medium'
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        Color severityColor;
        IconData severityIcon;
        
        switch (event['severity']) {
          case 'high':
            severityColor = Colors.red;
            severityIcon = Icons.error;
            break;
          case 'medium':
            severityColor = Colors.orange;
            severityIcon = Icons.warning;
            break;
          default:
            severityColor = Colors.green;
            severityIcon = Icons.info;
        }
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: severityColor.withValues(alpha: 0.1),
            child: Icon(severityIcon, color: severityColor, size: 20),
          ),
          title: Text(event['type'] as String),
          subtitle: Text(event['description'] as String),
          trailing: Text(
            event['time'] as String,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        );
      },
    );
  }

  Future<void> _runSecurityScan() async {
    _showLoadingDialog('Running comprehensive security scan...');
    await Future.delayed(const Duration(seconds: 4));
    if (context.mounted) {
      Navigator.pop(context);
      _showSuccessDialog('Security scan completed. No vulnerabilities found.');
    }
  }

  Future<void> _updateFirewallRules() async {
    _showLoadingDialog('Updating firewall rules...');
    await Future.delayed(const Duration(seconds: 2));
    if (context.mounted) {
      Navigator.pop(context);
      _showSuccessDialog('Firewall rules updated successfully!');
    }
  }

  Future<void> _forcePasswordReset() async {
    final confirmed = await _showConfirmationDialog(
      'Force Password Reset',
      'This will force all users to reset their passwords on next login. Continue?',
    );
    
    if (confirmed) {
      _showLoadingDialog('Initiating password reset for all users...');
      await Future.delayed(const Duration(seconds: 3));
      if (context.mounted) {
        Navigator.pop(context);
        _showSuccessDialog('Password reset initiated for all users!');
      }
    }
  }

  Future<void> _enable2FAForAll() async {
    final confirmed = await _showConfirmationDialog(
      'Enable 2FA for All Users',
      'This will require all users to set up two-factor authentication. Continue?',
    );
    
    if (confirmed) {
      _showLoadingDialog('Enabling 2FA for all users...');
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        Navigator.pop(context);
        _showSuccessDialog('2FA requirement enabled for all users!');
      }
    }
  }

  Future<void> _viewAuditLogs() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audit Logs'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: const [
              ListTile(
                title: Text('Admin Login'),
                subtitle: Text('admin@agroflow.com - 2024-01-15 10:30:00'),
                leading: Icon(Icons.login, color: Colors.green),
              ),
              ListTile(
                title: Text('User Suspended'),
                subtitle: Text('user123 suspended by admin - 2024-01-15 09:15:00'),
                leading: Icon(Icons.block, color: Colors.red),
              ),
              ListTile(
                title: Text('Security Scan'),
                subtitle: Text('Automated scan completed - 2024-01-15 08:00:00'),
                leading: Icon(Icons.security, color: Colors.blue),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessDialog('Full audit log exported to CSV!');
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _toggleSetting(String setting, bool value) {
    _showSuccessDialog('$setting ${value ? 'enabled' : 'disabled'} successfully!');
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}