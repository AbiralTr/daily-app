import 'package:drift/drift.dart';

/// A single task the user wants to get done on (or by) a given day.
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text().withLength(min: 1, max: 200)();

  TextColumn get notes => text().nullable()();

  /// The day (and, optionally, time) this task is due.
  DateTimeColumn get dueDate => dateTime()();

  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  /// Whether this task repeats every day rather than being a one-off.
  BoolColumn get isDaily => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
