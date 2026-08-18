import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/models/recurrence.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../shared/widgets/recurrence_picker.dart';
import '../../domain/task_priority.dart';
import '../providers/task_providers.dart';

/// Handles both creating a task (`taskId == null`) and editing an existing
/// one (`taskId` set, fields pre-filled from the database).
class TaskEditorScreen extends ConsumerStatefulWidget {
  const TaskEditorScreen({super.key, this.taskId});

  final int? taskId;

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _categoryController = TextEditingController();

  late DateTime _dueDate;
  Recurrence _recurrence = const Recurrence.none();
  TaskPriority _priority = TaskPriority.medium;

  Task? _original;
  bool _hydrated = false;

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    // Default a new task to whatever day the user was looking at (today, or
    // a day picked on the calendar). Edit mode overwrites this in _hydrate.
    _dueDate = ref.read(selectedDateProvider);
  }

  void _hydrate(Task task) {
    if (_hydrated) return;
    _hydrated = true;
    _original = task;
    _titleController.text = task.title;
    _notesController.text = task.notes ?? '';
    _categoryController.text = task.category ?? '';
    _dueDate = task.dueDate;
    _recurrence = Recurrence.decode(task.recurrence);
    _priority = TaskPriority.fromValue(task.priority);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );
    if (!mounted) return;

    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repository = ref.read(taskRepositoryProvider);
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();
    final category = _categoryController.text.trim();

    final int taskId;
    if (_isEditing && _original != null) {
      taskId = _original!.id;
      await repository.editTask(
        original: _original!,
        title: title,
        notes: notes.isEmpty ? null : notes,
        dueDate: _dueDate,
        recurrence: _recurrence,
        priority: _priority,
        category: category.isEmpty ? null : category,
      );
    } else {
      taskId = await repository.addTask(
        title: title,
        notes: notes.isEmpty ? null : notes,
        dueDate: _dueDate,
        recurrence: _recurrence,
        priority: _priority,
        category: category.isEmpty ? null : category,
      );
    }

    await NotificationService.instance.scheduleTaskReminder(
      taskId: taskId,
      title: title,
      body: notes.isEmpty ? null : notes,
      anchor: _dueDate,
      recurrence: _recurrence,
    );

    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final original = _original;
    if (original == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${original.title}" will be removed for good.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(taskRepositoryProvider).deleteTask(original.id);
    await NotificationService.instance.cancelTaskReminders(original.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && !_hydrated) {
      final asyncTask = ref.watch(taskByIdProvider(widget.taskId!));
      return asyncTask.when(
        data: (task) {
          if (task == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Task not found.')),
            );
          }
          _hydrate(task);
          return _buildForm(context);
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) =>
            Scaffold(body: Center(child: Text('Error: $error'))),
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit task' : 'New task'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
            ),
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Title is required'
                  : null,
              textInputAction: TextInputAction.next,
              autofocus: !_isEditing,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'Work, Health, Personal…',
              ),
            ),
            const SizedBox(height: 20),
            Text('Priority', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: TaskPriority.values
                  .map(
                    (priority) => ButtonSegment(
                      value: priority,
                      label: Text(priority.label),
                    ),
                  )
                  .toList(),
              selected: {_priority},
              onSelectionChanged: (selection) =>
                  setState(() => _priority = selection.first),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due'),
              subtitle: Text(DateFormat.yMMMEd().add_jm().format(_dueDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            RecurrencePicker(
              value: _recurrence,
              onChanged: (recurrence) =>
                  setState(() => _recurrence = recurrence),
            ),
          ],
        ),
      ),
    );
  }
}
