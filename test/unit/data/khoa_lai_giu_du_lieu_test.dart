import 'package:beong/app/router.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/session_store.dart';
import 'package:beong/data/local/settings_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/parent_pin_service.dart';
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

  test('gỡ PIN thì luồng thành viên phát lại ngay', () async {
    // Dòng "PIN của bố mẹ" trong Cài đặt đọc trạng thái từ chính luồng này.
    // Bản trước đọc một lần lúc dựng, nên gỡ PIN qua "Quên PIN?" xong dòng đó
    // vẫn ghi "Đang bật" trong khi DB đã sạch — bố mẹ đọc được là gỡ hỏng.
    // Nếu `watchMembers` không phát lại khi `pin_hash` đổi thì bản sửa im lặng
    // không chạy, và không màn hình nào lộ ra.
    final pin = ParentPinService(memberDao: members);
    await pin.setPin(familyId: familyId, pin: '1357');

    final luot = members.watchMembers(familyId);
    expect(
      luot.map(
        (ds) => ds
            .where((m) => m.kind == MemberKind.parent.name)
            .any((m) => (m.pinHash ?? '').isNotEmpty),
      ),
      emitsInOrder(<bool>[true, false]),
    );

    await pin.clearPin(familyId);
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
