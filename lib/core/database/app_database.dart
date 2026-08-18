import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/tasks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tasks, tasks.completedAt);
        await m.addColumn(tasks, tasks.priority);
        await m.addColumn(tasks, tasks.category);
      }
    },
  );

  /// All tasks due on [date] (ignoring time-of-day), earliest first.
  Stream<List<Task>> watchTasksForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(tasks)
          ..where(
            (t) =>
                t.dueDate.isBiggerOrEqualValue(start) &
                t.dueDate.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.dueDate)]))
        .watch();
  }

  /// Unfinished tasks due strictly before [date] (ignoring time-of-day).
  Stream<List<Task>> watchOverdueTasks(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    return (select(tasks)
          ..where(
            (t) => t.dueDate.isSmallerThanValue(start) & t.isDone.equals(false),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.dueDate)]))
        .watch();
  }

  /// Every task, used to build calendar markers.
  Stream<List<Task>> watchAllTasks() => select(tasks).watch();

  Future<Task?> getTask(int id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<bool> updateTask(TasksCompanion task) => update(tasks).replace(task);

  Future<int> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  Future<void> setDone(int id, bool done) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          isDone: Value(done),
          completedAt: Value(done ? DateTime.now() : null),
        ),
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'daily_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
