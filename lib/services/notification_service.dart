import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'attendance_channel',
        'Attendance Notifications',
        channelDescription: 'Notifications for attendance system',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> scheduleAttendanceReminder({
    required DateTime classTime,
    required String className,
  }) async {
    // Schedule reminder 15 minutes before class
    final reminderTime = classTime.subtract(const Duration(minutes: 15));

    if (reminderTime.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      classTime.millisecondsSinceEpoch ~/ 1000,
      'Class Reminder',
      'Time for $className attendance',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Class Reminders',
          channelDescription: 'Reminders for upcoming classes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> showAttendanceMarkedNotification(
    String studentName,
    String status,
  ) async {
    await showNotification(
      title: 'Attendance Marked',
      body: '$studentName marked as $status',
    );
  }

  static Future<void> showLocationErrorNotification() async {
    await showNotification(
      title: 'Location Error',
      body: 'Unable to verify location. Please check location permissions.',
    );
  }

  static Future<void> showFaceRecognitionErrorNotification() async {
    await showNotification(
      title: 'Face Recognition Error',
      body: 'Unable to recognize face. Please try again.',
    );
  }
}
