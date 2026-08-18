import '../../../core/database/app_database.dart';

/// A single day's instance of a task — for a one-off task this just wraps
/// the row itself, but for a recurring task the same [task] row can back
/// many occurrences, each with its own completion state stored separately
/// (see `TaskCompletions`).
class TaskOccurrence {
  const TaskOccurrence({
    required this.task,
    required this.occurrenceDate,
    required this.isDone,
  });

  final Task task;

  /// Day-only date this particular occurrence falls on.
  final DateTime occurrenceDate;

  final bool isDone;
}
