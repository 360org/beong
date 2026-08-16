import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/domain/services/money_exchange.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quy đổi xu ra tiền thật — ADR-017.
void main() {
  group('quy đổi', () {
    test('tắt thì không hiện gì cả', () {
      // Mặc định là tắt, và đó là quyết định có chủ ý: gắn việc nhà với tiền là
      // chủ đề gây tranh cãi, mà mặc định của app là một lời khuyên ngầm.
      expect(const MoneyExchange(null).enabled, isFalse);
      expect(const MoneyExchange(null).dongFor(100), isNull);
      expect(const MoneyExchange(null).labelFor(100), isNull);
    });

    test('tỷ giá không dương coi như tắt', () {
      expect(const MoneyExchange(0).enabled, isFalse);
      expect(const MoneyExchange(-5).dongFor(100), isNull);
    });

    test('10 xu = 1.000 đ thì 65 xu ra 6.500 đ', () {
      const rate = MoneyExchange(10);
      expect(rate.enabled, isTrue);
      expect(rate.dongFor(65), 6500);
      expect(rate.labelFor(65), '≈ 6.500 đ');
    });

    test('làm tròn **xuống**, không lên', () {
      // Hiện nhiều hơn số con thật sự đổi được là hứa hão, mà lời hứa hão về
      // tiền thì bố mẹ phải trả bằng tiền thật.
      const rate = MoneyExchange(3);
      expect(rate.dongFor(1), 333);
      expect(rate.dongFor(2), 666);
    });

    test('0 xu vẫn hiện 0 đ chứ không ẩn', () {
      expect(const MoneyExchange(10).labelFor(0), '≈ 0 đ');
    });
  });

  group('định dạng số tiền', () {
    test('ngăn cách hàng nghìn bằng dấu chấm, đúng lối viết tiếng Việt', () {
      expect(dinhDangDong(0), '0');
      expect(dinhDangDong(999), '999');
      expect(dinhDangDong(1000), '1.000');
      expect(dinhDangDong(6500), '6.500');
      expect(dinhDangDong(1234567), '1.234.567');
    });

    test('số âm giữ dấu trừ ở ngoài', () {
      expect(dinhDangDong(-6500), '-6.500');
    });
  });

  group('lưu tỷ giá', () {
    late AppDatabase db;
    late MemberDao memberDao;
    const familyId = 'fam-1';

    setUp(() async {
      db = AppDatabase.memory();
      memberDao = MemberDao(db);
      await memberDao.createFamily(
        FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('gia đình mới thì quy đổi đang tắt', () async {
      final rate = await memberDao.watchExchangeRate(familyId).first;
      expect(rate.enabled, isFalse);
    });

    test('bật rồi tắt lại được', () async {
      await memberDao.setExchangeRate(familyId, 10);
      expect((await memberDao.watchExchangeRate(familyId).first).xuPerUnit, 10);

      await memberDao.setExchangeRate(familyId, null);
      expect(
        (await memberDao.watchExchangeRate(familyId).first).enabled,
        isFalse,
      );
    });

    test('tỷ giá 0 hoặc âm bị từ chối, không lặng lẽ coi như tắt', () async {
      // 0 xu đổi được 1.000 đ nghĩa là xu vô giá trị hoặc vô hạn giá trị, tuỳ
      // cách đọc — không có cách hiểu nào đúng, nên đừng đoán hộ.
      await expectLater(
        memberDao.setExchangeRate(familyId, 0),
        throwsArgumentError,
      );
      await expectLater(
        memberDao.setExchangeRate(familyId, -1),
        throwsArgumentError,
      );
    });
  });
}
