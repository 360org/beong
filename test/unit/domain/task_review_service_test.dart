import 'package:beong/data/local/badge_dao.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/services/approval_rule.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/penalty_policy.dart';
import 'package:beong/domain/services/penalty_service.dart';
import 'package:beong/domain/services/task_review_service.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

/// ADR-023 đổi mặc định: con bấm xong là xong, không cần duyệt.
///
/// Điều dễ hỏng nhất khi đổi mặc định này: trước đây việc cộng xu nằm trong nút
/// duyệt ở UI, nên đường tự động duyệt đổi trạng thái mà **không cộng xu cho
/// ai**. Nhóm test đầu tiên giữ đúng chỗ đó.
void main() {
  late AppDatabase db;
  late TaskDao taskDao;
  late WalletDao walletDao;
  late MemberDao memberDao;
  late TaskReviewService service;

  const familyId = 'fam-1';
  const childId = 'con-1';
  const parentId = 'bo-me';

  Future<String> makeInstance({
    required String id,
    int points = 10,
    String? approvalMode,
    String? proofMode,
  }) async {
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: 'task-$id',
            familyId: familyId,
            title: 'Việc $id',
            points: Value(points),
            approvalMode: approvalMode == null
                ? const Value.absent()
                : Value(approvalMode),
            proofMode: proofMode == null
                ? const Value.absent()
                : Value(proofMode),
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
          ),
        );
    return id;
  }

  Future<TaskInstance> reload(String id) async =>
      (await taskDao.getInstanceById(id))!;

  setUp(() async {
    db = AppDatabase.memory();
    taskDao = TaskDao(db);
    walletDao = WalletDao(db);
    memberDao = MemberDao(db);
    service = TaskReviewService(
      taskDao: taskDao,
      walletDao: walletDao,
      memberDao: memberDao,
      badgeDao: BadgeDao(db),
      penaltyService: PenaltyService(
        taskDao: taskDao,
        walletDao: walletDao,
        memberDao: memberDao,
      ),
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

  group('needsApproval', () {
    test('nhà tắt duyệt thì không đọc tới cấu hình task', () {
      for (final mode in ApprovalMode.values) {
        expect(
          needsApproval(familyRequiresApproval: false, taskMode: mode),
          isFalse,
          reason: 'mode $mode',
        );
      }
    });

    test('nhà bật duyệt thì task manual phải duyệt', () {
      expect(
        needsApproval(
          familyRequiresApproval: true,
          taskMode: ApprovalMode.manual,
        ),
        isTrue,
      );
    });

    test('nhà bật duyệt nhưng task đặt riêng auto thì vẫn xong luôn', () {
      expect(
        needsApproval(
          familyRequiresApproval: true,
          taskMode: ApprovalMode.auto,
        ),
        isFalse,
      );
    });

    test('giá trị lạ trong DB được coi là manual — hướng chặt hơn', () {
      expect(approvalModeFromDb('rác'), ApprovalMode.manual);
      expect(approvalModeFromDb(null), ApprovalMode.manual);
      expect(approvalModeFromDb('auto'), ApprovalMode.auto);
    });
  });

  group('mặc định: xong là xong', () {
    test('gia đình mới không bắt duyệt', () async {
      final family = await memberDao.getFamily(familyId);
      expect(family.requireApproval, isFalse);
    });

    test('con bấm xong → approved **và cộng xu ngay**', () async {
      await makeInstance(id: 'i1');

      final doneNow = await service.complete('i1');

      expect(doneNow.xuCongNgay, isTrue);
      expect((await reload('i1')).status, InstanceStatus.approved.name);
      expect(
        (await walletDao.balanceOf(childId)).total,
        10,
        reason: 'đây là lỗi cũ: đổi trạng thái mà quên cộng xu',
      );
    });

    test('không ai duyệt thì reviewed_by để trống', () async {
      await makeInstance(id: 'i1');
      await service.complete('i1');

      final instance = await reload('i1');
      expect(instance.reviewedBy, isNull);
      expect(instance.completedAt, isNotNull);
    });

    test('bấm hai lần không cộng xu hai lần', () async {
      await makeInstance(id: 'i1');

      await service.complete('i1');
      await service.complete('i1');

      expect((await walletDao.balanceOf(childId)).total, 10);
    });

    test('việc 0 xu vẫn chốt xong được, không ghi dòng sổ cái nào', () async {
      await makeInstance(id: 'i1', points: 0);

      await service.complete('i1');

      expect((await reload('i1')).status, InstanceStatus.approved.name);
      expect(await db.select(db.pointTransactions).get(), isEmpty);
    });

    test('nhà tắt duyệt nhưng task yêu cầu photo proof thì vẫn phải chờ duyệt', () async {
      await makeInstance(id: 'i-proof-photo', proofMode: 'photo');

      final result = await service.complete('i-proof-photo');

      expect(result.xuCongNgay, isFalse);
      expect((await reload('i-proof-photo')).status, InstanceStatus.pendingReview.name);
      expect((await walletDao.balanceOf(childId)).total, 0);
    });

    test('nhà tắt duyệt nhưng task yêu cầu note proof thì vẫn phải chờ duyệt', () async {
      await makeInstance(id: 'i-proof-note', proofMode: 'note');

      final result = await service.complete('i-proof-note');

      expect(result.xuCongNgay, isFalse);
      expect((await reload('i-proof-note')).status, InstanceStatus.pendingReview.name);
      expect((await walletDao.balanceOf(childId)).total, 0);
    });
  });

  group('khi bố mẹ bật tính năng duyệt', () {
    setUp(() async {
      await memberDao.setRequireApproval(familyId, value: true);
    });

    test('con bấm xong → chờ duyệt, chưa cộng xu', () async {
      await makeInstance(id: 'i1');

      final doneNow = await service.complete('i1');

      expect(doneNow.xuCongNgay, isFalse);
      expect((await reload('i1')).status, InstanceStatus.pendingReview.name);
      expect((await walletDao.balanceOf(childId)).total, 0);
    });

    test('bố mẹ duyệt → cộng xu và ghi người duyệt', () async {
      await makeInstance(id: 'i1');
      await service.complete('i1');

      await service.approve(instanceId: 'i1', reviewerId: parentId);

      final instance = await reload('i1');
      expect(instance.status, InstanceStatus.approved.name);
      expect(instance.reviewedBy, parentId);
      expect((await walletDao.balanceOf(childId)).total, 10);
    });

    test('task đặt riêng auto vẫn xong luôn dù nhà bật duyệt', () async {
      await makeInstance(id: 'i1', approvalMode: 'auto');

      expect((await service.complete('i1')).xuCongNgay, isTrue);
      expect((await walletDao.balanceOf(childId)).total, 10);
    });

    test('duyệt tất cả cộng xu cho mọi việc đang chờ', () async {
      for (var i = 1; i <= 3; i++) {
        await makeInstance(id: 'i$i');
        await service.complete('i$i');
      }

      final count = await service.approveAll(
        familyId: familyId,
        reviewerId: parentId,
      );

      expect(count, 3);
      expect((await walletDao.balanceOf(childId)).total, 30);
      expect(await taskDao.pendingReview(familyId), isEmpty);
    });

    test('duyệt tất cả khi hàng đợi rỗng là vô hại', () async {
      expect(
        await service.approveAll(familyId: familyId, reviewerId: parentId),
        0,
      );
    });

    test('duyệt lại việc đã duyệt không cộng xu thêm', () async {
      await makeInstance(id: 'i1');
      await service.complete('i1');
      await service.approve(instanceId: 'i1', reviewerId: parentId);
      await service.approve(instanceId: 'i1', reviewerId: parentId);

      expect((await walletDao.balanceOf(childId)).total, 10);
    });

    test('từ chối thì không cộng xu và cũng không trừ xu', () async {
      await makeInstance(id: 'i1');
      await service.complete('i1');

      await service.reject(instanceId: 'i1', reviewerId: parentId);

      expect((await reload('i1')).status, InstanceStatus.rejected.name);
      expect((await walletDao.balanceOf(childId)).total, 0);
    });
  });

  group('mở lại việc đã xong', () {
    test('mở lại việc đã tự động duyệt: giữ xu, trừ phần phạt', () async {
      // Ca chính của ADR-023: nhà tắt duyệt, con bấm xong được 10 xu, bố mẹ
      // phát hiện chưa làm thật và mở lại.
      await memberDao.setPenaltyPolicy(
        familyId,
        const PenaltyPolicy(missedPct: 0, reopenPct: 20),
      );
      await makeInstance(id: 'i1');
      await service.complete('i1');
      expect((await walletDao.balanceOf(childId)).total, 10);

      final r = await service.reopen(instanceId: 'i1', reviewerId: parentId);

      expect(r.instance.status, InstanceStatus.scheduled.name);
      expect(r.xuDeducted, 2);
      expect((await walletDao.balanceOf(childId)).total, 8);
    });

    test('con làm lại rồi bấm xong: không cộng xu lần hai', () async {
      await memberDao.setPenaltyPolicy(
        familyId,
        const PenaltyPolicy(missedPct: 0, reopenPct: 20),
      );
      await makeInstance(id: 'i1');
      await service.complete('i1');
      await service.reopen(instanceId: 'i1', reviewerId: parentId);

      await service.complete('i1');

      // 10 kiếm được - 2 phạt. Việc này cuối cùng chỉ đáng đúng 10 xu của nó.
      expect((await walletDao.balanceOf(childId)).total, 8);
    });

    test('việc đã xong hôm nay hiện trong danh sách để mở lại', () async {
      await makeInstance(id: 'i1');
      await makeInstance(id: 'i2');
      await service.complete('i1');

      final done = await taskDao
          .watchApprovedForMember(
            memberId: childId,
            date: const CalendarDate(2026, 8, 1),
          )
          .first;

      expect(done.map((i) => i.id), ['i1']);
    });
  });

  group('huy hiệu vừa nhận được trả ra ngoài', () {
    test('lượt thứ 10 mở khoá huy hiệu và complete() nói tên nó', () async {
      // `awardNewBadges` vẫn luôn trả danh sách huy hiệu mới, nhưng trước đây
      // chỗ gọi **vứt đi** — con đạt huy hiệu mà màn hình không nói gì cả, phải
      // tự mò vào màn Huy hiệu mới biết.
      for (var i = 1; i <= 9; i++) {
        await makeInstance(id: 'v$i');
        await service.complete('v$i');
      }
      await makeInstance(id: 'v10');

      final ketQua = await service.complete('v10');

      expect(ketQua.xuCongNgay, isTrue);
      expect(
        ketQua.huyHieuMoi.map((b) => b.key),
        contains('tasks_10'),
        reason: 'việc thứ 10 mở khoá "Mười việc đầu tiên"',
      );
    });

    test('lượt bình thường thì không có huy hiệu nào', () async {
      await makeInstance(id: 'v1');
      final ketQua = await service.complete('v1');

      // Rỗng là chuyện thường; nhầm chỗ này thành "luôn có" sẽ nổ hoa giấy mỗi
      // lần bấm và huy hiệu mất hết ý nghĩa.
      expect(ketQua.huyHieuMoi, isEmpty);
    });

    test('việc vào hàng đợi duyệt thì chưa xét huy hiệu', () async {
      await memberDao.setRequireApproval(familyId, value: true);
      await makeInstance(id: 'v1');

      final ketQua = await service.complete('v1');

      expect(ketQua.xuCongNgay, isFalse);
      expect(ketQua.huyHieuMoi, isEmpty);
    });
  });

  /// Một lượt việc chỉ được trả xu **một lần**, kể cả khi bố mẹ đổi cách chia xu
  /// giữa hai lần cộng.
  ///
  /// Lỗi thật đã gặp: chốt chống trùng đặt theo `client_op_id`, nhưng hai đường
  /// cộng xu đặt khoá ở hai vùng không đụng nhau — chia theo tỷ lệ ghi
  /// `<op>:<hũ>` cho từng hũ, còn hũ Chờ chia ghi đúng `<op>`. Bố mẹ mở lại việc
  /// rồi bật "Con tự chia xu" là con được trả tiền hai lần cho một việc.
  group('không trả xu hai lần cho một lượt', () {
    Future<int> tongXu() async {
      final b = await walletDao.balanceOf(childId);
      return b.total;
    }

    test('mở lại rồi làm lại: vẫn đúng một lần, cùng chế độ chia', () async {
      await makeInstance(id: 'v1', points: 20);
      await service.complete('v1');
      expect(await tongXu(), 20);

      await service.reopen(instanceId: 'v1', reviewerId: parentId);
      await service.complete('v1');

      expect(
        await tongXu(),
        20,
        reason: 'làm lại không phải kiếm thêm lần nữa',
      );
    });

    test(
      'đổi sang "con tự chia" giữa hai lần thì vẫn không cộng thêm',
      () async {
        await makeInstance(id: 'v1', points: 20);
        await service.complete('v1');
        expect(await tongXu(), 20);

        // Đúng ba thao tác của bố mẹ trong đời thật, và là ca lỗi đã lọt.
        await service.reopen(instanceId: 'v1', reviewerId: parentId);
        await memberDao.setAllocationMode(familyId, AllocationMode.manual);
        await service.complete('v1');

        expect(
          await tongXu(),
          20,
          reason: 'đổi chế độ chia không được mở ra một đường cộng xu thứ hai',
        );
      },
    );

    test('đổi từ "con tự chia" về chia tự động cũng vậy', () async {
      // Canh cả chiều ngược lại: sửa một chiều mà bỏ chiều kia là chuyện thường.
      await memberDao.setAllocationMode(familyId, AllocationMode.manual);
      await makeInstance(id: 'v1', points: 20);
      await service.complete('v1');
      expect(await tongXu(), 20);

      await service.reopen(instanceId: 'v1', reviewerId: parentId);
      await memberDao.setAllocationMode(familyId, AllocationMode.auto);
      await service.complete('v1');

      expect(await tongXu(), 20);
    });

    test('duyệt hai lần cũng chỉ cộng một lần', () async {
      await memberDao.setRequireApproval(familyId, value: true);
      await makeInstance(id: 'v1', points: 20);
      await service.complete('v1');

      await service.approve(instanceId: 'v1', reviewerId: parentId);
      await service.approve(instanceId: 'v1', reviewerId: parentId);

      expect(await tongXu(), 20);
    });
  });
}
