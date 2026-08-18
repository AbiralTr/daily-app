import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_app/core/database/app_database.dart';
import 'package:daily_app/core/models/recurrence.dart';
import 'package:daily_app/features/events/data/event_repository.dart';

void main() {
  late AppDatabase db;
  late EventRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = EventRepository(db);
  });

  tearDown(() => db.close());

  test('addEvent makes the event show up on its start date', () async {
    await repository.addEvent(
      title: 'Dentist',
      startAt: DateTime(2026, 1, 5, 14),
    );

    final occurrences = await repository
        .watchEventsForDate(DateTime(2026, 1, 5))
        .first;

    expect(occurrences, hasLength(1));
    expect(occurrences.single.event.title, 'Dentist');
  });

  test('a multi-day event shows up on every day it spans', () async {
    await repository.addEvent(
      title: 'Conference',
      startAt: DateTime(2026, 1, 5, 9),
      endAt: DateTime(2026, 1, 7, 17),
    );

    for (final day in [
      DateTime(2026, 1, 5),
      DateTime(2026, 1, 6),
      DateTime(2026, 1, 7),
    ]) {
      final occurrences = await repository.watchEventsForDate(day).first;
      expect(occurrences, hasLength(1), reason: 'expected a hit on $day');
    }

    final before = await repository
        .watchEventsForDate(DateTime(2026, 1, 4))
        .first;
    final after = await repository
        .watchEventsForDate(DateTime(2026, 1, 8))
        .first;
    expect(before, isEmpty);
    expect(after, isEmpty);
  });

  test('a point-in-time event (no end) only shows on its own day', () async {
    await repository.addEvent(
      title: 'Call mom',
      startAt: DateTime(2026, 1, 5, 18),
    );

    expect(
      await repository.watchEventsForDate(DateTime(2026, 1, 4)).first,
      isEmpty,
    );
    expect(
      await repository.watchEventsForDate(DateTime(2026, 1, 6)).first,
      isEmpty,
    );
  });

  test(
    'a daily recurring event shows the same time-of-day on every day',
    () async {
      await repository.addEvent(
        title: 'Standup',
        startAt: DateTime(2026, 1, 5, 9, 30),
        endAt: DateTime(2026, 1, 5, 9, 45),
        recurrence: const Recurrence.daily(),
      );

      for (final day in [DateTime(2026, 1, 5), DateTime(2026, 1, 12)]) {
        final occurrence =
            (await repository.watchEventsForDate(day).first).single;
        expect(occurrence.startAt.hour, 9);
        expect(occurrence.startAt.minute, 30);
        expect(occurrence.startAt.day, day.day);
        expect(occurrence.endAt!.minute, 45);
      }

      expect(
        await repository.watchEventsForDate(DateTime(2026, 1, 4)).first,
        isEmpty,
        reason: 'should not occur before its anchor date',
      );
    },
  );

  test(
    'a weekly recurring event only occurs on its selected weekdays',
    () async {
      // Jan 5 2026 is a Monday.
      await repository.addEvent(
        title: 'Team sync',
        startAt: DateTime(2026, 1, 5, 10),
        recurrence: Recurrence.weekly({DateTime.monday, DateTime.friday}),
      );

      expect(
        (await repository.watchEventsForDate(DateTime(2026, 1, 5)).first)
            .length,
        1,
      ); // Monday
      expect(
        (await repository.watchEventsForDate(DateTime(2026, 1, 9)).first)
            .length,
        1,
      ); // Friday
      expect(
        await repository.watchEventsForDate(DateTime(2026, 1, 6)).first,
        isEmpty,
      ); // Tuesday
    },
  );

  test('deleteEvent removes it', () async {
    final id = await repository.addEvent(
      title: 'One-off',
      startAt: DateTime(2026, 1, 5),
    );

    await repository.deleteEvent(id);

    final occurrences = await repository
        .watchEventsForDate(DateTime(2026, 1, 5))
        .first;
    expect(occurrences, isEmpty);
  });

  test('editEvent updates fields on the existing row', () async {
    await repository.addEvent(title: 'Draft', startAt: DateTime(2026, 1, 5));
    final original =
        (await repository.watchEventsForDate(DateTime(2026, 1, 5)).first)
            .single
            .event;

    await repository.editEvent(
      original: original,
      title: 'Final',
      startAt: DateTime(2026, 1, 6, 10),
      location: 'Office',
    );

    final updated =
        (await repository.watchEventsForDate(DateTime(2026, 1, 6)).first)
            .single;
    expect(updated.event.id, original.id);
    expect(updated.event.title, 'Final');
    expect(updated.event.location, 'Office');
  });
}
