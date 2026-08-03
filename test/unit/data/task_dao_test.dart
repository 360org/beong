import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TaskDao dao;

  const familyId = 'fam-1';
  const childId = 'an';
  const parentId = 'bo';

  setUp(() async {
    db = AppDatabase.memory();
    dao = TaskDao(db);

    await db
        .into(db.families)
        .insert(FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'));
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: parentId,
            familyId: familyId,
            kind: MemberKind.parent.name,
            displayName: 'Bố',
          ),
        );
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: childId,
            familyId: familyId,
            kind: MemberKind.child.name,
            displayName: 'An',
          ),
        );
  });

  tearDown(() async => db.close());

  group('createTask & activeTasks', () {
    test('tạo task lẻ và lấy lại đúng', () async {
      await dao.createTask(
        TasksCompanion.insert(
          id: 'task-1',
          familyId: familyId,
          title: 'Đánh răng',
        ),
        [childId],
      );

      final tasks = await dao.activeTasks(familyId);
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Đánh răng');

      final assignees = await dao.assigneesOf('task-1');
      expect(assignees, [childId]);
    });
  });

  group('createRoutine', () {
    test('tạo routine kèm tasks', () async {
      await dao.createRoutine(
        routine: RoutinesCompanion.insert(
          id: 'routine-1',
          familyId: familyId,
          title: 'Buổi sáng',
        ),
        assigneeIds: [childId],
        routineTasks: [
          TasksCompanion.insert(
            id: 'rt-1',
            familyId: familyId,
            title: 'Đánh răng',
            routineId: const Value('routine-1'),
            orderIndex: const Value(0),
          ),
          TasksCompanion.insert(
            id: 'rt-2',
            familyId: familyId,
            title: 'Gấp chăn',
            routineId: const Value('routine-1'),
            orderIndex: const Value(1),
          ),
        ],
      );

      final tasks = await dao.activeTasks(familyId);
      expect(tasks.length, 2);
      expect(tasks.every((t) => t.routineId == 'routine-1'), isTrue);
    });
  });

  group('generateInstances', () {
    const today = CalendarDate(2026, 8, 3);

    setUp(() async {
      await dao.createTask(
        TasksCompanion.insert(
          id: 'task-daily',
          familyId: familyId,
          title: 'Việc hằng ngày',
          points: const Value(10),
        ),
        [childId],
      );
    });

    test('sinh instance cho 8 ngày (hôm nay + 7)', () async {
      final written = await dao.generateInstances(
        familyId: familyId,
        today: today,
      );
      expect(written, 8);
    });

    test('gọi lại không sinh trùng', () async {
      await dao.generateInstances(familyId: familyId, today: today);
      final second = await dao.generateInstances(
        familyId: familyId,
        today: today,
      );
      expect(second, 0, reason: 'Unique key chặn trùng');
    });

    test('lấy instance hôm nay của trẻ', () async {
      await dao.generateInstances(familyId: familyId, today: today);
      final instances = await dao.instancesForMember(
        memberId: childId,
        date: today,
      );
      expect(instances.length, 1);
      expect(instances.first.pointsSnapshot, 10);
    });
  });

  group('markCompleted & approve', () {
    const today = CalendarDate(2026, 8, 3);

    setUp(() async {
      await dao.createTask(
        TasksCompanion.insert(
          id: 'task-manual',
          familyId: familyId,
          title: 'Rửa bát',
          points: const Value(20),
        ),
        [childId],
      );
      await dao.generateInstances(familyId: familyId, today: today);
    });

    test('trẻ bấm xong → pending_review khi manual', () async {
      final instances = await dao.instancesForMember(
        memberId: childId,
        date: today,
      );
      await dao.markCompleted(instances.first.id);

      final updated = await dao.instancesForMember(
        memberId: childId,
        date: today,
      );
      expect(updated.first.status, InstanceStatus.pendingReview.name);
      expect(updated.first.completedAt, isNotNull);
    });

    test('auto-approve khi task đặt auto', () async {
      await dao.createTask(
        TasksCompanion.insert(
          id: 'task-auto',
          familyId: familyId,
          title: 'Tự duyệt',
          approvalMode: const Value('auto'),
        ),
        [childId],
      );
      await dao.generateInstances(
        familyId: familyId,
        today: today,
      );

      final instances = await dao.instancesForMember(
        memberId: childId,
        date: today,
      );
      final autoInstance = instances.firstWhere(
        (i) => i.taskId == 'task-auto',
      );
      await dao.markCompleted(autoInstance.id);

      final updated = await dao.instancesForMember(
        memberId: childId,
        date: today,
      );
      final updatedAuto = updated.firstWhere(
        (i) => i.taskId == 'task-auto',
      );
      expect(updatedAuto.status, InstanceStatus.approved.name);
    });

    test('bố mẹ duyệt → approved', () async {
      final instances = await dao.instancesForMember(
        memberId: childId,
        date: today,
      );
      await dao.markCompleted(instances.first.id);
      await dao.approve(
        instanceId: instances.first.id,
        reviewerId: parentId,
      );

      final updated = await dao.instancesForMember(
        memberId: childId,
        date: today,
      );
      expect(updated.first.status, InstanceStatus.approved.name);
      expect(updated.first.reviewedBy, parentId);
    });
  });

  group('routine bonus — ADR-011', () {
    const today = CalendarDate(2026, 8, 3);

    setUp(() async {
      await dao.createRoutine(
        routine: RoutinesCompanion.insert(
          id: 'routine-morning',
          familyId: familyId,
          title: 'Buổi sáng',
          completionBonus: const Value(15),
        ),
        assigneeIds: [childId],
        routineTasks: [
          TasksCompanion.insert(
            id: 'rt-a',
            familyId: familyId,
            title: 'Đánh răng',
            routineId: const Value('routine-morning'),
            orderIndex: const Value(0),
            points: const Value(10),
          ),
          TasksCompanion.insert(
            id: 'rt-b',
            familyId: familyId,
            title: 'Gấp chăn',
            routineId: const Value('routine-morning'),
            orderIndex: const Value(1),
            points: const Value(10),
          ),
        ],
      );
      await dao.generateInstances(familyId: familyId, today: today);
    });

    test('chưa làm hết thì không có bonus', () async {
      final instances = await dao.instancesForMember(
        memberId: childId,
        date: today,
      );
      await dao.markCompleted(instances.first.id);
      await dao.approve(
        instanceId: instances.first.id,
        reviewerId: parentId,
      );

      final got = await dao.checkAndAwardRoutineBonus(
        instanceId: instances.first.id,
        familyId: familyId,
      );
      expect(got, isFalse);
    });

    test('làm hết → cộng bonus đúng 1 lần', () async {
      final instances = await dao.instancesForMember(
        memberId: childId,
        date: today,
      );

      for (final i in instances) {
        await dao.markCompleted(i.id);
        await dao.approve(instanceId: i.id, reviewerId: parentId);
      }

      final got = await dao.checkAndAwardRoutineBonus(
        instanceId: instances.last.id,
        familyId: familyId,
      );
      expect(got, isTrue);

      // Gọi lại không thưởng lần nữa (idempotent).
      final again = await dao.checkAndAwardRoutineBonus(
        instanceId: instances.last.id,
        familyId: familyId,
      );
      expect(again, isFalse, reason: 'Bonus đã cộng rồi');

      // Xác nhận giao dịch bonus trong sổ cái.
      final txRows = await db.select(db.pointTransactions).get();
      final bonusTx = txRows.where(
        (t) => t.reason == TxReason.routineBonus.name,
      );
      expect(bonusTx.length, 1);
      expect(bonusTx.first.delta, 15);
    });
  });

  group('markMissed', () {
    test('instance quá hạn chuyển thành missed', () async {
      const yesterday = CalendarDate(2026, 8, 2);
      const today = CalendarDate(2026, 8, 3);

      await dao.createTask(
        TasksCompanion.insert(
          id: 'task-miss',
          familyId: familyId,
          title: 'Sẽ bỏ lỡ',
        ),
        [childId],
      );
      await dao.generateInstances(familyId: familyId, today: yesterday);

      // Giờ "hôm nay" là ngày 3 → ngày 2 chưa làm → missed.
      await dao.generateInstances(familyId: familyId, today: today);

      final instances = await dao.instancesForMember(
        memberId: childId,
        date: yesterday,
      );
      expect(instances.first.status, InstanceStatus.missed.name);
    });
  });

  group('pendingReview', () {
    test('danh sách chờ duyệt của gia đình', () async {
      const today = CalendarDate(2026, 8, 3);
      await dao.createTask(
        TasksCompanion.insert(
          id: 'task-pr',
          familyId: familyId,
          title: 'Chờ duyệt',
        ),
        [childId],
      );
      await dao.generateInstances(familyId: familyId, today: today);

      final instances = await dao.instancesForMember(
        memberId: childId,
        date: today,
      );
      await dao.markCompleted(instances.first.id);

      final pending = await dao.pendingReview(familyId);
      expect(pending.length, 1);
    });
  });
}
