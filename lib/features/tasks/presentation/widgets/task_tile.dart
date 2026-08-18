import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/widgets/meta_chip.dart';
import '../../domain/task_priority.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final priority = TaskPriority.fromValue(task.priority);
    final hasTimeOfDay = task.dueDate.hour != 0 || task.dueDate.minute != 0;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CheckBubble(
                    done: task.isDone,
                    color: priority.color,
                    onTap: onToggle,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isDone
                                ? scheme.onSurfaceVariant
                                : scheme.onSurface,
                          ),
                        ),
                        if (task.notes case final notes?
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
                            if (hasTimeOfDay)
                              MetaChip(
                                icon: Icons.schedule,
                                label: DateFormat.jm().format(task.dueDate),
                              ),
                            if (task.isDaily)
                              const MetaChip(
                                icon: Icons.repeat,
                                label: 'Daily',
                              ),
                            if (task.category case final category?
                                when category.isNotEmpty)
                              MetaChip(
                                icon: Icons.label_outline,
                                label: category,
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
      ),
    );
  }
}

class _CheckBubble extends StatelessWidget {
  const _CheckBubble({
    required this.done,
    required this.color,
    required this.onTap,
  });

  final bool done;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? scheme.primary : Colors.transparent,
            border: Border.all(color: done ? scheme.primary : color, width: 2),
          ),
          child: done
              ? Icon(Icons.check, size: 15, color: scheme.onPrimary)
              : null,
        ),
      ),
    );
  }
}
