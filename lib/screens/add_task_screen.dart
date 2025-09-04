// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/crop_task.dart';
import '../services/hybrid_storage_service.dart';
import '../services/notification_service.dart';
import '../services/achievement_service.dart';
import '../services/growth_analytics_service.dart';
import '../widgets/achievement_notification.dart';
import 'onboarding_screen.dart';

class AddTaskScreen extends StatefulWidget {
  final HybridStorageService storageService;
  final NotificationService notificationService;
  final DateTime? selectedDate;

  const AddTaskScreen({
    super.key,
    required this.storageService,
    required this.notificationService,
    this.selectedDate,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropNameController = TextEditingController();
  final _taskDescriptionController = TextEditingController();
  DateTime? _selectedDate;
  bool _isCompleted = false;
  String? _selectedTaskType;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
  }

  // Get current user to determine available task types
  late final _currentUser = widget.storageService.getCurrentUser();
  
  // Dynamic task types based on user's farming activities
  List<Map<String, dynamic>> get _availableTaskTypes {
    final cropTasks = [
      {'name': 'Land Preparation', 'icon': '🚜', 'category': 'crop'},
      {'name': 'Planting/Sowing', 'icon': '🌱', 'category': 'crop'},
      {'name': 'Watering/Irrigation', 'icon': '💧', 'category': 'crop'},
      {'name': 'Weeding', 'icon': '🌿', 'category': 'crop'},
      {'name': 'Fertilizing', 'icon': '🧪', 'category': 'crop'},
      {'name': 'Pest Control', 'icon': '🐛', 'category': 'crop'},
      {'name': 'Pruning', 'icon': '✂️', 'category': 'crop'},
      {'name': 'Harvesting', 'icon': '🧺', 'category': 'crop'},
    ];
    
    final livestockTasks = [
      {'name': 'Milking', 'icon': '🥛', 'category': 'livestock'},
      {'name': 'Feeding', 'icon': '🌾', 'category': 'livestock'},
      {'name': 'Health Check', 'icon': '🩺', 'category': 'livestock'},
      {'name': 'Breeding', 'icon': '💕', 'category': 'livestock'},
      {'name': 'Pasture Management', 'icon': '🌱', 'category': 'livestock'},
      {'name': 'Vaccination', 'icon': '💉', 'category': 'livestock'},
    ];
    
    final marketingTasks = [
      {'name': 'Market Research', 'icon': '📊', 'category': 'marketing'},
      {'name': 'Product Listing', 'icon': '📝', 'category': 'marketing'},
      {'name': 'Price Analysis', 'icon': '💰', 'category': 'marketing'},
      {'name': 'Customer Contact', 'icon': '📞', 'category': 'marketing'},
    ];
    
    // Return tasks based on user role
    if (_currentUser?.role.name == 'buyer') {
      return marketingTasks;
    } else if (_currentUser?.role.name == 'farmer') {
      return [...cropTasks, ...livestockTasks];
    } else {
      // Both role gets all tasks
      return [...cropTasks, ...livestockTasks, ...marketingTasks];
    }
  }

  String _getLabelForRole() {
    switch (_currentUser?.role.name) {
      case 'buyer':
        return 'Product/Service';
      case 'farmer':
        return 'Crop/Livestock';
      default:
        return 'Item/Subject';
    }
  }
  
  IconData _getIconForRole() {
    switch (_currentUser?.role.name) {
      case 'buyer':
        return Icons.shopping_cart;
      case 'farmer':
        return Icons.agriculture;
      default:
        return Icons.category;
    }
  }
  
  String _getHintForRole() {
    switch (_currentUser?.role.name) {
      case 'buyer':
        return 'e.g., Maize, Fertilizer, Seeds';
      case 'farmer':
        return 'e.g., Tomatoes, Dairy Cattle, Maize';
      default:
        return 'e.g., Tomatoes, Market Analysis';
    }
  }

  @override
  void dispose() {
    _cropNameController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 5),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date for the task')),
        );
      }
      return;
    }

    if (_selectedTaskType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a task type')),
      );
      return;
    }

    final newTask = CropTask(
      cropName: _cropNameController.text.trim(),
      taskDescription: _taskDescriptionController.text.trim(),
      date: _selectedDate!,
      isCompleted: _isCompleted,
      notes: _selectedTaskType,
    );

    await widget.storageService.addOrUpdateTask(newTask);
    await widget.notificationService.scheduleNotificationForTask(newTask);

    // Track achievement and analytics
    final achievementService = AchievementService();
    final analyticsService = GrowthAnalyticsService();
    
    await analyticsService.trackTaskAdded();
    final unlockedAchievement = await achievementService.updateProgress('first_task');
    
    if (unlockedAchievement != null && mounted) {
      AchievementNotification.show(context, unlockedAchievement);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to tasks screen (home screen with tasks tab)
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _confirmNavigateToOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Do you want to go back to the onboarding screen? Unsaved changes will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    if (confirmed == true) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _selectedDate != null
        ? DateFormat.yMMMMd().format(_selectedDate!)
        : 'Select task date';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Add Crop Task'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _cropNameController,
                  decoration: InputDecoration(
                    labelText: _getLabelForRole(),
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(_getIconForRole()),
                    hintText: _getHintForRole(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter ${_getLabelForRole().toLowerCase()}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _taskDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Task Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.task),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter task description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Task Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  initialValue: _selectedTaskType,
                  items: _availableTaskTypes
                      .map((task) => DropdownMenuItem<String>(
                            value: task['name'] as String,
                            child: Row(
                              children: [
                                Text(task['icon'] as String, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(task['name'] as String),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedTaskType = val),
                  validator: (val) =>
                      val == null ? 'Please select a task type' : null,
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(dateText, style: const TextStyle(fontSize: 16)),
                  trailing: TextButton(
                    onPressed: _pickDate,
                    child: const Text('Pick Date'),
                  ),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  value: _isCompleted,
                  onChanged: (val) =>
                      setState(() => _isCompleted = val ?? false),
                  title: const Text('Mark as completed'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 30),
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton(
                    onPressed: _saveTask,
                    onLongPress: _confirmNavigateToOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('Save Task'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
