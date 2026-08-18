import 'package:flutter/material.dart';

/// The bottom navigation bar shared by the three top-level tabs. Purely
/// presentational — the router shell decides what selecting a tab does.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
        NavigationDestination(
          icon: Icon(Icons.calendar_month),
          label: 'Calendar',
        ),
        NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
