import 'package:flutter/material.dart';
import '../services/climate_adaptation_service.dart';
import '../services/localization_service.dart';

class ClimateAdaptationScreen extends StatefulWidget {
  const ClimateAdaptationScreen({super.key});

  @override
  State<ClimateAdaptationScreen> createState() => _ClimateAdaptationScreenState();
}

class _ClimateAdaptationScreenState extends State<ClimateAdaptationScreen> with SingleTickerProviderStateMixin {
  final ClimateAdaptationService _climateService = ClimateAdaptationService();
  final LocalizationService _localizationService = LocalizationService();
  late TabController _tabController;
  
  Map<String, dynamic> _climateRecommendations = {};
  Map<String, dynamic> _carbonFootprint = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadClimateData();
  }

  Future<void> _loadClimateData() async {
    // Mock coordinates - in production, get from GPS
    const lat = -1.2921; // Nairobi coordinates
    const lon = 36.8219;
    
    final recommendations = await _climateService.getClimateRecommendations(lat, lon);
    final carbonData = await _climateService.calculateCarbonFootprint([
      {'type': 'fertilizer_use', 'amount': 50.0},
      {'type': 'fuel_use', 'liters': 100.0},
      {'type': 'tree_planting', 'trees': 20},
    ]);
    
    setState(() {
      _climateRecommendations = recommendations;
      _carbonFootprint = carbonData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌍 Climate-Smart Farming'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.wb_sunny), text: 'Climate'),
            Tab(icon: Icon(Icons.eco), text: 'Carbon'),
            Tab(icon: Icon(Icons.language), text: 'Regional'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildClimateTab(),
                _buildCarbonTab(),
                _buildRegionalTab(),
              ],
            ),
    );
  }

  Widget _buildClimateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildClimateZoneCard(),
          const SizedBox(height: 16),
          _buildRiskAssessment(),
          const SizedBox(height: 16),
          _buildWaterManagement(),
          const SizedBox(height: 16),
          _buildRecommendedCrops(),
        ],
      ),
    );
  }

  Widget _buildClimateZoneCard() {
    final climateZone = _climateRecommendations['climate_zone'] ?? 'unknown';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _getClimateIcon(climateZone),
              size: 64,
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            Text(
              'Climate Zone: ${climateZone.toUpperCase()}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getClimateDescription(climateZone),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAssessment() {
    final droughtRisk = _climateRecommendations['drought_risk'] ?? 'unknown';
    final floodRisk = _climateRecommendations['flood_risk'] ?? 'unknown';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Climate Risk Assessment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRiskIndicator(
                    'Drought Risk',
                    droughtRisk,
                    Icons.wb_sunny_outlined,
                    _getRiskColor(droughtRisk),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRiskIndicator(
                    'Flood Risk',
                    floodRisk,
                    Icons.water_drop,
                    _getRiskColor(floodRisk),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskIndicator(String title, String risk, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            risk.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterManagement() {
    final waterManagement = _climateRecommendations['water_management'] ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.water_drop, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Water Management Tips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...waterManagement.entries.map((entry) => 
              ExpansionTile(
                title: Text(
                  entry.key.toString().replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: (entry.value as List).map<Widget>((tip) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(child: Text(tip.toString())),
                            ],
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedCrops() {
    final crops = _climateRecommendations['recommended_crops'] ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.agriculture, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Climate-Adapted Crops',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: crops.map<Widget>((crop) => 
                Chip(
                  label: Text(crop.toString()),
                  backgroundColor: Colors.green.shade100,
                  labelStyle: TextStyle(color: Colors.green.shade800),
                ),
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarbonTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCarbonFootprintCard(),
          const SizedBox(height: 16),
          _buildCarbonReductionTips(),
        ],
      ),
    );
  }

  Widget _buildCarbonFootprintCard() {
    final totalEmissions = _carbonFootprint['total_emissions'] ?? 0.0;
    final carbonSequestered = _carbonFootprint['carbon_sequestered'] ?? 0.0;
    final netImpact = _carbonFootprint['net_impact'] ?? 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Carbon Footprint Analysis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildCarbonMetric(
                    'Emissions',
                    '${totalEmissions.toStringAsFixed(1)} kg CO₂',
                    Icons.cloud,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildCarbonMetric(
                    'Sequestered',
                    '${carbonSequestered.toStringAsFixed(1)} kg CO₂',
                    Icons.eco,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: netImpact >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: netImpact >= 0 ? Colors.green : Colors.red,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    netImpact >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: netImpact >= 0 ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Net Impact: ${netImpact.toStringAsFixed(1)} kg CO₂',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: netImpact >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    netImpact >= 0 ? 'Carbon Positive!' : 'Carbon Negative',
                    style: TextStyle(
                      color: netImpact >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarbonMetric(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildCarbonReductionTips() {
    final tips = _carbonFootprint['recommendations'] ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Carbon Reduction Tips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tips.map<Widget>((tip) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.eco, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tip.toString())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLanguageSelector(),
          const SizedBox(height: 16),
          _buildRegionalCrops(),
          const SizedBox(height: 16),
          _buildSeasonalCalendar(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Your Region',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LocalizationService.supportedLanguages.entries.map((entry) {
                final isSelected = entry.key == _localizationService.currentLanguage;
                return FilterChip(
                  label: Text('${entry.value['flag']} ${entry.value['name']}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _localizationService.setLanguage(entry.key);
                      setState(() {});
                    }
                  },
                  selectedColor: Colors.teal.shade100,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionalCrops() {
    final crops = _localizationService.getRegionalCrops();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Regional Crop Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: crops.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Center(
                    child: Text(
                      crops[index],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonalCalendar() {
    final seasons = _localizationService.getRegionalSeasons();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seasonal Farming Calendar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...seasons.entries.map((season) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      season.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: season.value.map<Widget>((month) => 
                        Chip(
                          label: Text(month),
                          backgroundColor: Colors.blue.shade100,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getClimateIcon(String climateZone) {
    switch (climateZone) {
      case 'tropical': return Icons.wb_sunny;
      case 'subtropical': return Icons.wb_cloudy;
      case 'temperate': return Icons.cloud;
      case 'cold': return Icons.ac_unit;
      default: return Icons.public;
    }
  }

  String _getClimateDescription(String climateZone) {
    switch (climateZone) {
      case 'tropical': return 'Hot and humid climate with consistent temperatures year-round';
      case 'subtropical': return 'Warm climate with distinct wet and dry seasons';
      case 'temperate': return 'Moderate climate with four distinct seasons';
      case 'cold': return 'Cool climate with short growing seasons';
      default: return 'Climate zone not determined';
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }
}