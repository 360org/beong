import 'package:beong/data/local/badge_dao.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/penalty_policy.dart';
import 'package:beong/domain/services/penalty_service.dart';
import 'package:beong/domain/services/task_review_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bố mẹ trả việc lại cho con — chủ dự án nêu 30/08/2026: *"thiếu tính năng
/// return task từ bố mẹ khi con bấm hoàn thành nhưng chưa hoàn thành / phải
/// làm lại. Nhớ test luôn cơ chế trừ xu nếu bật."*
///
/// Có **hai** đường trả lại, và hậu quả về xu khác hẳn nhau — đó là lý do file
/// này tồn tại:
///
/// - **Trả lại** một việc đang *chờ duyệt*: chưa cộng xu nên **không trừ gì**.
/// - **Cho làm lại** một việc *đã duyệt*: xu đã vào túi con rồi, nên có trừ
///   theo mức gia đình đặt (ADR-022).
///
/// Kiểm qua `TaskReviewService` — đúng cái cửa giao diện gọi — chứ không gọi
/// thẳng `PenaltyService`: cửa đó đã có test riêng, nhưng nó không nói được
/// rằng **nút bố mẹ bấm** dẫn tới đúng chỗ ấy.
void main() {
  late AppDatabase db;
  late TaskDao taskDao;
  late WalletDao walletDao;
  late MemberDao memberDao;
  late TaskReviewService service;

  const familyId = 'fam-1';
  const childId = 'con-1';
  const parentId = 'bo-me';
  const today = CalendarDate(2026, 8, 30);

  /// Dựng một lượt việc con **vừa bấm xong**, đáng [points] xu.
  ///
  /// `requireApproval` quyết định lượt vào *chờ duyệt* hay *xong luôn*.
  /// [points] để **bắt buộc**: mỗi test nói rõ việc đáng bao nhiêu xu, vì mọi
  /// khẳng định về mức trừ đều tính từ con số đó.
  Future<String> conBamXong({
    required String id,
    required int points,
  }) async {
    await taskDao.createTask(
      TasksCompanion.insert(
        id: 'task-$id',
        familyId: familyId,
        title: 'Việc $id',
        points: Value(points),
      ),
      const [childId],
    );
    await db
        .into(db.taskInstances)
        .insert(
          TaskInstancesCompanion.insert(
            id: id,
            familyId: familyId,
            taskId: 'task-$id',
            memberId: childId,
            dueDate: '$today',
            pointsSnapshot: points,
          ),
        );
    await service.complete(id);
    return id;
  }

  Future<String> trangThai(String instanceId) async {
    final row = await (db.select(
      db.taskInstances,
    )..where((i) => i.id.equals(instanceId))).getSingle();
    return row.status;
  }

  Future<void> datMucTru(int pct) => memberDao.setPenaltyPolicy(
    familyId,
    PenaltyPolicy(missedPct: 0, reopenPct: pct),
  );

  setUp(() async {
    db = AppDatabase.memory();
    taskDao = TaskDao(db);
    walletDao = WalletDao(db);
    memberDao = MemberDao(db);
    service = TaskReviewService(
      taskDao: taskDao,
      walletDao: walletDao,
      memberDao: memberDao,
      penaltyService: PenaltyService(
        taskDao: taskDao,
        walletDao: walletDao,
        memberDao: memberDao,
      ),
      badgeDao: BadgeDao(db),
    );

    await memberDao.createFamily(
      FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'),
    );
    await memberDao.addMember(
      MembersCompanion.insert(
        id: childId,
        familyId: familyId,
        kind: MemberKind.child.name,
        displayName: 'NEO',
      ),
    );
    await memberDao.addMember(
      MembersCompanion.insert(
        id: parentId,
        familyId: familyId,
        kind: MemberKind.parent.name,
        displayName: 'Bố mẹ',
      ),
    );
  });

  tearDown(() async => db.close());

  group('trả lại việc đang chờ duyệt', () {
    setUp(
      () => memberDao.setRequireApproval(familyId, value: true),
    );

    test('việc quay về chưa xong, con làm lại được', () async {
      final id = await conBamXong(id: 'i1', points: 20);
      expect(await trangThai(id), InstanceStatus.pendingReview.name);

      await service.reject(instanceId: id, reviewerId: parentId);

      expect(await trangThai(id), InstanceStatus.rejected.name);
    });

    test('KHÔNG trừ xu — vì chưa từng cộng xu nào', () async {
      await datMucTru(50);
      final id = await conBamXong(id: 'i2', points: 20);

      final truoc = await walletDao.balanceOf(childId);
      expect(
        truoc.total,
        0,
        reason: 'việc chờ duyệt thì xu chưa vào túi con',
      );

      await service.reject(instanceId: id, reviewerId: parentId);

      final sau = await walletDao.balanceOf(childId);
      expect(
        sau.total,
        0,
        reason:
            'trừ ở đây là trừ một khoản chưa từng cộng — con mất xu vì một '
            'việc con chưa được trả công',
      );
    });
  });

  group('cho làm lại việc đã duyệt', () {
    setUp(
      () => memberDao.setRequireApproval(familyId, value: false),
    );

    test('mức trừ 0% (mặc định) thì không mất xu nào', () async {
      final id = await conBamXong(id: 'i3', points: 20);
      final truoc = await walletDao.balanceOf(childId);
      expect(truoc.total, 20, reason: 'xong luôn thì xu vào ngay');

      final ketQua = await service.reopen(
        instanceId: id,
        reviewerId: parentId,
      );

      expect(ketQua.xuDeducted, 0);
      expect((await walletDao.balanceOf(childId)).total, 20);
      expect(await trangThai(id), InstanceStatus.scheduled.name);
    });

    test('bật mức trừ 50% thì mất đúng một nửa số xu của việc đó', () async {
      await datMucTru(50);
      final id = await conBamXong(id: 'i4', points: 20);
      expect((await walletDao.balanceOf(childId)).total, 20);

      final ketQua = await service.reopen(
        instanceId: id,
        reviewerId: parentId,
      );

      expect(ketQua.xuDeducted, 10, reason: '50% của 20 xu');
      expect((await walletDao.balanceOf(childId)).total, 10);
    });

    test('trừ theo xu **của lượt đó**, không theo giá việc hiện tại', () async {
      await datMucTru(50);
      final id = await conBamXong(id: 'i5', points: 20);
      // Bố mẹ đổi giá việc sau khi con đã làm xong.
      await taskDao.updateTask(taskId: 'task-i5', points: 100);

      final ketQua = await service.reopen(
        instanceId: id,
        reviewerId: parentId,
      );

      expect(
        ketQua.xuDeducted,
        10,
        reason:
            'ADR-007: đổi giá việc không được đổi hồi tố lượt đã sinh — nếu '
            'không, tăng giá một việc là trừ ngược vào xu con đã kiếm',
      );
    });

    test('làm lại hai lần thì trừ hai lần', () async {
      await datMucTru(50);
      final id = await conBamXong(id: 'i6', points: 20);

      await service.reopen(instanceId: id, reviewerId: parentId);
      // Con làm lại, bố mẹ lại thấy chưa đạt.
      await service.complete(id);
      final lan2 = await service.reopen(instanceId: id, reviewerId: parentId);

      expect(lan2.xuDeducted, 10);
      expect(
        (await walletDao.balanceOf(childId)).total,
        0,
        reason:
            'cộng 20, trừ 10, cộng lại 20, trừ 10 — còn 20? không: '
            'lần cộng thứ hai bị chặn trùng theo nhóm thao tác',
      );
    });

    test('không trừ xuống âm — con không thể nợ xu', () async {
      await datMucTru(100);
      final id = await conBamXong(id: 'i7', points: 20);
      // Con tiêu hết hũ Tiêu trước khi bố mẹ kịp trả lại việc. 20 xu chia
      // theo mặc định 50/40/10 nên hũ Tiêu chỉ có 10 — tiêu đúng 10 đó.
      final truoc = await walletDao.balanceOf(childId);
      await walletDao.debit(
        familyId: familyId,
        memberId: childId,
        amount: truoc.spend,
        jar: Jar.spend,
        reason: TxReason.rewardRedeemed,
        clientOpId: 'tieu-het',
      );
      expect((await walletDao.balanceOf(childId)).spend, 0);

      final ketQua = await service.reopen(
        instanceId: id,
        reviewerId: parentId,
      );

      // Mức trừ 100% của việc 20 xu = 20, nhưng con chỉ còn 10 (ở hai hũ
      // khác). Trừ được bao nhiêu thì trừ, và **không bao giờ** xuống âm.
      expect(ketQua.xuDeducted, lessThanOrEqualTo(20));
      final sau = await walletDao.balanceOf(childId);
      expect(
        sau.total,
        greaterThanOrEqualTo(0),
        reason: 'số dư âm là thứ không giải thích được cho một đứa trẻ',
      );
      expect(sau.spend, greaterThanOrEqualTo(0));
      expect(sau.save, greaterThanOrEqualTo(0));
      expect(sau.give, greaterThanOrEqualTo(0));
    });
  });
}
