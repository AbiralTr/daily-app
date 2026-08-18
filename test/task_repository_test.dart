import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_app/core/database/app_database.dart';
import 'package:daily_app/features/tasks/data/task_repository.dart';
import 'package:daily_app/features/tasks/domain/task_priority.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TaskRepository(db);
  });

  tearDown(() => db.close());

  test('addTask makes the task show up on its due date', () async {
    final dueDate = DateTime(2026, 1, 5, 9);
    await repository.addTask(title: 'Water the plants', dueDate: dueDate);

    final tasks = await repository.watchTasksForDate(dueDate).first;

    expect(tasks, hasLength(1));
    expect(tasks.single.title, 'Water the plants');
    expect(tasks.single.isDone, isFalse);
  });

  test('toggleDone flips isDone and stamps/clears completedAt', () async {
    await repository.addTask(title: 'Stretch', dueDate: DateTime(2026, 1, 5));
    final task =
        (await repository.watchTasksForDate(DateTime(2026, 1, 5)).first).single;

    await repository.toggleDone(task);
    final done =
        (await repository.watchTasksForDate(DateTime(2026, 1, 5)).first).single;
    expect(done.isDone, isTrue);
    expect(done.completedAt, isNotNull);

    await repository.toggleDone(done);
    final undone =
        (await repository.watchTasksForDate(DateTime(2026, 1, 5)).first).single;
    expect(undone.isDone, isFalse);
    expect(undone.completedAt, isNull);
  });

  test('deleteTask removes it', () async {
    final id = await repository.addTask(
      title: 'One-off',
      dueDate: DateTime(2026, 1, 5),
    );

    await repository.deleteTask(id);

    final tasks = await repository
        .watchTasksForDate(DateTime(2026, 1, 5))
        .first;
    expect(tasks, isEmpty);
  });

  test(
    'watchOverdueTasks only returns unfinished tasks before the given day',
    () async {
      await repository.addTask(
        title: 'Past unfinished',
        dueDate: DateTime(2026, 1, 1),
      );
      final pastDoneId = await repository.addTask(
        title: 'Past finished',
        dueDate: DateTime(2026, 1, 2),
      );
      await repository.addTask(title: 'Future', dueDate: DateTime(2026, 1, 10));

      final pastDone =
          (await repository.watchTasksForDate(DateTime(2026, 1, 2)).first)
              .single;
      await repository.toggleDone(pastDone);
      expect(pastDone.id, pastDoneId);

      final overdue = await repository
          .watchOverdueTasks(DateTime(2026, 1, 5))
          .first;

      expect(overdue.map((t) => t.title), ['Past unfinished']);
    },
  );

  test('editTask updates fields on the existing row', () async {
    await repository.addTask(
      title: 'Draft',
      dueDate: DateTime(2026, 1, 5),
      priority: TaskPriority.low,
    );
    final original =
        (await repository.watchTasksForDate(DateTime(2026, 1, 5)).first).single;

    await repository.editTask(
      original: original,
      title: 'Final',
      dueDate: DateTime(2026, 1, 6),
      priority: TaskPriority.high,
      isDaily: true,
      category: 'Work',
    );

    final updated =
        (await repository.watchTasksForDate(DateTime(2026, 1, 6)).first).single;
    expect(updated.id, original.id);
    expect(updated.title, 'Final');
    expect(updated.priority, TaskPriority.high.index);
    expect(updated.isDaily, isTrue);
    expect(updated.category, 'Work');
  });
}
