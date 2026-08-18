import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../shared/widgets/app_bottom_nav.dart';
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

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final tasksAsync = ref.watch(tasksForSelectedDateProvider);
    final allTasksAsync = ref.watch(allTasksProvider);
    final repository = ref.read(taskRepositoryProvider);

    final markedDays = allTasksAsync.maybeWhen(
      data: (tasks) => tasks.map((t) => _dayOnly(t.dueDate)).toSet(),
      orElse: () => <DateTime>{},
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, selectedDate),
            eventLoader: (day) =>
                markedDays.contains(_dayOnly(day)) ? const [1] : const [],
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
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Center(child: Text('No tasks for this day.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskTile(
                      task: task,
                      onToggle: () => repository.toggleDone(task),
                      onDelete: () => repository.deleteTask(task.id),
                      onTap: () => context.push('/task/${task.id}/edit'),
                    );
                  },
                );
              },
              error: (error, stack) => Center(child: Text('Error: $error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/task/new'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
    );
  }
}
