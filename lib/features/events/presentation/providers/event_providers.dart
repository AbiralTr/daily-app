import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/selected_date_provider.dart';
import '../../data/event_repository.dart';
import '../../domain/event_occurrence.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(appDatabaseProvider));
});

final eventsForSelectedDateProvider = StreamProvider<List<EventOccurrence>>((
  ref,
) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(eventRepositoryProvider).watchEventsForDate(date);
});

/// Every event, kept around for the calendar's day markers.
final allEventsProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchAllEvents();
});

final eventByIdProvider = FutureProvider.family<Event?, int>((ref, id) {
  return ref.watch(eventRepositoryProvider).getEvent(id);
});
