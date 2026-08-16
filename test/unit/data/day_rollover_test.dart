import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:flutter_test/flutter_test.dart';

/// Giờ đổi ngày của gia đình.
///
/// Cột `families.day_rollover_hour` có từ v1 và `DayStartService` đọc nó, nhưng
/// **không có gì ghi nó** và các màn hình thì tự dựng `FamilyClock` với mặc
/// định 4. Nhà đặt giờ khác sẽ rơi vào ca tệ nhất: bộ sinh việc ghi lượt cho
/// ngày X còn màn hình hỏi ngày X±1, con mở app thấy trống trơn.
void main() {
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

  test('mặc định là 4 giờ sáng', () async {
    expect(await memberDao.watchDayRolloverHour(familyId).first, 4);
  });

  test('đặt rồi thì đọc lại đúng', () async {
    await memberDao.setDayRolloverHour(familyId, 0);
    expect(await memberDao.watchDayRolloverHour(familyId).first, 0);
  });

  test('giờ ngoài 0..12 bị từ chối, không kẹp lặng lẽ', () async {
    // `FamilyClock` có `assert` cùng khoảng, mà `assert` tắt ở bản release —
    // giá trị hỏng sẽ lọt xuống và làm lệch ngày của cả nhà.
    await expectLater(
      memberDao.setDayRolloverHour(familyId, -1),
      throwsArgumentError,
    );
    await expectLater(
      memberDao.setDayRolloverHour(familyId, 13),
      throwsArgumentError,
    );
    expect(
      await memberDao.watchDayRolloverHour(familyId).first,
      4,
      reason: 'lần đặt hỏng không được ghi gì',
    );
  });

  test('giờ đổi ngày đổi thật sự ngày của gia đình', () async {
    // 02:00 sáng ngày 10: với mốc 4 giờ thì vẫn là ngày 9, với mốc 0 giờ thì đã
    // là ngày 10. Đây chính là chỗ hai bên lệch nhau nếu màn hình và bộ sinh
    // việc dùng hai mốc khác nhau.
    final luc2Gio = DateTime.utc(2026, 8, 10, 2);
    const offset = Duration.zero;

    expect(
      const FamilyClock(timeZoneOffset: offset).dateAt(luc2Gio).toString(),
      '2026-08-09',
    );
    expect(
      const FamilyClock(
        timeZoneOffset: offset,
        dayRolloverHour: 0,
      ).dateAt(luc2Gio).toString(),
      '2026-08-10',
    );
  });
}
