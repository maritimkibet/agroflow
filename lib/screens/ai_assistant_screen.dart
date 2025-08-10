import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;  // Temporarily disabled
import 'package:geolocator/geolocator.dart';
import '../services/hive_service.dart';
import '../services/weather_service.dart';
import '../models/user.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = []; // conversation history

  bool _isLoading = false;
  User? _currentUser;
  Map<String, dynamic>? _weatherData;
  Position? _currentPosition;

  late FlutterTts _flutterTts;
  // late stt.SpeechToText _speech;  // Temporarily disabled
  bool _isListening = false;

  final HiveService _hiveService = HiveService();
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    // _speech = stt.SpeechToText();  // Temporarily disabled
    _initializeUserData();
    _addWelcomeMessage();
  }

  Future<void> _initializeUserData() async {
    _currentUser = _hiveService.getCurrentUser();
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

  void _addWelcomeMessage() {
    final userName = _currentUser?.name ?? 'there';
    final userRole = _currentUser?.role.name ?? 'user';

    setState(() {
      _messages.add({
        'role': 'ai',
        'text':
            'Hello $userName! I\'m AgroFlow AI, your agricultural assistant. I can help you with farming advice, market insights, and more based on your location and current weather conditions. As a $userRole, what would you like to know today?',
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
    const apiKey = 'AIzaSyC2qxVLaZSVCcGu_khOHMeK0vRxGoOtCl8';
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey';

    // Build context-aware system prompt
    String systemPrompt = _buildSystemPrompt();

    // Prepare conversation with context
    String conversationText = '$systemPrompt\n\n';
    conversationText += messages
        .map(
          (msg) =>
              '${msg['role'] == 'user' ? 'User' : 'Assistant'}: ${msg['text']}',
        )
        .join('\n');

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": conversationText},
          ],
        },
      ],
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final aiResponse = data['candidates'][0]['content']['parts'][0]['text'];
      return aiResponse.trim();
    } else {
      throw Exception('Failed to get response: ${response.body}');
    }
  }

  String _buildSystemPrompt() {
    String prompt =
        '''You are AgroFlow AI, a global agricultural and marketplace assistant. You help farmers and sellers anywhere in the world with advice tailored to their exact location.

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

Current Weather Data:
- Temperature: ${_weatherData!['temperature']?.round() ?? 'N/A'}°C
- Condition: ${_weatherData!['description'] ?? 'N/A'}
- Humidity: ${_weatherData!['humidity'] ?? 'N/A'}%
- Wind Speed: ${_weatherData!['windSpeed'] ?? 'N/A'} m/s''';
    }

    prompt += '''

Your tasks:
1. Always use the location and weather data to make your advice relevant to the user's environment — including local climate patterns, planting seasons, and market trends.

2. For farmers:
- Recommend planting, irrigation, fertilization, and pest management strategies that suit the current and upcoming weather.
- Suggest harvest timing and crop care based on seasonal conditions in their area.

3. For sellers/buyers:
- Recommend best pricing strategies for their local market conditions.
- Suggest optimal times to sell based on demand, harvest cycles, and weather.
- Offer marketing and presentation tips.

4. If weather or location data is missing, request it before giving detailed advice.

5. Keep responses clear, practical, and relevant to the location provided.

6. Always consider the user's role when providing advice.''';

    return prompt;
  }

  Future _speak(String text) async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  Future<void> _startListening() async {
    // Speech-to-text temporarily disabled due to build issues
    _showError('Speech recognition temporarily unavailable');
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
              itemCount: _messages.length,
              itemBuilder: (context, index) {
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
                      color: isUser ? Colors.green[300] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(message['text'] ?? ''),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            if (_isListening) {
                              // _speech.stop();  // Temporarily disabled
                              setState(() => _isListening = false);
                            } else {
                              _startListening();
                            }
                          },
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _isLoading ? null : _sendMessage(),
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
