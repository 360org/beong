import 'dart:io';

import 'package:beong/core/widgets/thong_bao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canh yêu cầu chủ dự án nêu 30/08/2026: *"Notification phải tự mất sau 2-3
/// giây, không nằm mãi ở đó."*
void main() {
  group('thời lượng thông báo', () {
    test('nằm trong khoảng 2–3 giây chủ dự án yêu cầu', () {
      for (final d in [kThoiLuongThongBao, kThoiLuongThongBaoCoNut]) {
        expect(
          d.inMilliseconds,
          inInclusiveRange(2000, 3000),
          reason:
              'Mặc định của Material là 4 giây — dài hơn mức chủ dự án chấp '
              'nhận, và đủ để thanh đen che mất mục ngay dưới nó',
        );
      }
    });

    test('thông báo có nút không được ngắn hơn thông báo thường', () {
      // Người dùng phải kịp **đọc** câu vừa hiện rồi mới với tay bấm. Ngắn hơn
      // thì nút Hoàn tác chỉ còn là trang trí.
      expect(
        kThoiLuongThongBaoCoNut >= kThoiLuongThongBao,
        isTrue,
      );
    });
  });

  test('không chỗ nào tự dựng SnackBar ngoài thong_bao.dart', () {
    // Thời lượng phải nằm ở **một chỗ**. Dựng `SnackBar` tay ở màn hình nào là
    // chỗ đó lặng lẽ quay về mặc định 4 giây, và không ai thấy cho tới khi có
    // người dùng thật phàn nàn — đúng như lần này.
    final viPham = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('thong_bao.dart')) continue;
      final noiDung = entity.readAsStringSync();
      // `SnackBarAction(` là tham số hợp lệ truyền vào hàm dùng chung, nên gỡ
      // nó ra trước khi tìm — nếu không thì mọi nút "Hoàn tác" đều bị báo oan.
      final conLai = noiDung.replaceAll('SnackBarAction(', '');
      for (final dau in ['showSnackBar', 'SnackBar(']) {
        if (conLai.contains(dau)) {
          viPham.add('${entity.path} ($dau)');
          break;
        }
      }
    }

    expect(
      viPham,
      isEmpty,
      reason:
          'Dùng hienThongBao / hienThongBaoTuyChinh trong '
          'lib/core/widgets/thong_bao.dart thay vì dựng SnackBar tay:\n  '
          '${viPham.join('\n  ')}',
    );
  });

  testWidgets('thông báo tự biến mất, không nằm lại', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => hienThongBao(context, 'Đã bỏ khỏi thói quen'),
              child: const Text('hiện'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('hiện'));
    await tester.pump();
    expect(find.text('Đã bỏ khỏi thói quen'), findsOneWidget);

    // Sau 2 giây vẫn còn: đủ lâu để đọc.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Đã bỏ khỏi thói quen'), findsOneWidget);

    // Qua mốc thời lượng + hoạt ảnh trượt ra thì phải sạch màn hình.
    await tester.pump(kThoiLuongThongBao);
    await tester.pumpAndSettle();
    expect(
      find.text('Đã bỏ khỏi thói quen'),
      findsNothing,
      reason: 'Thông báo còn nằm đó sau khi hết giờ',
    );
  });

  testWidgets('thông báo mới đẩy thông báo cũ đi, không xếp hàng', (
    tester,
  ) async {
    // Bấm nhanh ba nút mà xếp hàng thì thanh cuối còn nằm đó sau chín giây —
    // đúng cảm giác "nằm mãi".
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => hienThongBao(context, 'Cái thứ nhất'),
                  child: const Text('một'),
                ),
                ElevatedButton(
                  onPressed: () => hienThongBao(context, 'Cái thứ hai'),
                  child: const Text('hai'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('một'));
    await tester.pump();
    await tester.tap(find.text('hai'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Cái thứ nhất'), findsNothing);
    expect(find.text('Cái thứ hai'), findsOneWidget);

    await tester.pump(kThoiLuongThongBao);
    await tester.pumpAndSettle();
    expect(find.text('Cái thứ hai'), findsNothing);
  });
}
