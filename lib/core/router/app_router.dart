import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/events/presentation/screens/event_editor_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tasks/presentation/screens/home_screen.dart';
import '../../features/tasks/presentation/screens/task_editor_screen.dart';
import 'app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              builder: (context, state) => const CalendarScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    // Full-screen routes (task/event editors) live on the root navigator so
    // they cover the bottom nav rather than swapping inside the shell.
    GoRoute(
      path: '/task/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TaskEditorScreen(),
    ),
    GoRoute(
      path: '/task/:id/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          TaskEditorScreen(taskId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/event/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EventEditorScreen(),
    ),
    GoRoute(
      path: '/event/:id/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          EventEditorScreen(eventId: int.parse(state.pathParameters['id']!)),
    ),
  ],
);
