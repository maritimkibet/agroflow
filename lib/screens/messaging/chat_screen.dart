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
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading messages...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Error loading messages', style: TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.green.shade400,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask questions about ${widget.product.name}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Say hello! 👋',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isMe = message.senderId == currentUser.id;
                    final showAvatar = index == 0 || 
                        messages[messages.length - index].senderId != message.senderId;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe && showAvatar) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.green.shade100,
                              child: Text(
                                widget.otherUser.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ] else if (!isMe) ...[
                            const SizedBox(width: 40),
                          ],
                          
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.green.shade500 : Colors.grey.shade200,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(message.timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          if (isMe && showAvatar) ...[
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.green.shade700,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ] else if (isMe) ...[
                            const SizedBox(width: 40),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _hasInternet ? Colors.grey.shade300 : Colors.red.shade300,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: _hasInternet 
                              ? 'Type a message...' 
                              : 'No internet - use call button',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                        ),
                        enabled: _hasInternet,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _hasInternet ? Colors.green.shade600 : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_hasInternet ? Colors.green.shade600 : Colors.grey.shade400)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _hasInternet ? _sendMessage : null,
                      icon: const Icon(Icons.send_rounded),
                      color: Colors.white,
                      iconSize: 20,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
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