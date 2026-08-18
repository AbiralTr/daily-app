import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The bottom navigation bar shared by the three top-level screens.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.selectedIndex});

  final int selectedIndex;

  static const _routes = ['/', '/calendar', '/settings'];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index != selectedIndex) context.go(_routes[index]);
      },
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
