import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around `flutter_local_notifications` for scheduling
/// per-task reminders. Call [init] once, before scheduling anything.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // TODO: use a device-timezone plugin (e.g. flutter_timezone) instead of
    // UTC once the app needs reminders to line up with the user's clock.
    tz.setLocalLocation(tz.getLocation('UTC'));

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(
      iOS: iosSettings,
      android: androidSettings,
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  /// Schedules a one-off reminder for a task at [dueDate]. Uses the task's
  /// database [id] as the notification id so it can be cancelled/replaced.
  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    String? body,
    required DateTime dueDate,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(dueDate, tz.local),
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task reminders',
          channelDescription: 'Reminders for your daily tasks',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);
}
