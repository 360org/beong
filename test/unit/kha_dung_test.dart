import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Rà soát khả dụng bằng cách **đọc mã nguồn**.
///
/// Bài học từ Sprint 0 đã ghi trong `05-roadmap.md`: mọi ràng buộc khả dụng ghi
/// trong tài liệu mà không có test tương ứng thì chỉ là ước muốn. Bảng màu hồ sơ
/// từng được tài liệu tuyên bố đạt WCAG AA trong khi thực tế chỉ 2.7:1.
///
/// Test này không thay được người thật bật TalkBack, nhưng nó chặn được đúng
/// cái trôi âm thầm: thêm một nút chỉ có icon rồi quên đặt tên cho nó.
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
      .toList();

  test('có file nguồn để soát', () {
    // Canh chính test này: `listSync` trả rỗng vì sai đường dẫn thì mọi test
    // dưới đây "xanh" mà không kiểm gì cả.
    expect(dartFiles.length, greaterThan(30));
  });

  test('mọi IconButton đều có tooltip', () {
    // Nút chỉ có icon mà không có tooltip thì TalkBack/VoiceOver đọc ra đúng
    // một chữ "nút" — người dùng không biết bấm vào sẽ xảy ra gì.
    final offenders = <String>[];

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      final buttons =
          'IconButton('.allMatches(source).length +
          'IconButton.filledTonal('.allMatches(source).length +
          'IconButton.filled('.allMatches(source).length;
      if (buttons == 0) continue;

      final tooltips = 'tooltip:'.allMatches(source).length;
      if (tooltips < buttons) {
        offenders.add('${file.path}: $buttons nút, $tooltips tooltip');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('AppIcon luôn tự loại khỏi cây ngữ nghĩa', () {
    // Icon trong app này là **trang trí**: chữ bên cạnh đã nói hết. Để nó vào
    // cây ngữ nghĩa thì trình đọc màn hình đọc tên file ảnh trước mỗi dòng.
    final source = File('lib/core/widgets/app_icon.dart').readAsStringSync();
    expect(source, contains('excludeFromSemantics: true'));
  });

  test('trần phóng chữ được áp ở gốc app', () {
    // Người dùng đặt cỡ chữ hệ thống lớn nhất mà app không chặn trần thì mọi
    // thẻ việc vỡ bố cục. Trần nằm trong `AppTypography.maxTextScale`.
    final source = File('lib/app/app.dart').readAsStringSync();
    expect(source, contains('AppTypography.maxTextScale'));
    expect(source, contains('clamp('));
  });

  test('không có màu nào bị hard-code trong tầng features', () {
    // `Color(0xFF...)` rải trong màn hình là đường ngắn nhất tới một app không
    // đổi được sáng/tối: token trong `core/theme` đổi theo chủ đề, hằng số thì
    // không.
    final offenders = <String>[];
    for (final file in dartFiles) {
      if (!file.path.startsWith('lib/features')) continue;
      final source = file.readAsStringSync();
      if (RegExp(r'Color\(0x').hasMatch(source)) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
