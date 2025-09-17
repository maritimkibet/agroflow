import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/hybrid_storage_service.dart';
import '../services/weather_service.dart';
import '../services/achievement_service.dart';
import '../services/growth_analytics_service.dart';
import '../widgets/achievement_notification.dart';
import '../models/user.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
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
    // Best-effort TTS init without blocking UI
    _flutterTts.setLanguage('en-US');
    _flutterTts.setPitch(1.0);

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

    final achievementService = AchievementService();
    final analyticsService = GrowthAnalyticsService();

    String responseText = '';
    try {
      responseText = await _getGeminiResponse(userMessage, _selectedImage);
      if (!mounted) return;

      setState(() {
        _messages.add({'role': 'ai', 'text': responseText});
        _selectedImage = null; // reset after sending
      });
    } catch (e) {
      debugPrint('AI Error: $e');
      if (mounted) {
        setState(() {
          String errorMessage = 'Sorry, I am having trouble right now. ';
          final msg = e.toString();
          if (msg.contains('Invalid API key')) {
            errorMessage += 'Please configure your Gemini API key.';
          } else if (msg.contains('Network')) {
            errorMessage += 'Please check your internet connection.';
          } else if (msg.contains('Rate limit')) {
            errorMessage += 'Too many requests - please wait and try again.';
          } else {
            errorMessage += 'Please try again in a moment!';
          }
          _messages.add({'role': 'ai', 'text': errorMessage});
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    // Fire-and-forget TTS and analytics after UI is updated
    if (responseText.isNotEmpty) {
      _speak(responseText); // intentionally not awaited
    }

    // Do not block UI on tracking; time-box these calls
    () async {
      try {
        await Future.any([
          analyticsService.trackAIAssistantUsed(),
          Future.delayed(const Duration(seconds: 3)),
        ]);

        final unlocked = await achievementService
            .updateProgress('ai_helper')
            .timeout(const Duration(seconds: 3));

        if (unlocked != null && mounted) {
          AchievementNotification.show(context, unlocked);
        }
      } catch (_) {
        // Swallow non-critical tracking errors
      }
    }();
  }

  Future<String> _getGeminiResponse(String text, File? imageFile) async {
    // Mock AI responses for demo purposes
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    final lowerText = text.toLowerCase().trim();

    // Precise greeting detection (no matching "this")
    final greeting =
        RegExp(r'\b(hi|hello|hey|good (morning|afternoon|evening))\b');
    if (greeting.hasMatch(lowerText)) {
      return "Hello! 👋 I'm AgroFlow AI, your farming assistant. I can help you with:\n\n"
          "🌱 Crop management advice\n🌦️ Weather-based recommendations\n🐛 Pest and disease identification\n"
          "💰 Market insights\n📊 Farm analytics\n\nWhat would you like to know about your farm today?";
    }

    if (lowerText.contains('how are you') || lowerText.contains('how do you do')) {
      return "I'm doing great, thank you for asking! 😊 I'm here and ready to help you with all your farming needs. "
          "Whether you need advice on crops, weather insights, or market information, I'm at your service!\n\n"
          "How can I assist you with your farm today?";
    }

    if (lowerText.contains('thank') || lowerText.contains('thanks')) {
      return "You're very welcome! 🌟 I'm always happy to help fellow farmers succeed. "
          "Remember, I'm here 24/7 whenever you need farming advice, weather updates, or market insights.\n\n"
          "Is there anything else I can help you with today?";
    }

    if (lowerText.contains('weather') ||
        lowerText.contains('rain') ||
        lowerText.contains('temperature')) {
      return "🌤️ **Weather Update & Farming Advice:**\n\n"
          "📊 **Current Conditions:**\n"
          "• Temperature: ${_weatherData?['temperature']?.round() ?? 25}°C\n"
          "• Humidity: ${_weatherData?['humidity'] ?? 65}%\n"
          "• Conditions: ${_weatherData?['description'] ?? 'Partly cloudy'}\n\n"
          "🌱 **Farming Recommendations:**\n"
          "• Best time to water: Early morning (6-8 AM)\n"
          "• Avoid spraying in windy conditions\n"
          "• Monitor soil moisture levels\n"
          "• Protect sensitive plants if temperature drops\n\n"
          "📅 **Planning Tip:** Check weather forecast before major farming activities!\n\n"
          "Need specific advice for your crops?";
    }

    if (lowerText.contains('dry') ||
        lowerText.contains('water') ||
        lowerText.contains('irrigation')) {
      return "🌿 I see your plants might need attention! Here's what I recommend:\n\n"
          "💧 **Immediate Actions:**\n"
          "• Check soil moisture 2-3 inches deep\n"
          "• Water early morning or late evening\n"
          "• Apply mulch to retain moisture\n\n"
          "🌡️ **Weather Consideration:**\n"
          "• Current temperature: ${_weatherData?['temperature']?.round() ?? 25}°C\n"
          "• Humidity: ${_weatherData?['humidity'] ?? 65}%\n\n"
          "📋 **Watering Schedule:**\n"
          "• Deep watering 2-3 times per week\n"
          "• Adjust based on plant type and season\n\n"
          "Would you like specific advice for your crop type?";
    }

    if (lowerText.contains('pest') ||
        lowerText.contains('bug') ||
        lowerText.contains('insect') ||
        lowerText.contains('disease')) {
      return "🐛 **Pest & Disease Management:**\n\n"
          "🔍 **Common Signs to Watch:**\n"
          "• Yellowing or spotted leaves\n"
          "• Holes in leaves or fruits\n"
          "• Unusual growth patterns\n"
          "• Sticky residue on plants\n\n"
          "🌿 **Organic Solutions:**\n"
          "• Neem oil spray (2-3 times/week)\n"
          "• Companion planting with marigolds\n"
          "• Beneficial insects like ladybugs\n"
          "• Proper spacing for air circulation\n\n"
          "📸 **Pro Tip:** Take a photo of affected plants for more specific diagnosis!\n\n"
          "What symptoms are you seeing on your plants?";
    }

    if (lowerText.contains('market') ||
        lowerText.contains('price') ||
        lowerText.contains('sell')) {
      return "💰 **Market Insights & Pricing:**\n\n"
          "📈 **Current Trends:**\n"
          "• Organic produce: 15-20% premium\n"
          "• Local markets: Higher margins\n"
          "• Direct-to-consumer: Best profits\n\n"
          "🎯 **Selling Strategies:**\n"
          "• Harvest at optimal ripeness\n"
          "• Clean and grade your produce\n"
          "• Build relationships with buyers\n"
          "• Consider value-added products\n\n"
          "📊 **Price Optimization:**\n"
          "• Track seasonal price patterns\n"
          "• Monitor competitor pricing\n"
          "• Quality over quantity approach\n\n"
          "Which crops are you planning to sell?";
    }

    if (lowerText.contains('fertilizer') ||
        lowerText.contains('nutrient') ||
        lowerText.contains('soil')) {
      return "🌱 **Soil & Nutrition Management:**\n\n"
          "🧪 **Soil Health Basics:**\n"
          "• Test pH levels (6.0-7.0 ideal for most crops)\n"
          "• Check organic matter content\n"
          "• Ensure proper drainage\n\n"
          "🌿 **Organic Fertilizers:**\n"
          "• Compost: Slow-release nutrients\n"
          "• Bone meal: Phosphorus boost\n"
          "• Fish emulsion: Quick nitrogen\n"
          "• Kelp meal: Trace minerals\n\n"
          "📅 **Feeding Schedule:**\n"
          "• Pre-planting: Compost incorporation\n"
          "• Growing season: Bi-weekly liquid feeds\n"
          "• Flowering: Reduce nitrogen, increase phosphorus\n\n"
          "What type of crops are you growing?";
    }

    if (imageFile != null) {
      return "📸 **Image Analysis:**\n\n"
          "I can see you've shared an image! Based on visual analysis, here are some general observations:\n\n"
          "🔍 **What I Notice:**\n"
          "• Plant health indicators\n"
          "• Growth stage assessment\n"
          "• Environmental conditions\n"
          "• Potential issues to monitor\n\n"
          "💡 **Recommendations:**\n"
          "• Continue monitoring plant development\n"
          "• Maintain consistent care routine\n"
          "• Document changes with photos\n"
          "• Consider environmental factors\n\n"
          "For more specific analysis, please describe what concerns you about this plant!";
    }

    // Default helpful response
    return "🌾 **AgroFlow AI at Your Service!**\n\n"
        "I understand you're asking about: \"$text\"\n\n"
        "💡 **Here's my advice:**\n"
        "• Focus on consistent plant care routines\n"
        "• Monitor weather conditions regularly\n"
        "• Keep detailed records of your farming activities\n"
        "• Consider sustainable farming practices\n\n"
        "🎯 **Specific Help Available:**\n"
        "• Crop management strategies\n"
        "• Pest and disease identification\n"
        "• Weather-based recommendations\n"
        "• Market timing advice\n"
        "• Soil health optimization\n\n"
        "Could you be more specific about what aspect of farming you'd like help with? I'm here to provide detailed, actionable advice! 🚜";
  }

  Future _speak(String text) async {
    try {
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
                        color: isUser ? Colors.green.shade300 : Colors.grey.shade200,
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.green.shade600),
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
                    onSubmitted: (_) async {
                      if (!_isLoading) {
                        await _sendMessage();
                      }
                    },
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