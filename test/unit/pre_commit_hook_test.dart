import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Chốt chặn giữ chính chốt chặn.
///
/// `.githooks/pre-commit` chạy `flutter analyze --fatal-infos` trước mỗi
/// commit. Nó tồn tại vì tính tới 26/08/2026, `main` đã **năm lần** được đẩy
/// lên trong trạng thái analyzer đỏ, và riêng bốn lỗi `discarded_futures` ở
/// `bee_mascot` / `celebration` / `onboarding` bị sửa rồi mất lại **ba lần**.
///
/// Test này không kiểm hook có chạy hay không — nó kiểm hook **còn tồn tại và
/// còn chạy đúng lệnh**. Một chốt chặn có thể bị xoá trong im lặng thì không
/// phải chốt chặn.
void main() {
  group('hook pre-commit', () {
    final hook = File('.githooks/pre-commit');

    test('còn tồn tại', () {
      expect(
        hook.existsSync(),
        isTrue,
        reason:
            '.githooks/pre-commit đã bị xoá — xem lý do nó có mặt ở đầu '
            'file test này trước khi bỏ hẳn',
      );
    });

    test('vẫn chạy analyze với --fatal-infos', () {
      final noiDung = hook.readAsStringSync();
      expect(
        noiDung,
        contains('flutter analyze --fatal-infos'),
        reason:
            'Bỏ `--fatal-infos` là bỏ đúng thứ CI đang canh: ở dự án này '
            'info cũng là đỏ',
      );
    });

    test('chạy được (có quyền thực thi)', () {
      // Bit thực thi nằm trong 3 chữ số cuối của mode; 0x40 = chủ sở hữu chạy
      // được. Hook không có quyền chạy thì git bỏ qua **trong im lặng** —
      // đúng loại hỏng tệ nhất: trông như đang được bảo vệ mà không.
      expect(
        hook.statSync().mode & 0x40,
        isNot(0),
        reason: 'chmod +x .githooks/pre-commit',
      );
    });
  });
}
