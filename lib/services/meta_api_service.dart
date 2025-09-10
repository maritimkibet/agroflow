import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'hive_service.dart';
import 'localization_service.dart';

class MetaAPIService {
  static final MetaAPIService _instance = MetaAPIService._internal();
  factory MetaAPIService() => _instance;
  MetaAPIService._internal();

  final HiveService _hiveService = HiveService();
  final LocalizationService _localizationService = LocalizationService();

  // Meta API credentials (stored securely)
  String? _facebookAccessToken;
  String? _instagramAccessToken;
  String? _whatsappBusinessToken;
  String? _facebookPageId;
  String? _instagramBusinessAccountId;

  // Initialize Meta API connections
  Future<void> initialize() async {
    await _loadStoredTokens();
  }

  Future<void> _loadStoredTokens() async {
    _facebookAccessToken = await _hiveService.getData('facebook_access_token');
    _instagramAccessToken = await _hiveService.getData('instagram_access_token');
    _whatsappBusinessToken = await _hiveService.getData('whatsapp_business_token');
    _facebookPageId = await _hiveService.getData('facebook_page_id');
    _instagramBusinessAccountId = await _hiveService.getData('instagram_business_account_id');
  }

  // Connect Facebook account
  Future<bool> connectFacebook(String accessToken, String pageId) async {
    try {
      // Verify token with Facebook Graph API
      final response = await http.get(
        Uri.parse('https://graph.facebook.com/me?access_token=$accessToken'),
      );

      if (response.statusCode == 200) {
        _facebookAccessToken = accessToken;
        _facebookPageId = pageId;
        
        await _hiveService.saveData('facebook_access_token', accessToken);
        await _hiveService.saveData('facebook_page_id', pageId);
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Connect Instagram Business account
  Future<bool> connectInstagram(String accessToken, String businessAccountId) async {
    try {
      final response = await http.get(
        Uri.parse('https://graph.facebook.com/$businessAccountId?access_token=$accessToken'),
      );

      if (response.statusCode == 200) {
        _instagramAccessToken = accessToken;
        _instagramBusinessAccountId = businessAccountId;
        
        await _hiveService.saveData('instagram_access_token', accessToken);
        await _hiveService.saveData('instagram_business_account_id', businessAccountId);
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Connect WhatsApp Business
  Future<bool> connectWhatsAppBusiness(String token) async {
    try {
      _whatsappBusinessToken = token;
      await _hiveService.saveData('whatsapp_business_token', token);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Cross-platform posting
  Future<Map<String, bool>> crossPlatformPost({
    required String content,
    List<File>? images,
    List<String> platforms = const ['facebook', 'instagram'],
    Map<String, String>? platformSpecificContent,
  }) async {
    final results = <String, bool>{};

    // Optimize content for each platform
    final optimizedContent = _optimizeContentForPlatforms(content, platformSpecificContent);

    if (platforms.contains('facebook') && _facebookAccessToken != null) {
      results['facebook'] = await _postToFacebook(
        optimizedContent['facebook'] ?? content,
        images,
      );
    }

    if (platforms.contains('instagram') && _instagramAccessToken != null) {
      results['instagram'] = await _postToInstagram(
        optimizedContent['instagram'] ?? content,
        images,
      );
    }

    if (platforms.contains('whatsapp') && _whatsappBusinessToken != null) {
      results['whatsapp'] = await _postToWhatsAppStatus(
        optimizedContent['whatsapp'] ?? content,
        images,
      );
    }

    return results;
  }

  // Post to Facebook
  Future<bool> _postToFacebook(String content, List<File>? images) async {
    try {
      String endpoint = 'https://graph.facebook.com/$_facebookPageId/feed';
      
      Map<String, dynamic> postData = {
        'message': content,
        'access_token': _facebookAccessToken,
      };

      // Handle image uploads
      if (images != null && images.isNotEmpty) {
        // For multiple images, create a photo album
        if (images.length > 1) {
          return await _createFacebookPhotoAlbum(content, images);
        } else {
          // Single image post
          return await _postFacebookPhoto(content, images.first);
        }
      }

      final response = await http.post(
        Uri.parse(endpoint),
        body: postData,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Post to Instagram
  Future<bool> _postToInstagram(String content, List<File>? images) async {
    try {
      if (images == null || images.isEmpty) {
        // Instagram requires media, so skip text-only posts
        return false;
      }

      // Step 1: Upload media
      final mediaIds = <String>[];
      for (final image in images) {
        final mediaId = await _uploadInstagramMedia(image, content);
        if (mediaId != null) {
          mediaIds.add(mediaId);
        }
      }

      if (mediaIds.isEmpty) return false;

      // Step 2: Publish media container
      String endpoint = 'https://graph.facebook.com/$_instagramBusinessAccountId/media_publish';
      
      final response = await http.post(
        Uri.parse(endpoint),
        body: {
          'creation_id': mediaIds.first,
          'access_token': _instagramAccessToken,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Upload Instagram media
  Future<String?> _uploadInstagramMedia(File image, String caption) async {
    try {
      // Convert image to base64 or upload to temporary server
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Create media container
      String endpoint = 'https://graph.facebook.com/$_instagramBusinessAccountId/media';
      
      final response = await http.post(
        Uri.parse(endpoint),
        body: {
          'image_url': 'data:image/jpeg;base64,$base64Image', // In production, use proper image hosting
          'caption': caption,
          'access_token': _instagramAccessToken,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Post Facebook photo
  Future<bool> _postFacebookPhoto(String content, File image) async {
    try {
      String endpoint = 'https://graph.facebook.com/$_facebookPageId/photos';
      
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse(endpoint),
        body: {
          'message': content,
          'source': base64Image,
          'access_token': _facebookAccessToken,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Create Facebook photo album
  Future<bool> _createFacebookPhotoAlbum(String content, List<File> images) async {
    try {
      // Create album first
      String albumEndpoint = 'https://graph.facebook.com/$_facebookPageId/albums';
      
      final albumResponse = await http.post(
        Uri.parse(albumEndpoint),
        body: {
          'name': 'AgroFlow Farm Update',
          'message': content,
          'access_token': _facebookAccessToken,
        },
      );

      if (albumResponse.statusCode != 200) return false;

      final albumData = json.decode(albumResponse.body);
      final albumId = albumData['id'];

      // Upload photos to album
      for (final image in images) {
        await _uploadPhotoToAlbum(albumId, image);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _uploadPhotoToAlbum(String albumId, File image) async {
    try {
      String endpoint = 'https://graph.facebook.com/$albumId/photos';
      
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      await http.post(
        Uri.parse(endpoint),
        body: {
          'source': base64Image,
          'access_token': _facebookAccessToken,
        },
      );
    } catch (e) {
      // Handle individual photo upload errors
    }
  }

  // Post to WhatsApp Status
  Future<bool> _postToWhatsAppStatus(String content, List<File>? images) async {
    try {
      // WhatsApp Business API for status updates
      // This is a simplified implementation
      String endpoint = 'https://graph.facebook.com/v18.0/YOUR_PHONE_NUMBER_ID/messages';
      
      Map<String, dynamic> messageData = {
        'messaging_product': 'whatsapp',
        'to': 'status@broadcast', // WhatsApp status broadcast
        'type': 'text',
        'text': {'body': content},
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $_whatsappBusinessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(messageData),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Optimize content for different platforms
  Map<String, String> _optimizeContentForPlatforms(
    String originalContent,
    Map<String, String>? platformSpecific,
  ) {
    final optimized = <String, String>{};

    // Facebook - longer content works well
    optimized['facebook'] = platformSpecific?['facebook'] ?? 
        '$originalContent\n\n#AgroFlow #SmartFarming #Agriculture';

    // Instagram - hashtag heavy, shorter
    optimized['instagram'] = platformSpecific?['instagram'] ?? 
        _shortenForInstagram(originalContent);

    // WhatsApp - conversational tone
    optimized['whatsapp'] = platformSpecific?['whatsapp'] ?? 
        'Check out my latest farm update! $originalContent';

    return optimized;
  }

  String _shortenForInstagram(String content) {
    // Limit to 125 characters for better engagement
    String shortened = content.length > 125 
        ? '${content.substring(0, 122)}...' 
        : content;
    
    return '$shortened\n\n🌱 #AgroFlow #FarmLife #SmartFarming #Agriculture #Farming #Harvest #Organic #Sustainable';
  }

  // AI-powered content recommendations
  Future<Map<String, dynamic>> getContentRecommendations(String content) async {
    try {
      // Analyze content with AI to suggest improvements
      final analysis = await _analyzeContentWithAI(content);
      
      return {
        'should_post_to_agroflow': analysis['farming_relevance'] > 0.7,
        'recommended_platforms': _getRecommendedPlatforms(analysis),
        'suggested_hashtags': _generateHashtags(analysis),
        'optimal_posting_time': _getOptimalPostingTime(),
        'engagement_prediction': analysis['engagement_score'],
        'content_improvements': analysis['suggestions'],
      };
    } catch (e) {
      return _getDefaultRecommendations();
    }
  }

  Future<Map<String, dynamic>> _analyzeContentWithAI(String content) async {
    // Mock AI analysis - in production, use actual AI service
    final farmingKeywords = [
      'farm', 'crop', 'harvest', 'plant', 'soil', 'seed', 'agriculture',
      'farming', 'organic', 'fertilizer', 'irrigation', 'livestock'
    ];
    
    final contentLower = content.toLowerCase();
    final farmingScore = farmingKeywords
        .where((keyword) => contentLower.contains(keyword))
        .length / farmingKeywords.length;

    return {
      'farming_relevance': farmingScore,
      'engagement_score': 0.75 + (farmingScore * 0.25),
      'sentiment': 'positive',
      'topics': ['farming', 'agriculture'],
      'suggestions': [
        'Add more specific details about your farming practice',
        'Include location information for local engagement',
        'Consider adding a call-to-action for other farmers',
      ],
    };
  }

  List<String> _getRecommendedPlatforms(Map<String, dynamic> analysis) {
    final platforms = <String>[];
    
    if (analysis['farming_relevance'] > 0.5) {
      platforms.add('agroflow');
    }
    
    if (analysis['engagement_score'] > 0.7) {
      platforms.addAll(['facebook', 'instagram']);
    }
    
    if (analysis['sentiment'] == 'positive') {
      platforms.add('whatsapp');
    }
    
    return platforms;
  }

  List<String> _generateHashtags(Map<String, dynamic> analysis) {
    final baseHashtags = ['#AgroFlow', '#SmartFarming', '#Agriculture'];
    final language = _localizationService.currentLanguage;
    
    // Add language-specific hashtags
    switch (language) {
      case 'sw':
        baseHashtags.addAll(['#KilimoKisasa', '#WakulimaWa Kenya']);
        break;
      case 'hi':
        baseHashtags.addAll(['#स्मार्टकृषि', '#किसान']);
        break;
      case 'es':
        baseHashtags.addAll(['#AgriculturaSostenible', '#Agricultores']);
        break;
      default:
        baseHashtags.addAll(['#FarmLife', '#Sustainable']);
    }
    
    return baseHashtags;
  }

  String _getOptimalPostingTime() {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Best times for agricultural content
    if (hour >= 6 && hour <= 9) {
      return 'Perfect time! Early morning posts get great engagement from farmers';
    } else if (hour >= 17 && hour <= 20) {
      return 'Good time! Evening posts catch farmers after work';
    } else {
      return 'Consider posting between 6-9 AM or 5-8 PM for better engagement';
    }
  }

  Map<String, dynamic> _getDefaultRecommendations() {
    return {
      'should_post_to_agroflow': true,
      'recommended_platforms': ['agroflow', 'facebook'],
      'suggested_hashtags': ['#AgroFlow', '#SmartFarming', '#Agriculture'],
      'optimal_posting_time': _getOptimalPostingTime(),
      'engagement_prediction': 0.6,
      'content_improvements': [
        'Add more farming-specific details',
        'Include relevant hashtags',
        'Consider adding images',
      ],
    };
  }

  // Monitor external posts and suggest AgroFlow cross-posting
  Future<void> monitorExternalPosts() async {
    // This would integrate with platform webhooks to detect farming-related posts
    // and suggest cross-posting to AgroFlow
  }

  // Get connection status
  Map<String, bool> getConnectionStatus() {
    return {
      'facebook': _facebookAccessToken != null,
      'instagram': _instagramAccessToken != null,
      'whatsapp': _whatsappBusinessToken != null,
    };
  }

  // Disconnect platforms
  Future<void> disconnectPlatform(String platform) async {
    switch (platform) {
      case 'facebook':
        _facebookAccessToken = null;
        _facebookPageId = null;
        await _hiveService.removeData('facebook_access_token');
        await _hiveService.removeData('facebook_page_id');
        break;
      case 'instagram':
        _instagramAccessToken = null;
        _instagramBusinessAccountId = null;
        await _hiveService.removeData('instagram_access_token');
        await _hiveService.removeData('instagram_business_account_id');
        break;
      case 'whatsapp':
        _whatsappBusinessToken = null;
        await _hiveService.removeData('whatsapp_business_token');
        break;
    }
  }

  // Get posting analytics
  Future<Map<String, dynamic>> getPostingAnalytics() async {
    // Fetch analytics from connected platforms
    final analytics = <String, dynamic>{};
    
    if (_facebookAccessToken != null) {
      analytics['facebook'] = await _getFacebookAnalytics();
    }
    
    if (_instagramAccessToken != null) {
      analytics['instagram'] = await _getInstagramAnalytics();
    }
    
    return analytics;
  }

  Future<Map<String, dynamic>> _getFacebookAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('https://graph.facebook.com/$_facebookPageId/insights?metric=page_impressions,page_engaged_users&access_token=$_facebookAccessToken'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      // Handle error
    }
    
    return {'error': 'Failed to fetch Facebook analytics'};
  }

  Future<Map<String, dynamic>> _getInstagramAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('https://graph.facebook.com/$_instagramBusinessAccountId/insights?metric=impressions,reach,profile_views&access_token=$_instagramAccessToken'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      // Handle error
    }
    
    return {'error': 'Failed to fetch Instagram analytics'};
  }
}