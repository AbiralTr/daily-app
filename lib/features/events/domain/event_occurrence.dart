import '../../../core/database/app_database.dart';

/// A single day's instance of an event. For a one-off event this carries
/// the row's own `startAt`/`endAt`; for a recurring event those are the
/// template's time-of-day combined with whichever date is being viewed.
class EventOccurrence {
  const EventOccurrence({
    required this.event,
    required this.startAt,
    required this.endAt,
  });

  final Event event;
  final DateTime startAt;
  final DateTime? endAt;
}
