import 'package:flutter/material.dart';

/// Mirrors the integer stored in `Tasks.priority`. Keep the declaration
/// order stable — the index is what's persisted.
enum TaskPriority {
  low,
  medium,
  high;

  factory TaskPriority.fromValue(int value) {
    if (value < 0 || value >= TaskPriority.values.length) {
      return TaskPriority.medium;
    }
    return TaskPriority.values[value];
  }

  String get label => switch (this) {
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
  };

  Color get color => switch (this) {
    TaskPriority.low => const Color(0xFF4C9F70),
    TaskPriority.medium => const Color(0xFFE0A02F),
    TaskPriority.high => const Color(0xFFD64545),
  };
}
