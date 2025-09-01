import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/hybrid_storage_service.dart';
import '../services/weather_service.dart';
import '../models/crop_task.dart';
import '../models/user.dart';

class AIAnalysisService {
  final HybridStorageService _storageService = HybridStorageService();
  final WeatherService _weatherService = WeatherService();
  
  static const String _apiKey = 'AIzaSyC2qxVLaZSVCcGu_khOHMeK0vRxGoOtCl8'; // Replace with your actual Gemini API key
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey';

  /// Performs comprehensive analysis when app opens
  Future<String> performStartupAnalysis() async {
    try {
      // Gather all data
      final user = _storageService.getCurrentUser();
      final tasks = _storageService.getAllTasks();
      final weather = await _weatherService.getCurrentWeather();
      
      // Generate analysis prompt
      final analysisPrompt = _buildAnalysisPrompt(user, tasks, weather);
      
      // Get AI analysis
      final analysis = await _getAIAnalysis(analysisPrompt);
      
      return analysis;
    } catch (e) {
      return _getFallbackAnalysis();
    }
  }

  String _buildAnalysisPrompt(User? user, List<CropTask> tasks, Map<String, dynamic>? weather) {
    final now = DateTime.now();
    final recentTasks = tasks.where((task) => 
        task.date.isAfter(now.subtract(const Duration(days: 7)))).toList();
    final upcomingTasks = tasks.where((task) => 
        task.date.isAfter(now) && task.date.isBefore(now.add(const Duration(days: 7)))).toList();
    final overdueTasks = tasks.where((task) => 
        task.date.isBefore(now) && !task.isCompleted).toList();
    
    String prompt = '''You are AgroFlow AI. Analyze the farmer's current situation and provide 3-4 actionable insights.

FARMER PROFILE:
- Name: ${user?.name ?? 'Farmer'}
- Role: ${user?.role.name ?? 'farmer'}
- Location: ${user?.location ?? 'Unknown'}

CURRENT WEATHER:''';

    if (weather != null) {
      prompt += '''
- Temperature: ${weather['temperature']?.round() ?? 'N/A'}°C
- Condition: ${weather['description'] ?? 'N/A'}
- Humidity: ${weather['humidity'] ?? 'N/A'}%
- Wind Speed: ${weather['windSpeed'] ?? 'N/A'} m/s''';
    } else {
      prompt += '\n- Weather data unavailable';
    }

    prompt += '''

TASK ANALYSIS:
- Total Tasks: ${tasks.length}
- Completed: ${tasks.where((t) => t.isCompleted).length}
- Pending: ${tasks.where((t) => !t.isCompleted).length}
- Overdue: ${overdueTasks.length}''';

    if (recentTasks.isNotEmpty) {
      prompt += '\n\nRECENT ACTIVITIES (Last 7 days):';
      for (final task in recentTasks.take(5)) {
        final daysAgo = now.difference(task.date).inDays;
        final timeRef = daysAgo == 0 ? 'today' : daysAgo == 1 ? 'yesterday' : '$daysAgo days ago';
        prompt += '\n- ${task.isCompleted ? '✅' : '⏳'} ${task.cropName}: ${task.taskDescription} ($timeRef)';
      }
    }

    if (upcomingTasks.isNotEmpty) {
      prompt += '\n\nUPCOMING TASKS (Next 7 days):';
      for (final task in upcomingTasks.take(5)) {
        final daysAhead = task.date.difference(now).inDays;
        final timeRef = daysAhead == 0 ? 'today' : daysAhead == 1 ? 'tomorrow' : 'in $daysAhead days';
        prompt += '\n- ${task.cropName}: ${task.taskDescription} ($timeRef)';
      }
    }

    if (overdueTasks.isNotEmpty) {
      prompt += '\n\n⚠️ OVERDUE TASKS:';
      for (final task in overdueTasks.take(3)) {
        final daysOverdue = now.difference(task.date).inDays;
        prompt += '\n- ${task.cropName}: ${task.taskDescription} ($daysOverdue days overdue)';
      }
    }

    prompt += '''

ANALYSIS REQUIREMENTS:
1. Provide 3-4 specific, actionable insights
2. Consider weather impact on farming activities
3. Prioritize urgent/overdue tasks
4. Give weather-appropriate recommendations
5. Include timing suggestions
6. Keep each insight concise (1-2 sentences)
7. Use emojis for visual appeal
8. Focus on immediate actions needed

Format as: "🌱 [Insight title]: [Specific recommendation]"

Provide practical farming advice based on this analysis:''';

    return prompt;
  }

  Future<String> _getAIAnalysis(String prompt) async {
    try {
      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      });

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'].trim();
        } else {
          throw Exception('No AI response received');
        }
      } else if (response.statusCode == 403) {
        throw Exception('Invalid API key - Please check your Gemini API configuration');
      } else if (response.statusCode == 429) {
        throw Exception('API rate limit exceeded - Please try again later');
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Network connection failed - Check your internet connection');
      }
      throw Exception('Analysis failed: $e');
    }
  }

  String _getFallbackAnalysis() {
    final tasks = _storageService.getAllTasks();
    final now = DateTime.now();
    final overdueTasks = tasks.where((task) => 
        task.date.isBefore(now) && !task.isCompleted).length;
    final upcomingTasks = tasks.where((task) => 
        task.date.isAfter(now) && task.date.isBefore(now.add(const Duration(days: 3)))).length;

    String analysis = '🌱 Daily Farming Insights:\n\n';

    if (overdueTasks > 0) {
      analysis += '⚠️ Priority Alert: You have $overdueTasks overdue tasks that need immediate attention.\n\n';
    }

    if (upcomingTasks > 0) {
      analysis += '📅 Upcoming Work: $upcomingTasks tasks scheduled for the next 3 days. Plan accordingly.\n\n';
    }

    analysis += '🌤️ Weather Check: Monitor weather conditions before starting outdoor activities.\n\n';
    analysis += '💧 Daily Reminder: Check soil moisture levels and water as needed.';

    return analysis;
  }

  /// Quick analysis for specific scenarios
  Future<String> getContextualTip(String context) async {
    try {
      final user = _storageService.getCurrentUser();
      final weather = await _weatherService.getCurrentWeather();
      
      String prompt = '''You are AgroFlow AI. Provide a quick farming tip for this context: "$context"

User: ${user?.name ?? 'Farmer'} (${user?.role.name ?? 'farmer'})
Location: ${user?.location ?? 'Unknown'}''';

      if (weather != null) {
        prompt += '''
Current Weather: ${weather['temperature']?.round() ?? 'N/A'}°C, ${weather['description'] ?? 'N/A'}''';
      }

      prompt += '''

Provide a single, specific, actionable tip (1-2 sentences) with an emoji. Focus on immediate action.''';

      return await _getAIAnalysis(prompt);
    } catch (e) {
      return '🌱 Keep monitoring your crops and weather conditions for optimal farming results.';
    }
  }

  Future analyzeAppData() async {}
}