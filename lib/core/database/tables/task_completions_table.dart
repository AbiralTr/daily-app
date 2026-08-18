import 'package:drift/drift.dart';

import 'tasks_table.dart';

/// Marks a single occurrence of a recurring task as done. A one-off task
/// (no recurrence) tracks completion directly on its `Tasks` row instead —
/// this table only matters once a task repeats and each occurrence needs
/// its own independent checkbox state.
class TaskCompletions extends Table {
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();

  /// Day-only (midnight) date of the occurrence that was completed.
  DateTimeColumn get date => dateTime()();

  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {taskId, date};
}
