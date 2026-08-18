import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/events_table.dart';
import 'tables/task_completions_table.dart';
import 'tables/tasks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks, TaskCompletions, Events])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tasks, tasks.completedAt);
        await m.addColumn(tasks, tasks.priority);
        await m.addColumn(tasks, tasks.category);
      }
      if (from < 3) {
        await m.createTable(events);
      }
      if (from < 4) {
        await m.addColumn(tasks, tasks.recurrence);
        // `isDaily` only existed pre-v4; carry its value into the new
        // `recurrence` column before dropping it.
        await customStatement(
          "UPDATE tasks SET recurrence = 'daily' WHERE is_daily = 1",
        );
        await m.dropColumn(tasks, 'is_daily');
        await m.addColumn(events, events.recurrence);
        await m.createTable(taskCompletions);
      }
    },
  );

  // ---- Tasks ----

  /// One-off tasks due on [date], plus (recurrence, isDone) needed to build
  /// a full [TaskOccurrence] list — done in the repository layer, which
  /// also decodes [Recurrence] and filters which recurring tasks actually
  /// occur on [date].
  Stream<List<(Task, bool completedAsOccurrence)>> watchTasksForDate(
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final query =
        select(tasks).join([
          leftOuterJoin(
            taskCompletions,
            taskCompletions.taskId.equalsExp(tasks.id) &
                taskCompletions.date.equals(start),
          ),
        ])..where(
          (tasks.recurrence.isNull() &
                  tasks.dueDate.isBiggerOrEqualValue(start) &
                  tasks.dueDate.isSmallerThanValue(end)) |
              (tasks.recurrence.isNotNull() &
                  tasks.dueDate.isSmallerThanValue(end)),
        );

    return query.watch().map((rows) {
      return rows.map((row) {
        final task = row.readTable(tasks);
        final completion = row.readTableOrNull(taskCompletions);
        return (task, completion != null);
      }).toList();
    });
  }

  /// Unfinished one-off tasks due strictly before [date]. Recurring tasks
  /// are excluded — a repeating task never "piles up" as overdue, it just
  /// reappears on its own schedule.
  Stream<List<Task>> watchOverdueTasks(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    return (select(tasks)
          ..where(
            (t) =>
                t.recurrence.isNull() &
                t.dueDate.isSmallerThanValue(start) &
                t.isDone.equals(false),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.dueDate)]))
        .watch();
  }

  /// Every task, used to build calendar markers (the caller works out which
  /// days a recurring task actually lands on).
  Stream<List<Task>> watchAllTasks() => select(tasks).watch();

  Future<Task?> getTask(int id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<bool> updateTask(TasksCompanion task) => update(tasks).replace(task);

  Future<int> deleteTask(int id) {
    // Foreign keys cascade this too, but that pragma is best-effort — clean
    // up completions explicitly so a deleted task never leaves orphans.
    return transaction(() async {
      await (delete(taskCompletions)..where((c) => c.taskId.equals(id))).go();
      return (delete(tasks)..where((t) => t.id.equals(id))).go();
    });
  }

  /// One-off task completion lives on the row itself.
  Future<void> setDone(int id, bool done) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          isDone: Value(done),
          completedAt: Value(done ? DateTime.now() : null),
        ),
      );

  /// Recurring task completion is per-occurrence, tracked in a side table.
  Future<void> setOccurrenceDone(int taskId, DateTime date, bool done) async {
    final day = DateTime(date.year, date.month, date.day);
    if (done) {
      await into(taskCompletions).insertOnConflictUpdate(
        TaskCompletionsCompanion.insert(taskId: taskId, date: day),
      );
    } else {
      await (delete(
        taskCompletions,
      )..where((c) => c.taskId.equals(taskId) & c.date.equals(day))).go();
    }
  }

  // ---- Events ----

  /// One-off events overlapping [date], plus every recurring event (whose
  /// occurrence-on-[date] check happens in the repository).
  Stream<List<Event>> watchEventsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(events)..where(
          (e) =>
              (e.recurrence.isNull() &
                  e.startAt.isSmallerThanValue(end) &
                  (e.endAt.isBiggerOrEqualValue(start) |
                      (e.endAt.isNull() &
                          e.startAt.isBiggerOrEqualValue(start)))) |
              (e.recurrence.isNotNull() & e.startAt.isSmallerThanValue(end)),
        ))
        .watch();
  }

  /// Every event, used to build calendar markers.
  Stream<List<Event>> watchAllEvents() => select(events).watch();

  Future<Event?> getEvent(int id) =>
      (select(events)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<int> insertEvent(EventsCompanion event) => into(events).insert(event);

  Future<bool> updateEvent(EventsCompanion event) =>
      update(events).replace(event);

  Future<int> deleteEvent(int id) =>
      (delete(events)..where((e) => e.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'daily_app.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (database) => database.execute('PRAGMA foreign_keys = ON;'),
    );
  });
}
