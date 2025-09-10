import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/community_post.dart';
import '../models/user.dart';

class CommunityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Create a new community post
  static Future<String> createPost({
    required String title,
    required String content,
    required String category,
    String cropType = '',
    String region = '',
    List<String> tags = const [],
    List<File> images = const [],
    File? video,
  }) async {
    try {
      // For demo purposes, simulate successful post creation
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock image URLs for demo
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        imageUrls.add('demo_image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
      }

      // Mock video URL if provided
      String? videoUrl;
      if (video != null) {
        videoUrl = 'demo_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      }

      // Create mock post ID
      final postId = 'post_${DateTime.now().millisecondsSinceEpoch}';
      
      return postId;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Get community posts with filtering
  static Stream<List<CommunityPost>> getPosts({
    String? category,
    String? cropType,
    String? region,
    List<String>? tags,
    int limit = 20,
  }) {
    // Return mock posts for presentation
    return Stream.value(_getMockPosts(category, cropType, region, tags, limit));
  }

  static List<CommunityPost> _getMockPosts(String? category, String? cropType, String? region, List<String>? tags, int limit) {
    final now = DateTime.now();
    final mockPosts = [
      CommunityPost(
        id: '1',
        userId: 'user1',
        userName: 'Sarah Johnson',
        userAvatar: 'sarah@example.com',
        title: 'Best practices for organic tomato farming',
        content: 'I\'ve been growing organic tomatoes for 5 years and wanted to share some tips that have worked well for me. First, soil preparation is crucial...',
        category: 'tip',
        cropType: 'Tomatoes',
        region: 'California',
        tags: ['organic', 'tomatoes', 'soil'],
        imageUrls: [],
        videoUrl: null,
        likes: 24,
        comments: 8,
        views: 156,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      CommunityPost(
        id: '2',
        userId: 'user2',
        userName: 'Mike Chen',
        userAvatar: 'mike@example.com',
        title: 'Help! My corn plants are showing yellow spots',
        content: 'I noticed yellow spots appearing on my corn leaves yesterday. The weather has been quite humid lately. Could this be a fungal infection? Any advice would be appreciated!',
        category: 'question',
        cropType: 'Corn',
        region: 'Iowa',
        tags: ['corn', 'disease', 'help'],
        imageUrls: [],
        videoUrl: null,
        likes: 12,
        comments: 15,
        views: 89,
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
      CommunityPost(
        id: '3',
        userId: 'user3',
        userName: 'Maria Rodriguez',
        userAvatar: 'maria@example.com',
        title: 'Successful harvest season - sharing my joy!',
        content: 'Just finished harvesting my vegetable garden and I\'m so proud of the results! This year\'s yield was 30% better than last year. The key was consistent watering and proper fertilization.',
        category: 'discussion',
        cropType: 'Mixed Vegetables',
        region: 'Texas',
        tags: ['harvest', 'success', 'vegetables'],
        imageUrls: [],
        videoUrl: null,
        likes: 45,
        comments: 22,
        views: 234,
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 12)),
      ),
      CommunityPost(
        id: '4',
        userId: 'user4',
        userName: 'David Kim',
        userAvatar: 'david@example.com',
        title: 'Irrigation system recommendations?',
        content: 'I\'m planning to upgrade my irrigation system for next season. Currently using sprinklers but considering drip irrigation. What are your experiences with different systems?',
        category: 'question',
        cropType: 'Rice',
        region: 'Arkansas',
        tags: ['irrigation', 'equipment', 'advice'],
        imageUrls: [],
        videoUrl: null,
        likes: 18,
        comments: 11,
        views: 127,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      CommunityPost(
        id: '5',
        userId: 'user5',
        userName: 'Emma Thompson',
        userAvatar: 'emma@example.com',
        title: 'Climate change adaptation strategies',
        content: 'With changing weather patterns, I\'ve had to adapt my farming practices. Here are some strategies that have helped me maintain productivity despite unpredictable weather...',
        category: 'tip',
        cropType: 'Wheat',
        region: 'Kansas',
        tags: ['climate', 'adaptation', 'sustainability'],
        imageUrls: [],
        videoUrl: null,
        likes: 67,
        comments: 31,
        views: 445,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];

    // Filter posts based on criteria
    var filtered = mockPosts.where((post) {
      if (category != null && category.isNotEmpty && post.category != category) return false;
      if (cropType != null && cropType.isNotEmpty && post.cropType != cropType) return false;
      if (region != null && region.isNotEmpty && post.region != region) return false;
      if (tags != null && tags.isNotEmpty) {
        final hasMatchingTag = tags.any((tag) => post.tags.contains(tag));
        if (!hasMatchingTag) return false;
      }
      return true;
    }).toList();

    return filtered.take(limit).toList();
  }

  // Get posts by user location
  static Stream<List<CommunityPost>> getLocalPosts(String userRegion, {int limit = 20}) {
    return _firestore.collection('community_posts')
        .where('region', isEqualTo: userRegion)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CommunityPost.fromFirestore(doc)).toList();
    });
  }

  // Search posts
  static Future<List<CommunityPost>> searchPosts(String query) async {
    try {
      // Search in title and content (basic implementation)
      final titleResults = await _firestore.collection('community_posts')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final contentResults = await _firestore.collection('community_posts')
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final Set<String> seenIds = {};
      final List<CommunityPost> results = [];

      for (final doc in [...titleResults.docs, ...contentResults.docs]) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          results.add(CommunityPost.fromFirestore(doc));
        }
      }

      return results;
    } catch (e) {
      throw Exception('Failed to search posts: $e');
    }
  }

  // Like/Unlike a post
  static Future<void> toggleLike(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final likeRef = _firestore.collection('post_likes').doc('${postId}_${user.uid}');
      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike
        await likeRef.delete();
        await _firestore.collection('community_posts').doc(postId).update({
          'likes': FieldValue.increment(-1),
        });
      } else {
        // Like
        await likeRef.set({
          'postId': postId,
          'userId': user.uid,
          'createdAt': Timestamp.now(),
        });
        await _firestore.collection('community_posts').doc(postId).update({
          'likes': FieldValue.increment(1),
        });

        // Update post author's reputation
        final postDoc = await _firestore.collection('community_posts').doc(postId).get();
        if (postDoc.exists) {
          final post = CommunityPost.fromFirestore(postDoc);
          await _updateUserReputation(post.userId, 'post_liked');
        }
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  // Check if user liked a post
  static Future<bool> hasUserLiked(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final likeDoc = await _firestore.collection('post_likes').doc('${postId}_${user.uid}').get();
      return likeDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // Add comment to post
  static Future<String> addComment({
    required String postId,
    required String content,
    List<File> images = const [],
    String? parentCommentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload images
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final ref = _storage.ref().child('comments/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await ref.putFile(images[i]);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = User.fromFirestore(userDoc);

      // Create comment
      final comment = Comment(
        id: '',
        postId: postId,
        userId: user.uid,
        userName: userData.name,
        userAvatar: userData.email ?? '',
        content: content,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        parentCommentId: parentCommentId,
      );

      final docRef = await _firestore.collection('comments').add(comment.toFirestore());

      // Update post comment count
      await _firestore.collection('community_posts').doc(postId).update({
        'comments': FieldValue.increment(1),
      });

      // Update user reputation
      await _updateUserReputation(user.uid, 'comment_added');

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Get comments for a post
  static Stream<List<Comment>> getComments(String postId) {
    return _firestore.collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    });
  }

  // Increment post views
  static Future<void> incrementViews(String postId) async {
    try {
      await _firestore.collection('community_posts').doc(postId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      // Silently fail for view tracking
    }
  }

  // Get user reputation
  static Future<UserReputation> getUserReputation(String userId) async {
    try {
      final doc = await _firestore.collection('user_reputation').doc(userId).get();
      if (doc.exists) {
        return UserReputation.fromFirestore(doc);
      } else {
        // Create initial reputation
        final reputation = UserReputation(
          userId: userId,
          lastUpdated: DateTime.now(),
        );
        await _firestore.collection('user_reputation').doc(userId).set(reputation.toFirestore());
        return reputation;
      }
    } catch (e) {
      throw Exception('Failed to get user reputation: $e');
    }
  }

  // Update user reputation
  static Future<void> _updateUserReputation(String userId, String action) async {
    try {
      final reputationRef = _firestore.collection('user_reputation').doc(userId);
      
      Map<String, dynamic> updates = {
        'lastUpdated': Timestamp.now(),
      };

      switch (action) {
        case 'post_created':
          updates['totalPosts'] = FieldValue.increment(1);
          updates['reputationScore'] = FieldValue.increment(5);
          break;
        case 'comment_added':
          updates['totalComments'] = FieldValue.increment(1);
          updates['reputationScore'] = FieldValue.increment(2);
          break;
        case 'post_liked':
          updates['totalLikes'] = FieldValue.increment(1);
          updates['reputationScore'] = FieldValue.increment(1);
          break;
        case 'helpful_answer':
          updates['helpfulAnswers'] = FieldValue.increment(1);
          updates['reputationScore'] = FieldValue.increment(10);
          break;
      }

      await reputationRef.set(updates, SetOptions(merge: true));

      // Update user level based on reputation score
      final doc = await reputationRef.get();
      if (doc.exists) {
        final reputation = UserReputation.fromFirestore(doc);
        String newLevel = _calculateLevel(reputation.reputationScore);
        
        if (newLevel != reputation.level) {
          await reputationRef.update({'level': newLevel});
          
          // Award badges based on level
          List<String> newBadges = List.from(reputation.badges);
          if (!newBadges.contains(newLevel)) {
            newBadges.add(newLevel);
            await reputationRef.update({'badges': newBadges});
          }
        }
      }
    } catch (e) {
      // Silently fail for reputation updates
    }
  }

  // Calculate user level based on reputation score
  static String _calculateLevel(double score) {
    if (score >= 1000) return 'Master';
    if (score >= 500) return 'Expert';
    if (score >= 100) return 'Intermediate';
    return 'Beginner';
  }

  // Get trending posts (most liked/commented in last 7 days)
  static Stream<List<CommunityPost>> getTrendingPosts({int limit = 10}) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    
    return _firestore.collection('community_posts')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
        .orderBy('createdAt', descending: true)
        .limit(limit * 3) // Get more to sort by engagement
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs.map((doc) => CommunityPost.fromFirestore(doc)).toList();
      
      // Sort by engagement score (likes + comments * 2)
      posts.sort((a, b) {
        final scoreA = a.likes + (a.comments * 2);
        final scoreB = b.likes + (b.comments * 2);
        return scoreB.compareTo(scoreA);
      });
      
      return posts.take(limit).toList();
    });
  }

  // Get user's posts
  static Stream<List<CommunityPost>> getUserPosts(String userId) {
    return _firestore.collection('community_posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CommunityPost.fromFirestore(doc)).toList();
    });
  }

  // Report a post
  static Future<void> reportPost(String postId, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('reports').add({
        'postId': postId,
        'reportedBy': user.uid,
        'reason': reason,
        'createdAt': Timestamp.now(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to report post: $e');
    }
  }

  // Get available crop types for filtering
  static Future<List<String>> getCropTypes() async {
    try {
      final snapshot = await _firestore.collection('community_posts')
          .where('cropType', isNotEqualTo: '')
          .get();
      
      final Set<String> cropTypes = {};
      for (final doc in snapshot.docs) {
        final cropType = doc.data()['cropType'] as String?;
        if (cropType != null && cropType.isNotEmpty) {
          cropTypes.add(cropType);
        }
      }
      
      final list = cropTypes.toList();
      list.sort();
      return list;
    } catch (e) {
      return [];
    }
  }

  // Get available regions for filtering
  static Future<List<String>> getRegions() async {
    try {
      final snapshot = await _firestore.collection('community_posts')
          .where('region', isNotEqualTo: '')
          .get();
      
      final Set<String> regions = {};
      for (final doc in snapshot.docs) {
        final region = doc.data()['region'] as String?;
        if (region != null && region.isNotEmpty) {
          regions.add(region);
        }
      }
      
      final list = regions.toList();
      list.sort();
      return list;
    } catch (e) {
      return [];
    }
  }
}