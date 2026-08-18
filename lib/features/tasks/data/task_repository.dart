import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Read/write access to tasks. Screens should go through this rather than
/// touching [AppDatabase] directly.
class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  Stream<List<Task>> watchTasksForDate(DateTime date) =>
      _db.watchTasksForDate(date);

  Future<int> addTask({
    required String title,
    String? notes,
    required DateTime dueDate,
    bool isDaily = false,
  }) {
    return _db.insertTask(
      TasksCompanion.insert(
        title: title,
        notes: Value.absentIfNull(notes),
        dueDate: dueDate,
        isDaily: Value(isDaily),
      ),
    );
  }

  Future<void> toggleDone(Task task) => _db.setDone(task.id, !task.isDone);

  Future<void> deleteTask(int id) => _db.deleteTask(id);
}
