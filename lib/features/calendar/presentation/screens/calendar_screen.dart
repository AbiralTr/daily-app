import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../events/presentation/providers/event_providers.dart';
import '../../../events/presentation/widgets/event_tile.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/presentation/widgets/task_tile.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;

  DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  void initState() {
    super.initState();
    _focusedDay = ref.read(selectedDateProvider);
  }

  Future<void> _openAddSheet() async {
    final choice = await showModalBottomSheet<_AddChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('New task'),
              subtitle: const Text('Something to do and check off'),
              onTap: () => Navigator.pop(context, _AddChoice.task),
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('New event'),
              subtitle: const Text('Something happening at a set time'),
              onTap: () => Navigator.pop(context, _AddChoice.event),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    context.push(choice == _AddChoice.task ? '/task/new' : '/event/new');
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final tasksAsync = ref.watch(tasksForSelectedDateProvider);
    final eventsAsync = ref.watch(eventsForSelectedDateProvider);
    final allTasksAsync = ref.watch(allTasksProvider);
    final allEventsAsync = ref.watch(allEventsProvider);
    final taskRepository = ref.read(taskRepositoryProvider);
    final eventRepository = ref.read(eventRepositoryProvider);

    final allTasks = allTasksAsync.valueOrNull ?? const [];
    final allEvents = allEventsAsync.valueOrNull ?? const [];

    bool dayHasMarker(DateTime day) {
      final d = _dayOnly(day);
      return allTasks.any((t) => taskRepository.occursOn(t, d)) ||
          allEvents.any((e) => eventRepository.occursOn(e, d));
    }

    final hasEvents = eventsAsync.maybeWhen(
      data: (events) => events.isNotEmpty,
      orElse: () => false,
    );
    final hasTasks = tasksAsync.maybeWhen(
      data: (occurrences) => occurrences.isNotEmpty,
      orElse: () => false,
    );
    final isLoading = eventsAsync.isLoading || tasksAsync.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, selectedDate),
            eventLoader: (day) => dayHasMarker(day) ? const [1] : const [],
            onDaySelected: (selectedDay, focusedDay) {
              setState(() => _focusedDay = focusedDay);
              ref.read(selectedDateProvider.notifier).state = _dayOnly(
                selectedDay,
              );
            },
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              outsideDaysVisible: false,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : !hasEvents && !hasTasks
                ? const Center(child: Text('Nothing on this day.'))
                : ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    children: [
                      if (hasEvents) ...[
                        const _SectionLabel('Events'),
                        for (final occurrence in eventsAsync.value!)
                          EventTile(
                            occurrence: occurrence,
                            onTap: () => context.push(
                              '/event/${occurrence.event.id}/edit',
                            ),
                          ),
                      ],
                      if (hasTasks) ...[
                        const _SectionLabel('Tasks'),
                        for (final occurrence in tasksAsync.value!)
                          TaskTile(
                            occurrence: occurrence,
                            onToggle: () =>
                                taskRepository.toggleOccurrence(occurrence),
                            onDelete: () =>
                                taskRepository.deleteTask(occurrence.task.id),
                            onTap: () => context.push(
                              '/task/${occurrence.task.id}/edit',
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum _AddChoice { task, event }

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
