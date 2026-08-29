import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/features/stats/jar_add_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

/// Thêm hũ mới thì tỷ lệ các hũ cũ phải chia lại sao cho **tổng vẫn 100%** —
/// chủ dự án chốt 26/08/2026.
///
/// Ràng buộc này không phải chuyện thẩm mỹ: tổng khác 100 thì `wallet_dao`
/// lặng lẽ rơi về kế hoạch mặc định, và mọi con số bố mẹ vừa đặt biến mất
/// không một lời báo.
void main() {
  JarDef hu(String key, int pct) =>
      JarDef(key: key, title: key, emoji: '💰', pct: pct);

  int tong(Map<String, int> moi, int pctHuMoi) =>
      moi.values.fold(pctHuMoi, (t, v) => t + v);

  test('ba hũ mặc định, hũ mới lấy 10% — tổng vẫn 100', () {
    final moi = chiaLaiTyLeHu([
      hu('spend', 50),
      hu('save', 40),
      hu('give', 10),
    ], 10);
    expect(tong(moi, 10), 100);
  });

  test('hũ lớn gánh nhiều hơn hũ nhỏ', () {
    final moi = chiaLaiTyLeHu([
      hu('spend', 50),
      hu('save', 40),
      hu('give', 10),
    ], 10);
    expect(moi['spend']! > moi['save']!, isTrue);
    expect(moi['save']! > moi['give']!, isTrue);
  });

  test('không hũ nào xuống dưới 0', () {
    final moi = chiaLaiTyLeHu([
      hu('spend', 90),
      hu('give', 10),
    ], 90);
    expect(moi.values.every((v) => v >= 0), isTrue);
    expect(tong(moi, 90), 100);
  });

  test('phần dư làm tròn dồn vào hũ lớn nhất, không phải hũ nhỏ', () {
    // 3 hũ 33/33/34, nhường 10% -> mỗi hũ chia lẻ, chắc chắn có dư.
    final moi = chiaLaiTyLeHu([
      hu('a', 33),
      hu('b', 33),
      hu('c', 34),
    ], 10);
    expect(tong(moi, 10), 100);
    expect(moi['c']! >= moi['a']!, isTrue);
  });

  test('tổng luôn 100 với mọi tỷ lệ hũ mới từ 0 tới 90', () {
    for (var pct = 0; pct <= 90; pct += 5) {
      final moi = chiaLaiTyLeHu([
        hu('spend', 50),
        hu('save', 40),
        hu('give', 10),
      ], pct);
      expect(
        tong(moi, pct),
        100,
        reason: 'hũ mới $pct% cho tổng ${tong(moi, pct)}',
      );
    }
  });

  test('chưa có hũ nào thì không chia gì cả', () {
    expect(chiaLaiTyLeHu(const [], 10), isEmpty);
  });
}
