import 'package:beong/core/theme/kid_scale.dart';
import 'package:beong/core/widgets/celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hoa giấy khi con bấm xong việc.
///
/// Hai điều dễ làm sai và cả hai đều khó thấy khi thử tay:
/// 1. Nổ lại mỗi lần widget dựng lại — mà widget dựng lại rất thường (danh sách
///    phát lại từ stream), nên màn hình sẽ lấp lánh liên tục.
/// 2. Chặn cú bấm tiếp theo trong lúc bay: con bấm việc thứ hai mà không ăn.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('không vẽ gì khi chưa bấm', (tester) async {
    await tester.pumpWidget(
      wrap(const ConfettiBurst(play: false, child: Text('việc'))),
    );

    expect(find.byKey(confettiLayerKey), findsNothing);
  });

  testWidgets('bấm một lần thì vẽ rồi tự dọn', (tester) async {
    await tester.pumpWidget(
      wrap(const ConfettiBurst(play: true, child: Text('việc'))),
    );
    // `play: true` ngay từ đầu **không** nổ: chỉ chuyển false -> true mới nổ, để
    // widget dựng lại với cùng giá trị không nổ lại.
    expect(find.byKey(confettiLayerKey), findsNothing);

    await tester.pumpWidget(
      wrap(const ConfettiBurst(play: false, child: Text('việc'))),
    );
    await tester.pumpWidget(
      wrap(const ConfettiBurst(play: true, child: Text('việc'))),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(confettiLayerKey), findsOneWidget);

    // Chạy hết rồi vẫn còn cây widget (nó chỉ vẽ trong suốt), không được rò
    // ticker.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('hoa giấy không ăn cú bấm của thẻ bên dưới', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        ConfettiBurst(
          play: false,
          child: GestureDetector(
            onTap: () => taps++,
            child: const SizedBox(width: 200, height: 80, child: Text('việc')),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      wrap(
        ConfettiBurst(
          play: true,
          child: GestureDetector(
            onTap: () => taps++,
            child: const SizedBox(width: 200, height: 80, child: Text('việc')),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Bấm **trong lúc** hoa giấy đang bay.
    await tester.tap(find.text('việc'));
    expect(taps, 1, reason: 'lớp hoa giấy phải IgnorePointer');
  });

  test('tuổi teen không ăn mừng bằng hoa giấy', () {
    // Bé 14 tuổi thấy hoa giấy là rườm rà — cờ này quyết định có gọi hiệu ứng
    // hay không ở màn hình con.
    expect(KidScale.little.celebrateOnTap, isTrue);
    expect(KidScale.middle.celebrateOnTap, isTrue);
    expect(KidScale.teen.celebrateOnTap, isFalse);
  });
}
