import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Apple từ chối bản nộp có icon kèm kênh alpha — lỗi **90717**:
///
/// > Invalid large app icon. The large app icon in the asset catalog in
/// > "Runner.app" can't be transparent or contain an alpha channel.
///
/// Lỗi này đã làm hỏng release #31 ngày 25/08/2026, **sau khi** IPA build xong
/// mất 3 phút. Nó chỉ lộ ra ở bước đẩy store, tức là mỗi lần sai phải trả giá
/// bằng cả một vòng CI. Test này kéo phát hiện về còn vài giây.
///
/// Chỉ canh iOS: macOS cho phép alpha (icon macOS vốn trong suốt), Android
/// cũng vậy.
void main() {
  test('icon iOS không có kênh alpha (Apple từ chối, lỗi 90717)', () {
    final thuMuc = Directory(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset',
    );
    expect(
      thuMuc.existsSync(),
      isTrue,
      reason: 'Không thấy thư mục icon iOS — đổi chỗ thì sửa cả test này',
    );

    final anh = thuMuc
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList();

    expect(anh, isNotEmpty, reason: 'Không có icon nào để kiểm');

    final coAlpha = <String>[];
    for (final f in anh) {
      // PNG: 8 byte chữ ký, rồi chunk IHDR. Byte thứ 25 là `colour type`.
      // 4 = xám + alpha, 6 = RGB + alpha. Xem PNG spec §11.2.2.
      final byte = f.readAsBytesSync();
      if (byte.length < 26) continue;
      final loaiMau = byte[25];
      if (loaiMau == 4 || loaiMau == 6) {
        coAlpha.add('${f.uri.pathSegments.last} (colour type $loaiMau)');
      }
    }

    expect(
      coAlpha,
      isEmpty,
      reason:
          'Icon iOS còn kênh alpha thì Apple từ chối ở bước đẩy store, sau khi '
          'đã build xong IPA. Ghép lên nền đặc rồi lưu lại dạng RGB.',
    );
  });
}
