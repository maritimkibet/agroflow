import 'hive_service.dart';

class GrowthAnalyticsService {
  static final GrowthAnalyticsService _instance = GrowthAnalyticsService._internal();
  factory GrowthAnalyticsService() => _instance;
  GrowthAnalyticsService._internal();

  final HiveService _hiveService = HiveService();

  Future<void> trackEvent(String event, {Map<String, dynamic>? properties}) async {
    final eventData = {
      'event': event,
      'timestamp': DateTime.now().toIso8601String(),
      'properties': properties ?? {},
    };

    // Store locally for offline tracking
    final events = await _getStoredEvents();
    events.add(eventData);
    await _hiveService.saveData('growth_events', events);

    // In production, also send to analytics service
    _sendToAnalytics(eventData);
  }

  Future<List<Map<String, dynamic>>> _getStoredEvents() async {
    final data = await _hiveService.getData('growth_events');
    if (data != null) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  void _sendToAnalytics(Map<String, dynamic> eventData) {
    // In production, integrate with Firebase Analytics, Mixpanel, etc.
    // Analytics events are processed silently in production
  }

  // Growth-specific tracking methods
  Future<void> trackAppOpen() async {
    await trackEvent('app_opened');
  }

  Future<void> trackTaskAdded() async {
    await trackEvent('task_added');
  }

  Future<void> trackProductListed() async {
    await trackEvent('product_listed');
  }

  Future<void> trackAIAssistantUsed() async {
    await trackEvent('ai_assistant_used');
  }

  Future<void> trackReferralShared(String method) async {
    await trackEvent('referral_shared', properties: {'method': method});
  }

  Future<void> trackAchievementUnlocked(String achievementId) async {
    await trackEvent('achievement_unlocked', properties: {'achievement_id': achievementId});
  }

  Future<void> trackMarketplaceView() async {
    await trackEvent('marketplace_viewed');
  }

  Future<void> trackMessageSent() async {
    await trackEvent('message_sent');
  }

  Future<void> trackFeatureUsage(String feature) async {
    await trackEvent('feature_used', properties: {'feature': feature});
  }

  // Get analytics for growth insights
  Future<Map<String, int>> getEventCounts() async {
    final events = await _getStoredEvents();
    final counts = <String, int>{};
    
    for (final event in events) {
      final eventName = event['event'] as String;
      counts[eventName] = (counts[eventName] ?? 0) + 1;
    }
    
    return counts;
  }

  Future<int> getDailyActiveUsers() async {
    final events = await _getStoredEvents();
    final today = DateTime.now();
    final todayEvents = events.where((event) {
      final eventDate = DateTime.parse(event['timestamp']);
      return eventDate.day == today.day &&
             eventDate.month == today.month &&
             eventDate.year == today.year;
    }).toList();
    
    return todayEvents.isNotEmpty ? 1 : 0; // Single user for now
  }
}