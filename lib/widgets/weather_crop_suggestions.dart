import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherCropSuggestions extends StatefulWidget {
  const WeatherCropSuggestions({super.key});

  @override
  State<WeatherCropSuggestions> createState() => _WeatherCropSuggestionsState();
}

class _WeatherCropSuggestionsState extends State<WeatherCropSuggestions> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _suggestions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final suggestions = await _weatherService.getLocationBasedSuggestions();
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_sunny, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Weather-Based Suggestions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ),
        ),
      );
    }

    if (_suggestions == null) {
      return const SizedBox.shrink();
    }

    final location = _suggestions!['location'] as Map<String, String>;
    final weather = _suggestions!['weather'] as Map<String, dynamic>;
    final recommendedCrops = _suggestions!['recommendedCrops'] as List<Map<String, dynamic>>;
    final farmingTips = _suggestions!['farmingTips'] as List<String>;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${location['city']}, ${location['country']}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadSuggestions,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh suggestions',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${weather['temperature'].toStringAsFixed(1)}°C - ${weather['description']}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            
            if (recommendedCrops.isNotEmpty) ...[
              const Text(
                '🌱 Recommended Crops',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...recommendedCrops.take(3).map((crop) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            crop['crop'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: crop['confidence'] == 'High' ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              crop['confidence'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        crop['reason'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (crop['plantingTip'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '💡 ${crop['plantingTip']}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 16),
            ],
            
            if (farmingTips.isNotEmpty) ...[
              const Text(
                '💡 Today\'s Farming Tips',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...farmingTips.take(2).map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}