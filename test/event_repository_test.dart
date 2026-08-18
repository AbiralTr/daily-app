import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_app/core/database/app_database.dart';
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

    final events = await repository
        .watchEventsForDate(DateTime(2026, 1, 5))
        .first;

    expect(events, hasLength(1));
    expect(events.single.title, 'Dentist');
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
      final events = await repository.watchEventsForDate(day).first;
      expect(events, hasLength(1), reason: 'expected a hit on $day');
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

  test('deleteEvent removes it', () async {
    final id = await repository.addEvent(
      title: 'One-off',
      startAt: DateTime(2026, 1, 5),
    );

    await repository.deleteEvent(id);

    final events = await repository
        .watchEventsForDate(DateTime(2026, 1, 5))
        .first;
    expect(events, isEmpty);
  });

  test('editEvent updates fields on the existing row', () async {
    await repository.addEvent(title: 'Draft', startAt: DateTime(2026, 1, 5));
    final original =
        (await repository.watchEventsForDate(DateTime(2026, 1, 5)).first)
            .single;

    await repository.editEvent(
      original: original,
      title: 'Final',
      startAt: DateTime(2026, 1, 6, 10),
      location: 'Office',
    );

    final updated =
        (await repository.watchEventsForDate(DateTime(2026, 1, 6)).first)
            .single;
    expect(updated.id, original.id);
    expect(updated.title, 'Final');
    expect(updated.location, 'Office');
  });
}
