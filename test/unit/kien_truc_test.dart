import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ràng buộc kiến trúc, canh bằng cách đọc chính mã nguồn.
///
/// Tầng repository chỉ có nghĩa nếu **không ai đi vòng qua nó**. Không có test
/// này thì `lib/domain/repositories/` chỉ là một lớp đổi tên: người sau thêm màn
/// mới, gõ `ref.watch(taskDaoProvider)` vì nó vẫn còn đó và vẫn chạy, và tầng
/// giữa mất tác dụng đúng lúc Sprint 3 cần tới nó nhất.
///
/// Đây cũng là bài học lặp lại của dự án: thứ tuyên bố trong tài liệu mà không
/// có test tương ứng thì chỉ là ước muốn.
void main() {
  List<File> dartFilesIn(String path) => Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .toList();

  group('lib/features không được chạm vào lib/data', () {
    test('không import trực tiếp tầng dữ liệu', () {
      final viPham = <String>[];
      for (final file in dartFilesIn('lib/features')) {
        for (final (i, line) in file.readAsLinesSync().indexed) {
          if (line.startsWith("import 'package:beong/data/")) {
            viPham.add('${file.path}:${i + 1} — ${line.trim()}');
          }
        }
      }

      expect(
        viPham,
        isEmpty,
        reason:
            'Màn hình phải đọc ghi qua lib/domain/repositories. Kiểu dữ liệu nào '
            'tầng UI thật sự cần thì cho repository `export` lại, đừng mở đường '
            'import thẳng.\n${viPham.join('\n')}',
      );
    });

    test('không gọi provider của DAO', () {
      // Chặn cả đường đi vòng: không import `lib/data` nhưng vẫn với tới DAO
      // qua provider được sinh ra ở `core/providers`.
      final viPham = <String>[];
      final mau = RegExp(r'\b\w+DaoProvider\b');
      for (final file in dartFilesIn('lib/features')) {
        for (final (i, line) in file.readAsLinesSync().indexed) {
          final hit = mau.firstMatch(line);
          if (hit != null) {
            viPham.add('${file.path}:${i + 1} — ${hit.group(0)}');
          }
        }
      }

      expect(viPham, isEmpty, reason: viPham.join('\n'));
    });
  });

  group('tầng repository giữ đúng vai', () {
    test('mọi repository đều có bản Local đi kèm', () {
      // Interface không có bản chạy được thì không ai dùng được, và ngược lại
      // bản chạy được mà không có interface thì Sprint 3 không thay thế được.
      for (final file in dartFilesIn('lib/domain/repositories')) {
        final src = file.readAsStringSync();
        final ten = RegExp(
          r'abstract interface class (\w+)',
        ).firstMatch(src)?.group(1);
        if (ten == null) continue;

        expect(
          src,
          contains('final class Local$ten implements $ten'),
          reason: '${file.path} khai $ten nhưng thiếu Local$ten',
        );
      }
    });

    test('repository không tự mở transaction hay chạm Drift', () {
      // Repository là chỗ trả lời "đọc ở đâu", không phải chỗ viết nghiệp vụ.
      // Nghiệp vụ cần transaction thì nằm ở lib/domain/services.
      for (final file in dartFilesIn('lib/domain/repositories')) {
        final src = file.readAsStringSync();
        expect(
          src,
          isNot(contains('transaction(')),
          reason: '${file.path} — transaction thuộc về DAO hoặc service',
        );
        expect(
          src,
          isNot(contains("import 'package:drift/drift.dart'")),
          reason: '${file.path} — repository không dựng câu truy vấn',
        );
      }
    });
  });
}
