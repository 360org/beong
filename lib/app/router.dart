import 'package:beong/core/l10n/gen/app_localizations.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/widgets/responsive_scaffold.dart';
import 'package:beong/features/child_home/child_home_screen.dart';
import 'package:beong/features/onboarding/onboarding_screen.dart';
import 'package:beong/features/parent_home/parent_home_screen.dart';
import 'package:beong/features/rewards/rewards_screen.dart';
import 'package:beong/features/settings/settings_screen.dart';
import 'package:beong/features/stats/stats_screen.dart';
import 'package:beong/features/tasks/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const home = '/';
  static const tasks = '/tasks';
  static const rewards = '/rewards';
  static const stats = '/stats';
  static const settings = '/settings';
  static const onboarding = '/onboarding';

  static const List<String> shellBranches = [
    home,
    tasks,
    rewards,
    stats,
    settings,
  ];
}

GoRouter createRouter({
  required AppSession? Function() getSession,
  required Listenable refreshListenable,
}) {
  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final session = getSession();
      final isOnboarding = state.matchedLocation == Routes.onboarding;

      if (session == null && !isOnboarding) return Routes.onboarding;
      if (session != null && isOnboarding) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => Consumer(
                  builder: (context, ref, _) {
                    final session = ref.watch(sessionProvider);
                    if (session == null) return const SizedBox.shrink();
                    if (session.isParent) return const ParentHomeScreen();
                    return const ChildHomeScreen();
                  },
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.tasks,
                builder: (context, state) => const TasksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.rewards,
                builder: (context, state) => const RewardsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.stats,
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

typedef _Titled = String Function(BuildContext context);

class _Branch {
  const _Branch({
    required this.path,
    required this.title,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final _Titled title;
  final _Titled label;
  final IconData icon;
  final IconData selectedIcon;
}

final _branches = <_Branch>[
  _Branch(
    path: Routes.home,
    title: (c) => L10n.of(c).parentHomeTitle,
    label: (c) => L10n.of(c).navHome,
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  _Branch(
    path: Routes.tasks,
    title: (c) => L10n.of(c).tasksTitle,
    label: (c) => L10n.of(c).navTasks,
    icon: Icons.fact_check_outlined,
    selectedIcon: Icons.fact_check_rounded,
  ),
  _Branch(
    path: Routes.rewards,
    title: (c) => L10n.of(c).rewardsTitle,
    label: (c) => L10n.of(c).navRewards,
    icon: Icons.redeem_outlined,
    selectedIcon: Icons.redeem_rounded,
  ),
  _Branch(
    path: Routes.stats,
    title: (c) => L10n.of(c).statsTitle,
    label: (c) => L10n.of(c).navStats,
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart_rounded,
  ),
  _Branch(
    path: Routes.settings,
    title: (c) => L10n.of(c).settingsTitle,
    label: (c) => L10n.of(c).navSettings,
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
  ),
];

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      destinations: [
        for (final b in _branches)
          AppDestination(
            icon: b.icon,
            selectedIcon: b.selectedIcon,
            label: b.label(context),
          ),
      ],
      body: navigationShell,
    );
  }
}
