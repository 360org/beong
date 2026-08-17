import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/features/settings/bao_loi_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Màn báo lỗi.
///
/// Test dữ liệu ở `test/unit/core/bao_cao_loi_test.dart` đã canh phần dựng và
/// gửi báo cáo. Chỗ này canh phần **người dùng nhìn thấy**, mà quan trọng nhất
/// là màn này không được **nói dối**: hiện "đã gửi rồi, cảm ơn" trong khi báo
/// cáo chưa đi đâu cả là cách chắc chắn nhất để không bao giờ nhận được nó.
void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.light(), home: child);

  testWidgets('chưa mô tả thì không gửi được', (tester) async {
    // Một báo cáo chỉ có nhật ký mà không biết người ta đang làm gì thì gần
    // như không lần lại được.
    await tester.pumpWidget(wrap(const BaoLoiScreen(duongDanAnh: null)));

    final nut = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(nut.onPressed, isNull);
  });

  testWidgets('gõ mô tả rồi thì nút bật lên', (tester) async {
    await tester.pumpWidget(wrap(const BaoLoiScreen(duongDanAnh: null)));

    await tester.enterText(find.byType(TextField), 'Xu không cộng');
    await tester.pump();

    final nut = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(nut.onPressed, isNotNull);
    expect(find.text('GỬI BÁO CÁO'), findsOneWidget);
  });

  testWidgets('khoảng trắng không tính là mô tả', (tester) async {
    await tester.pumpWidget(wrap(const BaoLoiScreen(duongDanAnh: null)));

    await tester.enterText(find.byType(TextField), '   \n  ');
    await tester.pump();

    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });

  testWidgets('không chụp được ảnh thì nói rõ, vẫn gửi được', (tester) async {
    await tester.pumpWidget(wrap(const BaoLoiScreen(duongDanAnh: null)));

    // Mất ảnh không được chặn cả báo cáo.
    expect(find.textContaining('Không chụp được ảnh'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);

    await tester.enterText(find.byType(TextField), 'Xu không cộng');
    await tester.pump();
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('màn hình không nhắc GitHub hay chi tiết kỹ thuật', (
    tester,
  ) async {
    // Bố mẹ đang bực vì app hỏng; bắt họ hiểu quy trình nội bộ của đội phát
    // triển là đẩy việc của mình sang cho người dùng.
    await tester.pumpWidget(wrap(const BaoLoiScreen(duongDanAnh: null)));

    for (final tu in ['GitHub', 'issue', 'token', 'endpoint', 'API']) {
      expect(
        find.textContaining(tu, findRichText: true),
        findsNothing,
        reason: 'màn này không nên nhắc "$tu"',
      );
    }
  });

  group('màn kết thúc', () {
    testWidgets('gửi xong thì cảm ơn và không đòi làm gì thêm', (tester) async {
      await tester.pumpWidget(
        wrap(const ManKetThucBaoLoi(tuGui: true)),
      );

      expect(find.textContaining('Đã gửi rồi'), findsOneWidget);
      expect(
        find.textContaining('chưa được gửi'),
        findsNothing,
        reason: 'gửi xong rồi mà còn nói chưa gửi thì người ta gửi lại lần nữa',
      );
    });

    testWidgets('chưa cấu hình thì nói thẳng là **chưa** gửi', (tester) async {
      await tester.pumpWidget(wrap(const ManKetThucBaoLoi(tuGui: false)));

      // Đây là cái bẫy chính của màn này. Gộp hai ca vào một là nói dối.
      expect(find.text('Chưa gửi được'), findsOneWidget);
      expect(find.textContaining('chưa đi đâu cả'), findsOneWidget);
      expect(find.textContaining('Đã gửi rồi'), findsNothing);
    });

    testWidgets('không bảo người dùng đi mở trang nào cả', (tester) async {
      // Ca này từng mở form tạo issue GitHub. Đẩy quy trình nội bộ của đội phát
      // triển sang cho một phụ huynh đang bực vì app hỏng là bắt họ làm việc
      // của mình.
      await tester.pumpWidget(wrap(const ManKetThucBaoLoi(tuGui: false)));

      for (final tu in ['trang', 'GitHub', 'issue', 'trình duyệt']) {
        expect(
          find.textContaining(tu, findRichText: true),
          findsNothing,
          reason: 'màn này không nên bảo người dùng làm gì với "$tu"',
        );
      }
    });
  });
}
