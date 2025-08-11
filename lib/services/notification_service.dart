import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/crop_task.dart';
import 'hive_service.dart';
import 'platform_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final HiveService _hiveService = HiveService();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // Check if platform supports notifications
    if (!PlatformService.instance.supportsFeature(PlatformFeature.notifications)) {
      debugPrint('Notifications not supported on this platform');
      return;
    }

    tz_data.initializeTimeZones();

    // Set local timezone for scheduling
    final String timeZoneName = await AwesomeNotifications().getLocalTimeZoneIdentifier();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'daily_tasks',
          channelName: 'Daily Tasks',
          channelDescription: 'Notifications for daily farming tasks',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelKey: 'daily_reminder',
          channelName: 'Daily Reminder',
          channelDescription: 'Daily reminder for farming tasks',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
        ),
      ],
      debug: true,
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  void listenToNotificationEvents() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction receivedAction) async {
        debugPrint('Notification tapped: ${receivedAction.id}');
        // You can add navigation or other logic here
      },
      onNotificationCreatedMethod: (ReceivedNotification notification) async {
        debugPrint('Notification created: ${notification.id}');
      },
      onDismissActionReceivedMethod: (ReceivedAction action) async {
        debugPrint('Notification dismissed: ${action.id}');
      },
    );
  }

  Future<void> scheduleTaskNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();

      final List<CropTask> tasks = _hiveService.getAllTasks();
      final DateTime now = DateTime.now();
      final List<CropTask> todayTasks = tasks.where((task) =>
          task.date.year == now.year &&
          task.date.month == now.month &&
          task.date.day == now.day).toList();

      if (todayTasks.isNotEmpty) {
        await _showTodayTasksNotification(todayTasks);
      }

      await _scheduleNextDayNotification();
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
    }
  }

  Future<void> _showTodayTasksNotification(List<CropTask> todayTasks) async {
    final String taskCount = todayTasks.length.toString();
    final String taskText = todayTasks.length == 1 ? 'task' : 'tasks';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 100,
        channelKey: 'daily_tasks',
        title: 'Today\'s Farming Tasks',
        body: 'You have $taskCount $taskText scheduled for today',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<void> _scheduleNextDayNotification() async {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1, 7, 0);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 101,
        channelKey: 'daily_reminder',
        title: 'Daily Farming Tasks',
        body: 'Check your tasks for today',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        year: tomorrow.year,
        month: tomorrow.month,
        day: tomorrow.day,
        hour: tomorrow.hour,
        minute: tomorrow.minute,
        second: 0,
        millisecond: 0,
        allowWhileIdle: true,
        repeats: false,
      ),
    );
  }

  /// Cancel a scheduled notification for a given task id (using hashCode)
  Future<void> cancelNotification(int hashCode) async {
    try {
      await AwesomeNotifications().cancel(hashCode);
      debugPrint('Cancelled notification with id: $hashCode');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  /// Schedule notification for a specific task, 15 minutes before the task time
  Future<void> scheduleNotificationForTask(CropTask task) async {
    try {
      final DateTime notifyTime = task.date.subtract(const Duration(minutes: 15));

      if (notifyTime.isBefore(DateTime.now())) {
        debugPrint('Notification time already passed for task: ${task.id}');
        return;
      }

      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(notifyTime, tz.local);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: task.id.hashCode,
          channelKey: 'daily_tasks',
          title: 'Upcoming Task: ${task.cropName}',
          body: '${task.taskDescription} at ${task.date.hour.toString().padLeft(2, '0')}:${task.date.minute.toString().padLeft(2, '0')}',
          notificationLayout: NotificationLayout.Default,
          payload: {'taskId': task.id},
        ),
        schedule: NotificationCalendar.fromDate(date: scheduledDate, allowWhileIdle: true),
      );

      debugPrint('Scheduled notification for task: ${task.id} at $notifyTime');
    } catch (e) {
      debugPrint('Error scheduling notification for task: $e');
    }
  }

  Future<void> scheduleNotification(CropTask newTask) async {}
}
