# Code Examples for Crop Task Tracking App

## 1. Hive Dependencies in pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  
  # Hive packages
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.2
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  
  # Hive code generation
  build_runner: ^2.4.8
  hive_generator: ^2.0.1
```

## 2. CropTask Model

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'crop_task.g.dart';

@HiveType(typeId: 0)
class CropTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String cropName;

  @HiveField(2)
  String taskDescription;

  @HiveField(3)
  DateTime date;

  CropTask({
    String? id,
    required this.cropName,
    required this.taskDescription,
    required this.date,
  }) : id = id ?? const Uuid().v4();
}
```

## 3. Hive Initialization in main.dart

```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'models/crop_task.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  
  // Register Hive Adapter
  Hive.registerAdapter(CropTaskAdapter());
  
  // Open the box
  await Hive.openBox<CropTask>('crop_tasks');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green.shade700,
          secondary: Colors.brown.shade600,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

## 4. Hive Service

```dart
import 'package:hive/hive.dart';
import '../models/crop_task.dart';

class HiveService {
  static const String boxName = 'crop_tasks';
  
  // Get the box
  Box<CropTask> get taskBox => Hive.box<CropTask>(boxName);
  
  // Add a new task
  Future<void> addTask(CropTask task) async {
    await taskBox.put(task.id, task);
  }
  
  // Get all tasks
  List<CropTask> getAllTasks() {
    return taskBox.values.toList();
  }
  
  // Get tasks sorted by date
  List<CropTask> getTasksSortedByDate() {
    final tasks = getAllTasks();
    tasks.sort((a, b) => a.date.compareTo(b.date));
    return tasks;
  }
  
  // Delete a task
  Future<void> deleteTask(String id) async {
    await taskBox.delete(id);
  }
}
```

## 5. Home Screen with Tabs

```dart
import 'package:flutter/material.dart';
import 'add_task_screen.dart';
import 'view_tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  static final List<Widget> _screens = [
    const AddTaskScreen(),
    const ViewTasksScreen(),
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroFlow'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_task),
            label: 'Add Task',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'View Tasks',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}
```

## 6. Add Task Screen (Form UI)

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/crop_task.dart';
import '../services/hive_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hiveService = HiveService();
  
  final _cropNameController = TextEditingController();
  final _taskDescriptionController = TextEditingController();
  DateTime? _selectedDate;
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  void _saveTask() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final task = CropTask(
        cropName: _cropNameController.text,
        taskDescription: _taskDescriptionController.text,
        date: _selectedDate!,
      );
      
      _hiveService.addTask(task);
      
      // Reset form
      _cropNameController.clear();
      _taskDescriptionController.clear();
      setState(() {
        _selectedDate = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task saved successfully')),
      );
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
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
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a crop name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taskDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Task Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a task description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedDate == null
                      ? 'Select a date'
                      : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Task'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _cropNameController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }
}
```

## 7. View Tasks Screen (List UI)

```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/crop_task.dart';
import '../services/hive_service.dart';

class ViewTasksScreen extends StatelessWidget {
  const ViewTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hiveService = HiveService();
    
    return ValueListenableBuilder(
      valueListenable: Hive.box<CropTask>('crop_tasks').listenable(),
      builder: (context, Box<CropTask> box, _) {
        final tasks = hiveService.getTasksSortedByDate();
        
        if (tasks.isEmpty) {
          return const Center(
            child: Text(
              'No tasks added yet',
              style: TextStyle(fontSize: 18),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final isToday = _isToday(task.date);
            final isUpcoming = task.date.isAfter(DateTime.now());
            
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: isToday 
                  ? Colors.green.shade50 
                  : null,
              child: ListTile(
                title: Text(
                  task.cropName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(task.taskDescription),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: isToday 
                              ? Colors.green 
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('yyyy-MM-dd').format(task.date),
                          style: TextStyle(
                            color: isToday 
                                ? Colors.green 
                                : null,
                            fontWeight: isToday 
                                ? FontWeight.bold 
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    hiveService.deleteTask(task.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task deleted')),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
}