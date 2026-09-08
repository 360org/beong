import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bánh cóc chặn nợ đa ngôn ngữ phình thêm.
///
/// Kế hoạch dịch (`docs/24-roadmap-da-ngon-ngu.md`) đứng yên đã lâu, trong khi
/// chuỗi tiếng Việt viết thẳng vào widget vẫn tăng đều: giữa 18/08 và 08/09/2026
/// nợ tăng khoảng 50%, còn số chỗ gọi `L10n.of` chỉ nhích từ 15 lên 18. Cứ đà
/// đó thì tới lúc thật sự dịch, việc phải làm lớn hơn hôm nay nhiều lần.
///
/// Test này **không đòi dọn nợ cũ** — dọn 897 chỗ không phải việc của một
/// commit. Nó chỉ khoá con số lại: thêm chuỗi cứng mới là đỏ, bớt đi thì hạ
/// [_nguong] xuống. Ngưỡng chỉ được đi một chiều.
///
/// Cách nhận diện: một literal chứa ký tự có dấu tiếng Việt thì gần như chắc là
/// chuỗi cho người đọc. Bỏ sót chuỗi thuần ASCII ("Save", "OK") là cố ý — bắt
/// chúng sẽ dính hàng loạt khoá, đường dẫn, tên biến và test thành ra vô dụng.
const _nguong = 897;

void main() {
  test('không thêm chuỗi tiếng Việt viết cứng trong lib/', () {
    final coDau = RegExp(
      '[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợ'
      'ùúủũụưừứửữựỳýỷỹỵđ]',
      caseSensitive: false,
    );
    final literal = RegExp("'[^']*'|\"[^\"]*\"");

    var tong = 0;
    final theoFile = <String, int>{};

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))
        // `lib/core/l10n/` là *đích đến* của chuỗi, không phải chỗ vi phạm.
        .where((f) => !f.path.contains('/l10n/'));

    for (final file in files) {
      for (final line in file.readAsLinesSync()) {
        final t = line.trimLeft();
        // Chú thích tiếng Việt là thứ dự án này khuyến khích, không phải nợ.
        if (t.startsWith('//') || t.startsWith('*')) continue;
        for (final m in literal.allMatches(line)) {
          if (coDau.hasMatch(m.group(0)!)) {
            tong++;
            theoFile[file.path] = (theoFile[file.path] ?? 0) + 1;
          }
        }
      }
    }

    final nang = theoFile.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    expect(
      tong,
      lessThanOrEqualTo(_nguong),
      reason:
          'Có $tong chuỗi tiếng Việt viết cứng, vượt ngưỡng $_nguong.\n'
          'Chuỗi mới phải vào `lib/core/l10n/arb/app_vi.arb` rồi đọc qua '
          '`L10n.of(context)` — xem CONTRIBUTING §Quy ước.\n'
          'Nhiều nhất: '
          '${nang.take(5).map((e) => '${e.key} (${e.value})').join(', ')}',
    );

    // Dọn được thì hạ ngưỡng ngay, nếu không lần sau lại có chỗ trống để đắp
    // nợ mới vào mà test vẫn xanh.
    expect(
      tong,
      greaterThan(_nguong - 20),
      reason:
          'Còn $tong chuỗi cứng, thấp hơn ngưỡng $_nguong khá nhiều. '
          'Hạ `_nguong` trong file này xuống $tong.',
    );
  });
}
