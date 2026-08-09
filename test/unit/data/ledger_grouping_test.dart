import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/jar_splitter.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Sổ của con" là chỗ trẻ tra xem xu đến từ đâu. Trước đây một việc 10 xu hiện
/// thành **ba dòng** (+5, +4, +1) vì sổ cái ghi mỗi hũ một dòng (ADR-016), và
/// mọi dòng đều mang cùng một chữ "Hoàn thành việc". Nhóm test này giữ chỗ đó.
void main() {
  late AppDatabase db;
  late WalletDao walletDao;
  late MemberDao memberDao;

  const familyId = 'fam-1';
  const childId = 'con-1';

  setUp(() async {
    db = AppDatabase.memory();
    walletDao = WalletDao(db);
    memberDao = MemberDao(db);

    await memberDao.createFamily(
      FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'),
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

  test('một lần cộng chia ba hũ ra **một** mục, không phải ba', () async {
    await walletDao.credit(
      familyId: familyId,
      memberId: childId,
      amount: 10,
      reason: TxReason.taskApproved,
      clientOpId: 'task-approved:i1',
      refType: 'task_instance',
      refId: 'i1',
      split: JarSplit.defaultSplit,
    );

    final raw = await walletDao.watchHistory(childId).first;
    expect(raw, hasLength(3), reason: 'sổ cái vẫn ghi mỗi hũ một dòng');

    final grouped = await walletDao.watchGroupedHistory(childId).first;
    expect(grouped, hasLength(1));
    expect(grouped.single.delta, 10, reason: 'tổng đúng bằng điểm việc');
    expect(grouped.single.byJar, {'spend': 5, 'save': 4, 'give': 1});
    expect(grouped.single.refId, 'i1', reason: 'để tra được tên việc');
  });

  test('nhiều việc ra nhiều mục, không lẫn vào nhau', () async {
    for (var i = 1; i <= 3; i++) {
      await walletDao.credit(
        familyId: familyId,
        memberId: childId,
        amount: 10,
        reason: TxReason.taskApproved,
        clientOpId: 'task-approved:i$i',
        refType: 'task_instance',
        refId: 'i$i',
        split: JarSplit.defaultSplit,
      );
    }

    final grouped = await walletDao.watchGroupedHistory(childId).first;
    expect(grouped, hasLength(3));
    expect(grouped.map((e) => e.refId).toSet(), {'i1', 'i2', 'i3'});
    expect(grouped.every((e) => e.delta == 10), isTrue);
  });

  test('thao tác một dòng vẫn ra một mục', () async {
    await walletDao.credit(
      familyId: familyId,
      memberId: childId,
      amount: 100,
      reason: TxReason.bonus,
      clientOpId: 'seed',
      split: JarSplit.spendOnly,
    );
    await walletDao.debit(
      familyId: familyId,
      memberId: childId,
      jar: Jar.spend,
      amount: 30,
      reason: TxReason.rewardRedeemed,
      clientOpId: 'redeem-1',
      refType: 'reward',
      refId: 'r1',
    );

    final grouped = await walletDao.watchGroupedHistory(childId).first;
    expect(grouped, hasLength(2));
    final redeem = grouped.firstWhere((e) => e.reason == 'rewardRedeemed');
    expect(redeem.delta, -30);
    expect(redeem.byJar, {'spend': -30});
  });

  test('khoản trừ nhiều hũ cũng gộp thành một mục', () async {
    await walletDao.credit(
      familyId: familyId,
      memberId: childId,
      amount: 10,
      reason: TxReason.bonus,
      clientOpId: 'seed',
      split: JarSplit.defaultSplit,
    );
    // 5 tiêu / 4 để dành / 1 cho đi; trừ 8 phải lấn sang hũ thứ hai.
    await walletDao.penalize(
      familyId: familyId,
      memberId: childId,
      amount: 8,
      clientOpId: 'missed-penalty:i1',
      refType: 'task_instance',
      refId: 'i1',
      note: 'Hết ngày chưa làm',
    );

    final grouped = await walletDao.watchGroupedHistory(childId).first;
    final penalty = grouped.firstWhere((e) => e.reason == 'penalty');
    expect(penalty.delta, -8);
    expect(penalty.byJar.length, greaterThan(1), reason: 'lấn sang hũ thứ hai');
    expect(penalty.note, 'Hết ngày chưa làm');
  });

  group('groupLedgerRows', () {
    test('dòng cũ không có opGroupId thì lấy id làm nhóm', () {
      final rows = [
        PointTransaction(
          id: 'x1',
          familyId: familyId,
          createdAt: DateTime(2026, 8),
          updatedAt: DateTime(2026, 8),
          memberId: childId,
          jar: 'spend',
          delta: 5,
          reason: 'taskApproved',
          clientOpId: 'x1',
        ),
        PointTransaction(
          id: 'x2',
          familyId: familyId,
          createdAt: DateTime(2026, 8),
          updatedAt: DateTime(2026, 8),
          memberId: childId,
          jar: 'save',
          delta: 4,
          reason: 'taskApproved',
          clientOpId: 'x2',
        ),
      ];

      // Không gộp được thì thà hiện hai mục còn hơn gộp sai hai giao dịch khác
      // nhau vào một mục.
      expect(groupLedgerRows(rows), hasLength(2));
    });

    test('danh sách rỗng ra danh sách rỗng', () {
      expect(groupLedgerRows([]), isEmpty);
    });

    test('giữ đúng thứ tự đầu vào', () {
      final rows = [
        for (final id in ['a', 'b', 'c'])
          PointTransaction(
            id: id,
            familyId: familyId,
            createdAt: DateTime(2026, 8),
            updatedAt: DateTime(2026, 8),
            memberId: childId,
            jar: 'spend',
            delta: 1,
            reason: 'bonus',
            clientOpId: id,
            opGroupId: id,
          ),
      ];

      expect(groupLedgerRows(rows).map((e) => e.groupId), ['a', 'b', 'c']);
    });
  });
}
