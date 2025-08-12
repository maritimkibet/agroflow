import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import '../services/hybrid_storage_service.dart';
import '../services/weather_service.dart';
import '../services/ai_analysis_service.dart';
import '../models/user.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  User? _currentUser;
  Map<String, dynamic>? _weatherData;
  Position? _currentPosition;

  late FlutterTts _flutterTts;
  final HybridStorageService _storageService = HybridStorageService();
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _initializeUserData();
    _addWelcomeMessage();
  }

  Future<void> _initializeUserData() async {
    _currentUser = _storageService.getCurrentUser();
    await _getCurrentLocation();
    await _getWeatherData();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _getWeatherData() async {
    try {
      _weatherData = await _weatherService.getCurrentWeather();
    } catch (e) {
      print('Error getting weather: $e');
    }
  }

  void _addWelcomeMessage() async {
    final userName = _currentUser?.name ?? 'there';
    final userRole = _currentUser?.role.name ?? 'user';
    
    // Get AI analysis for contextual welcome
    final aiAnalysis = AIAnalysisService();
    final insights = await aiAnalysis.analyzeAppData();
    
    String contextualMessage = 'Hello $userName! I\'m AgroFlow AI, your agricultural assistant. ';
    
    if (insights.isNotEmpty) {
      final urgentTasks = insights.where((insight) => 
        insight.toLowerCase().contains('urgent') || 
        insight.toLowerCase().contains('overdue') ||
        insight.toLowerCase().contains('immediate')).toList();
      
      if (urgentTasks.isNotEmpty) {
        contextualMessage += 'I\'ve analyzed your farm data and found some urgent matters that need attention:\n\n';
        contextualMessage += urgentTasks.take(2).join('\n\n');
        contextualMessage += '\n\nWhat would you like to address first?';
      } else {
        contextualMessage += 'I\'ve analyzed your current farming situation. Here\'s what I recommend today:\n\n';
        contextualMessage += insights.take(2).join('\n\n');
        contextualMessage += '\n\nHow can I help you optimize your farming today?';
      }
    } else {
      contextualMessage += 'I can help with farming advice, market insights, and more based on your location and weather. As a $userRole, what would you like to know today?';
    }
    
    setState(() {
      _messages.add({
        'role': 'ai',
        'text': contextualMessage,
      });
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': userMessage});
      _isLoading = true;
      _controller.clear();
    });

    try {
      final responseText = await _getGeminiResponse(_messages);
      setState(() {
        _messages.add({'role': 'ai', 'text': responseText});
      });
      await _speak(responseText);
    } catch (e) {
      _showError('Error: ${e.toString()}');
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Sorry, something went wrong.'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getGeminiResponse(List<Map<String, String>> messages) async {
    const apiKey = 'AIzaSyDvUIam0w81CiSBL0BaAuU-PZTJbDsEkvk';
    const url =
        'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$apiKey';

    final systemPrompt = _buildSystemPrompt();

    final contents = [
      {
        "parts": [
          {"text": systemPrompt}
        ]
      },
      for (var msg in messages)
        {
          "parts": [
            {
              "text":
                  "${msg['role'] == 'user' ? 'User' : 'Assistant'}: ${msg['text']}"
            }
          ]
        }
    ];

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"contents": contents}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'].trim();
    } else {
      throw Exception('Failed to get response: ${response.body}');
    }
  }

  String _buildSystemPrompt() {
    final recentTasks = _storageService
        .getAllTasks()
        .where((task) =>
            task.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .toList();

    String prompt = '''You are AgroFlow AI, a global agricultural and marketplace assistant. You analyze farming activities, weather patterns, and provide intelligent advice.

User Information:
- Role: ${_currentUser?.role.name ?? 'unknown'}
- Name: ${_currentUser?.name ?? 'User'}
- Location: ${_currentUser?.location ?? 'Unknown location'}''';

    if (_currentPosition != null) {
      prompt += '''
- GPS Coordinates: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}''';
    }
    if (_weatherData != null) {
      prompt += '''

Current Weather:
- Temperature: ${_weatherData!['temperature']?.round() ?? 'N/A'}°C
- Condition: ${_weatherData!['description'] ?? 'N/A'}
- Humidity: ${_weatherData!['humidity'] ?? 'N/A'}%
- Wind Speed: ${_weatherData!['windSpeed'] ?? 'N/A'} m/s''';
    }
    if (recentTasks.isNotEmpty) {
      prompt += '''

Recent Farming Activities (Last 30 days):''';
      for (final task in recentTasks.take(5)) {
        final status = task.isCompleted ? '✅ Completed' : '⏳ Pending';
        final daysAgo = DateTime.now().difference(task.date).inDays;
        prompt += '''
- ${task.cropName}: ${task.taskDescription} ($status) - $daysAgo days ago''';
      }
    }
    prompt += '''

Provide intelligent, context-aware farming advice considering the above data.''';
    return prompt;
  }

  Future _speak(String text) async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AgroFlow AI Assistant")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  final message = _messages[index];
                  final isUser = message['role'] == 'user';
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isUser ? Colors.green[300] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(message['text'] ?? ''),
                    ),
                  );
                } else {
                  // Typing indicator
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "AgroFlow AI is typing...",
                            style:
                                TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: _isLoading
                      ? null
                      : () {
                          _showError(
                              '💡 Tip: Ask me about farming, weather, crops, or marketplace advice!');
                        },
                  tooltip: 'Get help',
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) =>
                        _isLoading ? null : _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: "Ask a farming question...",
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
