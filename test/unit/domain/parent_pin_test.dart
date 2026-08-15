import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/parent_pin_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// PIN phụ huynh — chặn con tự đổi sang vai bố mẹ.
///
/// Hai hướng sai đều tệ và test này canh cả hai:
/// - **Quá lỏng**: con vẫn vào được vai bố mẹ → tự duyệt việc của mình.
/// - **Quá chặt**: nhà chưa đặt PIN mà bị khoá vai bố mẹ → không ai vào được
///   Cài đặt để đặt PIN, app tự khoá chính nó.
void main() {
  late AppDatabase db;
  late MemberDao memberDao;
  late ParentPinService service;

  const familyId = 'fam-1';
  const parentId = 'bo-me-1';
  const childId = 'con-1';

  setUp(() async {
    db = AppDatabase.memory();
    memberDao = MemberDao(db);
    service = ParentPinService(memberDao: memberDao);

    await memberDao.createFamily(
      FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'),
    );
    await memberDao.addMember(
      MembersCompanion.insert(
        id: parentId,
        familyId: familyId,
        kind: MemberKind.parent.name,
        displayName: 'Bố mẹ',
      ),
    );
    await memberDao.addMember(
      MembersCompanion.insert(
        id: childId,
        familyId: familyId,
        kind: MemberKind.child.name,
        displayName: 'Minh',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('dạng PIN', () {
    test('đúng bốn chữ số mới hợp lệ', () {
      expect(ParentPinService.isValidFormat('1234'), isTrue);
      expect(ParentPinService.isValidFormat('123'), isFalse);
      expect(ParentPinService.isValidFormat('12345'), isFalse);
      expect(ParentPinService.isValidFormat('12a4'), isFalse);
      expect(ParentPinService.isValidFormat(''), isFalse);
    });

    test('đặt PIN sai dạng bị từ chối', () {
      expect(
        () => service.setPin(familyId: familyId, pin: 'abcd'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('băm PIN', () {
    test('không lưu PIN dạng chữ thường trong DB', () async {
      await service.setPin(familyId: familyId, pin: '1234');

      final parent = (await memberDao.parents(familyId)).single;
      expect(parent.pinHash, isNotNull);
      expect(
        parent.pinHash,
        isNot(contains('1234')),
        reason: 'PIN phải được băm, không lưu thẳng',
      );
    });

    test('cùng PIN cho cùng hash, khác PIN cho khác hash', () {
      expect(
        ParentPinService.hashPin('1234'),
        ParentPinService.hashPin('1234'),
      );
      expect(
        ParentPinService.hashPin('1234'),
        isNot(ParentPinService.hashPin('4321')),
      );
    });
  });

  group('kiểm tra PIN', () {
    test('nhà chưa đặt PIN thì không khoá ai cả', () async {
      // Ca quan trọng nhất. Trả `false` ở đây là khoá cứng vai bố mẹ của **mọi**
      // nhà chưa đặt PIN — không ai vào được Cài đặt để đặt PIN nữa.
      expect(await service.isSet(familyId), isFalse);
      expect(await service.verify(familyId: familyId, pin: ''), isTrue);
      expect(await service.verify(familyId: familyId, pin: '9999'), isTrue);
    });

    test('đặt rồi thì đúng PIN mới qua', () async {
      await service.setPin(familyId: familyId, pin: '1234');

      expect(await service.isSet(familyId), isTrue);
      expect(await service.verify(familyId: familyId, pin: '1234'), isTrue);
      expect(await service.verify(familyId: familyId, pin: '4321'), isFalse);
      expect(await service.verify(familyId: familyId, pin: ''), isFalse);
    });

    test('đổi PIN thì PIN cũ hết tác dụng', () async {
      await service.setPin(familyId: familyId, pin: '1234');
      await service.setPin(familyId: familyId, pin: '5678');

      expect(await service.verify(familyId: familyId, pin: '1234'), isFalse);
      expect(await service.verify(familyId: familyId, pin: '5678'), isTrue);
    });

    test('bỏ PIN thì mở khoá lại', () async {
      await service.setPin(familyId: familyId, pin: '1234');
      await service.clearPin(familyId);

      expect(await service.isSet(familyId), isFalse);
      expect(await service.verify(familyId: familyId, pin: '0000'), isTrue);
    });

    test('PIN đặt cho mọi hồ sơ bố mẹ, không chỉ hồ sơ đầu', () async {
      await memberDao.addMember(
        MembersCompanion.insert(
          id: 'bo-me-2',
          familyId: familyId,
          kind: MemberKind.parent.name,
          displayName: 'Mẹ',
        ),
      );

      await service.setPin(familyId: familyId, pin: '1234');

      final parents = await memberDao.parents(familyId);
      expect(parents.length, 2);
      expect(
        parents.every((p) => (p.pinHash ?? '').isNotEmpty),
        isTrue,
        reason: 'một PIN chung cho cả nhà, không phải mỗi người một PIN',
      );
    });

    test('không đặt PIN lên hồ sơ trẻ', () async {
      await service.setPin(familyId: familyId, pin: '1234');

      final child = await memberDao.getMember(childId);
      expect(child.pinHash, isNull);
    });
  });
}
