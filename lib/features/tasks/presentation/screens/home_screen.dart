import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_bottom_nav.dart';
import '../providers/task_providers.dart';
import '../widgets/task_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final tasksAsync = ref.watch(tasksForSelectedDateProvider);

    return Scaffold(
      appBar: AppBar(title: Text(DateFormat.yMMMEd().format(selectedDate))),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text('No tasks for today.'));
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskTile(
                task: task,
                onToggle: () =>
                    ref.read(taskRepositoryProvider).toggleDone(task),
                onDelete: () =>
                    ref.read(taskRepositoryProvider).deleteTask(task.id),
              );
            },
          );
        },
        error: (error, stack) => Center(child: Text('Error: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/task/new'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 0),
    );
  }
}
