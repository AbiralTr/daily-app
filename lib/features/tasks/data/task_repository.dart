import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/task_priority.dart';

/// Read/write access to tasks. Screens should go through this rather than
/// touching [AppDatabase] directly.
class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  Stream<List<Task>> watchTasksForDate(DateTime date) =>
      _db.watchTasksForDate(date);

  Stream<List<Task>> watchOverdueTasks(DateTime date) =>
      _db.watchOverdueTasks(date);

  Stream<List<Task>> watchAllTasks() => _db.watchAllTasks();

  Future<Task?> getTask(int id) => _db.getTask(id);

  Future<int> addTask({
    required String title,
    String? notes,
    required DateTime dueDate,
    bool isDaily = false,
    TaskPriority priority = TaskPriority.medium,
    String? category,
  }) {
    return _db.insertTask(
      TasksCompanion.insert(
        title: title,
        notes: Value.absentIfNull(notes),
        dueDate: dueDate,
        isDaily: Value(isDaily),
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
    bool isDaily = false,
    TaskPriority priority = TaskPriority.medium,
    String? category,
  }) {
    return _db.updateTask(
      original
          .copyWith(
            title: title,
            notes: Value(notes),
            dueDate: dueDate,
            isDaily: isDaily,
            priority: priority.index,
            category: Value(category),
          )
          .toCompanion(false),
    );
  }

  Future<void> toggleDone(Task task) => _db.setDone(task.id, !task.isDone);

  Future<void> deleteTask(int id) => _db.deleteTask(id);
}
