import 'package:zest/main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:zest/app/data/db.dart';
import 'package:isar/isar.dart';

class NotificationShow {
  Future showNotification(
    int id,
    String title,
    String body,
    DateTime? date,
  ) async {
    await requestNotificationPermission();
    AndroidNotificationDetails androidNotificationDetails =
        const AndroidNotificationDetails(
          'Zest',
          'DARK NIGHT',
          priority: Priority.high,
          importance: Importance.max,
        );
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    var scheduledTime = tz.TZDateTime.from(date!, tz.local);
    flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'notification-payload',
    );
  }

  Future<void> requestNotificationPermission() async {
    final platform =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (platform != null) {
      await platform.requestExactAlarmsPermission();
      await platform.requestNotificationsPermission();
    }
  }
  
  // New method to reschedule notifications for recurring todos
  Future<void> rescheduleRecurringNotifications() async {
    // Get current date/time
    final now = DateTime.now();
    
    // Find all recurring todos with future dates
    final recurringTodos = isar.todos
        .filter()
        .isRecurringEqualTo(true)
        .and()
        .doneEqualTo(false)
        .and()
        .todoCompletedTimeGreaterThan(now)
        .findAllSync();
    
    // Cancel any existing notifications and reschedule
    for (var todo in recurringTodos) {
      await flutterLocalNotificationsPlugin.cancel(todo.id);
      
      if (todo.todoCompletedTime != null) {
        showNotification(
          todo.id,
          todo.name,
          todo.description,
          todo.todoCompletedTime,
        );
      }
    }
  }
}
