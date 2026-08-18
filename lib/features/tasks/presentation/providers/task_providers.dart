import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(appDatabaseProvider));
});

/// The day currently shown on the home/calendar screens. Defaults to today.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final tasksForSelectedDateProvider = StreamProvider<List<Task>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(taskRepositoryProvider).watchTasksForDate(date);
});
