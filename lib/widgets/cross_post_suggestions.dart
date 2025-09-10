import 'package:flutter/material.dart';
import '../services/content_intelligence_service.dart';

class CrossPostSuggestions extends StatefulWidget {
  const CrossPostSuggestions({super.key});

  @override
  State<CrossPostSuggestions> createState() => _CrossPostSuggestionsState();
}

class _CrossPostSuggestionsState extends State<CrossPostSuggestions> {
  final ContentIntelligenceService _contentService = ContentIntelligenceService();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final suggestions = await _contentService.getPendingSuggestions();
    setState(() {
      _suggestions = suggestions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Smart Suggestions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_suggestions.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'We found farming content from your social media that might interest the AgroFlow community!',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...(_suggestions.take(3).map((suggestion) => _buildSuggestionCard(suggestion))),
            if (_suggestions.length > 3) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _showAllSuggestions(),
                child: Text('View all ${_suggestions.length} suggestions'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final platform = suggestion['platform'] as String;
    final content = suggestion['content'] as String;
    final suggestedAt = DateTime.parse(suggestion['suggested_at']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPlatformIcon(platform),
                color: _getPlatformColor(platform),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'From ${_getPlatformName(platform)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(suggestedAt),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content.length > 100 ? '${content.substring(0, 100)}...' : content,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectSuggestion(suggestion['id']),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Skip'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _acceptSuggestion(suggestion),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'facebook': return Icons.facebook;
      case 'instagram': return Icons.camera_alt;
      case 'whatsapp': return Icons.message;
      default: return Icons.share;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'facebook': return Colors.blue;
      case 'instagram': return Colors.purple;
      case 'whatsapp': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getPlatformName(String platform) {
    switch (platform) {
      case 'facebook': return 'Facebook';
      case 'instagram': return 'Instagram';
      case 'whatsapp': return 'WhatsApp';
      default: return platform;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _acceptSuggestion(Map<String, dynamic> suggestion) async {
    final success = await _contentService.acceptSuggestion(suggestion['id']);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Posted to AgroFlow successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    await _loadSuggestions();
  }

  Future<void> _rejectSuggestion(String suggestionId) async {
    await _contentService.rejectSuggestion(suggestionId);
    await _loadSuggestions();
  }

  void _showAllSuggestions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'All Suggestions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    return _buildSuggestionCard(_suggestions[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}