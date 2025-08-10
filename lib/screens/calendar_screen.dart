import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/crop_task.dart';
import '../services/hybrid_storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/weather_widget.dart';
import 'add_task_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final HybridStorageService _storageService = HybridStorageService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CropTask> _selectedTasks = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTasksForSelectedDay();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh tasks when returning to this screen
    _loadTasksForSelectedDay();
  }

  void _loadTasksForSelectedDay() {
    if (_selectedDay != null) {
      setState(() {
        _selectedTasks = _storageService.getTasksForDate(_selectedDay!);
        _selectedTasks.sort((a, b) => a.date.compareTo(b.date));
      });
    }
  }

  List<CropTask> _getTasksForDay(DateTime day) {
    return _storageService.getTasksForDate(day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AgroFlow Calendar')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _storageService.syncPendingItems();
          _loadTasksForSelectedDay();
        },
        child: Column(
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
                startingDayOfWeek: StartingDayOfWeek.monday,
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _loadTasksForSelectedDay();
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: Colors.green.shade400,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.green.shade700,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                  markerSize: 6.0,
                  markerMargin: const EdgeInsets.symmetric(horizontal: 1.0),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: events.take(3).map((task) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.0),
                              height: 6.0,
                              width: 6.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: task.isCompleted 
                                    ? Colors.green.shade600 
                                    : Colors.orange.shade600,
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(),
              ),
              Expanded(
                child: _selectedTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks for ${_selectedDay != null ? "${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}" : "selected day"}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Tasks for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _selectedTasks.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final task = _selectedTasks[index];
                                return Card(
                                  elevation: 2,
                                  child: ListTile(
                                    leading: GestureDetector(
                                      onTap: () async {
                                        setState(() {
                                          task.isCompleted = !task.isCompleted;
                                        });
                                        await _storageService.addOrUpdateTask(task);
                                        _loadTasksForSelectedDay();
                                      },
                                      child: Icon(
                                        task.isCompleted
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: task.isCompleted
                                            ? Colors.green.shade600
                                            : Colors.grey.shade400,
                                        size: 28,
                                      ),
                                    ),
                                    title: Text(
                                      task.taskDescription,
                                      style: TextStyle(
                                        decoration: task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: task.isCompleted
                                            ? Colors.grey.shade600
                                            : null,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Crop: ${task.cropName}',
                                          style: TextStyle(
                                            color: Colors.green.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (task.priority != null)
                                          Text(
                                            'Priority: ${task.priority}',
                                            style: TextStyle(
                                              color: task.priority == 'High'
                                                  ? Colors.red.shade600
                                                  : task.priority == 'Medium'
                                                      ? Colors.orange.shade600
                                                      : Colors.blue.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: task.isCompleted
                                        ? Icon(
                                            Icons.done_all,
                                            color: Colors.green.shade600,
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskScreen(
                storageService: _storageService,
                notificationService: NotificationService(),
                selectedDate: _selectedDay,
              ),
            ),
          ).then((_) {
            // Refresh tasks when returning from add task screen
            _loadTasksForSelectedDay();
          });
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
