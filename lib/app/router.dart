import 'package:beong/core/l10n/gen/app_localizations.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/widgets/responsive_scaffold.dart';
import 'package:beong/features/child_home/child_home_screen.dart';
import 'package:beong/features/journey/journey_screen.dart';
import 'package:beong/features/members/vao_app_screen.dart';
import 'package:beong/features/onboarding/onboarding_screen.dart';
import 'package:beong/features/parent_home/parent_home_screen.dart';
import 'package:beong/features/rewards/rewards_screen.dart';
import 'package:beong/features/settings/penalty_settings_screen.dart';
import 'package:beong/features/settings/settings_screen.dart';
import 'package:beong/features/stats/badges_screen.dart';
import 'package:beong/features/stats/stats_screen.dart';
import 'package:beong/features/tasks/routine_editor_screen.dart';
import 'package:beong/features/tasks/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const home = '/';
  static const tasks = '/tasks';
  static const rewards = '/rewards';
  static const stats = '/stats';
  static const badges = '/badges';
  static const journey = '/journey';
  static const settings = '/settings';

  /// Trang con của Cài đặt — cấu hình trừ xu (ADR-022).
  static const penaltySettings = '/settings/penalty';

  /// Sửa một thói quen. Nhận `routineId` qua đường dẫn.
  static String routineEditor(String routineId) => '/tasks/routine/$routineId';
  static const onboarding = '/onboarding';

  /// Máy đã có dữ liệu nhưng chưa chọn ai đang dùng.
  ///
  /// Bốn bước: chọn nhà → chọn vai → chọn hồ sơ → điền mật khẩu (ADR-027).
  static const chonNguoiDung = '/vao-app';

  /// Cố ý tạo thêm một nhà nữa trên máy đã có dữ liệu.
  ///
  /// Phải nói rõ ý định bằng tham số này, vì mặc định máy có dữ liệu là
  /// **không** được vào onboarding — đó chính là bản sửa của §2. Không có
  /// đường này thì người muốn làm lại từ đầu bị kẹt vĩnh viễn với dữ liệu cũ,
  /// tức là đổi một cái bẫy lấy một cái bẫy khác.
  static const taoNhaMoi = '$onboarding?$thamSoTaoNhaMoi=1';
  static const thamSoTaoNhaMoi = 'tao-moi';

  static const List<String> shellBranches = [
    home,
    tasks,
    rewards,
    stats,
    badges,
    journey,
    settings,
  ];
}

/// Người mở app lúc này phải đi đâu — `null` là "cứ ở nguyên chỗ đang tới".
String? diemDenDauTien({
  required AppSession? session,
  required bool mayDaCoDuLieu,
  required String viTri,
  bool xinTaoNhaMoi = false,
}) {
  final laOnboarding = viTri == Routes.onboarding;
  final laChonNguoiDung = viTri == Routes.chonNguoiDung;

  if (session == null) {
    if (mayDaCoDuLieu) {
      // Vào onboarding phải là **cố ý**, không phải hệ quả của việc khoá máy.
      if (laOnboarding && xinTaoNhaMoi) return null;
      return laChonNguoiDung ? null : Routes.chonNguoiDung;
    }
    return laOnboarding ? null : Routes.onboarding;
  }

  // Đã chọn người dùng rồi thì hai màn "chưa vào được" kia không còn nghĩa.
  if (laOnboarding || laChonNguoiDung) return Routes.home;

  // Vai con không có Cài đặt, Thống kê và Nhiệm vụ (chỉ bố mẹ quản lý).
  if (!session.isParent &&
      (viTri.startsWith(Routes.settings) ||
          viTri.startsWith(Routes.stats) ||
          viTri.startsWith(Routes.tasks))) {
    return Routes.home;
  }

  // Vai phụ huynh không có tab Hành trình trẻ em.
  if (session.isParent && viTri.startsWith(Routes.journey)) {
    return Routes.home;
  }

  return null;
}

