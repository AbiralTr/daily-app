import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/widgets/progress_ring.dart';
import '../../domain/task_occurrence.dart';
import '../providers/task_providers.dart';
import '../widgets/task_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final tasksAsync = ref.watch(tasksForSelectedDateProvider);
    final isToday = _isToday(selectedDate);
    final overdueAsync = isToday
        ? ref.watch(overdueTasksProvider)
        : const AsyncValue<List<Task>>.data([]);
    final repository = ref.read(taskRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isToday ? _greeting() : 'Tasks',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            DateFormat.yMMMEd().format(selectedDate),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    tasksAsync.maybeWhen(
                      data: (occurrences) => ProgressRing(
                        done: occurrences.where((o) => o.isDone).length,
                        total: occurrences.length,
                      ),
                      orElse: () => const SizedBox(width: 56, height: 56),
                    ),
                  ],
                ),
              ),
            ),
            ...overdueAsync.maybeWhen(
              data: (overdue) => overdue.isEmpty
                  ? const []
                  : [
                      const _SectionLabel('Overdue'),
                      SliverList.builder(
                        itemCount: overdue.length,
                        itemBuilder: (context, index) {
                          final task = overdue[index];
                          final occurrence = TaskOccurrence(
                            task: task,
                            occurrenceDate: DateTime(
                              task.dueDate.year,
                              task.dueDate.month,
                              task.dueDate.day,
                            ),
                            isDone: task.isDone,
                          );
                          return TaskTile(
                            occurrence: occurrence,
                            onToggle: () =>
                                repository.toggleOccurrence(occurrence),
                            onDelete: () => repository.deleteTask(task.id),
                            onTap: () => context.push('/task/${task.id}/edit'),
                          );
                        },
                      ),
                    ],
              orElse: () => const [],
            ),
            tasksAsync.when(
              data: (occurrences) {
                if (occurrences.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  );
                }
                return SliverList.builder(
                  itemCount: occurrences.length,
                  itemBuilder: (context, index) {
                    final occurrence = occurrences[index];
                    return TaskTile(
                      occurrence: occurrence,
                      onToggle: () => repository.toggleOccurrence(occurrence),
                      onDelete: () => repository.deleteTask(occurrence.task.id),
                      onTap: () =>
                          context.push('/task/${occurrence.task.id}/edit'),
                    );
                  },
                );
              },
              error: (error, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Something went wrong: $error')),
              ),
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/task/new'),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 48,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Nothing on the list',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "New task" to add something.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
