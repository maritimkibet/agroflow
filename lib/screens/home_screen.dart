// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/hybrid_storage_service.dart';
import '../services/notification_service.dart';
import '../services/weather_service.dart';
import '../services/update_service.dart';
import '../services/ai_analysis_service.dart';
// import '../services/achievement_service.dart';
// import '../services/referral_service.dart';
// import '../services/growth_analytics_service.dart';
import '../widgets/growth_dashboard.dart';
import '../widgets/features_grid.dart';
import '../widgets/cross_post_suggestions.dart';
import '../widgets/weather_crop_suggestions.dart';
import '../services/admin_setup_service.dart';


import 'add_task_screen.dart';
import 'calendar_screen.dart';
import 'marketplace/marketplace_screen.dart';
import 'marketplace/add_product_screen.dart';

import 'settings_screen.dart';
import 'ai_assistant_screen.dart';
import 'progress_tracker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HybridStorageService _storageService = HybridStorageService();
  final NotificationService _notificationService = NotificationService();
  final WeatherService _weatherService = WeatherService();
  final UpdateService _updateService = UpdateService();
  final AIAnalysisService _aiAnalysisService = AIAnalysisService();
  // Services for future features
  // final AchievementService _achievementService = AchievementService();
  // final ReferralService _referralService = ReferralService();
  // final GrowthAnalyticsService _analyticsService = GrowthAnalyticsService();

  int _selectedIndex = 0;
  User? _currentUser;

  String _weatherSummary = '';
  String _temperature = '';
  int? _humidity;
  double? _windSpeed;

  
  String _aiInsights = '';
  bool _isLoadingInsights = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _storageService.startSyncMonitoring(); // Start monitoring connectivity
    _initializeAdminSetup(); // Initialize admin accounts
    _checkFirstLaunch();
    _loadWeather();
    _checkSyncStatus();
    _checkForUpdates(); // Check for app updates
    _loadAIInsights(); // Load AI analysis
  }

  void _loadCurrentUser() {
    final user = _storageService.getCurrentUser();
    if (user != _currentUser) {
      setState(() {
        _currentUser = user;
        _selectedIndex = 0; // Reset to first tab when user changes
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for user changes when returning to this screen
    _loadCurrentUser();
  }

  Future<void> _initializeAdminSetup() async {
    try {
      final adminSetupService = AdminSetupService();
      await adminSetupService.initializeDefaultAdmins();
    } catch (e) {
      debugPrint('Admin setup error: $e');
    }
  }

  Future<void> _checkForUpdates() async {
    // Check for updates after a short delay to not block UI
    Future.delayed(const Duration(seconds: 2), () async {
      if (await _updateService.shouldCheckForUpdates()) {
        final updateInfo = await _updateService.checkForUpdates();
        if (updateInfo != null && mounted) {
          await _updateService.showUpdateDialog(context, updateInfo);
        }
      }
    });
  }

  Future<void> _loadAIInsights() async {
    try {
      // Load AI insights in background
      final insights = await _aiAnalysisService.performStartupAnalysis();
      if (mounted) {
        setState(() {
          _aiInsights = insights;
          _isLoadingInsights = false;
        });
        
        // Show insights notification if there are urgent items
        if (insights.contains('⚠️') || insights.contains('Priority')) {
          _showInsightsSnackBar();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiInsights = 'Welcome to AgroFlow! 🌱 Check your tasks and weather for today\'s farming activities.';
          _isLoadingInsights = false;
        });
      }
    }
  }

  void _showInsightsSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('AI has important farming insights for you!'),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _selectedIndex = 0; // Go to dashboard
            });
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _checkSyncStatus() async {
    final syncStatus = await _storageService.getSyncStatus();
    if (mounted && syncStatus['pendingItems'] > 0) {
      // Show sync indicator if there are pending items
      setState(() {});
    }
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('firstLaunch') ?? true;

    if (isFirstLaunch) {
      await prefs.setBool('firstLaunch', false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTaskScreen(
              storageService: _storageService,
              notificationService: _notificationService,
            ),
          ),
        );
      });
    }
  }

  Future<void> _loadWeather() async {
    final weather = await _weatherService.getCurrentWeather();
    if (mounted && weather != null) {
      setState(() {
        _weatherSummary = weather['description'] ?? '';
        _temperature = weather['temperature'] != null
            ? "${(weather['temperature'] as num).toStringAsFixed(1)}°C"
            : '';
        _humidity = weather['humidity'] as int?;
        _windSpeed = (weather['windSpeed'] as num?)?.toDouble();

      });
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String getDynamicCropTip() {
    final temperature = _temperature.isNotEmpty 
        ? double.tryParse(_temperature.replaceAll('°C', '')) ?? 20 
        : 20;
    final humidity = _humidity ?? 50;
    final windKmh = (_windSpeed ?? 0) * 3.6;
    final rainExpected = _weatherSummary.toLowerCase().contains('rain');
    final isHot = temperature > 30;
    final isCold = temperature < 10;
    final isWindy = windKmh > 15;
    
    final Map<String, List<String>> intelligentTips = {
      'weeding': [
        if (rainExpected) 'Wait for dry weather before weeding to avoid soil compaction.',
        if (isHot) 'Weed early morning or evening to avoid heat stress on crops.',
        if (!rainExpected && !isHot) 'Perfect weather for weeding - soil is workable and plants won\'t stress.',
        'Water crops gently after weeding to help them recover.',
      ],
      'spraying': [
        if (isWindy) '⚠️ Wind speed is ${windKmh.toStringAsFixed(1)} km/h - avoid spraying to prevent drift.',
        if (rainExpected) '⚠️ Rain expected - delay spraying for 24-48 hours.',
        if (isHot) 'Spray early morning or evening to avoid evaporation and leaf burn.',
        if (!isWindy && !rainExpected) 'Good conditions for spraying - low wind and no rain expected.',
        'Always wear protective equipment when spraying.',
      ],
      'watering': [
        if (isHot) 'Water early morning or late evening to reduce evaporation in this heat.',
        if (rainExpected) 'Skip watering - rain is expected to provide natural irrigation.',
        if (humidity > 80) 'High humidity may reduce water needs - check soil moisture first.',
        if (humidity < 30) 'Low humidity increases water needs - monitor crops closely.',
      ],
      'fertilizing': [
        if (rainExpected) 'Perfect timing - rain will help dissolve and distribute fertilizer.',
        if (isHot && !rainExpected) 'Water immediately after fertilizing to prevent root burn.',
        if (isCold) 'Nutrient uptake is slower in cold weather - consider liquid fertilizers.',
      ],
      'harvesting': [
        if (rainExpected) 'Harvest before rain to prevent crop damage and quality loss.',
        if (isHot) 'Harvest early morning when crops are cool and turgid.',
        if (humidity > 80) 'High humidity may affect storage - ensure proper drying.',
      ],
      'milking': [
        if (isHot) 'Provide extra shade and water for dairy animals in this heat.',
        if (isCold) 'Check water systems for freezing - animals need warm water.',
        'Maintain consistent milking times for optimal milk production.',
        if (humidity > 80) 'High humidity can stress animals - ensure good ventilation.',
      ],
      'feeding': [
        if (isHot) 'Animals eat less in hot weather - provide high-energy feeds.',
        if (isCold) 'Increase feed portions to help animals maintain body heat.',
        if (rainExpected) 'Store feed in dry areas to prevent spoilage.',
      ],
      'health_check': [
        if (isHot) 'Watch for heat stress signs: panting, drooling, reduced activity.',
        if (isCold) 'Monitor for cold stress and respiratory issues.',
        if (humidity > 80) 'High humidity increases disease risk - check animals more frequently.',
      ],
      'market_research': [
        if (rainExpected) 'Weather may affect supply - good time to research price trends.',
        'Check seasonal demand patterns for your products.',
        'Monitor competitor pricing and market conditions.',
      ],
    };

    final allTasks = _storageService.getAllTasks();
    final recentTasks = allTasks
        .where((task) => task.date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();
    
    if (recentTasks.isNotEmpty) {
      recentTasks.sort((a, b) => b.date.compareTo(a.date));
      final lastTask = recentTasks.first;
      final taskType = lastTask.taskType?.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_') ?? 'general';
      
      final relevantTips = intelligentTips[taskType] ?? intelligentTips['general'] ?? [];
      
      if (relevantTips.isNotEmpty) {
        // Add context about the last task
        final daysAgo = DateTime.now().difference(lastTask.date).inDays;
        final timeContext = daysAgo == 0 ? 'today' : daysAgo == 1 ? 'yesterday' : '$daysAgo days ago';
        
        final tip = relevantTips.first;
        return 'Since you ${lastTask.isCompleted ? 'completed' : 'scheduled'} ${lastTask.taskDescription.toLowerCase()} $timeContext: $tip';
      }
    }

    // Weather-based general tips
    final weatherTips = <String>[
      if (isHot) '🌡️ High temperature (${temperature.round()}°C) - ensure adequate water for crops and livestock.',
      if (isCold) '❄️ Cold weather (${temperature.round()}°C) - protect sensitive crops and provide warm water for animals.',
      if (rainExpected) '🌧️ Rain expected - plan indoor activities and protect harvested crops.',
      if (isWindy) '💨 Windy conditions (${windKmh.toStringAsFixed(1)} km/h) - secure loose items and avoid spraying.',
      if (humidity > 80) '💧 High humidity ($humidity%) - monitor for fungal diseases and ensure good ventilation.',
      if (humidity < 30) '🏜️ Low humidity ($humidity%) - increase watering frequency and monitor plant stress.',
    ];

    if (weatherTips.isNotEmpty) {
      return weatherTips.first;
    }

    // Default tips based on user role
    final userRole = _currentUser?.role.name ?? 'farmer';
    final defaultTips = {
      'farmer': [
        'Monitor your crops daily for signs of pests or diseases.',
        'Keep detailed records of all farming activities.',
        'Plan your activities based on weather forecasts.',
      ],
      'buyer': [
        'Research market prices before making purchases.',
        'Build relationships with reliable suppliers.',
        'Consider seasonal price variations in your planning.',
      ],
      'both': [
        'Balance your farming and trading activities effectively.',
        'Use your farming knowledge to make better buying decisions.',
        'Consider vertical integration opportunities.',
      ],
    };

    final tips = defaultTips[userRole] ?? defaultTips['farmer']!;
    tips.shuffle();
    return tips.first;
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const GrowthDashboard(),
          const CrossPostSuggestions(),
          const FeaturesGrid(),
          _buildAIInsightsCard(),
          const SizedBox(height: 16),
          _buildWeatherCard(),
          const SizedBox(height: 16),
          const WeatherCropSuggestions(),
          const SizedBox(height: 16),
          _buildAdvisoryCard(),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weather Today',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _temperature.isNotEmpty ? _temperature : 'Loading...',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(_weatherSummary.isNotEmpty ? _weatherSummary : 'Fetching weather...'),
            if (_humidity != null) Text('Humidity: $_humidity%'),
            if (_windSpeed != null) Text('Wind Speed: ${_windSpeed!.toStringAsFixed(1)} m/s'),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsightsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'AI Farm Analysis',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoadingInsights)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isLoadingInsights
                    ? const Text(
                        'Analyzing your farm data, weather, and tasks...',
                        style: TextStyle(
                          color: Colors.black87,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Text(
                        _aiInsights,
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
              ),
              if (!_isLoadingInsights) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _loadAIInsights,
                      child: const Text(
                        'Refresh Analysis',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisoryCard() {
    final tip = getDynamicCropTip();
    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quick Farming Tip",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(tip),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    final tasks = _storageService.getAllTasks();
    tasks.sort((a, b) => a.date.compareTo(b.date));

    if (tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 64),
            Text('No tasks yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Add your first farming task!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _storageService.syncPendingItems();
        setState(() {}); // Refresh the UI
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            child: ListTile(
              leading: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isCompleted ? Colors.green : Colors.grey.shade300,
                ),
                child: task.isCompleted
                    ? const Center(
                        child: Text(
                          '✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
              title: Text(
                task.taskDescription,
                style: TextStyle(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${task.cropName} • ${task.date.toLocal().toString().split(' ')[0]}'),
                  if (task.priority != null)
                    Text(
                      'Priority: ${task.priority}',
                      style: TextStyle(
                        color: task.priority == 'High' ? Colors.red : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              onTap: () async {
                setState(() {
                  task.isCompleted = !task.isCompleted;
                });
                await _storageService.addOrUpdateTask(task);
                
                // Show completion feedback
                if (task.isCompleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Task completed: ${task.taskDescription}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📝 Task marked as pending: ${task.taskDescription}'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                
                setState(() {}); // Refresh UI
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMarketTab() => const MarketplaceScreen();
  Widget _buildSettingsTab() => const SettingsScreen(); // ✅
  Widget _buildGeminiChatTab() => const AIAssistantScreen(); // 👈 New tab widget for AI chat

  void _openAddProductScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBuyerOnly = _currentUser?.role == UserRole.buyer;
    
    // Build tabs based on user role
    final List<Widget> tabs = [];
    final List<BottomNavigationBarItem> navItems = [];
    
    if (!isBuyerOnly) {
      // Farmers and both roles get farming features
      tabs.addAll([
        _buildDashboardTab(),       // Index 0
        const CalendarScreen(),     // Index 1
        _buildTasksTab(),           // Index 2
      ]);
      navItems.addAll([
        const BottomNavigationBarItem(icon: SizedBox.shrink(), label: 'Dashboard'),
        const BottomNavigationBarItem(icon: SizedBox.shrink(), label: 'Calendar'),
        const BottomNavigationBarItem(icon: SizedBox.shrink(), label: 'Tasks'),
      ]);
    }
    
    // All users get marketplace
    tabs.add(_buildMarketTab());
    navItems.add(const BottomNavigationBarItem(icon: SizedBox.shrink(), label: 'Market'));
    
    // All users get settings and AI chat
    tabs.addAll([
      _buildSettingsTab(),
      _buildGeminiChatTab(),
    ]);
    navItems.addAll([
      const BottomNavigationBarItem(icon: SizedBox.shrink(), label: 'Settings'),
      const BottomNavigationBarItem(icon: SizedBox.shrink(), label: 'AI Chat'),
    ]);

    return Scaffold(
      appBar: AppBar(
        title: Text('AgroFlow - ${_currentUser?.name ?? 'User'}'),
        backgroundColor: Colors.green.shade700,
        actions: [
          // Text-only menu - professional look
          PopupMenuButton<String>(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            onSelected: (String value) {
              switch (value) {
                case 'crop_doctor':
                  if (mounted) Navigator.pushNamed(context, '/crop_doctor');
                  break;
                case 'analytics':
                  if (mounted) Navigator.pushNamed(context, '/analytics');
                  break;
                case 'achievements':
                  if (mounted) Navigator.pushNamed(context, '/achievements');
                  break;
                case 'progress':
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProgressTrackerScreen()),
                    );
                  }
                  break;
                case 'admin':
                  if (mounted) Navigator.pushNamed(context, '/admin_login');
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'crop_doctor',
                child: Text('Crop Doctor'),
              ),
              const PopupMenuItem<String>(
                value: 'analytics',
                child: Text('Farm Analytics'),
              ),
              const PopupMenuItem<String>(
                value: 'achievements',
                child: Text('Achievements'),
              ),
              const PopupMenuItem<String>(
                value: 'progress',
                child: Text('My Progress'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'admin',
                child: Text('Admin Panel'),
              ),
            ],
          ),
          // Sync status text indicator
          FutureBuilder<Map<String, dynamic>>(
            future: _storageService.getSyncStatus(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final syncStatus = snapshot.data!;
                final isOnline = syncStatus['isOnline'] as bool;
                final pendingItems = syncStatus['pendingItems'] as int;
                
                if (pendingItems > 0) {
                  return TextButton(
                    onPressed: () async {
                      if (isOnline) {
                        await _storageService.syncPendingItems();
                        if (mounted) setState(() {});
                      }
                    },
                    child: Text(
                      'Sync ($pendingItems)',
                      style: TextStyle(
                        color: isOnline ? Colors.orange : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  );
                } else if (isOnline) {
                  return const Text(
                    'Online',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  );
                } else {
                  return const Text(
                    'Offline',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
          // Show add product button when on marketplace tab
          if (_selectedIndex == (isBuyerOnly ? 0 : 3))
            TextButton(
              onPressed: _openAddProductScreen,
              child: const Text(
                'Add Product',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green.shade100,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey.shade700,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
      floatingActionButton: (!isBuyerOnly && _selectedIndex == 2)
          ? FloatingActionButton.extended(
              backgroundColor: Colors.green.shade700,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTaskScreen(
                      storageService: _storageService,
                      notificationService: _notificationService,
                    ),
                  ),
                );
              },
              label: const Text('Add Task'),
            )
          : null,
    );
  }
}
