import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_bottom_nav.dart';

/// The persistent scaffold + bottom nav for the three top-level tabs.
///
/// Wrapping the tab bodies in a [StatefulShellRoute] (rather than three
/// separate top-level `GoRoute`s that each drew their own bottom nav) means
/// the bar itself now lives outside any animated route transition — tapping
/// a tab swaps the body via an `IndexedStack` instantly, instead of the
/// whole page (bottom nav included) re-entering with a page transition.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        selectedIndex: navigationShell.currentIndex,
        onSelect: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
