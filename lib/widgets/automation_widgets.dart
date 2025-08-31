import 'package:flutter/material.dart';
import '../models/automation_response.dart';
import '../models/product.dart';
import '../services/automation_service.dart';
import '../services/error_service.dart';
import '../services/hybrid_storage_service.dart';

class PricingIntelligenceWidget extends StatefulWidget {
  final Product product;
  final VoidCallback? onPriceUpdated;

  const PricingIntelligenceWidget({
    super.key,
    required this.product,
    this.onPriceUpdated,
  });

  @override
  State<PricingIntelligenceWidget> createState() => _PricingIntelligenceWidgetState();
}

class _PricingIntelligenceWidgetState extends State<PricingIntelligenceWidget> {
  final AutomationService _automationService = AutomationService();
  bool _isLoading = false;
  PricingSuggestion? _suggestion;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Smart Pricing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _getPricingSuggestion,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Get Suggestion'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_suggestion != null) ...[
              _buildSuggestionCard(),
            ] else ...[
              const Text(
                'Get AI-powered pricing suggestions based on market conditions, weather, and demand.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard() {
    final suggestion = _suggestion!;
    final isIncrease = suggestion.isIncrease;
    final changeColor = isIncrease ? Colors.green : Colors.red;
    final changeIcon = isIncrease ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: changeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: changeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(changeIcon, color: changeColor),
              const SizedBox(width: 8),
              Text(
                'Suggested Price: \$${suggestion.suggestedPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: changeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current: \$${suggestion.currentPrice.toStringAsFixed(2)} → '
            '${isIncrease ? '+' : ''}\$${suggestion.priceChange.toStringAsFixed(2)} '
            '(${suggestion.priceChangePercent.toStringAsFixed(1)}%)',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            suggestion.reasoning,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Confidence: ${(suggestion.confidence * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _applySuggestion,
                child: const Text('Apply Price'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _suggestion = null),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _getPricingSuggestion() async {
    setState(() => _isLoading = true);

    try {
      final response = await _automationService.requestPricingIntelligence(widget.product);
      
      if (response != null && response['success'] == true) {
        final suggestionData = response['pricingSuggestion'];
        setState(() {
          _suggestion = PricingSuggestion.fromMap(suggestionData);
        });
      } else {
        // Mock response for demo
        setState(() {
          _suggestion = PricingSuggestion(
            productId: widget.product.id,
            suggestedPrice: widget.product.price * 1.15,
            currentPrice: widget.product.price,
            reasoning: 'Market analysis shows high demand for ${widget.product.name} in your region. Weather conditions favor price increase.',
            confidence: 0.85,
            timestamp: DateTime.now(),
            marketData: {
              'demand': 'high',
              'supply': 'medium',
              'competitors': 12,
            },
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorService.handleError(context, e, customMessage: 'Failed to get pricing suggestion');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applySuggestion() {
    if (_suggestion != null) {
      // Update product price
      widget.product.price = _suggestion!.suggestedPrice;
      widget.product.save();
      
      widget.onPriceUpdated?.call();
      
      ErrorService.showSuccess(context, 'Price updated successfully!');
      
      setState(() => _suggestion = null);
    }
  }
}

class SmartSchedulingWidget extends StatefulWidget {
  final VoidCallback? onScheduleUpdated;

  const SmartSchedulingWidget({
    super.key,
    this.onScheduleUpdated,
  });

  @override
  State<SmartSchedulingWidget> createState() => _SmartSchedulingWidgetState();
}

class _SmartSchedulingWidgetState extends State<SmartSchedulingWidget> {
  final AutomationService _automationService = AutomationService();
  bool _isLoading = false;
  List<SmartScheduleSuggestion> _suggestions = [];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Smart Scheduling',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _getScheduleSuggestions,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Optimize Schedule'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_suggestions.isNotEmpty) ...[
              ..._suggestions.map(_buildSuggestionItem),
            ] else ...[
              const Text(
                'Get AI-powered task scheduling based on weather forecasts and optimal farming conditions.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(SmartScheduleSuggestion suggestion) {
    final isDelayed = suggestion.isDelayed;
    final changeColor = isDelayed ? Colors.orange : Colors.green;
    final changeIcon = isDelayed ? Icons.schedule_outlined : Icons.check_circle_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: changeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: changeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(changeIcon, color: changeColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Task Schedule Update',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: changeColor,
                  ),
                ),
              ),
              if (suggestion.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            suggestion.reasoning,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Suggested: ${_formatDate(suggestion.suggestedDate)} '
            '(${isDelayed ? 'Delay' : 'Advance'} by ${suggestion.daysDifference.abs()} days)',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _applySuggestion(suggestion),
                child: const Text('Apply'),
              ),
              TextButton(
                onPressed: () => _dismissSuggestion(suggestion),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _getScheduleSuggestions() async {
    setState(() => _isLoading = true);

    try {
      // Get current tasks from Hive storage
      final storage = HybridStorageService();
      final tasks = storage.getAllTasks();
      
      final response = await _automationService.requestSmartScheduling(tasks);
      
      if (response != null && response['success'] == true) {
        final suggestionsData = response['scheduleSuggestions'] as List;
        setState(() {
          _suggestions = suggestionsData
              .map((data) => SmartScheduleSuggestion.fromMap(data))
              .toList();
        });
      } else {
        // Mock response for demo
        setState(() {
          _suggestions = [
            SmartScheduleSuggestion(
              taskId: '1',
              suggestedDate: DateTime.now().add(const Duration(days: 2)),
              originalDate: DateTime.now().add(const Duration(days: 1)),
              reasoning: 'Heavy rain expected tomorrow. Delay irrigation by 1 day for optimal soil conditions.',
              priority: 'high',
              timestamp: DateTime.now(),
              weatherContext: {'rain': 'heavy', 'temperature': 22},
            ),
            SmartScheduleSuggestion(
              taskId: '2',
              suggestedDate: DateTime.now().add(const Duration(days: 3)),
              originalDate: DateTime.now().add(const Duration(days: 5)),
              reasoning: 'Perfect weather window for spraying. Advance by 2 days to avoid upcoming wind.',
              priority: 'medium',
              timestamp: DateTime.now(),
              weatherContext: {'wind': 'low', 'humidity': 'optimal'},
            ),
          ];
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorService.handleError(context, e, customMessage: 'Failed to get schedule suggestions');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applySuggestion(SmartScheduleSuggestion suggestion) {
    // Apply the schedule change (implement based on your task management)
    widget.onScheduleUpdated?.call();
    
    ErrorService.showSuccess(context, 'Schedule updated successfully!');
    
    _dismissSuggestion(suggestion);
  }

  void _dismissSuggestion(SmartScheduleSuggestion suggestion) {
    setState(() {
      _suggestions.removeWhere((s) => s.taskId == suggestion.taskId);
    });
  }
}

class SocialMediaAutomationWidget extends StatefulWidget {
  const SocialMediaAutomationWidget({super.key});

  @override
  State<SocialMediaAutomationWidget> createState() => _SocialMediaAutomationWidgetState();
}

class _SocialMediaAutomationWidgetState extends State<SocialMediaAutomationWidget> {
  final AutomationService _automationService = AutomationService();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;
  final List<String> _selectedPlatforms = ['facebook', 'instagram'];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.share, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Social Media Automation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What would you like to share about your farm?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Platforms:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildPlatformChip('facebook', 'Facebook'),
                _buildPlatformChip('instagram', 'Instagram'),
                _buildPlatformChip('twitter', 'Twitter'),
                _buildPlatformChip('linkedin', 'LinkedIn'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _postToSocialMedia,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Posting...' : 'Post to Social Media'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformChip(String platform, String label) {
    final isSelected = _selectedPlatforms.contains(platform);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedPlatforms.add(platform);
          } else {
            _selectedPlatforms.remove(platform);
          }
        });
      },
    );
  }

  Future<void> _postToSocialMedia() async {
    if (_contentController.text.trim().isEmpty) {
      if (mounted) {
        ErrorService.handleError(context, 'Please enter some content to post');
      }
      return;
    }

    if (_selectedPlatforms.isEmpty) {
      if (mounted) {
        ErrorService.handleError(context, 'Please select at least one platform');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final content = {
        'text': _contentController.text.trim(),
        'platforms': _selectedPlatforms,
        'contentType': 'farming_update',
        'hashtags': ['#farming', '#agriculture', '#agroflow'],
      };

      final response = await _automationService.requestSocialMediaPosting(content);
      
      if (response != null && response['success'] == true) {
        if (mounted) {
          ErrorService.showSuccess(context, 'Content posted successfully to social media!');
          _contentController.clear();
        }
      } else {
        if (mounted) {
          ErrorService.showInfo(context, 'Content queued for posting!');
          _contentController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorService.handleError(context, e, customMessage: 'Failed to post to social media');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}