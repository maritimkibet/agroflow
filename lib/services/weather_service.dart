import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'platform_service.dart';

class WeatherService {
  final String _apiKey = '521524a9f71eae6f1e35b3122388862a';

  /// Fetches current weather from OpenWeatherMap based on device location.
  /// Returns null on failure.
  Future<Map<String, dynamic>?> getCurrentWeather() async {
    try {
      // Check if platform supports location
      if (!PlatformService.instance.supportsFeature(PlatformFeature.location)) {
        // Use default location (Nairobi, Kenya) for desktop/web
        return await _getWeatherByCoordinates(-1.2921, 36.8219);
      }

      final position = await _determinePosition();
      return await _getWeatherByCoordinates(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("WeatherService error: $e");
      // Fallback to default location on error
      return await _getWeatherByCoordinates(-1.2921, 36.8219);
    }
  }

  /// Get weather by specific coordinates
  Future<Map<String, dynamic>?> _getWeatherByCoordinates(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=$lat&lon=$lon'
        '&units=metric&appid=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final temp = data['main']?['temp'];
        final description = data['weather']?[0]?['description'];
        final humidity = data['main']?['humidity'];
        final windSpeed = data['wind']?['speed'];
        final iconCode = data['weather']?[0]?['icon'];

        if (temp != null && description != null) {
          return {
            'temperature': temp,
            'description': _capitalize(description),
            'humidity': humidity,
            'windSpeed': windSpeed,
            'iconCode': iconCode,
          };
        } else {
          debugPrint("Unexpected weather API format: $data");
          return null;
        }
      } else {
        debugPrint("Weather API error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Weather API error: $e");
      return null;
    }
  }

  /// Gets the device's current position after checking permissions.
  /// Throws exceptions if services/permissions are disabled.
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied by the user.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Capitalizes the first letter of the input string.
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
