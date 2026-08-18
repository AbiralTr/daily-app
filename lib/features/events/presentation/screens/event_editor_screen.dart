import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/models/recurrence.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/providers/selected_date_provider.dart';
import '../../../../shared/widgets/recurrence_picker.dart';
import '../providers/event_providers.dart';

/// Handles both creating an event (`eventId == null`) and editing an
/// existing one (`eventId` set, fields pre-filled from the database).
class EventEditorScreen extends ConsumerStatefulWidget {
  const EventEditorScreen({super.key, this.eventId});

  final int? eventId;

  @override
  ConsumerState<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends ConsumerState<EventEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

  late DateTime _startAt;
  DateTime? _endAt;
  bool _isAllDay = false;
  Recurrence _recurrence = const Recurrence.none();

  Event? _original;
  bool _hydrated = false;

  bool get _isEditing => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    // Default a new event to 9am on whatever day the user was looking at.
    final selected = ref.read(selectedDateProvider);
    _startAt = DateTime(selected.year, selected.month, selected.day, 9);
  }

  void _hydrate(Event event) {
    if (_hydrated) return;
    _hydrated = true;
    _original = event;
    _titleController.text = event.title;
    _notesController.text = event.notes ?? '';
    _locationController.text = event.location ?? '';
    _startAt = event.startAt;
    _endAt = event.endAt;
    _isAllDay = event.isAllDay;
    _recurrence = Recurrence.decode(event.recurrence);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    var time = TimeOfDay.fromDateTime(_startAt);
    if (!_isAllDay) {
      final picked = await showTimePicker(context: context, initialTime: time);
      if (!mounted) return;
      if (picked != null) time = picked;
    }

    setState(() {
      _startAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (_endAt != null && !_endAt!.isAfter(_startAt)) {
        _endAt = _startAt.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endAt ?? _startAt.add(const Duration(hours: 1)),
      firstDate: _startAt,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    var time = TimeOfDay.fromDateTime(
      _endAt ?? _startAt.add(const Duration(hours: 1)),
    );
    if (!_isAllDay) {
      final picked = await showTimePicker(context: context, initialTime: time);
      if (!mounted) return;
      if (picked != null) time = picked;
    }

    setState(() {
      _endAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repository = ref.read(eventRepositoryProvider);
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();
    final location = _locationController.text.trim();
    final startAt = _isAllDay
        ? DateTime(_startAt.year, _startAt.month, _startAt.day)
        : _startAt;
    final endAt = _isAllDay ? null : _endAt;
    final recurrence = _recurrence;

    final int eventId;
    if (_isEditing && _original != null) {
      eventId = _original!.id;
      await repository.editEvent(
        original: _original!,
        title: title,
        notes: notes.isEmpty ? null : notes,
        location: location.isEmpty ? null : location,
        startAt: startAt,
        endAt: endAt,
        isAllDay: _isAllDay,
        recurrence: recurrence,
      );
    } else {
      eventId = await repository.addEvent(
        title: title,
        notes: notes.isEmpty ? null : notes,
        location: location.isEmpty ? null : location,
        startAt: startAt,
        endAt: endAt,
        isAllDay: _isAllDay,
        recurrence: recurrence,
      );
    }

    if (_isAllDay) {
      // No specific instant to remind at.
      await NotificationService.instance.cancelEventReminders(eventId);
    } else {
      await NotificationService.instance.scheduleEventReminder(
        eventId: eventId,
        title: title,
        body: location.isEmpty ? null : location,
        anchor: startAt,
        recurrence: recurrence,
      );
    }

    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final original = _original;
    if (original == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
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

    await ref.read(eventRepositoryProvider).deleteEvent(original.id);
    await NotificationService.instance.cancelEventReminders(original.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && !_hydrated) {
      final asyncEvent = ref.watch(eventByIdProvider(widget.eventId!));
      return asyncEvent.when(
        data: (event) {
          if (event == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Event not found.')),
            );
          }
          _hydrate(event);
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
    final dateFormat = _isAllDay
        ? DateFormat.yMMMEd()
        : DateFormat.yMMMEd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit event' : 'New event'),
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
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('All day'),
              value: _isAllDay,
              onChanged: (value) => setState(() => _isAllDay = value),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Starts'),
              subtitle: Text(dateFormat.format(_startAt)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickStart,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ends'),
              subtitle: Text(
                _endAt == null ? 'No end time' : dateFormat.format(_endAt!),
              ),
              trailing: _endAt == null
                  ? const Icon(Icons.calendar_today_outlined)
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear end time',
                      onPressed: () => setState(() => _endAt = null),
                    ),
              onTap: _pickEnd,
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
