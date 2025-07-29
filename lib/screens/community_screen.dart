import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _postTitleController = TextEditingController();
  final _postBodyController = TextEditingController();

  void _showAddPostDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _postTitleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _postBodyController,
              decoration: const InputDecoration(labelText: 'Body'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _postTitleController.clear();
              _postBodyController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addPost,
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPost() async {
    final user = _auth.currentUser;
    final authorName = user?.displayName ?? user?.email ?? user?.uid ?? 'Anonymous';

    final title = _postTitleController.text.trim();
    final body = _postBodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    await _firestore.collection('posts').add({
      'title': title,
      'body': body,
      'author': authorName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _postTitleController.clear();
    _postBodyController.clear();
    if (mounted) Navigator.pop(context);
  }

  void _openPostDetail(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: Colors.green.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final posts = snapshot.data!.docs;

          if (posts.isEmpty) {
            return const Center(child: Text('No posts yet. Be the first!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final data = post.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp?;
              final timeStr = timestamp != null
                  ? DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch)
                      .toLocal()
                      .toString()
                      .split('.')[0]
                  : 'Just now';

              return Card(
                child: ListTile(
                  title: Text(data['title'] ?? 'No Title'),
                  subtitle: Text('By ${data['author'] ?? 'Unknown'} • $timeStr'),
                  onTap: () => _openPostDetail(post.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        onPressed: _showAddPostDialog,
        child: const Icon(Icons.add_comment),
      ),
    );
  }
}

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _commentController = TextEditingController();

  Future<void> _addComment() async {
    final user = _auth.currentUser;
    final authorName = user?.displayName ?? user?.email ?? user?.uid ?? 'Anonymous';

    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    await _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'comment': comment,
      'author': authorName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postRef = _firestore.collection('posts').doc(widget.postId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: postRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();

              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data == null) return const Center(child: Text('Post not found'));

              final timestamp = data['timestamp'] as Timestamp?;
              final timeStr = timestamp != null
                  ? DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch)
                      .toLocal()
                      .toString()
                      .split('.')[0]
                  : 'Just now';

              return ListTile(
                title: Text(
                  data['title'] ?? 'No Title',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('By ${data['author'] ?? 'Unknown'} • $timeStr'),
              );
            },
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: postRef.collection('comments').orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return const Center(child: Text('No comments yet.'));
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final commentData = comments[index].data() as Map<String, dynamic>;
                    final timestamp = commentData['timestamp'] as Timestamp?;
                    final timeStr = timestamp != null
                        ? DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch)
                            .toLocal()
                            .toString()
                            .split('.')[0]
                        : 'Just now';

                    return ListTile(
                      title: Text(commentData['comment'] ?? ''),
                      subtitle: Text('By ${commentData['author'] ?? 'Unknown'} • $timeStr'),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addComment,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
