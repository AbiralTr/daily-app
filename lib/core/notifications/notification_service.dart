import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/recurrence.dart';

/// Wraps `flutter_local_notifications` for scheduling task/event reminders,
/// including recurring ones (daily, or specific weekdays). Call [init] once
/// at startup, before scheduling anything.
///
/// Robustness notes:
/// - The local timezone is read from the device rather than assumed, so
///   reminders fire at the right wall-clock time regardless of where the
///   phone is.
/// - Task and event notification ids are namespaced apart (see
///   [_taskNotificationId]/[_eventNotificationId]) so a task and an event
///   with the same database id can never overwrite each other's reminder.
/// - Every public method that talks to the plugin is wrapped so a
///   permission denial or platform quirk can never throw out of a save/
///   delete flow — reminders are a nice-to-have, not a blocker.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      // If the platform can't tell us the timezone, fall back to UTC rather
      // than crashing startup — reminders will just be offset until this
      // succeeds on a later launch.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

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

    try {
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (_) {
      // Leave _initialized false — every scheduling call below no-ops
      // until a future init() succeeds instead of throwing mid-app-use.
    }
  }

  /// Explicitly (re-)prompts for notification permission. `init` already
  /// requests it on iOS, so this is mainly for a "turn on notifications"
  /// button in Settings and for Android 13+, which needs it separately.
  Future<bool> requestPermissions() async {
    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (_) {
      // Fall through to false below.
    }
    return false;
  }

  // ---- Tasks ----

  /// Schedules (or, if already scheduled, replaces) the reminder(s) for a
  /// task due/anchored at [anchor]. For a one-off task this is a single
  /// alert; for a recurring one it's a repeating alert per matching weekday
  /// (or daily). Silently does nothing if notifications aren't available —
  /// scheduling should never block saving the task.
  Future<void> scheduleTaskReminder({
    required int taskId,
    required String title,
    String? body,
    required DateTime anchor,
    Recurrence recurrence = const Recurrence.none(),
  }) async {
    await cancelTaskReminders(taskId);
    if (!_initialized) return;

    try {
      switch (recurrence.frequency) {
        case RecurrenceFrequency.none:
          if (!anchor.isAfter(DateTime.now())) return;
          await _schedule(
            id: _taskNotificationId(taskId, 0),
            title: title,
            body: body,
            date: tz.TZDateTime.from(anchor, tz.local),
          );
        case RecurrenceFrequency.daily:
          await _schedule(
            id: _taskNotificationId(taskId, 0),
            title: title,
            body: body,
            date: _nextInstanceOfTime(anchor.hour, anchor.minute),
            matchComponents: DateTimeComponents.time,
          );
        case RecurrenceFrequency.weekly:
          for (final weekday in recurrence.weekdays) {
            await _schedule(
              id: _taskNotificationId(taskId, weekday),
              title: title,
              body: body,
              date: _nextInstanceOfWeekdayTime(
                weekday,
                anchor.hour,
                anchor.minute,
              ),
              matchComponents: DateTimeComponents.dayOfWeekAndTime,
            );
          }
      }
    } catch (_) {
      // Best-effort: a scheduling failure shouldn't surface as an error to
      // the user mid-save.
    }
  }

  Future<void> cancelTaskReminders(int taskId) async {
    for (var slot = 0; slot <= 7; slot++) {
      await _safeCancel(_taskNotificationId(taskId, slot));
    }
  }

  // ---- Events ----

  /// Schedules a reminder at the event's own start time (or per matching
  /// weekday/day for a recurring event). All-day events have no meaningful
  /// instant to remind at, so callers should skip calling this for those.
  Future<void> scheduleEventReminder({
    required int eventId,
    required String title,
    String? body,
    required DateTime anchor,
    Recurrence recurrence = const Recurrence.none(),
  }) async {
    await cancelEventReminders(eventId);
    if (!_initialized) return;

    try {
      switch (recurrence.frequency) {
        case RecurrenceFrequency.none:
          if (!anchor.isAfter(DateTime.now())) return;
          await _schedule(
            id: _eventNotificationId(eventId, 0),
            title: title,
            body: body,
            date: tz.TZDateTime.from(anchor, tz.local),
          );
        case RecurrenceFrequency.daily:
          await _schedule(
            id: _eventNotificationId(eventId, 0),
            title: title,
            body: body,
            date: _nextInstanceOfTime(anchor.hour, anchor.minute),
            matchComponents: DateTimeComponents.time,
          );
        case RecurrenceFrequency.weekly:
          for (final weekday in recurrence.weekdays) {
            await _schedule(
              id: _eventNotificationId(eventId, weekday),
              title: title,
              body: body,
              date: _nextInstanceOfWeekdayTime(
                weekday,
                anchor.hour,
                anchor.minute,
              ),
              matchComponents: DateTimeComponents.dayOfWeekAndTime,
            );
          }
      }
    } catch (_) {
      // Same reasoning as scheduleTaskReminder.
    }
  }

  Future<void> cancelEventReminders(int eventId) async {
    for (var slot = 0; slot <= 7; slot++) {
      await _safeCancel(_eventNotificationId(eventId, slot));
    }
  }

  // ---- Shared plumbing ----

  Future<void> _schedule({
    required int id,
    required String title,
    String? body,
    required tz.TZDateTime date,
    DateTimeComponents? matchComponents,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: date,
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'reminders',
          'Reminders',
          channelDescription: 'Task and event reminders',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchComponents,
    );
  }

  Future<void> _safeCancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {
      // Cancelling an id that was never scheduled is a no-op we don't
      // need to know about.
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Slot 0 is the one-off/daily reminder; slots 1-7 are the weekly variant,
  /// one per [DateTime.weekday]. `taskId * 10` leaves room for all eight
  /// without colliding across tasks.
  static int _taskNotificationId(int taskId, int slot) => taskId * 10 + slot;

  /// Offset well clear of any realistic task-id range so a task and an
  /// event that happen to share a database id never fight over the same
  /// notification.
  static int _eventNotificationId(int eventId, int slot) =>
      5000000 + eventId * 10 + slot;
}
