import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/features/members/add_child_sheet.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

/// Thêm bé thứ hai trở đi.
///
/// Onboarding chỉ khai được **một** bé; trước khi có sheet "Thêm bé" thì nhà
/// hai con phải đăng xuất rồi làm lại từ đầu và mất hết dữ liệu cũ.
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

  Future<void> addChild(String id, {required int colorIndex}) {
    return memberDao.addMember(
      MembersCompanion.insert(
        id: id,
        familyId: familyId,
        kind: MemberKind.child.name,
        displayName: id,
        colorIndex: Value(colorIndex),
      ),
    );
  }

  group('màu gợi ý cho bé mới', () {
    test('nhà chưa có ai thì lấy màu đầu tiên', () {
      expect(nextFreeColorIndex(const []), 0);
    });

    test('tránh màu các bé đã dùng', () async {
      await addChild('con-1', colorIndex: 0);
      await addChild('con-2', colorIndex: 2);

      final members = await memberDao.watchMembers(familyId).first;
      final next = nextFreeColorIndex(members);

      // Trùng màu thì avatar và thẻ việc của hai bé trông y hệt nhau, mà màu là
      // thứ đầu tiên trẻ chưa đọc thạo dùng để nhận ra phần của mình.
      expect(next, 1);
      expect(members.map((m) => m.colorIndex), isNot(contains(next)));
    });

    test('hết màu thì quay vòng chứ không chặn thêm bé', () async {
      for (var i = 0; i < AppColors.profilePalette.length; i++) {
        await addChild('con-$i', colorIndex: i);
      }
      final members = await memberDao.watchMembers(familyId).first;

      // Thà hai bé trùng màu còn hơn không thêm được bé thứ N.
      expect(
        nextFreeColorIndex(members),
        inInclusiveRange(0, AppColors.profilePalette.length - 1),
      );
    });
  });

  test('thêm bé xong thì cả hai bé đều là trẻ của nhà', () async {
    await addChild('con-1', colorIndex: 0);
    await addChild('con-2', colorIndex: 1);

    final children = await memberDao.children(familyId);
    expect(children, hasLength(2));
    expect(
      children.every((c) => c.kind == MemberKind.child.name),
      isTrue,
    );
  });
}
