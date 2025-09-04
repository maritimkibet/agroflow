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
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload images
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final ref = _storage.ref().child('community_posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await ref.putFile(images[i]);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Upload video if provided
      String? videoUrl;
      if (video != null) {
        final ref = _storage.ref().child('community_posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_video.mp4');
        await ref.putFile(video);
        videoUrl = await ref.getDownloadURL();
      }

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = User.fromFirestore(userDoc);

      // Create post
      final post = CommunityPost(
        id: '',
        userId: user.uid,
        userName: userData.name,
        userAvatar: userData.email ?? '',
        title: title,
        content: content,
        category: category,
        cropType: cropType,
        region: region.isEmpty ? (userData.location ?? '') : region,
        tags: tags,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('community_posts').add(post.toFirestore());
      
      // Update user reputation
      await _updateUserReputation(user.uid, 'post_created');
      
      return docRef.id;
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
    Query query = _firestore.collection('community_posts')
        .orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (cropType != null && cropType.isNotEmpty) {
      query = query.where('cropType', isEqualTo: cropType);
    }
    if (region != null && region.isNotEmpty) {
      query = query.where('region', isEqualTo: region);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CommunityPost.fromFirestore(doc)).toList();
    });
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