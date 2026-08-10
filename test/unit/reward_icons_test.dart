import 'dart:io';

import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/utils/ngay_viet.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bộ hình của phần thưởng, và cách hiển thị ngày tháng tiếng Việt.
void main() {
  /// Điều kiện thật để một icon hiện được là **có file asset**, không phải có
  /// mặt trong map emoji: `AppIcon` đọc thẳng `assets/icons/<key>.png`. Vì vậy
  /// test kiểm file, và khoá `jar_*` chỉ có asset mà không có emoji vẫn hợp lệ.
  void expectCoAsset(String key) {
    expect(
      File(assetPathForIcon(key)).existsSync(),
      isTrue,
      reason: 'thiếu ${assetPathForIcon(key)} — AppIcon sẽ hiện dấu hỏi',
    );
  }

  group('bộ hình phần thưởng', () {
    test('mọi khoá đều có file asset', () {
      kRewardIconKeys.forEach(expectCoAsset);
    });

    test('không trùng khoá', () {
      expect(kRewardIconKeys.toSet().length, kRewardIconKeys.length);
    });

    test('mọi khoá nhiệm vụ cũng có file asset', () {
      kTaskIconKeys.forEach(expectCoAsset);
    });

    test('mọi emoji tra ngược được đều có file asset', () {
      // `jars.emoji` và `members.avatar_key` lưu ký tự emoji; thiếu asset ở đây
      // là hũ hoặc avatar hiện dấu hỏi.
      kEmojiIconKeys.values.forEach(expectCoAsset);
    });

    test('mặc định của phần thưởng khác mặc định của nhiệm vụ', () {
      // Dùng chung một mặc định thì mọi phần thưởng tự nhập trông như một việc
      // phải làm — đúng cái đã xảy ra khi phần thưởng rơi về ✏️.
      expect(kDefaultRewardIconKey, isNot(kDefaultTaskIconKey));
      expect(kRewardIconKeys, contains(kDefaultRewardIconKey));
      expectCoAsset(kDefaultRewardIconKey);
      expectCoAsset(kDefaultTaskIconKey);
    });

    test('không lẫn hình việc nhà vào bộ phần thưởng', () {
      // Chọn 🧹 cho một phần thưởng thì vô nghĩa như chọn 🍦 cho việc nhà.
      for (final key in const ['broom', 'trash', 'dish', 'tooth', 'laundry']) {
        expect(
          kRewardIconKeys,
          isNot(contains(key)),
          reason: '"$key" là hình việc nhà',
        );
      }
    });

    test('không lẫn hình phần thưởng vào bộ nhiệm vụ', () {
      for (final key in const ['ice_cream', 'pizza', 'money', 'ticket']) {
        expect(
          kTaskIconKeys,
          isNot(contains(key)),
          reason: '"$key" là hình phần thưởng',
        );
      }
    });
  });

  group('ngày tháng kiểu Việt', () {
    test('ngày ngắn là dd/MM, luôn hai chữ số', () {
      expect(ngayNganGon(const CalendarDate(2026, 8, 1)), '01/08');
      expect(ngayNganGon(const CalendarDate(2026, 12, 25)), '25/12');
    });

    test('ngày đầy đủ là dd/MM/yyyy, không phải ISO', () {
      // ISO `2026-08-10` là dạng **lưu trong DB**, không phải dạng người Việt
      // đọc. Và không được ra `08/10/2026` kiểu Mỹ — cùng chuỗi số nhưng đọc
      // thành tháng Tám ngày Mười.
      expect(ngayDayDu(const CalendarDate(2026, 8, 10)), '10/08/2026');
    });

    test('ngày kèm giờ có đủ giờ phút hai chữ số', () {
      expect(ngayGio(DateTime(2026, 8, 10, 9, 5)), '10/08 09:05');
      expect(ngayGio(DateTime(2026, 8, 10, 14, 30)), '10/08 14:30');
    });

    test('thứ viết tắt theo quy ước 1 = thứ Hai', () {
      expect(thuNganGon(1), 'T2');
      expect(thuNganGon(7), 'CN');
    });

    test('chuỗi thứ xếp tăng dần và bỏ trùng', () {
      expect(thuTuChuoi('5,1,3,1'), 'T2, T4, T6');
    });

    test('đủ bảy thứ thì gọi là hằng ngày, không liệt kê bảy chữ', () {
      expect(thuTuChuoi('1,2,3,4,5,6,7'), 'Hằng ngày');
    });

    test('rỗng trả null để mỗi màn tự chọn cách nói', () {
      expect(thuTuChuoi(''), isNull);
      expect(thuTuChuoi('  '), isNull);
    });
  });
}
