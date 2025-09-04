import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String title;
  final String content;
  final String category; // 'question', 'tip', 'discussion'
  final String cropType;
  final String region;
  final List<String> tags;
  final List<String> imageUrls;
  final String? videoUrl;
  final int likes;
  final int comments;
  final int views;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar = '',
    required this.title,
    required this.content,
    required this.category,
    this.cropType = '',
    this.region = '',
    this.tags = const [],
    this.imageUrls = const [],
    this.videoUrl,
    this.likes = 0,
    this.comments = 0,
    this.views = 0,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? 'discussion',
      cropType: data['cropType'] ?? '',
      region: data['region'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrl: data['videoUrl'],
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      views: data['views'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'title': title,
      'content': content,
      'category': category,
      'cropType': cropType,
      'region': region,
      'tags': tags,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'likes': likes,
      'comments': comments,
      'views': views,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  CommunityPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? title,
    String? content,
    String? category,
    String? cropType,
    String? region,
    List<String>? tags,
    List<String>? imageUrls,
    String? videoUrl,
    int? likes,
    int? comments,
    int? views,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      cropType: cropType ?? this.cropType,
      region: region ?? this.region,
      tags: tags ?? this.tags,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      views: views ?? this.views,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final List<String> imageUrls;
  final int likes;
  final bool isVerified;
  final DateTime createdAt;
  final String? parentCommentId; // For nested replies

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatar = '',
    required this.content,
    this.imageUrls = const [],
    this.likes = 0,
    this.isVerified = false,
    required this.createdAt,
    this.parentCommentId,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      likes: data['likes'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      parentCommentId: data['parentCommentId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'imageUrls': imageUrls,
      'likes': likes,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'parentCommentId': parentCommentId,
    };
  }
}

class UserReputation {
  final String userId;
  final int totalLikes;
  final int totalPosts;
  final int totalComments;
  final int helpfulAnswers;
  final List<String> badges;
  final double reputationScore;
  final String level; // 'Beginner', 'Intermediate', 'Expert', 'Master'
  final DateTime lastUpdated;

  UserReputation({
    required this.userId,
    this.totalLikes = 0,
    this.totalPosts = 0,
    this.totalComments = 0,
    this.helpfulAnswers = 0,
    this.badges = const [],
    this.reputationScore = 0.0,
    this.level = 'Beginner',
    required this.lastUpdated,
  });

  factory UserReputation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserReputation(
      userId: doc.id,
      totalLikes: data['totalLikes'] ?? 0,
      totalPosts: data['totalPosts'] ?? 0,
      totalComments: data['totalComments'] ?? 0,
      helpfulAnswers: data['helpfulAnswers'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
      reputationScore: (data['reputationScore'] ?? 0.0).toDouble(),
      level: data['level'] ?? 'Beginner',
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalLikes': totalLikes,
      'totalPosts': totalPosts,
      'totalComments': totalComments,
      'helpfulAnswers': helpfulAnswers,
      'badges': badges,
      'reputationScore': reputationScore,
      'level': level,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}