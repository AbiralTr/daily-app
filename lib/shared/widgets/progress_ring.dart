import 'package:flutter/material.dart';

/// A ring showing `done / total`, with the fraction in the middle.
/// Reads as an empty ring rather than a full one when there's nothing to do.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.done,
    required this.total,
    this.size = 56,
  });

  final int done;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = total == 0 ? 0.0 : done / total;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: total == 0 ? 0 : 1,
              strokeWidth: 5,
              color: scheme.surfaceContainerHighest,
            ),
          ),
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              tween: Tween(begin: 0, end: fraction),
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                color: scheme.primary,
              ),
            ),
          ),
          Text(
            '$done/$total',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
