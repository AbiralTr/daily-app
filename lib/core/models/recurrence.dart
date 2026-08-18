/// How a task or event repeats. Shared between the two features since both
/// offer the same choice: never, every day, or specific days of the week.
enum RecurrenceFrequency { none, daily, weekly }

class Recurrence {
  const Recurrence.none()
    : frequency = RecurrenceFrequency.none,
      weekdays = const {};

  const Recurrence.daily()
    : frequency = RecurrenceFrequency.daily,
      weekdays = const {};

  /// [weekdays] uses [DateTime.weekday] numbering: 1 = Monday, 7 = Sunday.
  const Recurrence.weekly(this.weekdays)
    : frequency = RecurrenceFrequency.weekly;

  final RecurrenceFrequency frequency;
  final Set<int> weekdays;

  bool get repeats => frequency != RecurrenceFrequency.none;

  /// Whether this recurrence produces an occurrence on [date]. Callers are
  /// responsible for also checking [date] isn't before the item's anchor
  /// date — a recurrence has no opinion on when it started.
  bool occursOn(DateTime date) {
    switch (frequency) {
      case RecurrenceFrequency.none:
        return false;
      case RecurrenceFrequency.daily:
        return true;
      case RecurrenceFrequency.weekly:
        return weekdays.contains(date.weekday);
    }
  }

  String get label {
    switch (frequency) {
      case RecurrenceFrequency.none:
        return 'Does not repeat';
      case RecurrenceFrequency.daily:
        return 'Every day';
      case RecurrenceFrequency.weekly:
        if (weekdays.length == 5 &&
            !weekdays.contains(DateTime.saturday) &&
            !weekdays.contains(DateTime.sunday)) {
          return 'Every weekday';
        }
        if (weekdays.length == 7) return 'Every day';
        return 'Weekly on ${_weekdayNames(weekdays)}';
    }
  }

  /// Compact storage format for a nullable TEXT column:
  /// `null`/`"none"` → no repeat, `"daily"`, or `"weekly:1,3,5"`.
  String encode() {
    switch (frequency) {
      case RecurrenceFrequency.none:
        return 'none';
      case RecurrenceFrequency.daily:
        return 'daily';
      case RecurrenceFrequency.weekly:
        final sorted = weekdays.toList()..sort();
        return 'weekly:${sorted.join(',')}';
    }
  }

  static Recurrence decode(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'none') {
      return const Recurrence.none();
    }
    if (raw == 'daily') return const Recurrence.daily();
    if (raw.startsWith('weekly:')) {
      final days = raw
          .substring('weekly:'.length)
          .split(',')
          .where((s) => s.isNotEmpty)
          .map(int.parse)
          .toSet();
      if (days.isEmpty) return const Recurrence.none();
      return Recurrence.weekly(days);
    }
    return const Recurrence.none();
  }

  static const weekdayOrder = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  static const weekdayShortNames = {
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };

  static String _weekdayNames(Set<int> weekdays) {
    final sorted = weekdays.toList()..sort();
    return sorted.map((d) => weekdayShortNames[d]).join(', ');
  }
}
