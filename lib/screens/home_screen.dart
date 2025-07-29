// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/crop_task.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/weather_service.dart';

import 'add_task_screen.dart';
import 'calendar_screen.dart';
import 'marketplace/marketplace_screen.dart';
import 'marketplace/add_product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HiveService _hiveService = HiveService();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final WeatherService _weatherService = WeatherService();

  int _selectedIndex = 0;

  String _weatherSummary = '';
  String _temperature = '';
  int? _humidity;
  double? _windSpeed;
  String? _iconCode;

  @override
  void initState() {
    super.initState();
    _hiveService.init();
    _checkFirstLaunch();
    _loadWeather();
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
              hiveService: _hiveService,
              firestoreService: _firestoreService,
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
        _iconCode = weather['iconCode'] as String?;
      });
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Dynamic crop tip logic (same as you wrote)
  String getDynamicCropTip() {
    final Map<String, List<String>> tipsByTask = {
      'weeding': [
        'Avoid spraying immediately after weeding to let plants recover.',
        'Water your crops gently after weeding for better growth.',
        'Check soil moisture after weeding to optimize watering.',
      ],
      'spraying': [
        'Avoid spraying if wind speed exceeds 15 km/h.',
        'Do not spray if rain is expected within 24 hours.',
        'Wear protective gear while spraying.',
      ],
      'watering': [
        'Water crops early in the morning or late afternoon to reduce evaporation.',
        'Avoid overwatering to prevent root rot.',
      ],
      'general': [
        'Keep an eye on local weather to optimize your farming tasks.',
        'Regularly inspect your crops for pests and diseases.',
      ],
    };

    final tasksBox = _hiveService.taskBox;
    final completedTasks = tasksBox.values
        .where((task) => task.isCompleted && task.taskType != null)
        .toList();
    if (completedTasks.isNotEmpty) {
      completedTasks.sort((a, b) => b.date.compareTo(a.date)); // newest first
      final lastTaskType = completedTasks.first.taskType!.toLowerCase();

      final relevantTips = tipsByTask[lastTaskType] ?? tipsByTask['general']!;

      final windKmh = (_windSpeed ?? 0) * 3.6; // m/s to km/h
      final rainExpected = _weatherSummary.toLowerCase().contains('rain');

      final filteredTips = relevantTips.where((tip) {
        if (lastTaskType == 'spraying') {
          if (windKmh > 15) return tip.contains('wind speed') || tip.contains('spraying');
          if (rainExpected) return tip.contains('rain') || tip.contains('spraying');
        }
        return true;
      }).toList();

      if (filteredTips.isNotEmpty) {
        filteredTips.shuffle();
        return filteredTips.first;
      }
    }

    final generalTips = tipsByTask['general']!;
    generalTips.shuffle();
    return generalTips.first;
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWeatherCard(),
          const SizedBox(height: 16),
          _buildAdvisoryCard(),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    String iconUrl = _iconCode != null
        ? 'https://openweathermap.org/img/wn/$_iconCode@2x.png'
        : '';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: iconUrl.isNotEmpty
            ? Image.network(iconUrl, width: 48, height: 48)
            : const Icon(Icons.wb_sunny_outlined, size: 36, color: Colors.orange),
        title: Text(_temperature.isNotEmpty ? _temperature : 'Loading...'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_weatherSummary.isNotEmpty ? _weatherSummary : 'Fetching weather...'),
            if (_humidity != null) Text('Humidity: $_humidity%'),
            if (_windSpeed != null) Text('Wind Speed: ${_windSpeed!.toStringAsFixed(1)} m/s'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisoryCard() {
    final tip = getDynamicCropTip();
    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.tips_and_updates, color: Colors.green, size: 30),
        title: const Text("Crop Tip of the Day"),
        subtitle: Text(tip),
      ),
    );
  }

  Widget _buildTasksTab() {
    return ValueListenableBuilder(
      valueListenable: _hiveService.taskBox.listenable(),
      builder: (context, Box<CropTask> box, _) {
        final tasks = box.values.toList();
        tasks.sort((a, b) => a.date.compareTo(b.date));

        if (tasks.isEmpty) {
          return const Center(child: Text('No tasks yet'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return ListTile(
              title: Text(task.taskDescription),
              subtitle: Text('${task.cropName} • ${task.date.toLocal().toString().split(' ')[0]}'),
              trailing: Icon(
                task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: task.isCompleted ? Colors.green : Colors.grey,
              ),
              onTap: () {
                setState(() {
                  task.isCompleted = !task.isCompleted;
                  task.save();
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMarketTab() => const MarketplaceScreen();

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
    final tabs = [
      _buildDashboardTab(),        // Index 0
      const CalendarScreen(),      // Index 1
      _buildTasksTab(),            // Index 2
      _buildMarketTab(),           // Index 3
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroFlow'),
        backgroundColor: Colors.green.shade700,
        actions: [
          if (_selectedIndex == 3)
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              tooltip: 'Add Product',
              onPressed: _openAddProductScreen,
            ),
        ],
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green.shade100,
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey.shade700,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Market'),
        ],
      ),
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton(
              backgroundColor: Colors.green.shade700,
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTaskScreen(
                      hiveService: _hiveService,
                      firestoreService: _firestoreService,
                      notificationService: _notificationService,
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }
}
