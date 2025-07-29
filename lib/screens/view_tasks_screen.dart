import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/crop_task.dart';
import '../services/hive_service.dart';

class ViewTasksScreen extends StatefulWidget {
  const ViewTasksScreen({super.key});

  @override
  State<ViewTasksScreen> createState() => _ViewTasksScreenState();
}

class _ViewTasksScreenState extends State<ViewTasksScreen> {
  final HiveService _hiveService = HiveService();
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _hiveService.init();
  }

  List<CropTask> _getFilteredTasks(Box<CropTask> box) {
    final now = DateTime.now();
    final tasks = box.values.toList();
    switch (_filter) {
      case 'Completed':
        return tasks.where((t) => t.isCompleted).toList();
      case 'Pending':
        return tasks.where((t) => !t.isCompleted && t.date.isAfter(now)).toList();
      case 'Overdue':
        return tasks.where((t) => !t.isCompleted && t.date.isBefore(now)).toList();
      default:
        return tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        backgroundColor: Colors.green.shade700,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Pending', child: Text('Pending')),
              const PopupMenuItem(value: 'Completed', child: Text('Completed')),
              const PopupMenuItem(value: 'Overdue', child: Text('Overdue')),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _hiveService.taskBox.listenable(),
        builder: (context, Box<CropTask> box, _) {
          final filteredTasks = _getFilteredTasks(box);
          if (filteredTasks.isEmpty) {
            return const Center(child: Text('No tasks match this filter.'));
          }

          filteredTasks.sort((a, b) => a.date.compareTo(b.date));

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const Divider(),
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              final isOverdue = !task.isCompleted && task.date.isBefore(DateTime.now());

              return ListTile(
                tileColor: isOverdue ? Colors.red.shade50 : null,
                title: Text(
                  task.taskDescription,
                  style: TextStyle(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  '${task.cropName} • ${task.date.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(color: isOverdue ? Colors.red : null),
                ),
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
      ),
    );
  }
}
