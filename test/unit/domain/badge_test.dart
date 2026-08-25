import 'dart:io';

import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/domain/entities/badge_def.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quy tắc trao huy hiệu — `01-product-spec.md` §4.6.
void main() {
  BadgeProgress progress({
    int streak = 0,
    int tasks = 0,
    int routineDays = 0,
    int redemptions = 0,
  }) => BadgeProgress(
    streakDays: streak,
    tasksDone: tasks,
    routinePerfectDays: routineDays,
    redemptions: redemptions,
  );

  group('danh mục huy hiệu', () {
    // Con số cứng ở đây là **cố ý**: nó không canh "đúng 11" cho vui, nó canh
    // việc không ai xoá nhầm một huy hiệu. Xoá huy hiệu là lấy lại thứ đã trao
    // cho một đứa trẻ — thêm thì cứ thêm và sửa số này, xoá thì phải dừng lại
    // nghĩ. 8 -> 11 khi bổ sung bậc cho thói quen và đổi thưởng.
    test('đủ số huy hiệu trong danh mục', () {
      expect(kBadges.length, 11);
    });

    test('khoá không trùng nhau', () {
      // Khoá đi vào `badges_earned.badge_key`; trùng khoá là hai huy hiệu khác
      // nhau đè lên nhau trong DB.
      expect(kBadges.map((b) => b.key).toSet().length, kBadges.length);
    });

    test('mọi huy hiệu đều có file hình', () {
      // Điều kiện thật để hình hiện được là có asset — `AppIcon` đọc thẳng file.
      for (final badge in kBadges) {
        expect(
          File(assetPathForIcon(badge.iconKey)).existsSync(),
          isTrue,
          reason: '${badge.key} thiếu ${assetPathForIcon(badge.iconKey)}',
        );
      }
    });

    test('mô tả viết cho trẻ đọc, không có công thức', () {
      for (final badge in kBadges) {
        expect(badge.description, isNotEmpty);
        expect(
          badge.description,
          isNot(contains('>=')),
          reason: 'mô tả là câu cho trẻ, không phải điều kiện của máy',
        );
      }
    });

    test('có đủ bốn loại điều kiện', () {
      expect(
        kBadges.map((b) => b.kind).toSet().length,
        BadgeKind.values.length,
      );
    });
  });

  group('xét huy hiệu đạt được', () {
    test('chưa làm gì thì chưa có huy hiệu nào', () {
      expect(earnedBadges(progress()), isEmpty);
    });

    test('đủ mốc thì đạt, thiếu một là chưa', () {
      expect(
        earnedBadges(progress(streak: 2)).map((b) => b.key),
        isNot(contains('streak_3')),
      );
      expect(
        earnedBadges(progress(streak: 3)).map((b) => b.key),
        contains('streak_3'),
      );
    });

    test('vượt mốc cao thì được cả các mốc thấp hơn', () {
      // Con làm 30 ngày liền mà chỉ được huy hiệu 30 ngày, không được 3 và 7,
      // thì bảng huy hiệu nhìn như bị lỗi.
      final keys = earnedBadges(progress(streak: 30)).map((b) => b.key);
      expect(keys, containsAll(['streak_3', 'streak_7', 'streak_30']));
    });

    test('các loại điều kiện không lẫn vào nhau', () {
      // Nhiều streak không được tự cho huy hiệu "100 việc".
      final keys = earnedBadges(progress(streak: 30)).map((b) => b.key);
      expect(keys, isNot(contains('tasks_10')));
      expect(keys, isNot(contains('first_reward')));
    });

    test('đổi thưởng lần đầu là đạt ngay', () {
      expect(
        earnedBadges(progress(redemptions: 1)).map((b) => b.key),
        contains('first_reward'),
      );
    });

    test('trọn bộ thói quen 7 ngày', () {
      expect(
        earnedBadges(progress(routineDays: 6)).map((b) => b.key),
        isNot(contains('routine_7')),
      );
      expect(
        earnedBadges(progress(routineDays: 7)).map((b) => b.key),
        contains('routine_7'),
      );
    });

    test('làm nhiều thứ cùng lúc thì đạt nhiều huy hiệu', () {
      final keys = earnedBadges(
        progress(streak: 7, tasks: 50, routineDays: 7, redemptions: 3),
      ).map((b) => b.key);
      expect(
        keys,
        containsAll([
          'streak_3',
          'streak_7',
          'tasks_10',
          'tasks_50',
          'routine_7',
          'first_reward',
        ]),
      );
      expect(keys, isNot(contains('tasks_100')));
    });
  });
}
