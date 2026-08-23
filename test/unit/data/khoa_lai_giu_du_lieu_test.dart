import 'package:beong/app/router.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/session_store.dart';
import 'package:beong/data/local/settings_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/mat_khau_ho_so.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

/// Khoá máy lại rồi vào lại — dữ liệu phải còn nguyên **một** nhà.
///
/// Kịch bản đã dựng lại được ở `docs/13-audit-luong-vao-app.md` §2: bấm ĐĂNG
/// XUẤT xong app về onboarding, làm lại onboarding sinh ra gia đình thứ hai, và
/// nhà đầu tiên — xu, sổ cái, huy hiệu của con — nằm lại trong DB không màn
/// hình nào mở tới được. Sổ cái "chỉ ghi thêm, không xoá" thành vô nghĩa nếu cả
/// cuốn sổ biến mất khỏi giao diện vì một lần bấm nhầm.
void main() {
  late AppDatabase db;
  late MemberDao members;
  late SessionStore session;

  const familyId = 'nha-1';
  const parentId = 'bo-me-1';

  setUp(() async {
    db = AppDatabase.memory();
    members = MemberDao(db);
    session = SessionStore(SettingsDao(db));

    await members.createFamily(
      FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'),
    );
    await members.addMember(
      MembersCompanion.insert(
        id: parentId,
        familyId: familyId,
        kind: MemberKind.parent.name,
        displayName: 'Bố mẹ',
      ),
    );
    await members.addMember(
      MembersCompanion.insert(
        id: 'con-1',
        familyId: familyId,
        kind: MemberKind.child.name,
        displayName: 'Minh',
        colorIndex: const Value(1),
      ),
    );
    await session.save(
      const AppSession(familyId: familyId, activeMemberId: parentId),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('khoá máy chỉ xoá session, không đụng dữ liệu nhà', () async {
    await session.clear();

    expect(await session.load(), isNull);
    expect((await members.allFamilies()).length, 1);
    expect((await members.watchMembers(familyId).first).length, 2);
  });

  test('khoá xong thì đi tới màn chọn người dùng, không phải onboarding', () {
    // Ràng buộc nối hai mảnh lại: `allFamilies` không rỗng là thứ nuôi cờ
    // `mayDaCoDuLieu`, và cờ đó là thứ router đọc.
    expect(
      diemDenDauTien(
        session: null,
        mayDaCoDuLieu: true,
        viTri: Routes.home,
      ),
      Routes.chonNguoiDung,
    );
  });

  test('đổi mật khẩu thì luồng thành viên phát lại ngay', () async {
    // Dòng "Mật khẩu hồ sơ" trong Cài đặt đọc trạng thái từ chính luồng này.
    // Bản trước đọc một lần lúc dựng, nên đổi mật khẩu ở chỗ khác xong dòng đó
    // vẫn ghi số cũ trong khi DB đã đổi. Nếu `watchMembers` không phát lại khi
    // `pin_hash` đổi thì bản sửa im lặng không chạy, và không màn hình nào lộ
    // ra.
    final matKhau = MatKhauHoSo(memberDao: members);

    final luot = members
        .watchMembers(familyId)
        .map((ds) => ds.where((m) => (m.pinHash ?? '').isEmpty).length);

    // `emitsThrough` chứ không phải `emitsInOrder([2, 1, 0])`: Drift gộp hai
    // lần ghi sát nhau thành một lần phát, nên nhịp trung gian không chắc có.
    // Ràng buộc thật là **có phát lại**, không phải phát bao nhiêu lần.
    expect(luot, emitsThrough(0));

    await matKhau.dat(memberId: parentId, matKhau: '1357');
    await matKhau.dat(memberId: 'con-1', matKhau: '2468');
  });

  test('máy đã lỡ dính lỗi vẫn mở lại được nhà cũ', () async {
    // Máy nào đăng xuất trước khi có bản sửa thì đang mang sẵn vài nhà mồ côi.
    // `allFamilies` trả **hết**, đó là lý do màn chọn người dùng liệt kê mọi
    // nhà chứ không chỉ nhà mới nhất — nếu không, dữ liệu cũ vẫn kẹt lại.
    await members.createFamily(
      FamiliesCompanion.insert(id: 'nha-2', name: 'Nhà mình'),
    );

    final all = await members.allFamilies();
    expect(all.length, 2);
    expect(all.map((f) => f.id), containsAll(<String>[familyId, 'nha-2']));
  });
}
