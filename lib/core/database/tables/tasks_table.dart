import 'package:drift/drift.dart';

/// A single task the user wants to get done on (or by) a given day.
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 1, max: 200)();

  TextColumn get notes => text().nullable()();

  /// The day (and, optionally, time) this task is due.
  DateTimeColumn get dueDate => dateTime()();

  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  /// When the task was marked done. Cleared when it's un-checked.
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Encoded [Recurrence] — null/absent means a one-off task. See
  /// `Recurrence.encode`/`decode`.
  TextColumn get recurrence => text().nullable()();

  /// Index into `TaskPriority.values` (0 = low, 1 = medium, 2 = high).
  IntColumn get priority => integer().withDefault(const Constant(1))();

  /// Free-form label, e.g. "Work", "Health". Empty/absent for uncategorized.
  TextColumn get category => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
