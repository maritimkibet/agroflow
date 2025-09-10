import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../config/secrets.dart';
import '../models/product.dart';
import '../models/crop_task.dart';
import 'hybrid_storage_service.dart';

class AutomationService {
  static final AutomationService _instance = AutomationService._internal();
  factory AutomationService() => _instance;
  AutomationService._internal();

  final HybridStorageService _storage = HybridStorageService();

  // Send pricing intelligence request to Make.com
  Future<Map<String, dynamic>?> requestPricingIntelligence(Product product) async {
    try {
      final user = _storage.getCurrentUser();
      if (user == null) throw Exception('User not authenticated');

      final position = await _getCurrentLocation();
      final weatherData = await _getCurrentWeather(position);

      final payload = {
        'type': 'pricing_intelligence',
        'timestamp': DateTime.now().toIso8601String(),
        'user': {
          'id': user.id,
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          }
        },
        'product': {
          'id': product.id,
          'name': product.name,
          'type': product.type.toString().split('.').last,
          'currentPrice': product.price,
          'description': product.description,
          'location': product.location,
          'listingType': product.listingType.toString().split('.').last,
          'sellerId': product.sellerId,
        },
        'context': {
          'weather': weatherData,
          'season': _getCurrentSeason(),
          'marketConditions': await _getMarketContext(),
        }
      };

      final response = await http.post(
        Uri.parse(Secrets.makeWebhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Secret': Secrets.webhookSecret,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Webhook failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Pricing intelligence error: $e');
      return null;
    }
  }

  // Send crop management data for smart scheduling
  Future<Map<String, dynamic>?> requestSmartScheduling(List<CropTask> tasks) async {
    try {
      final user = _storage.getCurrentUser();
      if (user == null) throw Exception('User not authenticated');

      final position = await _getCurrentLocation();
      final weatherData = await _getCurrentWeather(position);
      final forecast = await _getWeatherForecast(position);

      final payload = {
        'type': 'smart_scheduling',
        'timestamp': DateTime.now().toIso8601String(),
        'user': {
          'id': user.id,
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          }
        },
        'tasks': tasks.map((task) => {
          'id': task.id,
          'cropName': task.cropName,
          'taskDescription': task.taskDescription,
          'date': task.date.toIso8601String(),
          'priority': task.priority ?? 'medium',
          'taskType': task.taskType ?? 'general',
          'isCompleted': task.isCompleted,
          'notes': task.notes,
        }).toList(),
        'context': {
          'currentWeather': weatherData,
          'forecast': forecast,
          'season': _getCurrentSeason(),
          'soilConditions': await _getSoilConditions(position),
        }
      };

      final response = await http.post(
        Uri.parse(Secrets.makeWebhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Secret': Secrets.webhookSecret,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Webhook failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Smart scheduling error: $e');
      return null;
    }
  }

  // Send social media content for cross-posting
  Future<Map<String, dynamic>?> requestSocialMediaPosting(Map<String, dynamic> content) async {
    try {
      final user = _storage.getCurrentUser();
      if (user == null) throw Exception('User not authenticated');

      final payload = {
        'type': 'social_media_posting',
        'timestamp': DateTime.now().toIso8601String(),
        'user': {
          'id': user.id,
          'name': user.name,
        },
        'content': {
          'text': content['text'],
          'images': content['images'] ?? [],
          'hashtags': content['hashtags'] ?? [],
          'platforms': content['platforms'] ?? ['facebook', 'instagram', 'twitter'],
          'scheduledTime': content['scheduledTime'],
        },
        'context': {
          'contentType': content['contentType'] ?? 'general',
          'farmingActivity': content['farmingActivity'],
          'location': content['location'],
        }
      };

      final response = await http.post(
        Uri.parse(Secrets.makeWebhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Secret': Secrets.webhookSecret,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Webhook failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Social media posting error: $e');
      return null;
    }
  }

  // Helper methods
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, dynamic>> _getCurrentWeather(Position position) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=${Secrets.openWeatherApiKey}&units=metric'
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'temperature': data['main']['temp'],
          'humidity': data['main']['humidity'],
          'pressure': data['main']['pressure'],
          'windSpeed': data['wind']['speed'],
          'description': data['weather'][0]['description'],
          'cloudiness': data['clouds']['all'],
        };
      }
    } catch (e) {
      debugPrint('Weather API error: $e');
    }
    
    return {
      'temperature': 25.0,
      'humidity': 60,
      'description': 'clear sky',
    };
  }

  Future<List<Map<String, dynamic>>> _getWeatherForecast(Position position) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=${Secrets.openWeatherApiKey}&units=metric'
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['list'] as List).take(5).map((item) => {
          'date': item['dt_txt'],
          'temperature': item['main']['temp'],
          'humidity': item['main']['humidity'],
          'description': item['weather'][0]['description'],
          'precipitation': item['rain']?['3h'] ?? 0.0,
        }).toList();
      }
    } catch (e) {
      debugPrint('Weather forecast error: $e');
    }
    
    return [];
  }

  String _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }

  Future<Map<String, dynamic>> _getMarketContext() async {
    // This would integrate with market data APIs
    return {
      'demandLevel': 'high',
      'supplyLevel': 'medium',
      'pricetrend': 'increasing',
      'competitorCount': 15,
    };
  }

  Future<Map<String, dynamic>> _getSoilConditions(Position position) async {
    // This would integrate with soil data APIs or IoT sensors
    return {
      'moisture': 'optimal',
      'ph': 6.5,
      'nutrients': 'adequate',
      'temperature': 18.0,
    };
  }
}