import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Read/write access to events. Screens should go through this rather than
/// touching [AppDatabase] directly.
class EventRepository {
  EventRepository(this._db);

  final AppDatabase _db;

  Stream<List<Event>> watchEventsForDate(DateTime date) =>
      _db.watchEventsForDate(date);

  Stream<List<Event>> watchAllEvents() => _db.watchAllEvents();

  Future<Event?> getEvent(int id) => _db.getEvent(id);

  Future<int> addEvent({
    required String title,
    String? notes,
    String? location,
    required DateTime startAt,
    DateTime? endAt,
    bool isAllDay = false,
  }) {
    return _db.insertEvent(
      EventsCompanion.insert(
        title: title,
        notes: Value.absentIfNull(notes),
        location: Value.absentIfNull(location),
        startAt: startAt,
        endAt: Value.absentIfNull(endAt),
        isAllDay: Value(isAllDay),
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
          )
          .toCompanion(false),
    );
  }

  Future<void> deleteEvent(int id) => _db.deleteEvent(id);
}
