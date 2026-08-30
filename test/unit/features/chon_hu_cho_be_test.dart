import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/features/members/chon_hu_cho_be.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chọn bé mới dùng những hũ nào.
///
/// Chủ dự án nêu 30/08/2026: *"khi tạo profile cho trẻ thì phải có option để
/// chọn bao nhiêu hũ — ví dụ tổng hũ đã tạo có 8 hũ, chọn 3 hũ cho profile cần
/// tạo."*
///
/// Điều phải giữ bằng mọi giá: tổng của bộ hũ bé nhận **luôn đúng 100%**. Tổng
/// khác 100 thì `wallet_dao.planFor` lặng lẽ rơi về kế hoạch mặc định — bé
/// nhận một bộ hũ không ai đặt, và không có lời báo nào.
JarDef hu(String key, int pct) =>
    JarDef(key: key, title: key, emoji: '🛍️', pct: pct);

int tong(Map<String, int> m) => m.values.fold(0, (a, b) => a + b);

void main() {
  final boTamHu = [
    hu('spend', 30),
    hu('save', 20),
    hu('give', 10),
    hu('hoctap', 10),
    hu('dochoi', 10),
    hu('sach', 8),
    hu('xedap', 7),
    hu('tudien', 5),
  ];

  test('giữ cả bộ thì tỷ lệ vẫn đủ 100%', () {
    final moi = tyLeSauKhiChon(boTamHu, {for (final j in boTamHu) j.key});
    expect(tong(moi), 100);
  });

  test('chọn 3 trong 8 hũ thì ba hũ đó chia nhau đúng 100%', () {
    final moi = tyLeSauKhiChon(boTamHu, {'spend', 'save', 'give'});

    expect(moi.keys.toSet(), {'spend', 'save', 'give'});
    expect(
      tong(moi),
      100,
      reason:
          'ba hũ này đang cộng lại mới 60%. Không chia lại là để hụt 40% — và '
          'tầng chia xu im lặng rơi về bộ mặc định',
    );
  });

  test('chia theo tỷ lệ hiện có, hũ lớn vẫn lớn hơn hũ nhỏ', () {
    final moi = tyLeSauKhiChon(boTamHu, {'spend', 'save', 'give'});

    expect(moi['spend'], greaterThan(moi['save'] ?? 0));
    expect(moi['save'], greaterThan(moi['give'] ?? 0));
  });

  test('chọn đúng một hũ thì hũ đó nhận trọn 100%', () {
    expect(tyLeSauKhiChon(boTamHu, {'spend'}), {'spend': 100});
  });

  test('hũ bị bỏ không còn trong bảng tỷ lệ', () {
    final moi = tyLeSauKhiChon(boTamHu, {'spend', 'save'});
    expect(moi.containsKey('hoctap'), isFalse);
  });

  test('không chọn hũ nào thì trả bảng rỗng, không chia bừa', () {
    expect(
      tyLeSauKhiChon(boTamHu, const {}),
      isEmpty,
      reason:
          'giao diện khoá ô cuối cùng lại nên ca này không xảy ra qua tay '
          'người dùng — nhưng trả 100% cho một hũ không ai chọn thì tệ hơn là '
          'trả rỗng',
    );
  });

  test('bộ hũ lẻ vẫn cộng đủ 100, không hụt vì làm tròn', () {
    // 3 hũ 33/33/34 là ca làm tròn kinh điển.
    final bo = [hu('a', 33), hu('b', 33), hu('c', 34), hu('d', 20)];
    expect(tong(tyLeSauKhiChon(bo, {'a', 'b', 'c'})), 100);
    expect(tong(tyLeSauKhiChon(bo, {'a', 'd'})), 100);
    expect(tong(tyLeSauKhiChon(bo, {'b', 'c', 'd'})), 100);
  });
}
