import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Thẻ việc nhà, và cụ thể là **ba trạng thái không được trông giống nhau**.
///
/// Lỗi thật đã gặp: `isPending` có sẵn trong `TaskCard` nhưng chỉ được gộp vào
/// `isDone`, tức là không điều khiển gì cả — một cái cờ chết. Kết quả là khi nhà
/// bật chế độ duyệt, việc con vừa bấm hiện y hệt việc đã được duyệt: cùng gạch
/// ngang, cùng dấu tích xanh. Con thấy tích xanh mà số xu không nhích là lúc con
/// thôi tin vào cái tích đó.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );

  TaskCard the({
    bool isCompleted = false,
    bool isPending = false,
    bool isMissed = false,
  }) => TaskCard(
    title: 'Gấp chăn màn',
    points: 10,
    isCompleted: isCompleted,
    isPending: isPending,
    isMissed: isMissed,
    onToggle: () {},
  );

  TextStyle titleStyle(WidgetTester tester) =>
      tester.widget<Text>(find.text('Gấp chăn màn')).style!;

  group('chờ bố mẹ duyệt', () {
    testWidgets('nói thẳng ra bằng chữ', (tester) async {
      await tester.pumpWidget(wrap(the(isPending: true)));

      // Không bắt con suy ra từ màu sắc: viết ra.
      expect(find.text('Chờ bố mẹ duyệt'), findsOneWidget);
    });

    testWidgets('không dùng dấu tích như việc đã duyệt', (tester) async {
      await tester.pumpWidget(wrap(the(isPending: true)));

      expect(
        find.byIcon(Icons.check_rounded),
        findsNothing,
        reason: 'dấu tích là "xu đã vào ví"; chờ duyệt thì chưa',
      );
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    });

    testWidgets('không gạch ngang tên việc', (tester) async {
      await tester.pumpWidget(wrap(the(isPending: true)));

      // Gạch ngang nghĩa là xong hẳn. Bố mẹ vẫn có thể mở lại việc này.
      expect(titleStyle(tester).decoration, isNot(TextDecoration.lineThrough));
    });

    testWidgets('khác việc đã duyệt ở cả hình, không chỉ ở màu', (
      tester,
    ) async {
      // WCAG 1.4.1: phân biệt bằng màu đơn thuần thì người mù màu không thấy.
      await tester.pumpWidget(wrap(the(isPending: true)));
      final choDuyet = tester
          .widgetList<Icon>(find.byType(Icon))
          .map((i) => i.icon)
          .toSet();

      await tester.pumpWidget(wrap(the(isCompleted: true)));
      final daDuyet = tester
          .widgetList<Icon>(find.byType(Icon))
          .map((i) => i.icon)
          .toSet();

      expect(choDuyet.intersection(daDuyet), isEmpty);
    });

    testWidgets('bấm lại không làm gì — đang chờ người khác', (tester) async {
      var bam = 0;
      await tester.pumpWidget(
        wrap(
          TaskCard(
            title: 'Gấp chăn màn',
            points: 10,
            isCompleted: false,
            isPending: true,
            onToggle: () => bam++,
          ),
        ),
      );

      await tester.tap(find.byType(TaskCard));
      await tester.pump();

      expect(bam, 0);
    });
  });

  group('ba trạng thái còn lại vẫn đúng', () {
    testWidgets('chưa làm: ô tròn rỗng, chữ không gạch, bấm được', (
      tester,
    ) async {
      var bam = 0;
      await tester.pumpWidget(
        wrap(
          TaskCard(
            title: 'Gấp chăn màn',
            points: 10,
            isCompleted: false,
            onToggle: () => bam++,
          ),
        ),
      );

      expect(titleStyle(tester).decoration, isNot(TextDecoration.lineThrough));
      expect(find.text('Chờ bố mẹ duyệt'), findsNothing);

      await tester.tap(find.byType(TaskCard));
      await tester.pump();
      expect(bam, 1);
    });

    testWidgets('đã duyệt: có dấu tích và gạch ngang', (tester) async {
      await tester.pumpWidget(wrap(the(isCompleted: true)));

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(titleStyle(tester).decoration, TextDecoration.lineThrough);
      expect(find.text('Chờ bố mẹ duyệt'), findsNothing);
    });

    testWidgets('bỏ lỡ: dấu X, không phải dấu tích', (tester) async {
      await tester.pumpWidget(wrap(the(isMissed: true)));

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });
  });
}
