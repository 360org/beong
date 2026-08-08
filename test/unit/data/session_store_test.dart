import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/session_store.dart';
import 'package:beong/data/local/settings_dao.dart';
import 'package:flutter_test/flutter_test.dart';

/// Session không sống qua lần mở app là lỗi đã chặn đường cả luồng khởi tạo
/// (`docs/09-onboarding-pairing.md` §2): mở lại app là quay về onboarding và
/// tạo ra một gia đình mới. Những test dưới đây giữ đúng chỗ đó.
void main() {
  late AppDatabase db;
  late SessionStore store;

  setUp(() {
    db = AppDatabase.memory();
    store = SessionStore(SettingsDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('máy chưa từng đăng nhập thì không có session', () async {
    expect(await store.load(), isNull);
  });

  test('lưu rồi đọc lại ra đúng session', () async {
    const session = AppSession(familyId: 'fam-1', activeMemberId: 'me-1');

    await store.save(session);

    expect(await store.load(), session);
  });

  test('giữ được vai con, không mặc định thành bố mẹ', () async {
    // Chỗ này dễ sai: `AppSession.isParent` mặc định là true, nên nếu cờ vai
    // không thật sự được lưu thì bé mở app lại sẽ vào màn hình bố mẹ.
    const session = AppSession(
      familyId: 'fam-1',
      activeMemberId: 'con-1',
      isParent: false,
    );

    await store.save(session);

    expect(await store.load(), session);
    expect((await store.load())!.isParent, isFalse);
  });

  test('lưu lần sau ghi đè lần trước, không cộng thêm hàng', () async {
    await store.save(
      const AppSession(familyId: 'fam-1', activeMemberId: 'me-1'),
    );
    await store.save(
      const AppSession(
        familyId: 'fam-1',
        activeMemberId: 'con-1',
        isParent: false,
      ),
    );

    final loaded = await store.load();
    expect(loaded!.activeMemberId, 'con-1');
    expect(loaded.isParent, isFalse);

    final rows = await db.select(db.deviceSettings).get();
    expect(rows.length, 3, reason: 'đúng ba khoá, không nhân bản');
  });

  test('đăng xuất xoá sạch session', () async {
    await store.save(
      const AppSession(familyId: 'fam-1', activeMemberId: 'me-1'),
    );

    await store.clear();

    expect(await store.load(), isNull);
    expect(await db.select(db.deviceSettings).get(), isEmpty);
  });

  test('session nửa vời bị coi như chưa có', () async {
    // Ghi thiếu member_id — mô phỏng ca ghi bị ngắt giữa. Nếu load() trả về
    // một AppSession với memberId rỗng thì router sẽ dựng màn hình trống thay
    // vì đưa về onboarding.
    final settings = SettingsDao(db);
    await settings.write('session.family_id', 'fam-1');

    expect(await store.load(), isNull);
  });

  test('giá trị rỗng cũng coi như chưa có session', () async {
    final settings = SettingsDao(db);
    await settings.writeAll({
      'session.family_id': '',
      'session.active_member_id': '',
      'session.is_parent': 'true',
    });

    expect(await store.load(), isNull);
  });

  group('SettingsDao', () {
    test('readAll trả đúng các khoá có mặt, bỏ khoá chưa ghi', () async {
      final settings = SettingsDao(db);
      await settings.writeAll({'a': '1', 'b': '2'});

      expect(await settings.readAll({'a', 'b', 'c'}), {'a': '1', 'b': '2'});
    });

    test('readAll với tập rỗng không chạy truy vấn nào', () async {
      expect(await SettingsDao(db).readAll({}), isEmpty);
    });

    test('write ghi đè giá trị cũ của cùng khoá', () async {
      final settings = SettingsDao(db);
      await settings.write('k', 'cũ');
      await settings.write('k', 'mới');

      expect(await settings.read('k'), 'mới');
    });

    test('read khoá chưa có trả null', () async {
      expect(await SettingsDao(db).read('không-có'), isNull);
    });
  });
}
