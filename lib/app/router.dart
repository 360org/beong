import 'package:beong/core/l10n/gen/app_localizations.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/widgets/responsive_scaffold.dart';
import 'package:beong/features/child_home/child_home_screen.dart';
import 'package:beong/features/onboarding/onboarding_screen.dart';
import 'package:beong/features/parent_home/parent_home_screen.dart';
import 'package:beong/features/rewards/rewards_screen.dart';
import 'package:beong/features/settings/jar_settings_screen.dart';
import 'package:beong/features/settings/penalty_settings_screen.dart';
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

  /// Trang con của Cài đặt — cấu hình trừ xu (ADR-022).
  static const penaltySettings = '/settings/penalty';
  static const jarSettings = '/settings/jars';
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

      // Vai con không có Cài đặt. Chặn cả ở router chứ không chỉ ẩn tab: link
      // sâu hay `goBranch` gọi sai vẫn phải rơi về chỗ an toàn.
      final settingsPath = state.matchedLocation.startsWith(Routes.settings);
      if (session != null && !session.isParent && settingsPath) {
        return Routes.home;
      }

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
                routes: [
                  GoRoute(
                    // Đường dẫn con nên thanh điều hướng vẫn hiện và nút back
                    // quay về đúng tab Cài đặt.
                    path: 'penalty',
                    builder: (context, state) => const PenaltySettingsScreen(),
                  ),
                  GoRoute(
                    path: 'jars',
                    builder: (context, state) => const JarSettingsScreen(),
                  ),
                ],
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
    this.parentOnly = false,
  });

  final String path;
  final _Titled title;
  final _Titled label;
  final IconData icon;
  final IconData selectedIcon;

  /// Chỉ hiện với vai bố mẹ. Cài đặt là chỗ đổi cấu hình cả nhà — trừ xu, chế
  /// độ duyệt, chia xu — nên không phải việc của con.
  ///
  /// Đây **chỉ là ẩn ở giao diện**, không phải cơ chế bảo vệ: vai lưu ở local
  /// không cấp quyền (ADR-018). Chặn thật sẽ đến từ credential khi có backend.
  final bool parentOnly;
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
    parentOnly: true,
  ),
];

class _AppShell extends ConsumerWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isParent = ref.watch(sessionProvider)?.isParent ?? false;

    // Số nhánh của `StatefulShellRoute` là **cố định**; chỉ danh sách hiện ra là
    // lọc. Vì vậy phải giữ bảng ánh xạ: chỉ số trong thanh nav ≠ chỉ số nhánh.
    // Không có bảng này thì ẩn một tab làm mọi tab sau nó nhảy sang nhánh khác.
    final visible = <int>[
      for (var i = 0; i < _branches.length; i++)
        if (isParent || !_branches[i].parentOnly) i,
    ];

    final selected = visible.indexOf(navigationShell.currentIndex);

    return ResponsiveScaffold(
      // Nhánh hiện tại không nằm trong danh sách hiện ra (ví dụ vừa đổi vai
      // trong lúc đang ở Cài đặt) thì chọn tab đầu — router sẽ đẩy về đúng chỗ.
      selectedIndex: selected < 0 ? 0 : selected,
      onDestinationSelected: (index) {
        final branch = visible[index];
        navigationShell.goBranch(
          branch,
          initialLocation: branch == navigationShell.currentIndex,
        );
      },
      destinations: [
        for (final i in visible)
          AppDestination(
            icon: _branches[i].icon,
            selectedIcon: _branches[i].selectedIcon,
            label: _branches[i].label(context),
          ),
      ],
      body: navigationShell,
    );
  }
}
