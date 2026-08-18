import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/recurrence.dart';
import '../../../../shared/widgets/meta_chip.dart';
import '../../domain/event_occurrence.dart';

class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.occurrence, required this.onTap});

  final EventOccurrence occurrence;
  final VoidCallback onTap;

  String _timeRange() {
    final event = occurrence.event;
    if (event.isAllDay) return 'All day';
    final start = DateFormat.jm().format(occurrence.startAt);
    if (occurrence.endAt == null) return start;
    return '$start – ${DateFormat.jm().format(occurrence.endAt!)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final event = occurrence.event;
    final recurrence = Recurrence.decode(event.recurrence);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.event_outlined,
                    size: 22,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: theme.textTheme.bodyLarge),
                      if (event.notes case final notes?
                          when notes.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          MetaChip(icon: Icons.schedule, label: _timeRange()),
                          if (recurrence.repeats)
                            MetaChip(
                              icon: Icons.repeat,
                              label: recurrence.label,
                            ),
                          if (event.location case final location?
                              when location.isNotEmpty)
                            MetaChip(
                              icon: Icons.place_outlined,
                              label: location,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
