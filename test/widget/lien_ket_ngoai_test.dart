import 'package:beong/core/widgets/lien_ket_ngoai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dòng địa chỉ bấm được ở Cài đặt → Quyền riêng tư / Điều khoản / Liên hệ.
///
/// Chủ dự án nêu 30/08/2026: *"link điều khoản / riêng tư không click được."*
/// Trước đó địa chỉ chỉ là chữ nằm trong một đoạn văn: trông như link, bấm vào
/// không có gì xảy ra. Không test nào đỏ, vì không có gì để đỏ — chỗ ấy không
/// có mã nào cả.
///
/// Hai điều file này canh, và cả hai đều từng là chỗ hỏng lặng lẽ:
///
/// 1. Bấm vào thì **thật sự gọi mở** đúng địa chỉ ấy.
/// 2. Máy không mở được thì **nói ra**, không im lặng.
void main() {
  final diaChi = Uri.parse('https://beong.net/quyen-rieng-tu.html');

  Widget dung({required MoUri mo}) => MaterialApp(
    home: Scaffold(
      body: DongLienKet(nhan: 'Đọc bản đầy đủ', diaChi: diaChi, mo: mo),
    ),
  );

  testWidgets('bấm vào là mở đúng địa chỉ', (tester) async {
    final daGoi = <Uri>[];
    await tester.pumpWidget(
      dung(
        mo: (u) async {
          daGoi.add(u);
          return true;
        },
      ),
    );

    await tester.tap(find.text('Đọc bản đầy đủ'));
    await tester.pumpAndSettle();

    expect(daGoi, [diaChi]);
  });

  testWidgets('mở được thì không quấy người dùng bằng thông báo nào', (
    tester,
  ) async {
    await tester.pumpWidget(dung(mo: (_) async => true));

    await tester.tap(find.text('Đọc bản đầy đủ'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('máy không mở được thì chép địa chỉ và nói ra', (tester) async {
    final chep = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          chep.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(dung(mo: (_) async => false));
    await tester.tap(find.text('Đọc bản đầy đủ'));
    await tester.pumpAndSettle();

    expect(
      chep,
      [diaChi.toString()],
      reason: 'không mở được mà cũng không chép thì người dùng hết đường đi',
    );
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.textContaining(diaChi.toString()),
      findsOneWidget,
      reason: 'câu báo phải mang nguyên địa chỉ, phòng khi chép hụt',
    );
  });

  // Không cài giả bộ nhớ tạm ở test này — cố ý. Máy không có kênh bộ nhớ tạm
  // là chuyện có thật, và câu thông báo **không được** phụ thuộc vào việc chép
  // xong: chờ một lời hứa không bao giờ về thì bấm vào vẫn không thấy gì, đúng
  // cái lỗi đang sửa.
  testWidgets('tầng nền ném lỗi cũng đi vào đường lui, không văng ra', (
    tester,
  ) async {
    await tester.pumpWidget(
      dung(mo: (_) async => throw Exception('không có trình duyệt')),
    );

    await tester.tap(find.text('Đọc bản đầy đủ'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('vùng bấm cao ít nhất 48dp', (tester) async {
    await tester.pumpWidget(dung(mo: (_) async => true));

    // Ngón tay không nhắm được vào một dòng chữ cao 20px. 48dp là vùng chạm
    // tối thiểu của dự án, và một cái link bấm hụt thì y như link không bấm
    // được — đúng thứ vừa phải sửa.
    expect(
      tester.getSize(find.byType(InkWell)).height,
      greaterThanOrEqualTo(48.0),
    );
  });
}
