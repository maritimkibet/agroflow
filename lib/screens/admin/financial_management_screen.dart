import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FinancialManagementScreen extends StatefulWidget {
  const FinancialManagementScreen({super.key});

  @override
  State<FinancialManagementScreen> createState() => _FinancialManagementScreenState();
}

class _FinancialManagementScreenState extends State<FinancialManagementScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _financialData = {};

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() => _isLoading = true);
    try {
      // Simulate financial data loading
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _financialData = {
          'totalRevenue': 125000.0,
          'monthlyRevenue': 15000.0,
          'subscriptions': 450,
          'transactions': 1250,
          'commissionRate': 5.0,
          'pendingPayouts': 8500.0,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading financial data: $e')),
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
                    'Financial Management',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Financial Overview Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildFinancialCard(
                        'Total Revenue',
                        '\$${_formatNumber(_financialData['totalRevenue'] ?? 0)}',
                        Icons.attach_money,
                        Colors.green,
                        '+12% this month',
                      ),
                      _buildFinancialCard(
                        'Monthly Revenue',
                        '\$${_formatNumber(_financialData['monthlyRevenue'] ?? 0)}',
                        Icons.trending_up,
                        Colors.blue,
                        'Current month',
                      ),
                      _buildFinancialCard(
                        'Active Subscriptions',
                        '${_financialData['subscriptions'] ?? 0}',
                        Icons.subscriptions,
                        Colors.purple,
                        '95% retention',
                      ),
                      _buildFinancialCard(
                        'Pending Payouts',
                        '\$${_formatNumber(_financialData['pendingPayouts'] ?? 0)}',
                        Icons.payment,
                        Colors.orange,
                        '23 farmers',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      // Revenue Chart
                      Expanded(
                        flex: 2,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Revenue Trend',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: LineChart(
                                    LineChartData(
                                      gridData: const FlGridData(show: true),
                                      titlesData: const FlTitlesData(show: true),
                                      borderData: FlBorderData(show: true),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: [
                                            const FlSpot(0, 3),
                                            const FlSpot(1, 4),
                                            const FlSpot(2, 3.5),
                                            const FlSpot(3, 5),
                                            const FlSpot(4, 4.5),
                                            const FlSpot(5, 6),
                                          ],
                                          isCurved: true,
                                          color: Colors.blue,
                                          barWidth: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Financial Actions
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Financial Actions',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildActionButton(
                                  'Process Payouts',
                                  Icons.payment,
                                  Colors.green,
                                  _processPayouts,
                                ),
                                const SizedBox(height: 8),
                                _buildActionButton(
                                  'Generate Report',
                                  Icons.assessment,
                                  Colors.blue,
                                  _generateFinancialReport,
                                ),
                                const SizedBox(height: 8),
                                _buildActionButton(
                                  'Update Commission',
                                  Icons.percent,
                                  Colors.orange,
                                  _updateCommissionRate,
                                ),
                                const SizedBox(height: 8),
                                _buildActionButton(
                                  'Tax Settings',
                                  Icons.account_balance,
                                  Colors.purple,
                                  _manageTaxSettings,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Recent Transactions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTransactionsList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFinancialCard(
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

  Widget _buildTransactionsList() {
    final transactions = [
      {'user': 'John Farmer', 'amount': 250.0, 'type': 'Sale', 'date': '2024-01-15'},
      {'user': 'Mary Buyer', 'amount': -50.0, 'type': 'Refund', 'date': '2024-01-14'},
      {'user': 'Bob Farmer', 'amount': 180.0, 'type': 'Sale', 'date': '2024-01-14'},
      {'user': 'Alice Buyer', 'amount': 320.0, 'type': 'Sale', 'date': '2024-01-13'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isPositive = (transaction['amount'] as double) > 0;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isPositive ? Colors.green.shade100 : Colors.red.shade100,
            child: Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
          title: Text(transaction['user'] as String),
          subtitle: Text('${transaction['type']} • ${transaction['date']}'),
          trailing: Text(
            '\$${(transaction['amount'] as double).abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  Future<void> _processPayouts() async {
    final confirmed = await _showConfirmationDialog(
      'Process Payouts',
      'This will process all pending payouts. Continue?',
    );
    
    if (confirmed) {
      _showLoadingDialog('Processing payouts...');
      await Future.delayed(const Duration(seconds: 3));
      Navigator.pop(context);
      _showSuccessDialog('Payouts processed successfully!');
    }
  }

  Future<void> _generateFinancialReport() async {
    _showLoadingDialog('Generating financial report...');
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);
    _showSuccessDialog('Financial report generated and sent to your email!');
  }

  Future<void> _updateCommissionRate() async {
    final controller = TextEditingController(text: '5.0');
    
    final newRate = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Commission Rate'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Commission Rate (%)',
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    
    if (newRate != null) {
      _showSuccessDialog('Commission rate updated to ${newRate.toStringAsFixed(1)}%');
    }
  }

  Future<void> _manageTaxSettings() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tax Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('VAT Rate'),
              trailing: Text('20%'),
            ),
            ListTile(
              title: Text('Income Tax'),
              trailing: Text('15%'),
            ),
            ListTile(
              title: Text('Transaction Fee'),
              trailing: Text('2.5%'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessDialog('Tax settings updated successfully!');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
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