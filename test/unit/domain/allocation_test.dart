import 'package:beong/data/local/badge_dao.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/services/penalty_service.dart';
import 'package:beong/domain/services/task_review_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chế độ "con tự chia" (ADR-024): xu vào **hũ chờ**, con chia cuối ngày.
///
/// Chỗ dễ mất xu nhất trong tính năng này là `WalletBalance`: nó vốn chỉ biết ba
/// hũ, nên xu vào hũ chờ sẽ **biến mất khỏi số dư** nếu không xử lý. Nhóm test
/// đầu tiên chốt đúng chỗ đó.
void main() {
  late AppDatabase db;
  late TaskDao taskDao;
  late WalletDao walletDao;
  late MemberDao memberDao;
  late TaskReviewService review;

  const familyId = 'fam-1';
  const childId = 'con-1';

  Future<void> makeInstance({required String id, int points = 10}) async {
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
          ),
        );
  }

  setUp(() async {
    db = AppDatabase.memory();
    taskDao = TaskDao(db);
    walletDao = WalletDao(db);
    memberDao = MemberDao(db);
    review = TaskReviewService(
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

  group('chế độ mặc định: chia tự động', () {
    test('gia đình mới chia tự động', () async {
      expect(
        await memberDao.watchAllocationMode(familyId).first,
        AllocationMode.auto,
      );
    });

    test('làm xong việc thì xu chia ngay vào ba hũ, hũ chờ rỗng', () async {
      await makeInstance(id: 'i1');
      await review.complete('i1');

      final balance = await walletDao.balanceOf(childId);
      expect(balance.spend, 5);
      expect(balance.save, 4);
      expect(balance.give, 1);
      expect(balance.inbox, 0);
      expect(balance.total, 10);
    });
  });

  group('chế độ con tự chia', () {
    setUp(() async {
      await memberDao.setAllocationMode(familyId, AllocationMode.manual);
    });

    test('xu vào hũ chờ, **vẫn tính vào tổng điểm**', () async {
      // Đây là chỗ dễ hỏng: bỏ hũ chờ ra khỏi tổng thì con làm xong việc mà màn
      // hình hiện 0 điểm.
      await makeInstance(id: 'i1');
      await review.complete('i1');

      final balance = await walletDao.balanceOf(childId);
      expect(balance.inbox, 10);
      expect(balance.allocated, 0);
      expect(balance.total, 10, reason: 'xu là của con ngay khi làm xong');
    });

    test('nhiều việc thì cộng dồn trong hũ chờ', () async {
      for (var i = 1; i <= 3; i++) {
        await makeInstance(id: 'i$i');
        await review.complete('i$i');
      }

      expect((await walletDao.balanceOf(childId)).inbox, 30);
    });

    test('con chia sang hũ: tổng không đổi, chỉ đổi chỗ', () async {
      await makeInstance(id: 'i1');
      await review.complete('i1');

      await walletDao.moveFromInbox(
        familyId: familyId,
        memberId: childId,
        toJar: Jar.save,
        amount: 6,
        clientOpId: 'alloc-1',
      );

      final balance = await walletDao.balanceOf(childId);
      expect(balance.inbox, 4);
      expect(balance.save, 6);
      expect(balance.total, 10, reason: 'chia xu không sinh thêm xu');
    });

    test(
      'chia thành hai dòng bù nhau, gộp thành **một** mục lịch sử',
      () async {
        await makeInstance(id: 'i1');
        await review.complete('i1');
        await walletDao.moveFromInbox(
          familyId: familyId,
          memberId: childId,
          toJar: Jar.spend,
          amount: 10,
          clientOpId: 'alloc-1',
        );

        final rows = await walletDao.watchHistory(childId).first;
        final transfers = rows.where((r) => r.reason == 'jarTransfer').toList();
        expect(transfers, hasLength(2));
        expect(transfers.fold(0, (sum, r) => sum + r.delta), 0);

        final grouped = await walletDao.watchGroupedHistory(childId).first;
        final transferEntry = grouped.firstWhere(
          (e) => e.reason == 'jarTransfer',
        );
        expect(transferEntry.delta, 0, reason: 'đổi chỗ, không đổi tổng');
      },
    );

    test('chia nhiều hơn số xu đang chờ thì bị từ chối', () async {
      await makeInstance(id: 'i1');
      await review.complete('i1');

      await expectLater(
        walletDao.moveFromInbox(
          familyId: familyId,
          memberId: childId,
          toJar: Jar.save,
          amount: 50,
          clientOpId: 'alloc-1',
        ),
        throwsA(isA<WalletException>()),
      );
      expect((await walletDao.balanceOf(childId)).inbox, 10);
    });

    test('không chuyển hũ chờ sang chính nó', () async {
      await makeInstance(id: 'i1');
      await review.complete('i1');

      await expectLater(
        walletDao.moveFromInbox(
          familyId: familyId,
          memberId: childId,
          toJar: Jar.inbox,
          amount: 5,
          clientOpId: 'alloc-1',
        ),
        throwsA(isA<WalletException>()),
      );
    });

    test('chia lại cùng clientOpId không chia hai lần', () async {
      await makeInstance(id: 'i1');
      await review.complete('i1');

      await walletDao.moveFromInbox(
        familyId: familyId,
        memberId: childId,
        toJar: Jar.save,
        amount: 5,
        clientOpId: 'alloc-1',
      );
      await walletDao.moveFromInbox(
        familyId: familyId,
        memberId: childId,
        toJar: Jar.save,
        amount: 5,
        clientOpId: 'alloc-1',
      );

      final balance = await walletDao.balanceOf(childId);
      expect(balance.save, 5);
      expect(balance.inbox, 5);
    });

    test('đổi chế độ không hồi tố: xu đã ở hũ chờ vẫn ở đó', () async {
      await makeInstance(id: 'i1');
      await review.complete('i1');
      expect((await walletDao.balanceOf(childId)).inbox, 10);

      await memberDao.setAllocationMode(familyId, AllocationMode.auto);
      await makeInstance(id: 'i2');
      await review.complete('i2');

      final balance = await walletDao.balanceOf(childId);
      expect(balance.inbox, 10, reason: 'phần cũ không tự chia');
      expect(balance.allocated, 10, reason: 'phần mới chia ngay');
      expect(balance.total, 20);
    });
  });

  group('trừ xu lấy hũ chờ trước', () {
    test('khoản trừ lấy ở hũ chờ trước khi đụng hũ đã chia', () async {
      // Xu trong hũ chờ là xu con chưa cam kết vào giá trị nào, nên lấy ở đó ít
      // phá vỡ nhất (ADR-022 + ADR-024).
      await memberDao.setAllocationMode(familyId, AllocationMode.manual);
      await makeInstance(id: 'i1');
      await review.complete('i1');
      await walletDao.moveFromInbox(
        familyId: familyId,
        memberId: childId,
        toJar: Jar.save,
        amount: 6,
        clientOpId: 'alloc-1',
      );
      // Còn: hũ chờ 4, để dành 6.

      await walletDao.penalize(
        familyId: familyId,
        memberId: childId,
        amount: 4,
        clientOpId: 'pen-1',
      );

      final balance = await walletDao.balanceOf(childId);
      expect(balance.inbox, 0);
      expect(balance.save, 6, reason: 'hũ đã chia được giữ nguyên');
    });
  });
}
