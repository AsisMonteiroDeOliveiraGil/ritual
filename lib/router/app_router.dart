import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ritual/features/habits/presentation/screens/habit_detail_screen.dart';
import 'package:ritual/features/habits/presentation/screens/add_habit_category_screen.dart';
import 'package:ritual/features/habits/presentation/screens/habit_eval_type_screen.dart';
import 'package:ritual/features/habits/presentation/screens/habit_define_screen.dart';
import 'package:ritual/features/habits/presentation/screens/habit_frequency_screen.dart';
import 'package:ritual/features/habits/presentation/screens/habit_schedule_screen.dart';
import 'package:ritual/features/habits/presentation/screens/habits_screen.dart';
import 'package:ritual/features/habits/presentation/screens/gym_screen.dart';
import 'package:ritual/features/habits/presentation/screens/settings_screen.dart';
import 'package:ritual/features/habits/presentation/screens/stats_screen.dart';
import 'package:ritual/features/habits/presentation/screens/today_screen.dart';
import 'package:ritual/features/habits/presentation/providers/today_selected_date_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/today',
    routes: [
      ShellRoute(
        builder: (context, state, child) => _ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/today',
            builder: (context, state) => const TodayScreen(),
          ),
          GoRoute(
            path: '/habits',
            builder: (context, state) => const HabitsScreen(),
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: '/gym',
            builder: (context, state) => const GymScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/habit/new',
        builder: (context, state) => const AddHabitCategoryScreen(),
      ),
      GoRoute(
        path: '/habit/new/eval',
        builder: (context, state) => const HabitEvalTypeScreen(),
      ),
      GoRoute(
        path: '/habit/new/define',
        builder: (context, state) => const HabitDefineScreen(),
      ),
      GoRoute(
        path: '/habit/new/frequency',
        builder: (context, state) => const HabitFrequencyScreen(),
      ),
      GoRoute(
        path: '/habit/new/schedule',
        builder: (context, state) => const HabitScheduleScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/habit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return HabitDetailScreen(habitId: id);
        },
      ),
    ],
  );
}

class _ShellScaffold extends StatelessWidget {
  final Widget child;

  const _ShellScaffold({required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/habits')) return 1;
    if (location.startsWith('/stats')) return 2;
    if (location.startsWith('/gym')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (value) {
          switch (value) {
            case 0:
              if (location.startsWith('/today')) {
                final now = DateTime.now();
                ProviderScope.containerOf(context)
                    .read(todaySelectedDateProvider.notifier)
                    .state = DateTime(now.year, now.month, now.day);
              }
              context.go('/today');
              break;
            case 1:
              context.go('/habits');
              break;
            case 2:
              context.go('/stats');
              break;
            case 3:
              context.go('/gym');
              break;
          }
        },
        backgroundColor: const Color(0xFF151515),
        selectedItemColor: const Color(0xFFC63C54),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Hoy'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Hábitos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Gimnasio',
          ),
        ],
      ),
    );
  }
}
