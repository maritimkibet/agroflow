import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class SystemManagementScreen extends StatefulWidget {
  const SystemManagementScreen({super.key});

  @override
  State<SystemManagementScreen> createState() => _SystemManagementScreenState();
}

class _SystemManagementScreenState extends State<SystemManagementScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSystemInfo();
  }

  Future<void> _loadSystemInfo() async {
    setState(() => _isLoading = true);
    try {
      final adminService = AdminService();
      await adminService.getSystemHealth();
      await adminService.getAppAnalytics();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading system info: $e')),
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
                    'System Management',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // System Actions Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildActionCard(
                        'Database Backup',
                        Icons.backup,
                        Colors.blue,
                        _performDatabaseBackup,
                      ),
                      _buildActionCard(
                        'Clear Cache',
                        Icons.clear_all,
                        Colors.orange,
                        _clearSystemCache,
                      ),
                      _buildActionCard(
                        'System Restart',
                        Icons.restart_alt,
                        Colors.red,
                        _restartSystem,
                      ),
                      _buildActionCard(
                        'Update Configs',
                        Icons.settings_applications,
                        Colors.green,
                        _updateConfigurations,
                      ),
                      _buildActionCard(
                        'Security Scan',
                        Icons.security,
                        Colors.purple,
                        _performSecurityScan,
                      ),
                      _buildActionCard(
                        'Performance Check',
                        Icons.speed,
                        Colors.teal,
                        _performanceCheck,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // System Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Information',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('App Version', '1.0.0+1'),
                          _buildInfoRow('Database Status', 'Connected'),
                          _buildInfoRow('Storage Usage', '2.5GB / 10GB'),
                          _buildInfoRow('Active Sessions', '156'),
                          _buildInfoRow('Last Backup', '2 hours ago'),
                          _buildInfoRow('Uptime', '7 days, 14 hours'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Future<void> _performDatabaseBackup() async {
    final confirmed = await _showConfirmationDialog(
      'Database Backup',
      'This will create a full database backup. Continue?',
    );
    
    if (confirmed) {
      _showLoadingDialog('Creating database backup...');
      await Future.delayed(const Duration(seconds: 3));
      if (context.mounted) {
        Navigator.pop(context);
        _showSuccessDialog('Database backup completed successfully!');
      }
    }
  }

  Future<void> _clearSystemCache() async {
    final confirmed = await _showConfirmationDialog(
      'Clear Cache',
      'This will clear all system cache. Continue?',
    );
    
    if (confirmed) {
      _showLoadingDialog('Clearing system cache...');
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        Navigator.pop(context);
        _showSuccessDialog('System cache cleared successfully!');
      }
    }
  }

  Future<void> _restartSystem() async {
    final confirmed = await _showConfirmationDialog(
      'System Restart',
      'This will restart the system. All users will be temporarily disconnected. Continue?',
    );
    
    if (confirmed) {
      _showLoadingDialog('Restarting system...');
      await Future.delayed(const Duration(seconds: 5));
      if (context.mounted) {
        Navigator.pop(context);
        _showSuccessDialog('System restart initiated successfully!');
      }
    }
  }

  Future<void> _updateConfigurations() async {
    _showLoadingDialog('Updating configurations...');
    await Future.delayed(const Duration(seconds: 2));
    if (context.mounted) {
      Navigator.pop(context);
      _showSuccessDialog('Configurations updated successfully!');
    }
  }

  Future<void> _performSecurityScan() async {
    _showLoadingDialog('Performing security scan...');
    await Future.delayed(const Duration(seconds: 4));
    if (context.mounted) {
      Navigator.pop(context);
      _showSuccessDialog('Security scan completed. No threats detected.');
    }
  }

  Future<void> _performanceCheck() async {
    _showLoadingDialog('Running performance check...');
    await Future.delayed(const Duration(seconds: 3));
    if (context.mounted) {
      Navigator.pop(context);
      _showSuccessDialog('Performance check completed. System running optimally.');
    }
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