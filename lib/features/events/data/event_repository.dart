import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/recurrence.dart';
import '../domain/event_occurrence.dart';

/// Read/write access to events. Screens should go through this rather than
/// touching [AppDatabase] directly.
class EventRepository {
  EventRepository(this._db);

  final AppDatabase _db;

  /// Occurrences landing on [date] — one-off events overlapping that day,
  /// plus any recurring event whose schedule includes it.
  Stream<List<EventOccurrence>> watchEventsForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return _db.watchEventsForDate(day).map((events) {
      final occurrences = <EventOccurrence>[];
      for (final event in events) {
        final recurrence = Recurrence.decode(event.recurrence);
        if (recurrence.repeats) {
          final anchor = DateTime(
            event.startAt.year,
            event.startAt.month,
            event.startAt.day,
          );
          if (day.isBefore(anchor) || !recurrence.occursOn(day)) continue;
          occurrences.add(
            EventOccurrence(
              event: event,
              startAt: DateTime(
                day.year,
                day.month,
                day.day,
                event.startAt.hour,
                event.startAt.minute,
              ),
              endAt: event.endAt == null
                  ? null
                  : DateTime(
                      day.year,
                      day.month,
                      day.day,
                      event.endAt!.hour,
                      event.endAt!.minute,
                    ),
            ),
          );
        } else {
          occurrences.add(
            EventOccurrence(
              event: event,
              startAt: event.startAt,
              endAt: event.endAt,
            ),
          );
        }
      }
      occurrences.sort((a, b) => a.startAt.compareTo(b.startAt));
      return occurrences;
    });
  }

  Stream<List<Event>> watchAllEvents() => _db.watchAllEvents();

  /// Whether the recurring event in [event] occurs on [date] at all (used
  /// by the calendar to decide whether to mark that day).
  bool occursOn(Event event, DateTime date) {
    final recurrence = Recurrence.decode(event.recurrence);
    final anchor = DateTime(
      event.startAt.year,
      event.startAt.month,
      event.startAt.day,
    );
    final day = DateTime(date.year, date.month, date.day);
    if (recurrence.repeats) {
      return !day.isBefore(anchor) && recurrence.occursOn(day);
    }
    final end = event.endAt ?? event.startAt;
    return !day.isBefore(anchor) &&
        !day.isAfter(DateTime(end.year, end.month, end.day));
  }

  Future<Event?> getEvent(int id) => _db.getEvent(id);

  Future<int> addEvent({
    required String title,
    String? notes,
    String? location,
    required DateTime startAt,
    DateTime? endAt,
    bool isAllDay = false,
    Recurrence recurrence = const Recurrence.none(),
  }) {
    return _db.insertEvent(
      EventsCompanion.insert(
        title: title,
        notes: Value.absentIfNull(notes),
        location: Value.absentIfNull(location),
        startAt: startAt,
        endAt: Value.absentIfNull(endAt),
        isAllDay: Value(isAllDay),
        recurrence: Value(recurrence.repeats ? recurrence.encode() : null),
      ),
    );
  }

  Future<void> editEvent({
    required Event original,
    required String title,
    String? notes,
    String? location,
    required DateTime startAt,
    DateTime? endAt,
    bool isAllDay = false,
    Recurrence recurrence = const Recurrence.none(),
  }) {
    return _db.updateEvent(
      original
          .copyWith(
            title: title,
            notes: Value(notes),
            location: Value(location),
            startAt: startAt,
            endAt: Value(endAt),
            isAllDay: isAllDay,
            recurrence: Value(recurrence.repeats ? recurrence.encode() : null),
          )
          .toCompanion(false),
    );
  }

  Future<void> deleteEvent(int id) => _db.deleteEvent(id);
}
