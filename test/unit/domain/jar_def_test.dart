import 'package:beong/domain/entities/jar_def.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JarPlan', () {
    test('ba hũ mặc định hợp lệ và tổng 100', () {
      expect(JarPlan.defaultPlan.isValid, isTrue);
      expect(JarPlan.defaultPlan.totalPct, 100);
    });

    test('hũ mặc định giữ đúng khoá cũ để sổ cái không phải di trú', () {
      expect(JarPlan.defaultPlan.jars.map((j) => j.key), [
        'spend',
        'save',
        'give',
      ]);
    });

    test('mọi hũ mặc định đều có emoji', () {
      for (final jar in kDefaultJars) {
        expect(jar.emoji.trim(), isNotEmpty, reason: jar.key);
      }
    });

    test('tổng khác 100 là không hợp lệ', () {
      const plan = JarPlan([
        JarDef(key: 'a', title: 'A', emoji: '🎁', pct: 50),
        JarDef(key: 'b', title: 'B', emoji: '📚', pct: 30),
      ]);
      expect(plan.isValid, isFalse);
    });

    test('trùng khoá là không hợp lệ', () {
      const plan = JarPlan([
        JarDef(key: 'a', title: 'A', emoji: '🎁', pct: 50),
        JarDef(key: 'a', title: 'A2', emoji: '📚', pct: 50),
      ]);
      expect(plan.isValid, isFalse);
    });

    test('không có hũ nào là không hợp lệ', () {
      expect(const JarPlan([]).isValid, isFalse);
    });

    test('ordered sắp theo orderIndex, hũ Cho đi ở cuối', () {
      // Thứ tự này quyết định hũ nào bị trừ trước khi phạt (ADR-022).
      expect(JarPlan.defaultPlan.ordered.last.key, kJarGive);
      expect(JarPlan.defaultPlan.ordered.first.key, kJarSpend);
    });
  });

  group('splitByPlan', () {
    test('chia đúng tỷ lệ mặc định', () {
      expect(splitByPlan(100, JarPlan.defaultPlan), {
        'spend': 50,
        'save': 40,
        'give': 10,
      });
    });

    test('tổng các phần luôn đúng bằng số xu, kể cả khi lẻ', () {
      for (var amount = 1; amount <= 97; amount++) {
        final parts = splitByPlan(amount, JarPlan.defaultPlan);
        expect(
          parts.values.fold(0, (a, b) => a + b),
          amount,
          reason: 'chia $amount xu',
        );
      }
    });

    test('phần dư dồn vào hũ đầu tiên', () {
      // 7 xu: save 2 (7*40/100=2), give 0, spend nhận 5 còn lại.
      expect(splitByPlan(7, JarPlan.defaultPlan), {
        'spend': 5,
        'save': 2,
        'give': 0,
      });
    });

    test('số âm chia cùng tỷ lệ để hoàn tác được', () {
      final parts = splitByPlan(-100, JarPlan.defaultPlan);
      expect(parts.values.fold(0, (a, b) => a + b), -100);
      expect(parts['save'], -40);
    });

    test('0 xu ra 0 cho mọi hũ, không mất hũ nào', () {
      final parts = splitByPlan(0, JarPlan.defaultPlan);
      expect(parts.length, 3);
      expect(parts.values.every((v) => v == 0), isTrue);
    });

    test('kế hoạch nhiều hũ do bố mẹ tự lập vẫn cộng đủ', () {
      const plan = JarPlan([
        JarDef(key: 'spend', title: 'Tiêu', emoji: '🛍️', pct: 40),
        JarDef(key: 'book', title: 'Sách', emoji: '📚', pct: 25, orderIndex: 1),
        JarDef(
          key: 'trip',
          title: 'Đi chơi',
          emoji: '✈️',
          pct: 25,
          orderIndex: 2,
        ),
        JarDef(
          key: 'give',
          title: 'Cho đi',
          emoji: '💝',
          pct: 10,
          orderIndex: 3,
        ),
      ]);

      for (var amount = 1; amount <= 60; amount++) {
        final parts = splitByPlan(amount, plan);
        expect(parts.values.fold(0, (a, b) => a + b), amount);
        expect(parts.length, 4);
      }
    });

    test('kế hoạch không hợp lệ thì báo lỗi, không chia sai lặng lẽ', () {
      const bad = JarPlan([
        JarDef(key: 'a', title: 'A', emoji: '🎁', pct: 70),
      ]);
      expect(() => splitByPlan(10, bad), throwsArgumentError);
    });

    test('một hũ 100% thì nhận hết', () {
      const plan = JarPlan([
        JarDef(key: 'spend', title: 'Tiêu', emoji: '🛍️', pct: 100),
      ]);
      expect(splitByPlan(37, plan), {'spend': 37});
    });
  });

  group('AllocationMode', () {
    test('mặc định là auto, giữ đúng ADR-016', () {
      expect(allocationModeFromDb(null), AllocationMode.auto);
      expect(allocationModeFromDb('rác'), AllocationMode.auto);
      expect(allocationModeFromDb('manual'), AllocationMode.manual);
    });
  });

  group('kJarEmojis', () {
    test('có đủ lựa chọn và không trùng', () {
      expect(kJarEmojis.length, greaterThanOrEqualTo(12));
      expect(kJarEmojis.toSet().length, kJarEmojis.length);
    });

    test('emoji của ba hũ mặc định đều nằm trong bộ chọn', () {
      for (final jar in kDefaultJars) {
        expect(kJarEmojis, contains(jar.emoji), reason: jar.key);
      }
    });
  });
}
