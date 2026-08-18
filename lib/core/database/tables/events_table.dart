import 'package:drift/drift.dart';

/// Something happening at (or over) a specific time — an appointment,
/// meeting, or reminder to track, as opposed to a [Tasks] row, which is
/// work to check off.
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 1, max: 200)();

  TextColumn get notes => text().nullable()();

  TextColumn get location => text().nullable()();

  DateTimeColumn get startAt => dateTime()();

  /// Null for an event with no set end time.
  DateTimeColumn get endAt => dateTime().nullable()();

  BoolColumn get isAllDay => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
