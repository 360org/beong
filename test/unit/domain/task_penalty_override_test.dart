import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/penalty_policy.dart';
import 'package:beong/domain/services/penalty_service.dart';
import 'package:beong/domain/services/schedule.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

/// Mức trừ xu riêng theo từng việc — ADR-022.
///
/// Trước đây chỉ có một mức chung cho cả nhà, nên "quên đổ rác" và "quên tập
/// đàn" bị trừ như nhau dù bố mẹ coi trọng khác nhau.
void main() {
  test('mức riêng được chốt vào lượt việc lúc sinh, như điểm', () {
    // Chốt cùng `pointsSnapshot` vì cùng một lý do (ADR-007): bố mẹ đổi mức
    // trừ hôm nay không được làm đổi những lượt đã sinh từ hôm qua.
    final planned = planInstances(
      tasks: [
        const SchedulableTask(
          taskId: 'task-1',
          schedule: Schedule.daily(),
          assigneeIds: ['con-1'],
          points: 20,
          missedPenaltyPct: 100,
        ),
      ],
      from: const CalendarDate(2026, 8, 10),
      horizonDays: 0,
    );

    expect(planned.single.missedPenaltyPct, 100);
  });

  test('task không đặt mức riêng thì lượt việc để null', () {
    final planned = planInstances(
      tasks: [
        const SchedulableTask(
          taskId: 'task-1',
          schedule: Schedule.daily(),
          assigneeIds: ['con-1'],
          points: 20,
        ),
      ],
      from: const CalendarDate(2026, 8, 10),
      horizonDays: 0,
    );

    expect(planned.single.missedPenaltyPct, isNull);
  });

  group('áp khoản trừ', () {
    late AppDatabase db;
    late TaskDao taskDao;
    late MemberDao memberDao;
    late WalletDao walletDao;
    late PenaltyService service;

    const familyId = 'fam-1';
    const childId = 'con-1';

    setUp(() async {
      db = AppDatabase.memory();
      taskDao = TaskDao(db);
      memberDao = MemberDao(db);
      walletDao = WalletDao(db);
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
          id: childId,
          familyId: familyId,
          kind: MemberKind.child.name,
          displayName: 'Minh',
        ),
      );
      // Vốn có sẵn để trừ vào.
      await walletDao.creditToJarKey(
        familyId: familyId,
        memberId: childId,
        jarKey: 'spend',
        amount: 500,
        reason: TxReason.bonus,
        clientOpId: 'von',
      );
    });

    tearDown(() async {
      await db.close();
    });

    /// Một lượt việc đã bỏ lỡ, kèm mức trừ riêng (hoặc `null` = theo nhà).
    Future<void> seedMissed({
      required String id,
      required int points,
      int? pct,
    }) async {
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-$id',
              familyId: familyId,
              title: 'Việc $id',
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
              dueDate: '2026-08-0$id',
              pointsSnapshot: points,
              status: const Value('missed'),
              missedPenaltyPct: Value(pct),
            ),
          );
    }

    test('mức riêng thắng mức chung của nhà', () async {
      await memberDao.setPenaltyPolicy(
        familyId,
        const PenaltyPolicy(missedPct: 50, reopenPct: 0),
      );
      // Việc 1 theo nhà (50% của 20 = 10), việc 2 đặt riêng 100% (= 20).
      await seedMissed(id: '1', points: 20);
      await seedMissed(id: '2', points: 20, pct: 100);

      final outcome = await service.applyMissedPenalties(familyId: familyId);
      expect(outcome.xuDeducted, 30);
    });

    test('đặt riêng 0% là **không trừ** việc đó', () async {
      await memberDao.setPenaltyPolicy(
        familyId,
        const PenaltyPolicy(missedPct: 50, reopenPct: 0),
      );
      await seedMissed(id: '1', points: 20, pct: 0);

      final outcome = await service.applyMissedPenalties(familyId: familyId);
      expect(outcome.xuDeducted, 0);
      expect((await walletDao.balanceOf(childId)).spend, 500);
    });

    test('nhà tắt trừ xu thì mức riêng cũng không trừ', () async {
      // Điểm quan trọng: để mức riêng vượt qua công tắc chung thì bố mẹ tắt
      // trừ xu ở Cài đặt xong vẫn thấy con bị trừ, và không hiểu vì sao.
      await seedMissed(id: '1', points: 20, pct: 100);

      final outcome = await service.applyMissedPenalties(familyId: familyId);
      expect(outcome.xuDeducted, 0);
      expect((await walletDao.balanceOf(childId)).spend, 500);
    });
  });
}
