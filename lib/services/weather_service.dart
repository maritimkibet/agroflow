import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'platform_service.dart';
import 'localization_service.dart';

class WeatherService {
  final String _apiKey = '521524a9f71eae6f1e35b3122388862a';
  final LocalizationService _localizationService = LocalizationService();

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

  /// Get location-based crop suggestions
  Future<Map<String, dynamic>?> getLocationBasedSuggestions() async {
    try {
      final position = await _determinePosition();
      final weather = await _getWeatherByCoordinates(position.latitude, position.longitude);
      
      if (weather == null) return null;

      final temperature = weather['temperature'] as double;
      final humidity = weather['humidity'] as int? ?? 50;
      final description = weather['description'] as String;
      
      // Get regional crops based on current language/location
      final regionalCrops = _localizationService.getRegionalCrops();
      
      // Get location info from coordinates
      final locationInfo = await _getLocationInfo(position.latitude, position.longitude);
      
      return {
        'location': locationInfo,
        'weather': weather,
        'recommendedCrops': _getWeatherBasedCropRecommendations(temperature, humidity, description, regionalCrops),
        'farmingTips': _getLocationSpecificTips(temperature, humidity, description),
        'plantingCalendar': _getPlantingCalendar(position.latitude),
      };
    } catch (e) {
      debugPrint("Location suggestions error: $e");
      return null;
    }
  }

