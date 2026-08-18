import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_app/core/database/app_database.dart';
import 'package:daily_app/core/models/recurrence.dart';
import 'package:daily_app/features/tasks/data/task_repository.dart';

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

    final occurrences = await repository.watchTasksForDate(dueDate).first;

    expect(occurrences, hasLength(1));
    expect(occurrences.single.task.title, 'Water the plants');
    expect(occurrences.single.isDone, isFalse);
  });

  test(
    'toggleOccurrence flips a one-off task and stamps/clears completedAt',
    () async {
      await repository.addTask(title: 'Stretch', dueDate: DateTime(2026, 1, 5));
      final occurrence =
          (await repository.watchTasksForDate(DateTime(2026, 1, 5)).first)
              .single;

      await repository.toggleOccurrence(occurrence);
      final done =
          (await repository.watchTasksForDate(DateTime(2026, 1, 5)).first)
              .single;
      expect(done.isDone, isTrue);
      expect(done.task.completedAt, isNotNull);

      await repository.toggleOccurrence(done);
      final undone =
          (await repository.watchTasksForDate(DateTime(2026, 1, 5)).first)
              .single;
      expect(undone.isDone, isFalse);
      expect(undone.task.completedAt, isNull);
    },
  );

  test(
    'a daily task occurs every day and each day completes independently',
    () async {
      await repository.addTask(
        title: 'Meditate',
        dueDate: DateTime(2026, 1, 5, 7),
        recurrence: const Recurrence.daily(),
      );

      for (final day in [
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 6),
        DateTime(2026, 1, 20),
      ]) {
        final occurrences = await repository.watchTasksForDate(day).first;
        expect(
          occurrences,
          hasLength(1),
          reason: 'expected an instance on $day',
        );
        expect(occurrences.single.isDone, isFalse);
      }

      // It shouldn't appear before its anchor date.
      expect(
        await repository.watchTasksForDate(DateTime(2026, 1, 4)).first,
        isEmpty,
      );

      // Completing one day's occurrence doesn't affect another day's.
      final jan5 =
          (await repository.watchTasksForDate(DateTime(2026, 1, 5)).first)
              .single;
      await repository.toggleOccurrence(jan5);

      final jan5After =
          (await repository.watchTasksForDate(DateTime(2026, 1, 5)).first)
              .single;
      final jan6 =
          (await repository.watchTasksForDate(DateTime(2026, 1, 6)).first)
              .single;
      expect(jan5After.isDone, isTrue);
      expect(jan6.isDone, isFalse);
    },
  );

  test('a weekly task only occurs on its selected weekdays', () async {
    // Jan 5 2026 is a Monday.
    await repository.addTask(
      title: 'Gym',
      dueDate: DateTime(2026, 1, 5, 18),
      recurrence: Recurrence.weekly({DateTime.monday, DateTime.wednesday}),
    );

    expect(
      (await repository.watchTasksForDate(DateTime(2026, 1, 5)).first).length,
      1,
    ); // Monday
    expect(
      (await repository.watchTasksForDate(DateTime(2026, 1, 7)).first).length,
      1,
    ); // Wednesday
    expect(
      await repository.watchTasksForDate(DateTime(2026, 1, 6)).first,
      isEmpty,
    ); // Tuesday
  });

  test('deleteTask removes it and its completions', () async {
    final id = await repository.addTask(
      title: 'One-off',
      dueDate: DateTime(2026, 1, 5),
    );

    await repository.deleteTask(id);

    final occurrences = await repository
        .watchTasksForDate(DateTime(2026, 1, 5))
        .first;
    expect(occurrences, isEmpty);
  });

  test('watchOverdueTasks only returns unfinished one-off tasks before the given day', () async {
    await repository.addTask(
      title: 'Past unfinished',
      dueDate: DateTime(2026, 1, 1),
    );
    await repository.addTask(
      title: 'Past finished',
      dueDate: DateTime(2026, 1, 2),
    );
    await repository.addTask(title: 'Future', dueDate: DateTime(2026, 1, 10));
    await repository.addTask(
      title: 'Recurring, never overdue',
      dueDate: DateTime(2026, 1, 1),
      recurrence: const Recurrence.daily(),
    );

    final pastDone =
        (await repository.watchTasksForDate(DateTime(2026, 1, 2)).first)
            .firstWhere((o) => o.task.title == 'Past finished');
    await repository.toggleOccurrence(pastDone);

    final overdue = await repository
        .watchOverdueTasks(DateTime(2026, 1, 5))
        .first;

    expect(overdue.map((t) => t.title), ['Past unfinished']);
  });

  test('editTask updates fields on the existing row', () async {
    await repository.addTask(
      title: 'Draft',
      dueDate: DateTime(2026, 1, 5),
      recurrence: const Recurrence.none(),
    );
    final original =
        (await repository.watchTasksForDate(DateTime(2026, 1, 5)).first)
            .single
            .task;

    await repository.editTask(
      original: original,
      title: 'Final',
      dueDate: DateTime(2026, 1, 6),
      recurrence: Recurrence.weekly({DateTime.tuesday}),
      category: 'Work',
    );

    // Jan 6 2026 is a Tuesday.
    final updated =
        (await repository.watchTasksForDate(DateTime(2026, 1, 6)).first).single;
    expect(updated.task.id, original.id);
    expect(updated.task.title, 'Final');
    expect(updated.task.category, 'Work');
    expect(
      Recurrence.decode(updated.task.recurrence).frequency,
      RecurrenceFrequency.weekly,
    );
  });
}
