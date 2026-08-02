import 'package:beong/core/widgets/responsive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Khung điều hướng phải đổi hình dạng theo bề rộng — `docs/02-architecture.md` §6.
/// Ba điểm gãy này là hợp đồng của layout; test giữ cho nó không vỡ âm thầm.
void main() {
  const destinations = [
    AppDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Trang chính',
    ),
    AppDestination(
      icon: Icons.checklist_outlined,
      selectedIcon: Icons.checklist_rounded,
      label: 'Việc nhà',
    ),
  ];

  Widget wrap(Size size) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: ResponsiveScaffold(
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          body: const Text('nội dung'),
        ),
      ),
    );
  }

  testWidgets('dưới 600dp dùng thanh điều hướng đáy', (tester) async {
    await tester.pumpWidget(wrap(const Size(400, 800)));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('nội dung'), findsOneWidget);
  });

  testWidgets('600–1024dp dùng rail thu gọn', (tester) async {
    await tester.pumpWidget(wrap(const Size(800, 800)));

    expect(find.byType(NavigationBar), findsNothing);

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
  });

  testWidgets('trên 1024dp dùng rail mở rộng kèm nhãn', (tester) async {
    await tester.pumpWidget(wrap(const Size(1440, 900)));

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
  });

  testWidgets('bấm mục điều hướng trả về đúng chỉ số', (tester) async {
    var selected = -1;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(400, 800)),
        child: MaterialApp(
          home: ResponsiveScaffold(
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (i) => selected = i,
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Việc nhà'));
    expect(selected, 1);
  });
}
