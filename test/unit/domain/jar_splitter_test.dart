import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/jar_splitter.dart';
import 'package:flutter_test/flutter_test.dart';

/// ADR-016. Ràng buộc quan trọng nhất: tổng ba hũ **luôn** bằng số xu đã chia.
/// Lệch một xu vì làm tròn là mất niềm tin của đứa trẻ.
void main() {
  group('splitAmount', () {
    test('chia chẵn theo tỷ lệ mặc định 50/40/10', () {
      final result = splitAmount(100, JarSplit.defaultSplit);
      expect(result[Jar.spend], 50);
      expect(result[Jar.save], 40);
      expect(result[Jar.give], 10);
    });

    test('phần dư dồn vào hũ Tiêu, tổng vẫn khớp', () {
      final result = splitAmount(25, JarSplit.defaultSplit);
      // save = 10, give = 2, spend nhận phần còn lại là 13.
      expect(result[Jar.save], 10);
      expect(result[Jar.give], 2);
      expect(result[Jar.spend], 13);
      expect(result.values.reduce((a, b) => a + b), 25);
    });

    test('tổng luôn khớp với mọi số xu từ 0 đến 500', () {
      for (var amount = 0; amount <= 500; amount++) {
        final result = splitAmount(amount, JarSplit.defaultSplit);
        expect(
          result.values.reduce((a, b) => a + b),
          amount,
          reason: 'Chia $amount xu bị lệch tổng',
        );
      }
    });

    test('tổng khớp với nhiều tỷ lệ khác nhau', () {
      const splits = [
        JarSplit(spend: 33, save: 33, give: 34),
        JarSplit(spend: 70, save: 29, give: 1),
        JarSplit(spend: 0, save: 100, give: 0),
        JarSplit.spendOnly,
      ];
      for (final split in splits) {
        for (var amount = 1; amount <= 100; amount++) {
          expect(
            splitAmount(amount, split).values.reduce((a, b) => a + b),
            amount,
            reason: 'Lệch với $split khi chia $amount xu',
          );
        }
      }
    });

    test('số âm chia cùng tỷ lệ để hoàn tác được giao dịch', () {
      final earned = splitAmount(25, JarSplit.defaultSplit);
      final refunded = splitAmount(-25, JarSplit.defaultSplit);

      for (final jar in Jar.values) {
        expect(
          earned[jar]! + refunded[jar]!,
          0,
          reason: 'Hoàn xu không đưa hũ ${jar.name} về trạng thái cũ',
        );
      }
    });

    test('không xu thì cả ba hũ đều bằng 0', () {
      final result = splitAmount(0, JarSplit.defaultSplit);
      expect(result.values.every((v) => v == 0), isTrue);
    });

    test('spendOnly dồn tất cả vào hũ Tiêu', () {
      final result = splitAmount(37, JarSplit.spendOnly);
      expect(result[Jar.spend], 37);
      expect(result[Jar.save], 0);
      expect(result[Jar.give], 0);
    });

    test('từ chối tỷ lệ không cộng thành 100', () {
      expect(
        () => splitAmount(10, const JarSplit(spend: 50, save: 40, give: 5)),
        throwsArgumentError,
      );
    });
  });

  group('JarSplit', () {
    test('mặc định hợp lệ', () {
      expect(JarSplit.defaultSplit.isValid, isTrue);
      expect(JarSplit.spendOnly.isValid, isTrue);
    });

    test('từ chối phần trăm âm', () {
      expect(const JarSplit(spend: 110, save: -10, give: 0).isValid, isFalse);
    });

    test('chuyển đổi qua lại JSON để lưu vào DB', () {
      const split = JarSplit(spend: 60, save: 30, give: 10);
      expect(JarSplit.fromJson(split.toJson()), split);
    });
  });
}
