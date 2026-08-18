import 'package:flutter/material.dart';

import '../../core/models/recurrence.dart';

/// Lets the user choose "never / daily / weekly", with a weekday chip
/// selector that appears when weekly is chosen. Shared by the task and
/// event editors so both offer identical repeat options.
class RecurrencePicker extends StatelessWidget {
  const RecurrencePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Recurrence value;
  final ValueChanged<Recurrence> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Repeat', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<RecurrenceFrequency>(
          segments: const [
            ButtonSegment(
              value: RecurrenceFrequency.none,
              label: Text('Never'),
            ),
            ButtonSegment(
              value: RecurrenceFrequency.daily,
              label: Text('Daily'),
            ),
            ButtonSegment(
              value: RecurrenceFrequency.weekly,
              label: Text('Weekly'),
            ),
          ],
          selected: {value.frequency},
          onSelectionChanged: (selection) {
            switch (selection.first) {
              case RecurrenceFrequency.none:
                onChanged(const Recurrence.none());
              case RecurrenceFrequency.daily:
                onChanged(const Recurrence.daily());
              case RecurrenceFrequency.weekly:
                onChanged(
                  Recurrence.weekly(
                    value.weekdays.isEmpty
                        ? {DateTime.now().weekday}
                        : value.weekdays,
                  ),
                );
            }
          },
        ),
        if (value.frequency == RecurrenceFrequency.weekly) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final day in Recurrence.weekdayOrder)
                FilterChip(
                  label: Text(Recurrence.weekdayShortNames[day]!),
                  selected: value.weekdays.contains(day),
                  onSelected: (selected) {
                    final updated = Set<int>.from(value.weekdays);
                    if (selected) {
                      updated.add(day);
                    } else if (updated.length > 1) {
                      // Keep at least one day selected so "weekly" always
                      // means something.
                      updated.remove(day);
                    }
                    onChanged(Recurrence.weekly(updated));
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}
