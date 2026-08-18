import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/recurrence.dart';
import '../domain/task_occurrence.dart';
import '../domain/task_priority.dart';

/// Read/write access to tasks. Screens should go through this rather than
/// touching [AppDatabase] directly.
class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  /// Occurrences landing on [date] — one-off tasks due that day, plus any
  /// recurring task whose schedule includes it.
  Stream<List<TaskOccurrence>> watchTasksForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return _db.watchTasksForDate(day).map((rows) {
      final occurrences = <TaskOccurrence>[];
      for (final (task, completedAsOccurrence) in rows) {
        final recurrence = Recurrence.decode(task.recurrence);
        if (recurrence.repeats) {
          if (!recurrence.occursOn(day)) continue;
          occurrences.add(
            TaskOccurrence(
              task: task,
              occurrenceDate: day,
              isDone: completedAsOccurrence,
            ),
          );
        } else {
          occurrences.add(
            TaskOccurrence(
              task: task,
              occurrenceDate: day,
              isDone: task.isDone,
            ),
          );
        }
      }
      occurrences.sort(
        (a, b) =>
            _timeOfDayMinutes(a.task.dueDate)
                .compareTo(_timeOfDayMinutes(b.task.dueDate)),
      );
      return occurrences;
    });
  }

  static int _timeOfDayMinutes(DateTime dateTime) =>
      dateTime.hour * 60 + dateTime.minute;

  Stream<List<Task>> watchOverdueTasks(DateTime date) =>
      _db.watchOverdueTasks(date);

  Stream<List<Task>> watchAllTasks() => _db.watchAllTasks();

  /// Whether the recurring task in [task] occurs on [date] at all (used by
  /// the calendar to decide whether to mark that day).
  bool occursOn(Task task, DateTime date) {
    final recurrence = Recurrence.decode(task.recurrence);
    final anchor = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
    );
    final day = DateTime(date.year, date.month, date.day);
    if (recurrence.repeats) {
      return !day.isBefore(anchor) && recurrence.occursOn(day);
    }
    return day == anchor;
  }

  Future<Task?> getTask(int id) => _db.getTask(id);

  Future<int> addTask({
    required String title,
    String? notes,
    required DateTime dueDate,
    Recurrence recurrence = const Recurrence.none(),
    TaskPriority priority = TaskPriority.medium,
    String? category,
  }) {
    return _db.insertTask(
      TasksCompanion.insert(
        title: title,
        notes: Value.absentIfNull(notes),
        dueDate: dueDate,
        recurrence: Value(recurrence.repeats ? recurrence.encode() : null),
        priority: Value(priority.index),
        category: Value.absentIfNull(category),
      ),
    );
  }

  Future<void> editTask({
    required Task original,
    required String title,
    String? notes,
    required DateTime dueDate,
    Recurrence recurrence = const Recurrence.none(),
    TaskPriority priority = TaskPriority.medium,
    String? category,
  }) {
    return _db.updateTask(
      original
          .copyWith(
            title: title,
            notes: Value(notes),
            dueDate: dueDate,
            recurrence: Value(recurrence.repeats ? recurrence.encode() : null),
            priority: priority.index,
            category: Value(category),
          )
          .toCompanion(false),
    );
  }

  /// Toggles completion for one occurrence — the row itself for a one-off
  /// task, or a `TaskCompletions` entry for that date if it recurs.
  Future<void> toggleOccurrence(TaskOccurrence occurrence) {
    final recurrence = Recurrence.decode(occurrence.task.recurrence);
    if (recurrence.repeats) {
      return _db.setOccurrenceDone(
        occurrence.task.id,
        occurrence.occurrenceDate,
        !occurrence.isDone,
      );
    }
    return _db.setDone(occurrence.task.id, !occurrence.isDone);
  }

  Future<void> deleteTask(int id) => _db.deleteTask(id);
}
