import 'package:flutter/material.dart';

/// Central place for the app's look and feel. Kept deliberately small for
/// now — expand as screens land.
abstract final class AppTheme {
  static const Color _seed = Colors.teal;

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: _seed),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: Brightness.dark,
      ),
    );
  }
}