  /// Get location information from coordinates
  Future<Map<String, String>> _getLocationInfo(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/geo/1.0/reverse'
        '?lat=$lat&lon=$lon&limit=1&appid=$_apiKey',
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          final location = data[0];
          return {
            'city': location['name'] ?? 'Unknown',
            'state': location['state'] ?? '',
            'country': location['country'] ?? 'Unknown',
          };
        }
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
    }
    
    return {
      'city': 'Unknown',
      'state': '',
      'country': 'Unknown',
    };
  }

  /// Get weather-based crop recommendations
  List<Map<String, dynamic>> _getWeatherBasedCropRecommendations(
    double temperature, 
    int humidity, 
    String description,
    List<String> regionalCrops,
  ) {
    final recommendations = <Map<String, dynamic>>[];
    
    // Temperature-based recommendations
    if (temperature >= 25 && temperature <= 35) {
      // Hot weather crops
      final hotWeatherCrops = regionalCrops.where((crop) => 
        ['Maize', 'Sorghum', 'Millet', 'Cotton', 'Sugarcane', 'Tomatoes', 'Peppers'].contains(crop)
      ).toList();
      
      for (final crop in hotWeatherCrops.take(3)) {
        recommendations.add({
          'crop': crop,
          'reason': 'Thrives in current hot weather (${temperature.round()}°C)',
          'confidence': 'High',
          'plantingTip': 'Plant early morning or evening to avoid heat stress',
        });
      }
    } else if (temperature >= 15 && temperature < 25) {
      // Moderate weather crops
      final moderateCrops = regionalCrops.where((crop) => 
        ['Wheat', 'Barley', 'Beans', 'Peas', 'Carrots', 'Lettuce', 'Spinach'].contains(crop)
      ).toList();
      
      for (final crop in moderateCrops.take(3)) {
        recommendations.add({
          'crop': crop,
          'reason': 'Perfect temperature range (${temperature.round()}°C)',
          'confidence': 'High',
          'plantingTip': 'Ideal conditions for planting and growth',
        });
      }
    } else if (temperature < 15) {
      // Cool weather crops
      final coolCrops = regionalCrops.where((crop) => 
        ['Potatoes', 'Cabbage', 'Broccoli', 'Cauliflower', 'Onions'].contains(crop)
      ).toList();
      
      for (final crop in coolCrops.take(3)) {
        recommendations.add({
          'crop': crop,
          'reason': 'Suitable for cooler weather (${temperature.round()}°C)',
          'confidence': 'Medium',
          'plantingTip': 'Consider greenhouse or protected cultivation',
        });
      }
    }

    // Humidity-based recommendations
    if (humidity > 70) {
      recommendations.add({
        'crop': 'Rice',
        'reason': 'High humidity ($humidity%) favors rice cultivation',
        'confidence': 'High',
        'plantingTip': 'Ensure proper drainage to prevent waterlogging',
      });
    }

    // Weather condition-based recommendations
    if (description.toLowerCase().contains('rain')) {
      recommendations.add({
        'crop': 'Any water-loving crops',
        'reason': 'Rainy weather provides natural irrigation',
        'confidence': 'Medium',
        'plantingTip': 'Good time for transplanting seedlings',
      });
    }

    return recommendations.take(5).toList();
  }

  /// Get location-specific farming tips
  List<String> _getLocationSpecificTips(double temperature, int humidity, String description) {
    final tips = <String>[];
    
    if (temperature > 30) {
      tips.add('🌡️ High temperature: Provide shade for livestock and increase watering frequency');
      tips.add('💧 Consider drip irrigation to conserve water in hot weather');
    }
    
    if (humidity > 80) {
      tips.add('💨 High humidity: Ensure good ventilation to prevent fungal diseases');
      tips.add('🍄 Monitor crops closely for signs of mold or mildew');
    }
    
    if (description.toLowerCase().contains('rain')) {
      tips.add('🌧️ Rainy weather: Delay fertilizer application and check drainage systems');
      tips.add('🚜 Avoid heavy machinery on wet soil to prevent compaction');
    }
    
    if (description.toLowerCase().contains('wind')) {
      tips.add('💨 Windy conditions: Secure loose structures and avoid spraying pesticides');
      tips.add('🌱 Provide windbreaks for young plants');
    }
    
    return tips;
  }

  /// Get planting calendar based on latitude (hemisphere and season)
  Map<String, dynamic> _getPlantingCalendar(double latitude) {
    final isNorthernHemisphere = latitude > 0;
    final currentMonth = DateTime.now().month;
    
    if (isNorthernHemisphere) {
      // Northern hemisphere planting calendar
      return {
        'currentSeason': _getNorthernSeason(currentMonth),
        'plantNow': _getNorthernPlantingCrops(currentMonth),
        'plantNext': _getNorthernPlantingCrops((currentMonth % 12) + 1),
      };
    } else {
      // Southern hemisphere planting calendar (seasons reversed)
      return {
        'currentSeason': _getSouthernSeason(currentMonth),
        'plantNow': _getSouthernPlantingCrops(currentMonth),
        'plantNext': _getSouthernPlantingCrops((currentMonth % 12) + 1),
      };
    }
  }

  String _getNorthernSeason(int month) {
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Fall';
    return 'Winter';
  }

  String _getSouthernSeason(int month) {
    if (month >= 3 && month <= 5) return 'Fall';
    if (month >= 6 && month <= 8) return 'Winter';
    if (month >= 9 && month <= 11) return 'Spring';
    return 'Summer';
  }

  List<String> _getNorthernPlantingCrops(int month) {
    switch (month) {
      case 3: case 4: case 5: // Spring
        return ['Tomatoes', 'Peppers', 'Lettuce', 'Spinach', 'Peas', 'Carrots'];
      case 6: case 7: case 8: // Summer
        return ['Beans', 'Corn', 'Squash', 'Cucumbers', 'Herbs'];
      case 9: case 10: case 11: // Fall
        return ['Cabbage', 'Broccoli', 'Radishes', 'Winter Wheat'];
      default: // Winter
        return ['Plan for next season', 'Prepare soil', 'Greenhouse crops'];
    }
  }

  List<String> _getSouthernPlantingCrops(int month) {
    switch (month) {
      case 3: case 4: case 5: // Fall (Southern)
        return ['Cabbage', 'Broccoli', 'Radishes', 'Winter crops'];
      case 6: case 7: case 8: // Winter (Southern)
        return ['Plan for next season', 'Prepare soil', 'Cool season crops'];
      case 9: case 10: case 11: // Spring (Southern)
        return ['Tomatoes', 'Peppers', 'Lettuce', 'Spinach', 'Peas'];
      default: // Summer (Southern)
        return ['Beans', 'Corn', 'Squash', 'Cucumbers', 'Heat-tolerant crops'];
    }
  }

  /// Capitalizes the first letter of the input string.
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
