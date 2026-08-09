import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/jar_splitter.dart';
import 'package:beong/domain/services/penalty_policy.dart';
import 'package:beong/domain/services/penalty_service.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

/// Trừ xu là chỗ trẻ dễ mất niềm tin nhất vào app, nên tầng này bị kiểm chặt:
/// không trừ hai lần, không trừ về âm, không trừ hồi tố, và không lấy xu từ hũ
/// Cho đi khi hũ Tiêu còn.
void main() {
  late AppDatabase db;
  late TaskDao taskDao;
  late WalletDao walletDao;
  late MemberDao memberDao;
  late PenaltyService service;

  const familyId = 'fam-1';
  const childId = 'con-1';
  const parentId = 'bo-me';

  /// Cho con [amount] xu vào hũ Tiêu để có gì mà trừ.
  Future<void> giveXu(int amount, {String opId = 'seed'}) async {
    await walletDao.credit(
      familyId: familyId,
      memberId: childId,
      amount: amount,
      reason: TxReason.bonus,
      clientOpId: opId,
      split: JarSplitAllSpend.value,
    );
  }

  /// Một lượt việc đã bỏ, đáng [points] xu.
  Future<String> missedInstance({
    required String id,
    int points = 10,
    String status = 'missed',
  }) async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: 'task-$id',
            familyId: familyId,
            title: 'Việc $id',
            points: Value(points),
          ),
        );
    await db
        .into(db.taskInstances)
        .insert(
          TaskInstancesCompanion.insert(
            id: id,
            familyId: familyId,
            taskId: 'task-$id',
            memberId: childId,
            dueDate: '2026-08-01',
            pointsSnapshot: points,
            status: Value(status),
          ),
        );
    return id;
  }

  setUp(() async {
    db = AppDatabase.memory();
    taskDao = TaskDao(db);
    walletDao = WalletDao(db);
    memberDao = MemberDao(db);
    service = PenaltyService(
      taskDao: taskDao,
      walletDao: walletDao,
      memberDao: memberDao,
    );

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

  group('chính sách', () {
    test('gia đình mới mặc định tắt trừ xu', () async {
      expect(await memberDao.penaltyPolicyOf(familyId), PenaltyPolicy.off);
    });

    test('đặt rồi đọc lại ra đúng mức', () async {
      await memberDao.setPenaltyPolicy(
        familyId,
        const PenaltyPolicy(missedPct: 50, reopenPct: 20),
      );

      expect(
        await memberDao.penaltyPolicyOf(familyId),
        const PenaltyPolicy(missedPct: 50, reopenPct: 20),
      );
    });

    test('mức ngoài 0–100 bị từ chối, không kẹp lặng lẽ', () async {
      expect(
        () => memberDao.setPenaltyPolicy(
          familyId,
          const PenaltyPolicy(missedPct: 150, reopenPct: 0),
        ),
        throwsArgumentError,
      );
    });
  });

  group('trừ xu vì bỏ việc', () {
    test('trừ đúng phần trăm điểm của việc', () async {
      await giveXu(100);
      await memberDao.setPenaltyPolicy(
        familyId,
        const PenaltyPolicy(missedPct: 50, reopenPct: 0),
      );
      await missedInstance(id: 'i1');

      final outcome = await service.applyMissedPenalties(familyId: familyId);

      expect(outcome.xuDeducted, 5);
      expect((await walletDao.balanceOf(childId)).total, 95);
    });

    test('chạy lại không trừ thêm lần nữa', () async {
      await giveXu(100);
      await memberDao.setPenaltyPolicy(
        familyId,
        const PenaltyPolicy(missedPct: 50, reopenPct: 0),
      );
      await missedInstance(id: 'i1');

      await service.applyMissedPenalties(familyId: familyId);
      final second = await service.applyMissedPenalties(familyId: familyId);

      expect(second, PenaltyOutcome.none);
      expect((await walletDao.balanceOf(childId)).total, 95);
    });

    test(
      'chính sách tắt thì không trừ, và **không** trừ hồi tố khi bật',
      () async {
        await giveXu(100);
        await missedInstance(id: 'i1');

        // Chạy trong lúc còn tắt: không trừ, nhưng đã đánh dấu đã xử lý.
        expect(
          await service.applyMissedPenalties(familyId: familyId),
          PenaltyOutcome.none,
        );

        // Bố mẹ bật lên hôm sau. Việc bỏ từ hôm trước không bị lôi ra xử.
        await memberDao.setPenaltyPolicy(
          familyId,
          const PenaltyPolicy(missedPct: 50, reopenPct: 0),
        );
        await service.applyMissedPenalties(familyId: familyId);

        expect((await walletDao.balanceOf(childId)).total, 100);
      },
    );

    test('chỉ xét lượt đã bỏ, không xét lượt còn đang mở', () async {
      await giveXu(100);
      await memberDao.setPenaltyPolicy(
        familyId,
        const PenaltyPolicy(missedPct: 50, reopenPct: 0),
      );
      await missedInstance(id: 'i1', status: 'scheduled');
      await missedInstance(id: 'i2', status: 'approved');

      expect(
        await service.applyMissedPenalties(familyId: familyId),
        PenaltyOutcome.none,
      );
      expect((await walletDao.balanceOf(childId)).total, 100);
    });

    test('không có xu thì không trừ về âm', () async {
      await memberDao.setPenaltyPolicy(
        familyId,
        const PenaltyPolicy(missedPct: 50, reopenPct: 0),
      );
      await missedInstance(id: 'i1');

      final outcome = await service.applyMissedPenalties(familyId: familyId);

      expect(outcome.xuDeducted, 0);
      expect((await walletDao.balanceOf(childId)).total, 0);
    });

    test('có ít xu hơn khoản trừ thì chỉ trừ tới 0', () async {
      await giveXu(3);
      await memberDao.setPenaltyPolicy(
        familyId,
        const PenaltyPolicy(missedPct: 100, reopenPct: 0),
      );
      await missedInstance(id: 'i1');

      final outcome = await service.applyMissedPenalties(familyId: familyId);

      expect(outcome.xuDeducted, 3);
      expect((await walletDao.balanceOf(childId)).total, 0);
    });
  });

  group('mở lại việc', () {
    setUp(() async {
      await memberDao.setPenaltyPolicy(
        familyId,
        const PenaltyPolicy(missedPct: 50, reopenPct: 20),
      );
    });

    test('lượt về lại scheduled và đếm số lần mở lại', () async {
      await giveXu(100);
      await missedInstance(id: 'i1', status: 'pendingReview');

      final r = await service.reopenInstance(
        instanceId: 'i1',
        reviewerId: parentId,
      );

      expect(r.instance.status, InstanceStatus.scheduled.name);
      expect(r.instance.reopenCount, 1);
      expect(r.instance.completedAt, isNull, reason: 'con phải làm lại');
      expect(r.xuDeducted, 2);
    });

    test('mở lại hai lần thì trừ hai lần', () async {
      await giveXu(100);
      await missedInstance(id: 'i1', status: 'pendingReview');

      await service.reopenInstance(instanceId: 'i1', reviewerId: parentId);
      final second = await service.reopenInstance(
        instanceId: 'i1',
        reviewerId: parentId,
      );

      expect(second.instance.reopenCount, 2);
      expect((await walletDao.balanceOf(childId)).total, 96);
    });

    test('xu đã cộng cho việc không bị thu hồi khi mở lại', () async {
      // Việc được duyệt (cộng 10 xu), rồi bố mẹ phát hiện chưa làm và mở lại.
      // Chỉ mất 20% tiền phạt, không mất cả 10 xu — trừ hai lần cho một lỗi là
      // sai, xem doc của TaskDao.reopen.
      await missedInstance(id: 'i1', status: 'approved');
      await walletDao.credit(
        familyId: familyId,
        memberId: childId,
        amount: 10,
        reason: TxReason.taskApproved,
        clientOpId: 'task:i1',
        split: JarSplitAllSpend.value,
      );
      expect((await walletDao.balanceOf(childId)).total, 10);

      await service.reopenInstance(instanceId: 'i1', reviewerId: parentId);

      expect((await walletDao.balanceOf(childId)).total, 8);
    });

    test('mức mở lại bằng 0 thì mở lại được mà không trừ gì', () async {
      await giveXu(100);
      await memberDao.setPenaltyPolicy(
        familyId,
        const PenaltyPolicy(missedPct: 50, reopenPct: 0),
      );
      await missedInstance(id: 'i1', status: 'pendingReview');

      final r = await service.reopenInstance(
        instanceId: 'i1',
        reviewerId: parentId,
      );

      expect(r.instance.reopenCount, 1);
      expect(r.xuDeducted, 0);
      expect((await walletDao.balanceOf(childId)).total, 100);
    });
  });

  group('thứ tự hũ khi trừ', () {
    test(
      'trừ hũ Tiêu trước, không đụng Để dành và Cho đi khi còn đủ',
      () async {
        await walletDao.credit(
          familyId: familyId,
          memberId: childId,
          amount: 100,
          reason: TxReason.bonus,
          clientOpId: 'seed',
          split: JarSplit.defaultSplit,
        );
        await memberDao.setPenaltyPolicy(
          familyId,
          const PenaltyPolicy(missedPct: 50, reopenPct: 0),
        );
        await missedInstance(id: 'i1', points: 20);

        await service.applyMissedPenalties(familyId: familyId);

        final b = await walletDao.balanceOf(childId);
        expect(b.spend, 40, reason: '50 - 10');
        expect(b.save, 40, reason: 'không bị đụng');
        expect(b.give, 10, reason: 'không bị đụng');
      },
    );

    test('hết hũ Tiêu mới lấn sang Để dành, Cho đi là cuối cùng', () async {
      await walletDao.credit(
        familyId: familyId,
        memberId: childId,
        amount: 10,
        reason: TxReason.bonus,
        clientOpId: 'seed',
        split: JarSplit.defaultSplit,
      );
      // 5 tiêu / 4 để dành / 1 cho đi
      await memberDao.setPenaltyPolicy(
        familyId,
        const PenaltyPolicy(missedPct: 100, reopenPct: 0),
      );
      await missedInstance(id: 'i1', points: 8);

      await service.applyMissedPenalties(familyId: familyId);

      final b = await walletDao.balanceOf(childId);
      expect(b.spend, 0, reason: 'lấy hết 5 xu hũ Tiêu trước');
      expect(b.save, 1, reason: 'lấy tiếp 3 xu từ hũ Để dành');
      expect(b.give, 1, reason: 'hũ Cho đi được giữ tới cùng');
    });
  });
}

/// Tỷ lệ dồn hết vào hũ Tiêu — giữ số dư dễ tính trong phần lớn test.
abstract final class JarSplitAllSpend {
  static const JarSplit value = JarSplit.spendOnly;
}
