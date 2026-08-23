import 'package:beong/core/l10n/gen/app_localizations.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/widgets/responsive_scaffold.dart';
import 'package:beong/features/child_home/child_home_screen.dart';
import 'package:beong/features/members/vao_app_screen.dart';
import 'package:beong/features/onboarding/onboarding_screen.dart';
import 'package:beong/features/parent_home/parent_home_screen.dart';
import 'package:beong/features/rewards/rewards_screen.dart';
import 'package:beong/features/settings/jar_settings_screen.dart';
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
  static const settings = '/settings';

  /// Trang con của Cài đặt — cấu hình trừ xu (ADR-022).
  static const penaltySettings = '/settings/penalty';
  static const jarSettings = '/settings/jars';
  static const badges = '/stats/badges';

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
    settings,
  ];
}

/// Người mở app lúc này phải đi đâu — `null` là "cứ ở nguyên chỗ đang tới".
///
/// Tách khỏi [createRouter] để test được bằng bảng, không cần dựng cả cây
/// widget. Ba trạng thái, không phải hai — đó chính là chỗ trước đây sai:
///
/// | Máy có dữ liệu | Có session | Đi đâu |
/// |---|---|---|
/// | không | không | onboarding |
/// | **có** | **không** | **màn chọn người dùng** |
/// | có | có | trang chính |
///
/// Gộp hai dòng đầu làm một (`session == null` → onboarding) là lỗi §2 trong
/// `docs/13-audit-luong-vao-app.md`: bấm KHOÁ LẠI xong onboarding tạo thêm một
/// gia đình nữa, còn gia đình cũ nằm lại trong DB không đường vào.
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

  // Vai con không có Cài đặt. Chặn cả ở router chứ không chỉ ẩn tab: link sâu
  // hay `goBranch` gọi sai vẫn phải rơi về chỗ an toàn.
  if (!session.isParent && viTri.startsWith(Routes.settings)) {
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
                routes: [
                  GoRoute(
                    // Đường dẫn con nên thanh điều hướng vẫn hiện và nút back
                    // quay về đúng tab Nhiệm vụ.
                    path: 'routine/:routineId',
                    // `redirect` chứ không phải `?? ''`: chuỗi rỗng lọt xuống
                    // thì màn sửa thói quen mở ra **trống trơn**, không báo gì
                    // — im lặng sai còn khó lần ra hơn một cú crash. Về thẳng
                    // danh sách là thứ người dùng hiểu được ngay.
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
                routes: [
                  GoRoute(
                    path: 'badges',
                    builder: (context, state) => const BadgesScreen(),
                  ),
                ],
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
