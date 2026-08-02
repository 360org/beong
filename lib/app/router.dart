import 'package:beong/core/l10n/gen/app_localizations.dart';
import 'package:beong/core/widgets/placeholder_screen.dart';
import 'package:beong/core/widgets/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Đường dẫn của các màn hình chính. Dùng hằng số, không rải chuỗi thô.
abstract final class Routes {
  static const home = '/';
  static const tasks = '/tasks';
  static const rewards = '/rewards';
  static const stats = '/stats';
  static const settings = '/settings';

  static const List<String> shellBranches = [
    home,
    tasks,
    rewards,
    stats,
    settings,
  ];
}

/// Router của app.
///
/// Dùng [StatefulShellRoute] để mỗi tab giữ được lịch sử điều hướng riêng —
/// quan trọng trên desktop, nơi người dùng nhảy qua lại giữa các mục nhiều hơn.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: Routes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          for (final branch in _branches)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: branch.path,
                  builder: (context, state) => PlaceholderScreen(
                    title: branch.title(context),
                    icon: branch.icon,
                  ),
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
    icon: Icons.checklist_outlined,
    selectedIcon: Icons.checklist_rounded,
  ),
  _Branch(
    path: Routes.rewards,
    title: (c) => L10n.of(c).rewardsTitle,
    label: (c) => L10n.of(c).navRewards,
    icon: Icons.card_giftcard_outlined,
    selectedIcon: Icons.card_giftcard_rounded,
  ),
  _Branch(
    path: Routes.stats,
    title: (c) => L10n.of(c).statsTitle,
    label: (c) => L10n.of(c).navStats,
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
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
        // Bấm lại tab đang mở → quay về gốc của tab đó.
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
