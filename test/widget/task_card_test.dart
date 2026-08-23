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

  group('phản hồi ngay khi chạm', () {
    // "Bấm hoàn thành nhiệm vụ bị giật cục" — chủ dự án báo 23/08.
    //
    // Một nửa cảm giác đó là khoảng lặng: trạng thái thật đi một vòng dài (ghi
    // DB → cộng xu → thưởng trọn bộ → huy hiệu → luồng phát lại), và trước bản
    // này thẻ chỉ vẽ theo trạng thái thật. Con chạm vào, **không có gì xảy
    // ra**, rồi đột nhiên mọi thứ nhảy một lượt.

    testWidgets('tích hiện ngay trong khung hình chạm, không chờ DB', (
      tester,
    ) async {
      var goi = 0;
      await tester.pumpWidget(
        wrap(
          TaskCard(
            title: 'Gấp chăn màn',
            points: 10,
            isCompleted: false,
            // Cố ý **không** đổi `isCompleted` sau khi gọi: mô phỏng đúng lúc
            // DB chưa trả lời. Đó là khoảng thời gian cần lấp.
            onToggle: () => goi++,
          ),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsNothing);

      await tester.tap(find.byType(TaskCard));
      await tester.pump();

      expect(goi, 1);
      expect(
        find.byIcon(Icons.check_rounded),
        findsOneWidget,
        reason: 'chạm xong phải thấy ngay, không đợi vòng dữ liệu',
      );
    });

    testWidgets('chạm hai lần chỉ tính một', (tester) async {
      var goi = 0;
      await tester.pumpWidget(
        wrap(
          TaskCard(
            title: 'Gấp chăn màn',
            points: 10,
            isCompleted: false,
            onToggle: () => goi++,
          ),
        ),
      );

      await tester.tap(find.byType(TaskCard));
      await tester.pump();
      await tester.tap(find.byType(TaskCard));
      await tester.pump();

      // Trẻ nhỏ bấm hai lần là chuyện thường. Không chặn thì lượt thứ hai lại
      // gọi cả vòng ghi DB một lần nữa.
      expect(goi, 1);
    });

    testWidgets('trạng thái thật về thì thẻ nhả cờ tạm', (tester) async {
      // Nếu không nhả, thẻ giữ một lời hứa sai khi việc ghi hỏng — sai mà im
      // lặng còn khó lần ra hơn một cú chậm.
      await tester.pumpWidget(wrap(the()));
      await tester.tap(find.byType(TaskCard));
      await tester.pump();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.pumpWidget(wrap(the(isMissed: true)));
      await tester.pump();

      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
