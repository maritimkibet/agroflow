import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../services/hybrid_storage_service.dart';
import '../services/weather_service.dart';
import '../services/achievement_service.dart';
import '../services/growth_analytics_service.dart';
import '../widgets/achievement_notification.dart';
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
  File? _selectedImage;

  late FlutterTts _flutterTts;
  final HybridStorageService _storageService = HybridStorageService();
  final WeatherService _weatherService = WeatherService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _initializeUserData();
    _addWelcomeMessage();
  }

  Future<void> _initializeUserData() async {
    _currentUser = _storageService.getCurrentUser();
    await _getWeatherData();
  }

  Future<void> _getWeatherData() async {
    try {
      _weatherData = await _weatherService.getCurrentWeather();
    } catch (e) {
      debugPrint('Error getting weather: $e');
    }
  }

  void _addWelcomeMessage() {
    final userName = _currentUser?.name ?? 'there';
    final userRole = _currentUser?.role.name ?? 'user';

    String contextualMessage =
        'Hello $userName! 🌾 I am AgroFlow AI, your intelligent agricultural assistant powered by Google Gemini. ';
    contextualMessage +=
        'I can help with farming advice, weather insights, crop management, pest control, and marketplace guidance. ';
    contextualMessage += 'As a $userRole, what would you like to know today?';

    setState(() {
      _messages.add({'role': 'ai', 'text': contextualMessage});
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
    if (userMessage.isEmpty && _selectedImage == null) return;

    setState(() {
      if (userMessage.isNotEmpty) {
        _messages.add({'role': 'user', 'text': userMessage});
      }
      _isLoading = true;
      _controller.clear();
    });

    // Track AI usage
    final achievementService = AchievementService();
    final analyticsService = GrowthAnalyticsService();

    await analyticsService.trackAIAssistantUsed();
    final unlockedAchievement = await achievementService.updateProgress(
      'ai_helper',
    );
    if (unlockedAchievement != null && mounted) {
      AchievementNotification.show(context, unlockedAchievement);
    }

    try {
      final responseText = await _getGeminiResponse(
        userMessage,
        _selectedImage,
      );
      setState(() {
        _messages.add({'role': 'ai', 'text': responseText});
        _selectedImage = null; // reset after sending
      });
      await _speak(responseText);
    } catch (e) {
      debugPrint('AI Error: $e');
      if (mounted) {
        setState(() {
          String errorMessage = 'Sorry, I am having trouble right now. ';
          if (e.toString().contains('Invalid API key')) {
            errorMessage += 'Please configure your Gemini API key.';
          } else if (e.toString().contains('Network')) {
            errorMessage += 'Please check your internet connection.';
          } else if (e.toString().contains('Rate limit')) {
            errorMessage += 'Too many requests - please wait and try again.';
          } else {
            errorMessage += 'Please try again in a moment!';
          }
          _messages.add({'role': 'ai', 'text': errorMessage});
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _getGeminiResponse(String text, File? imageFile) async {
    const apiKey = 'YOUR_API_KEY'; // replace with your Gemini API key
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey';

    final systemPrompt = _buildSystemPrompt();

    final List<Map<String, dynamic>> parts = [
      {"text": systemPrompt},
      if (text.isNotEmpty) {"text": text},
    ];

    if (imageFile != null) {
      final base64Image = base64Encode(await imageFile.readAsBytes());
      parts.add({
        "inlineData": {"mimeType": "image/jpeg", "data": base64Image},
      });
    }

    final requestBody = {
      "contents": [
        {"parts": parts},
      ],
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        return data['candidates'][0]['content']['parts'][0]['text'].trim();
      } else {
        throw Exception('No AI response received');
      }
    } else if (response.statusCode == 403) {
      throw Exception('Invalid API key - Please configure your Gemini API key');
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit exceeded - Please try again in a moment');
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  String _buildSystemPrompt() {
    final recentTasks =
        _storageService
            .getAllTasks()
            .where(
              (task) => task.date.isAfter(
                DateTime.now().subtract(const Duration(days: 30)),
              ),
            )
            .toList();

    String prompt =
        '''You are AgroFlow AI, a farming assistant powered by Google Gemini. 
User Information:
- Role: ${_currentUser?.role.name ?? 'farmer'}
- Name: ${_currentUser?.name ?? 'User'}
- Location: ${_currentUser?.location ?? 'Unknown location'}''';

    if (_weatherData != null) {
      prompt += '''
Weather:
- Temp: ${_weatherData!['temperature']?.round() ?? 'N/A'}°C
- Condition: ${_weatherData!['description'] ?? 'N/A'}
- Humidity: ${_weatherData!['humidity'] ?? 'N/A'}%
- Wind: ${_weatherData!['windSpeed'] ?? 'N/A'} m/s''';
    }

    if (recentTasks.isNotEmpty) {
      prompt += '\nRecent Farming Tasks:';
      for (final task in recentTasks.take(5)) {
        final status = task.isCompleted ? '✅ Done' : '⏳ Pending';
        final daysAgo = DateTime.now().difference(task.date).inDays;
        prompt +=
            '\n- ${task.cropName}: ${task.taskDescription} ($status, $daysAgo days ago)';
      }
    }

    prompt += '''
Instructions:
- Give practical farming advice
- Be concise, clear, and supportive
- Use emojis for engagement 🌱🌾☀️
''';

    return prompt;
  }

  Future _speak(String text) async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AgroFlow AI Assistant"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.psychology),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _pickImage,
            tooltip: "Attach image",
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.green.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.psychology, color: Colors.green.shade700, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Powered by Google Gemini AI',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  Image.file(_selectedImage!, height: 120),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
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
                            isUser
                                ? Colors.green.shade300
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message['text'] ?? '',
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                } else {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.green.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "AgroFlow AI is thinking...",
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Ask me anything about farming...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
