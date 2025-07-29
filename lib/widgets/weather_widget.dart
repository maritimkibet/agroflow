import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      final data = await _weatherService.getCurrentWeather();
      if (!mounted) return;
      setState(() {
        _weatherData = data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load weather data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_weatherData == null) {
      return const Center(child: Text('No weather data available.'));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      child: ListTile(
        leading: Image.network(
          'https://openweathermap.org/img/wn/${_weatherData!['iconCode']}@2x.png',
          width: 50,
          height: 50,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.error_outline),
        ),
        title: Text('${_weatherData!['temperature']}°C'),
        subtitle: Text(_weatherData!['description']),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Humidity: ${_weatherData!['humidity']}%'),
            Text('Wind: ${_weatherData!['windSpeed']} m/s'),
          ],
        ),
      ),
    );
  }
}
