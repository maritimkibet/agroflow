import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/message.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../services/messaging_service.dart';
import '../../services/hybrid_storage_service.dart';

class ChatScreen extends StatefulWidget {
  final Product product;
  final User otherUser;

  const ChatScreen({
    super.key,
    required this.product,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final MessagingService _messagingService = MessagingService();
  final HybridStorageService _storage = HybridStorageService();
  
  bool _isOnline = false;
  DateTime? _lastSeen;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    _markMessagesAsRead();
  }

  Future<void> _checkUserStatus() async {
    _hasInternet = await _messagingService.hasInternetConnection();
    if (_hasInternet) {
      _isOnline = await _messagingService.isUserOnline(widget.otherUser.id);
      _lastSeen = await _messagingService.getUserLastSeen(widget.otherUser.id);
    }
    if (mounted) setState(() {});
  }

  Future<void> _markMessagesAsRead() async {
    await _messagingService.markMessagesAsRead(widget.product.id, widget.otherUser.id);
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final currentUser = _storage.getCurrentUser();
    if (currentUser == null) return;

    final message = Message(
      senderId: currentUser.id,
      receiverId: widget.otherUser.id,
      productId: widget.product.id,
      content: content,
    );

    try {
      await _messagingService.sendMessage(message);
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall() async {
    if (widget.product.contactNumber == null || widget.product.contactNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No contact number available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final phoneUrl = 'tel:${widget.product.contactNumber}';
    if (await canLaunchUrl(Uri.parse(phoneUrl))) {
      await launchUrl(Uri.parse(phoneUrl));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not make phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusText() {
    if (!_hasInternet) return 'No internet connection';
    if (_isOnline) return 'Online';
    if (_lastSeen != null) {
      final diff = DateTime.now().difference(_lastSeen!);
      if (diff.inMinutes < 1) return 'Last seen just now';
      if (diff.inHours < 1) return 'Last seen ${diff.inMinutes}m ago';
      if (diff.inDays < 1) return 'Last seen ${diff.inHours}h ago';
      return 'Last seen ${diff.inDays}d ago';
    }
    return 'Offline';
  }

  Color _getStatusColor() {
    if (!_hasInternet) return Colors.grey;
    return _isOnline ? Colors.green : Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _storage.getCurrentUser();
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to chat')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUser.name),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Call button - show when offline or no internet
          if (!_isOnline || !_hasInternet)
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: _makePhoneCall,
              tooltip: 'Call ${widget.otherUser.name}',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showProductInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Product info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Icon(Icons.shopping_bag, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Discussing: ${widget.product.name}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
                Text(
                  '\$${widget.product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagingService.getConversationMessages(
                widget.product.id,
                widget.otherUser.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation about\n${widget.product.name}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser.id;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green.shade300 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message.content),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _hasInternet 
                          ? 'Type a message...' 
                          : 'No internet - use call button',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    enabled: _hasInternet,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _hasInternet ? _sendMessage : null,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showProductInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: \$${widget.product.price.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Description: ${widget.product.description}'),
            if (widget.product.location != null) ...[
              const SizedBox(height: 8),
              Text('Location: ${widget.product.location}'),
            ],
            if (widget.product.contactNumber != null) ...[
              const SizedBox(height: 8),
              Text('Contact: ${widget.product.contactNumber}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}