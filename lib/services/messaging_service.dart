import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/message.dart';
import 'hybrid_storage_service.dart';
import 'achievement_service.dart';
import 'growth_analytics_service.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final HybridStorageService _storage = HybridStorageService();
  
  // Online status tracking

  // Initialize messaging service
  Future<void> initialize() async {
    await _setupPresenceSystem();
  }

  // Setup Firebase presence system
  Future<void> _setupPresenceSystem() async {
    final currentUser = _storage.getCurrentUser();
    if (currentUser == null) return;

    final userStatusRef = _database.child('status/${currentUser.id}');
    final connectedRef = _database.child('.info/connected');

    // When connected, set user as online
    connectedRef.onValue.listen((event) {
      if (event.snapshot.value == true) {
        userStatusRef.set({
          'online': true,
          'lastSeen': DateTime.now().toIso8601String(),
        });

        // When disconnected, set user as offline
        userStatusRef.onDisconnect().set({
          'online': false,
          'lastSeen': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  // Check if user is online
  Future<bool> isUserOnline(String userId) async {
    try {
      final snapshot = await _database.child('status/$userId/online').get();
      return snapshot.value == true;
    } catch (e) {
      debugPrint('Error checking online status: $e');
      return false;
    }
  }

  // Get user's last seen time
  Future<DateTime?> getUserLastSeen(String userId) async {
    try {
      final snapshot = await _database.child('status/$userId/lastSeen').get();
      final lastSeenStr = snapshot.value as String?;
      return lastSeenStr != null ? DateTime.tryParse(lastSeenStr) : null;
    } catch (e) {
      debugPrint('Error getting last seen: $e');
      return null;
    }
  }

  // Send message
  Future<void> sendMessage(Message message) async {
    try {
      // Save to Firebase
      await _database.child('messages/${message.id}').set(message.toMap());
      
      // Save to local storage
      // await _storage.saveMessage(message);
      
      // Track messaging for achievements
      final achievementService = AchievementService();
      final analyticsService = GrowthAnalyticsService();
      
      await analyticsService.trackMessageSent();
      await achievementService.updateProgress('community_helper');
      
      // Send notification to receiver if they're offline
      final isReceiverOnline = await isUserOnline(message.receiverId);
      if (!isReceiverOnline) {
        await _sendOfflineNotification(message);
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      throw Exception('Failed to send message');
    }
  }

  // Get messages for a conversation
  Stream<List<Message>> getConversationMessages(String productId, String otherUserId) {
    final currentUser = _storage.getCurrentUser();
    if (currentUser == null) return Stream.value([]);

    return _database
        .child('messages')
        .orderByChild('productId')
        .equalTo(productId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Message>[];

      final messages = <Message>[];
      data.forEach((key, value) {
        final messageData = Map<String, dynamic>.from(value);
        final message = Message.fromMap(messageData, id: key);
        
        // Only include messages between current user and other user
        if ((message.senderId == currentUser.id && message.receiverId == otherUserId) ||
            (message.senderId == otherUserId && message.receiverId == currentUser.id)) {
          messages.add(message);
        }
      });

      // Sort by timestamp
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  // Get all conversations for current user
  Stream<List<Map<String, dynamic>>> getUserConversations() {
    final currentUser = _storage.getCurrentUser();
    if (currentUser == null) return Stream.value([]);

    return _database
        .child('messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Map<String, dynamic>>[];

      final conversations = <String, Map<String, dynamic>>{};
      
      data.forEach((key, value) {
        final messageData = Map<String, dynamic>.from(value);
        final message = Message.fromMap(messageData, id: key);
        
        // Only include messages involving current user
        if (message.senderId == currentUser.id || message.receiverId == currentUser.id) {
          final otherUserId = message.senderId == currentUser.id 
              ? message.receiverId 
              : message.senderId;
          
          final conversationKey = '${message.productId}_$otherUserId';
          
          // Keep only the latest message for each conversation
          if (!conversations.containsKey(conversationKey) ||
              message.timestamp.isAfter(conversations[conversationKey]!['timestamp'])) {
            conversations[conversationKey] = {
              'productId': message.productId,
              'otherUserId': otherUserId,
              'lastMessage': message.content,
              'timestamp': message.timestamp,
              'isRead': message.isRead,
            };
          }
        }
      });

      final result = conversations.values.toList();
      result.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
      return result;
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String productId, String otherUserId) async {
    final currentUser = _storage.getCurrentUser();
    if (currentUser == null) return;

    try {
      final snapshot = await _database.child('messages').get();
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      final updates = <String, dynamic>{};
      data.forEach((key, value) {
        final messageData = Map<String, dynamic>.from(value);
        final message = Message.fromMap(messageData, id: key);
        
        // Mark unread messages from other user as read
        if (message.productId == productId &&
            message.senderId == otherUserId &&
            message.receiverId == currentUser.id &&
            !message.isRead) {
          updates['messages/$key/isRead'] = true;
        }
      });

      if (updates.isNotEmpty) {
        await _database.update(updates);
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Send offline notification (placeholder - would integrate with push notifications)
  Future<void> _sendOfflineNotification(Message message) async {
    // This would integrate with Firebase Cloud Messaging or similar
    // Offline notification sent silently in production
  }

  // Check internet connectivity
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }
}