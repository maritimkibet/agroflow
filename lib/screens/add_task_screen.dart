import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/crop_task.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'onboarding_screen.dart';

class AddTaskScreen extends StatefulWidget {
  final HiveService hiveService;
  final FirestoreService firestoreService;
  final NotificationService notificationService;

  const AddTaskScreen({
    super.key,
    required this.hiveService,
    required this.firestoreService,
    required this.notificationService,
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

  final List<String> _taskTypes = [
    'Weeding',
    'Spraying',
    'Watering',
    'Fertilizing',
    'Harvesting',
  ];

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

    await widget.hiveService.saveTask(newTask);
    await widget.firestoreService.addOrUpdateTask(newTask);
    await widget.notificationService.scheduleNotificationForTask(newTask);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task saved successfully')),
    );

    Navigator.of(context).pop();
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
                  decoration: const InputDecoration(
                    labelText: 'Crop Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.grass),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter crop name';
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
                  value: _selectedTaskType,
                  items: _taskTypes
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
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
