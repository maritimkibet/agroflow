import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/crop_task.dart';
import '../services/hive_service.dart';
import '../widgets/weather_widget.dart'; // Make sure this file exists

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final HiveService _hiveService = HiveService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CropTask> _selectedTasks = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _updateSelectedTasks();
  }

  void _updateSelectedTasks() {
    final tasksBox = _hiveService.taskBox;
    if (tasksBox.isOpen) {
      final allTasks = tasksBox.values.toList();
      setState(() {
        _selectedTasks = allTasks
            .where((task) => isSameDay(task.date, _selectedDay))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
      });
    }
  }

  List<CropTask> _getTasksForDay(DateTime day) {
    final tasksBox = _hiveService.taskBox;
    if (!tasksBox.isOpen) return [];
    return tasksBox.values
        .where((task) => isSameDay(task.date, day))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AgroFlow Calendar')),
      body: ValueListenableBuilder(
        valueListenable: _hiveService.taskBox.listenable(),
        builder: (context, Box<CropTask> box, _) {
          return Column(
            children: [
              const SizedBox(height: 12),
              const WeatherWidget(), // Make sure this widget exists
              const SizedBox(height: 12),
              TableCalendar<CropTask>(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                calendarFormat: CalendarFormat.month,
                eventLoader: _getTasksForDay,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _updateSelectedTasks();
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.green.shade400,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.green.shade700,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.green.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _selectedTasks.isEmpty
                    ? const Center(child: Text('No tasks for selected day'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _selectedTasks.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final task = _selectedTasks[index];
                          return ListTile(
                            leading: Icon(
                              task.isCompleted
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: task.isCompleted
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            title: Text(task.taskDescription),
                            subtitle: Text(task.cropName),
                            onTap: () {
                              task.isCompleted = !task.isCompleted;
                              task.save();
                              _updateSelectedTasks();
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
