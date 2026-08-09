import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/data/seed/presets.dart';
import 'package:beong/data/seed/reward_presets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mọi nhiệm vụ đều phải có icon.
///
/// `iconForKey` có đường rơi về `⭐`, nên một khoá sai **không gây lỗi** — nó chỉ
/// làm thẻ việc hiện ngôi sao chung chung, giống hệt mọi việc khác. Trẻ đọc hình
/// trước khi đọc chữ, nên một danh sách toàn ⭐ là mất gần hết tác dụng của thẻ
/// việc mà không có dấu hiệu nào trong log hay test.
void main() {
  group('mọi preset đều có icon thật', () {
    test('task preset: không khoá nào rơi về ⭐', () {
      for (final preset in kTaskPresets) {
        expect(
          preset.iconKey,
          isNotEmpty,
          reason: 'preset ${preset.key} không có iconKey',
        );
        expect(
          taskIcons.containsKey(preset.iconKey),
          isTrue,
          reason:
              'preset ${preset.key} dùng khoá "${preset.iconKey}" '
              'không có trong taskIcons — sẽ hiện ⭐',
        );
      }
    });

    test('reward preset: không khoá nào rơi về ⭐', () {
      for (final preset in kRewardPresets) {
        expect(
          taskIcons.containsKey(preset.iconKey),
          isTrue,
          reason: 'phần thưởng ${preset.key} dùng khoá "${preset.iconKey}"',
        );
      }
    });

    test('routine preset có icon', () {
      for (final routine in kRoutinePresets) {
        expect(
          taskIcons.containsKey(routine.iconKey),
          isTrue,
          reason: 'routine ${routine.key} dùng khoá "${routine.iconKey}"',
        );
      }
    });
  });

  group('bộ hình bố mẹ chọn được', () {
    test('mọi khoá đều tra ra emoji thật', () {
      for (final key in kTaskIconKeys) {
        expect(
          taskIcons.containsKey(key),
          isTrue,
          reason: 'kTaskIconKeys có "$key" nhưng taskIcons không có',
        );
        expect(iconForKey(key), isNot(taskIconFallback));
      }
    });

    test('không trùng khoá', () {
      expect(kTaskIconKeys.toSet().length, kTaskIconKeys.length);
    });

    test('có đủ hình cho nhiệm vụ ngoài việc nhà', () {
      // App dùng cho cả học bài, đi chơi, thể dục — đó là lý do tab tên "Nhiệm
      // vụ" chứ không phải "Việc nhà". Bộ hình chỉ có chổi với bát đĩa thì bố mẹ
      // không tả được việc học.
      for (final key in const ['books', 'abacus', 'soccer', 'park', 'music']) {
        expect(
          kTaskIconKeys,
          contains(key),
          reason: 'thiếu hình cho nhóm việc ngoài việc nhà',
        );
      }
    });

    test('không dùng emoji người', () {
      // Hình người luôn mang theo giới tính và màu da, mà đây là bộ hình dùng
      // chung cho mọi bé.
      const human = ['🏃', '🏊', '🧍', '👦', '👧', '🧑', '👶'];
      for (final key in kTaskIconKeys) {
        expect(
          human,
          isNot(contains(iconForKey(key))),
          reason: '"$key" là emoji người',
        );
      }
    });

    test('đủ nhiều để không phải dùng lại một hình cho mọi việc', () {
      expect(kTaskIconKeys.length, greaterThanOrEqualTo(20));
    });
  });
}