GoRouter createRouter({
  required AppSession? Function() getSession,
  required bool Function() getMayDaCoDuLieu,
  required Listenable refreshListenable,
}) {
  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: refreshListenable,
    redirect: (context, state) => diemDenDauTien(
      session: getSession(),
      mayDaCoDuLieu: getMayDaCoDuLieu(),
      viTri: state.matchedLocation,
      xinTaoNhaMoi: state.uri.queryParameters[Routes.thamSoTaoNhaMoi] == '1',
    ),
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.chonNguoiDung,
        builder: (context, state) => const VaoAppScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          // 0: Trang chính
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
          // 1: Nhiệm vụ
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.tasks,
                builder: (context, state) => const TasksScreen(),
                routes: [
                  GoRoute(
                    path: 'routine/:routineId',
                    redirect: (context, state) =>
                        (state.pathParameters['routineId'] ?? '').isEmpty
                        ? Routes.tasks
                        : null,
                    builder: (context, state) => RoutineEditorScreen(
                      routineId: state.pathParameters['routineId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 2: Phần thưởng
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.rewards,
                builder: (context, state) => const RewardsScreen(),
              ),
            ],
          ),
          // 3: Thống kê (Dành cho bố mẹ)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.stats,
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          // 4: Huy hiệu
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.badges,
                builder: (context, state) => const BadgesScreen(),
              ),
            ],
          ),
          // 5: Hành trình (Dành cho con)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.journey,
                builder: (context, state) => const JourneyScreen(),
              ),
            ],
          ),
          // 6: Cài đặt (Dành cho bố mẹ)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'penalty',
                    builder: (context, state) => const PenaltySettingsScreen(),
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

enum RoleAudience { parentOnly, childOnly, all }

class _Branch {
  const _Branch({
    required this.path,
    required this.title,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.audience = RoleAudience.all,
  });

  final String path;
  final _Titled title;
  final _Titled label;
  final IconData icon;
  final IconData selectedIcon;
  final RoleAudience audience;
}

final _branches = <_Branch>[
  // 0: Home
  _Branch(
    path: Routes.home,
    title: (c) => L10n.of(c).parentHomeTitle,
    label: (c) => L10n.of(c).navHome,
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  // 1: Tasks
  _Branch(
    path: Routes.tasks,
    title: (c) => L10n.of(c).tasksTitle,
    label: (c) => L10n.of(c).navTasks,
    icon: Icons.fact_check_outlined,
    selectedIcon: Icons.fact_check_rounded,
    audience: RoleAudience.parentOnly,
  ),
  // 2: Rewards
  _Branch(
    path: Routes.rewards,
    title: (c) => L10n.of(c).rewardsTitle,
    label: (c) => L10n.of(c).navRewards,
    icon: Icons.redeem_outlined,
    selectedIcon: Icons.redeem_rounded,
  ),
  // 3: Stats (Bố mẹ)
  _Branch(
    path: Routes.stats,
    title: (c) => L10n.of(c).statsTitle,
    label: (c) => L10n.of(c).navStats,
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart_rounded,
    audience: RoleAudience.parentOnly,
  ),
  // 4: Badges (Cả hai xem được, đặc biệt là con)
  _Branch(
    path: Routes.badges,
    title: (c) => 'Huy hiệu',
    label: (c) => L10n.of(c).navBadges,
    icon: Icons.military_tech_outlined,
    selectedIcon: Icons.military_tech_rounded,
    audience: RoleAudience.childOnly,
  ),
  // 5: Journey (Con)
  _Branch(
    path: Routes.journey,
    title: (c) => 'Hành trình',
    label: (c) => L10n.of(c).navJourney,
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore_rounded,
    audience: RoleAudience.childOnly,
  ),
  // 6: Settings (Bố mẹ)
  _Branch(
    path: Routes.settings,
    title: (c) => L10n.of(c).settingsTitle,
    label: (c) => L10n.of(c).navSettings,
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    audience: RoleAudience.parentOnly,
  ),
];

class _AppShell extends ConsumerWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isParent = ref.watch(sessionProvider)?.isParent ?? false;

    // Lọc danh sách tab nhìn thấy theo vai trò:
    // - Bố mẹ (isParent = true): Home (0), Tasks (1), Rewards (2), Stats (3), Settings (6) -> 5 tabs
    // - Con (isParent = false): Home (0), Tasks (1), Rewards (2), Badges (4), Journey (5) -> 5 tabs
    final visible = <int>[
      for (var i = 0; i < _branches.length; i++)
        if (_branches[i].audience == RoleAudience.all ||
            (isParent && _branches[i].audience == RoleAudience.parentOnly) ||
            (!isParent && _branches[i].audience == RoleAudience.childOnly))
          i,
    ];

    final selected = visible.indexOf(navigationShell.currentIndex);

    return ResponsiveScaffold(
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
