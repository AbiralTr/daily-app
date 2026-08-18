import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The day currently shown on the home/calendar screens. Defaults to today.
/// Lives at the core level since both the tasks and events features read it.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
