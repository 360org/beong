import 'package:dailychildren/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Một mục điều hướng chính của app.
class AppDestination {
  const AppDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Khung điều hướng dùng chung cho mọi nền tảng — `docs/02-architecture.md` §6.
///
/// Không fork màn hình theo nền tảng: cùng một cây widget, chỉ đổi cách bố trí
/// điều hướng theo bề rộng.
///
/// - < 600dp  → thanh điều hướng dưới đáy (mobile)
/// - 600–1024 → rail bên trái, chỉ icon
/// - > 1024   → rail mở rộng kèm nhãn (desktop)
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.floatingActionButton,
    super.key,
  });

  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (AppBreakpoints.isCompact(width)) {
      return Scaffold(
        body: SafeArea(child: body),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final extended = AppBreakpoints.isExpanded(width);

    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              extended: extended,
              minExtendedWidth: 220,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Bọc nội dung màn hình với lề ngang đúng theo bề rộng thiết bị.
class ScreenPadding extends StatelessWidget {
  const ScreenPadding({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = AppBreakpoints.isCompact(width)
        ? AppSpacing.screenPaddingMobile
        : AppSpacing.screenPaddingDesktop;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      child: child,
    );
  }
}
