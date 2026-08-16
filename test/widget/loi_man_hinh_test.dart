import 'dart:async';

import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/loi_man_hinh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Trạng thái lỗi.
///
/// Trước đây **không một `StreamBuilder` nào** trong app kiểm `hasError`: luồng
/// hỏng thì `snap.data` là `null`, màn hình rơi về mặc định và hiện như thể nhà
/// chưa có việc nào. Người dùng thấy dữ liệu **sai** chứ không thấy lỗi.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );

  testWidgets('luồng hỏng thì hiện báo lỗi, không hiện danh sách rỗng', (
    tester,
  ) async {
    final controller = StreamController<List<String>>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      wrap(
        LuongDuLieu<List<String>>(
          stream: controller.stream,
          builder: (context, data) => Text('${data.length} mục'),
        ),
      ),
    );

    // Chưa có gì: vòng xoay, không phải "0 mục".
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('0 mục'), findsNothing);

    controller.addError(Exception('DB hỏng'));
    await tester.pump();

    expect(find.text('Chỗ này đang trục trặc'), findsOneWidget);
    expect(
      find.text('0 mục'),
      findsNothing,
      reason: 'lỗi mà hiện danh sách rỗng là nói dối người dùng',
    );
  });

  testWidgets('có dữ liệu thì dựng nội dung như thường', (tester) async {
    final controller = StreamController<List<String>>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      wrap(
        LuongDuLieu<List<String>>(
          stream: controller.stream,
          builder: (context, data) => Text('${data.length} mục'),
        ),
      ),
    );

    controller.add(['a', 'b']);
    await tester.pump();

    expect(find.text('2 mục'), findsOneWidget);
    expect(find.text('Chỗ này đang trục trặc'), findsNothing);
  });

  testWidgets('danh sách rỗng thật thì vẫn dựng nội dung, không báo lỗi', (
    tester,
  ) async {
    final controller = StreamController<List<String>>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      wrap(
        LuongDuLieu<List<String>>(
          stream: controller.stream,
          builder: (context, data) => Text('${data.length} mục'),
        ),
      ),
    );

    controller.add([]);
    await tester.pump();

    // Phân biệt "rỗng" với "hỏng" là cả mục đích của widget này.
    expect(find.text('0 mục'), findsOneWidget);
  });

  testWidgets('trấn an rằng dữ liệu của con không mất', (tester) async {
    await tester.pumpWidget(wrap(LoiManHinh(error: Exception('x'))));

    // Trẻ con đọc màn hình này. "Số liệu của con vẫn còn nguyên" là câu quan
    // trọng nhất ở đây — mất xu là nỗi lo thật của một đứa trẻ.
    expect(find.textContaining('vẫn còn nguyên'), findsOneWidget);
  });

  testWidgets('có nút thử lại khi chỗ gọi truyền vào', (tester) async {
    var called = 0;
    await tester.pumpWidget(
      wrap(LoiManHinh(error: Exception('x'), onRetry: () => called++)),
    );

    await tester.tap(find.text('THỬ LẠI'));
    expect(called, 1);
  });
}
