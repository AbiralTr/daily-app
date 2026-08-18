import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_bottom_nav.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('More settings coming soon.')),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 2),
    );
  }
}
