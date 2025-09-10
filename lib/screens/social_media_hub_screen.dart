import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/meta_api_service.dart';

class SocialMediaHubScreen extends StatefulWidget {
  const SocialMediaHubScreen({super.key});

  @override
  State<SocialMediaHubScreen> createState() => _SocialMediaHubScreenState();
}

class _SocialMediaHubScreenState extends State<SocialMediaHubScreen> with SingleTickerProviderStateMixin {
  final MetaAPIService _metaService = MetaAPIService();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  late TabController _tabController;
  final List<File> _selectedImages = [];
  Map<String, bool> _selectedPlatforms = {
    'agroflow': true,
    'facebook': false,
    'instagram': false,
    'whatsapp': false,
  };
  
  Map<String, dynamic>? _contentRecommendations;
  Map<String, bool> _connectionStatus = {};
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadConnectionStatus();
  }

  Future<void> _loadConnectionStatus() async {
    final status = _metaService.getConnectionStatus();
    setState(() {
      _connectionStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📱 Social Media Hub'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.create), text: 'Create Post'),
            Tab(icon: Icon(Icons.link), text: 'Connections'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreatePostTab(),
          _buildConnectionsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildCreatePostTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContentInput(),
          const SizedBox(height: 16),
          _buildImageSelector(),
          const SizedBox(height: 16),
          _buildPlatformSelector(),
          const SizedBox(height: 16),
          if (_contentRecommendations != null) _buildRecommendations(),
          const SizedBox(height: 20),
          _buildPostButton(),
        ],
      ),
    );
  }

  Widget _buildContentInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What\'s happening on your farm?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Share your farming journey, harvest updates, tips, or ask questions...',
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                if (text.length > 50) {
                  _getContentRecommendations();
                }
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_contentController.text.length}/2200',
                  style: TextStyle(
                    color: _contentController.text.length > 2200 ? Colors.red : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _getContentRecommendations,
                  icon: const Icon(Icons.psychology, size: 16),
                  label: const Text('Get AI Suggestions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_camera, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Add Photos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Post to Platforms',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...(_selectedPlatforms.keys.map((platform) {
              final isConnected = _connectionStatus[platform] ?? false;
              final platformName = _getPlatformDisplayName(platform);
              final platformIcon = _getPlatformIcon(platform);
              
              return CheckboxListTile(
                title: Row(
                  children: [
                    Icon(platformIcon, color: _getPlatformColor(platform)),
                    const SizedBox(width: 8),
                    Text(platformName),
                    if (!isConnected && platform != 'agroflow') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Not Connected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                value: (_selectedPlatforms[platform] ?? false) && (isConnected || platform == 'agroflow'),
                onChanged: (isConnected || platform == 'agroflow') ? (value) {
                  setState(() {
                    _selectedPlatforms[platform] = value ?? false;
                  });
                } : null,
              );
            })),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _contentRecommendations!;
    
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'AI Recommendations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recommendations['should_post_to_agroflow'] == true)
              _buildRecommendationItem(
                '✅ Great content for AgroFlow!',
                'This post will engage well with the farming community',
                Colors.green,
              ),
            _buildRecommendationItem(
              '📱 Recommended Platforms',
              (recommendations['recommended_platforms'] as List).join(', '),
              Colors.blue,
            ),
            _buildRecommendationItem(
              '⏰ ${recommendations['optimal_posting_time']}',
              '',
              Colors.orange,
            ),
            if (recommendations['suggested_hashtags'] != null)
              _buildRecommendationItem(
                '🏷️ Suggested Hashtags',
                (recommendations['suggested_hashtags'] as List).join(' '),
                Colors.purple,
              ),
            const SizedBox(height: 8),
            const Text(
              'Content Improvements:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...(recommendations['content_improvements'] as List).map((improvement) =>
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text('• $improvement'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostButton() {
    final selectedCount = _selectedPlatforms.values.where((v) => v).length;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isPosting || selectedCount == 0 ? null : _publishPost,
        icon: _isPosting 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send),
        label: Text(_isPosting ? 'Publishing...' : 'Publish to $selectedCount Platform${selectedCount != 1 ? 's' : ''}'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildConnectionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildConnectionCard('Facebook', 'facebook', Icons.facebook, Colors.blue),
          _buildConnectionCard('Instagram', 'instagram', Icons.camera_alt, Colors.purple),
          _buildConnectionCard('WhatsApp Business', 'whatsapp', Icons.message, Colors.green),
          const SizedBox(height: 20),
          _buildConnectionInfo(),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(String name, String platform, IconData icon, Color color) {
    final isConnected = _connectionStatus[platform] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(name),
        subtitle: Text(isConnected ? 'Connected' : 'Not connected'),
        trailing: isConnected
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _disconnectPlatform(platform),
                    child: const Text('Disconnect'),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: () => _connectPlatform(platform),
                child: const Text('Connect'),
              ),
      ),
    );
  }

  Widget _buildConnectionInfo() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Connection Benefits',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('• Post to multiple platforms simultaneously'),
            Text('• Get AI-powered content recommendations'),
            Text('• Track engagement across all platforms'),
            Text('• Automatic hashtag suggestions'),
            Text('• Optimal posting time recommendations'),
            SizedBox(height: 12),
            Text(
              'Note: Your data is secure and only used for posting. We never store your social media credentials.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalyticsCard('Posts Published', '12', Icons.publish, Colors.blue),
          const SizedBox(height: 12),
          _buildAnalyticsCard('Total Reach', '1,234', Icons.visibility, Colors.green),
          const SizedBox(height: 12),
          _buildAnalyticsCard('Engagement Rate', '8.5%', Icons.favorite, Colors.red),
          const SizedBox(height: 12),
          _buildAnalyticsCard('Best Platform', 'AgroFlow', Icons.star, Colors.orange),
          const SizedBox(height: 20),
          _buildEngagementChart(),
          const SizedBox(height: 20),
          _buildPlatformBreakdown(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Engagement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBarChart('Mon', 0.3, Colors.blue),
                  _buildBarChart('Tue', 0.7, Colors.green),
                  _buildBarChart('Wed', 0.5, Colors.orange),
                  _buildBarChart('Thu', 0.9, Colors.purple),
                  _buildBarChart('Fri', 0.6, Colors.red),
                  _buildBarChart('Sat', 0.8, Colors.teal),
                  _buildBarChart('Sun', 0.4, Colors.indigo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(String day, double value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 150 * value,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPlatformBreakdown() {
    final platforms = [
      {'name': 'AgroFlow', 'percentage': 45, 'color': Colors.green},
      {'name': 'Facebook', 'percentage': 30, 'color': Colors.blue},
      {'name': 'Instagram', 'percentage': 20, 'color': Colors.purple},
      {'name': 'WhatsApp', 'percentage': 5, 'color': Colors.green.shade700},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...platforms.map((platform) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: platform['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(platform['name'] as String),
                  ),
                  Text(
                    '${platform['percentage']}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _getPlatformDisplayName(String platform) {
    switch (platform) {
      case 'agroflow': return 'AgroFlow';
      case 'facebook': return 'Facebook';
      case 'instagram': return 'Instagram';
      case 'whatsapp': return 'WhatsApp';
      default: return platform;
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'agroflow': return Icons.agriculture;
      case 'facebook': return Icons.facebook;
      case 'instagram': return Icons.camera_alt;
      case 'whatsapp': return Icons.message;
      default: return Icons.share;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'agroflow': return Colors.green;
      case 'facebook': return Colors.blue;
      case 'instagram': return Colors.purple;
      case 'whatsapp': return Colors.green.shade700;
      default: return Colors.grey;
    }
  }

  Future<void> _addImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage();
    
    setState(() {
      _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
    });
  }

  Future<void> _getContentRecommendations() async {
    if (_contentController.text.trim().isEmpty) return;
    
    final recommendations = await _metaService.getContentRecommendations(_contentController.text);
    
    setState(() {
      _contentRecommendations = recommendations;
      
      // Auto-select recommended platforms
      final recommendedPlatforms = recommendations['recommended_platforms'] as List;
      for (final platform in recommendedPlatforms) {
        if (_selectedPlatforms.containsKey(platform)) {
          _selectedPlatforms[platform] = true;
        }
      }
    });
  }

  Future<void> _publishPost() async {
    setState(() {
      _isPosting = true;
    });

    try {
      final selectedPlatforms = _selectedPlatforms.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      final results = await _metaService.crossPlatformPost(
        content: _contentController.text,
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
        platforms: selectedPlatforms,
      );

      // Show results
      _showPostResults(results);

      // Clear form
      _contentController.clear();
      setState(() {
        _selectedImages.clear();
        _selectedPlatforms = {
          'agroflow': true,
          'facebook': false,
          'instagram': false,
          'whatsapp': false,
        };
        _contentRecommendations = null;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: $e')),
        );
      }
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  void _showPostResults(Map<String, bool> results) {
    final successful = results.entries.where((e) => e.value).map((e) => e.key).toList();
    final failed = results.entries.where((e) => !e.value).map((e) => e.key).toList();

    String message = '';
    if (successful.isNotEmpty) {
      message += 'Successfully posted to: ${successful.join(', ')}';
    }
    if (failed.isNotEmpty) {
      if (message.isNotEmpty) message += '\n';
      message += 'Failed to post to: ${failed.join(', ')}';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: failed.isEmpty ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _connectPlatform(String platform) async {
    // Show connection dialog with proper authentication flow
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _buildConnectionDialog(platform),
    );
    
    if (result != null) {
      await _processConnection(platform, result);
    }
  }

  Widget _buildConnectionDialog(String platform) {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    
    return AlertDialog(
      title: Text('Connect ${_getPlatformDisplayName(platform)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your ${_getPlatformDisplayName(platform)} account details:'),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username/Handle',
                border: OutlineInputBorder(),
                prefixText: '@',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                hintText: '+1234567890',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'We\'ll send a verification code to confirm your account ownership.',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final username = usernameController.text.trim();
            final email = emailController.text.trim();
            final phone = phoneController.text.trim();
            
            if (username.isNotEmpty && (email.isNotEmpty || phone.isNotEmpty)) {
              Navigator.pop(context, {
                'username': username,
                'email': email,
                'phone': phone,
              });
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in username and at least one contact method'),
                  ),
                );
              }
            }
          },
          child: const Text('Connect'),
        ),
      ],
    );
  }

  Future<void> _processConnection(String platform, Map<String, String> credentials) async {
    // Show verification dialog
    final verified = await _showVerificationDialog(platform, credentials);
    
    if (verified) {
      setState(() {
        _connectionStatus[platform] = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getPlatformDisplayName(platform)} connected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<bool> _showVerificationDialog(String platform, Map<String, String> credentials) async {
    final codeController = TextEditingController();
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verify Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('We sent a verification code to ${(credentials['email']?.isNotEmpty ?? false) ? credentials['email'] : credentials['phone']}'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(),
                hintText: '123456',
              ),
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.length == 6) {
                // In production, verify with backend
                Navigator.pop(context, true);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid 6-digit code')),
                  );
                }
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    ) ?? false;
  }



  Future<void> _disconnectPlatform(String platform) async {
    await _metaService.disconnectPlatform(platform);
    
    setState(() {
      _connectionStatus[platform] = false;
      _selectedPlatforms[platform] = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_getPlatformDisplayName(platform)} disconnected')),
      );
    }
  }
}