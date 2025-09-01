import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/blockchain_traceability_service.dart';

class TraceabilityScreen extends StatefulWidget {
  const TraceabilityScreen({super.key});

  @override
  State<TraceabilityScreen> createState() => _TraceabilityScreenState();
}

class _TraceabilityScreenState extends State<TraceabilityScreen> with SingleTickerProviderStateMixin {
  final BlockchainTraceabilityService _traceabilityService = BlockchainTraceabilityService();
  late TabController _tabController;
  
  String? _selectedProductId;
  List<TraceabilityBlock> _productHistory = [];
  Map<String, dynamic> _sustainabilityMetrics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSustainabilityMetrics();
  }

  Future<void> _loadSustainabilityMetrics() async {
    // Mock farmer ID - in production, get from current user
    final metrics = _traceabilityService.getSustainabilityMetrics('current_farmer_id');
    setState(() {
      _sustainabilityMetrics = metrics;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔗 Farm-to-Table Traceability'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code), text: 'QR Codes'),
            Tab(icon: Icon(Icons.timeline), text: 'History'),
            Tab(icon: Icon(Icons.eco), text: 'Sustainability'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQRCodeTab(),
          _buildHistoryTab(),
          _buildSustainabilityTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecordDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildQRCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProductSelector(),
          if (_selectedProductId != null) ...[
            const SizedBox(height: 20),
            _buildQRCodeGenerator(),
          ],
          const SizedBox(height: 20),
          _buildQRCodeInfo(),
        ],
      ),
    );
  }

  Widget _buildProductSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Product for QR Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedProductId,
              decoration: const InputDecoration(
                labelText: 'Product',
                border: OutlineInputBorder(),
              ),
              items: [
                'PROD001 - Organic Tomatoes',
                'PROD002 - Free-range Eggs',
                'PROD003 - Maize Harvest',
                'PROD004 - Coffee Beans',
              ].map((product) => DropdownMenuItem(
                value: product.split(' - ')[0],
                child: Text(product),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProductId = value;
                  _loadProductHistory();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeGenerator() {
    final qrData = _traceabilityService.generateQRCodeData(_selectedProductId!);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Product QR Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: qrData.toString(),
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan this QR code to view complete product traceability',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Share QR code
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Download QR code
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeInfo() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'How QR Codes Work',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('• Customers scan QR codes to see product journey'),
            Text('• View farming practices and certifications'),
            Text('• Verify authenticity and quality'),
            Text('• Build trust with transparent information'),
            Text('• Increase product value through traceability'),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _productHistory.length,
      itemBuilder: (context, index) {
        final block = _productHistory[index];
        return _buildHistoryCard(block);
      },
    );
  }

  Widget _buildHistoryCard(TraceabilityBlock block) {
    IconData actionIcon;
    Color actionColor;
    
    switch (block.action) {
      case 'planting':
        actionIcon = Icons.eco;
        actionColor = Colors.green;
        break;
      case 'harvest':
        actionIcon = Icons.agriculture;
        actionColor = Colors.orange;
        break;
      case 'processing':
        actionIcon = Icons.factory;
        actionColor = Colors.blue;
        break;
      case 'transport':
        actionIcon = Icons.local_shipping;
        actionColor = Colors.purple;
        break;
      default:
        actionIcon = Icons.circle;
        actionColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(actionIcon, color: actionColor),
        title: Text(
          block.action.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${block.timestamp.day}/${block.timestamp.month}/${block.timestamp.year}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (block.location != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text('Location: ${block.location}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (block.certifications.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.verified, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text('Certifications: ${block.certifications.join(', ')}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                const Text(
                  'Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...block.data.entries.map((entry) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Block Hash: ${block.hash.substring(0, 16)}...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSustainabilityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSustainabilityScore(),
          const SizedBox(height: 20),
          _buildSustainabilityMetrics(),
          const SizedBox(height: 20),
          _buildCertificationStatus(),
        ],
      ),
    );
  }

  Widget _buildSustainabilityScore() {
    final score = _sustainabilityMetrics['sustainability_score'] ?? 0.0;
    final scorePercentage = score / 100;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Sustainability Score',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: scorePercentage,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      score >= 80 ? Colors.green :
                      score >= 60 ? Colors.orange : Colors.red,
                    ),
                  ),
                ),
                Text(
                  '${score.toInt()}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getSustainabilityLevel(score),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: score >= 80 ? Colors.green :
                       score >= 60 ? Colors.orange : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSustainabilityMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sustainability Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Total Products',
              '${_sustainabilityMetrics['total_products'] ?? 0}',
              Icons.inventory,
            ),
            _buildMetricRow(
              'Organic Products',
              '${(_sustainabilityMetrics['organic_percentage'] ?? 0).toInt()}%',
              Icons.eco,
            ),
            _buildMetricRow(
              'Certified Products',
              '${(_sustainabilityMetrics['certification_rate'] ?? 0).toInt()}%',
              Icons.verified,
            ),
            _buildMetricRow(
              'Avg. Carbon Footprint',
              '${(_sustainabilityMetrics['average_carbon_footprint'] ?? 0).toStringAsFixed(1)} kg CO₂',
              Icons.cloud,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Certifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCertificationItem('Organic', true),
            _buildCertificationItem('Fair Trade', false),
            _buildCertificationItem('Rainforest Alliance', false),
            _buildCertificationItem('GlobalGAP', true),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to certification application
              },
              icon: const Icon(Icons.add_circle),
              label: const Text('Apply for Certification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationItem(String name, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getSustainabilityLevel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  void _loadProductHistory() {
    if (_selectedProductId != null) {
      setState(() {
        _productHistory = _traceabilityService.getProductHistory(_selectedProductId!);
      });
    }
  }

  void _showAddRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Traceability Record'),
        content: const Text('This feature allows you to add new records to the blockchain for product traceability.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement add record functionality
            },
            child: const Text('Add Record'),
          ),
        ],
      ),
    );
  }
}