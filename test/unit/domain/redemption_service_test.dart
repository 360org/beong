import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/reward_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/jar_splitter.dart';
import 'package:beong/domain/services/redemption_service.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

/// Ba lỗi thật của luồng đổi thưởng cũ, mỗi lỗi một nhóm test ở đây:
/// không nguyên tử, từ chối không hoàn xu, không có đường duyệt.
void main() {
  late AppDatabase db;
  late RewardDao rewardDao;
  late WalletDao walletDao;
  late MemberDao memberDao;
  late RedemptionService service;

  const familyId = 'fam-1';
  const childId = 'con-1';
  const parentId = 'bo-me';

  Future<void> giveXu(int amount) => walletDao.credit(
    familyId: familyId,
    memberId: childId,
    amount: amount,
    reason: TxReason.bonus,
    clientOpId: 'seed-$amount',
    split: JarSplit.spendOnly,
  );

  Future<Reward> makeReward({
    String id = 'r1',
    int cost = 50,
    int? stock,
    bool requiresApproval = true,
    bool active = true,
  }) async {
    await rewardDao.createReward(
      RewardsCompanion.insert(
        id: id,
        familyId: familyId,
        title: 'Phần thưởng $id',
        costPoints: cost,
        stock: Value(stock),
        requiresApproval: Value(requiresApproval),
        active: Value(active),
      ),
    );
    return (await rewardDao.getReward(id))!;
  }

  setUp(() async {
    db = AppDatabase.memory();
    rewardDao = RewardDao(db);
    walletDao = WalletDao(db);
    memberDao = MemberDao(db);
    service = RedemptionService(rewardDao: rewardDao, walletDao: walletDao);

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

  group('đổi thưởng', () {
    test('trừ đúng số xu và tạo phiếu chờ duyệt', () async {
      await giveXu(100);
      final reward = await makeReward();

      final id = await service.redeem(
        familyId: familyId,
        memberId: childId,
        reward: reward,
        clientOpId: 'op-1',
      );

      expect((await walletDao.balanceOf(childId)).total, 50);
      final redemption = await rewardDao.getRedemption(id);
      expect(redemption!.status, RedemptionStatus.pending.name);
      expect(redemption.costSnapshot, 50);
    });

    test(
      'phần thưởng không cần duyệt thì thành phiếu dùng được ngay',
      () async {
        await giveXu(100);
        final reward = await makeReward(requiresApproval: false);

        final id = await service.redeem(
          familyId: familyId,
          memberId: childId,
          reward: reward,
          clientOpId: 'op-1',
        );

        expect(
          (await rewardDao.getRedemption(id))!.status,
          RedemptionStatus.fulfilled.name,
        );
      },
    );

    test('không đủ xu thì **không** trừ gì và không có phiếu nào', () async {
      await giveXu(10);
      final reward = await makeReward();

      await expectLater(
        service.redeem(
          familyId: familyId,
          memberId: childId,
          reward: reward,
          clientOpId: 'op-1',
        ),
        throwsA(isA<RedemptionException>()),
      );

      expect((await walletDao.balanceOf(childId)).total, 10);
      expect(await db.select(db.redemptions).get(), isEmpty);
    });

    test('hết hàng thì báo lỗi **trước khi** trừ xu', () async {
      // Đây là lỗi cũ: UI trừ xu trước rồi DAO mới ném lỗi hết hàng, con mất xu
      // mà không có phiếu.
      await giveXu(100);
      final reward = await makeReward(stock: 0);

      await expectLater(
        service.redeem(
          familyId: familyId,
          memberId: childId,
          reward: reward,
          clientOpId: 'op-1',
        ),
        throwsA(isA<RedemptionException>()),
      );

      expect((await walletDao.balanceOf(childId)).total, 100);
      expect(await db.select(db.redemptions).get(), isEmpty);
    });

    test('phần thưởng đã ẩn thì không đổi được', () async {
      await giveXu(100);
      final reward = await makeReward(active: false);

      await expectLater(
        service.redeem(
          familyId: familyId,
          memberId: childId,
          reward: reward,
          clientOpId: 'op-1',
        ),
        throwsA(isA<RedemptionException>()),
      );
      expect((await walletDao.balanceOf(childId)).total, 100);
    });

    test('chỉ tiêu xu hũ Tiêu, không lấy hũ Để dành', () async {
      // Xu chia 50/40/10 → hũ Tiêu chỉ có 50. Thưởng 80 xu phải bị từ chối dù
      // tổng số dư là 100.
      await walletDao.credit(
        familyId: familyId,
        memberId: childId,
        amount: 100,
        reason: TxReason.bonus,
        clientOpId: 'seed-split',
        split: JarSplit.defaultSplit,
      );
      final reward = await makeReward(cost: 80);

      await expectLater(
        service.redeem(
          familyId: familyId,
          memberId: childId,
          reward: reward,
          clientOpId: 'op-1',
        ),
        throwsA(isA<RedemptionException>()),
      );
      expect((await walletDao.balanceOf(childId)).of(Jar.save), 40);
    });

    test('hết hàng thì giảm stock, đổi tiếp là hết', () async {
      await giveXu(200);
      final reward = await makeReward(stock: 1);

      await service.redeem(
        familyId: familyId,
        memberId: childId,
        reward: reward,
        clientOpId: 'op-1',
      );

      final refreshed = (await rewardDao.getReward('r1'))!;
      expect(refreshed.stock, 0);

      await expectLater(
        service.redeem(
          familyId: familyId,
          memberId: childId,
          reward: refreshed,
          clientOpId: 'op-2',
        ),
        throwsA(isA<RedemptionException>()),
      );
      expect((await walletDao.balanceOf(childId)).total, 150);
    });
  });

  group('bố mẹ duyệt', () {
    test('duyệt thì phiếu thành dùng được, xu không đổi', () async {
      await giveXu(100);
      final reward = await makeReward();
      final id = await service.redeem(
        familyId: familyId,
        memberId: childId,
        reward: reward,
        clientOpId: 'op-1',
      );

      await service.approve(redemptionId: id, resolvedBy: parentId);

      final redemption = (await rewardDao.getRedemption(id))!;
      expect(redemption.status, RedemptionStatus.fulfilled.name);
      expect(redemption.resolvedBy, parentId);
      expect((await walletDao.balanceOf(childId)).total, 50);
    });

    test('con bấm đã dùng thì phiếu đóng lại', () async {
      await giveXu(100);
      final reward = await makeReward(requiresApproval: false);
      final id = await service.redeem(
        familyId: familyId,
        memberId: childId,
        reward: reward,
        clientOpId: 'op-1',
      );

      await service.markUsed(id);

      expect((await rewardDao.getRedemption(id))!.usedAt, isNotNull);
    });
  });

  group('bố mẹ từ chối', () {
    test('**hoàn đủ xu** và hoàn lại số lượng', () async {
      // Lỗi cũ: từ chối hoàn stock nhưng không hoàn xu — con mất xu cho một
      // phần thưởng không được nhận.
      await giveXu(100);
      final reward = await makeReward(stock: 2);
      final id = await service.redeem(
        familyId: familyId,
        memberId: childId,
        reward: reward,
        clientOpId: 'op-1',
      );
      expect((await walletDao.balanceOf(childId)).total, 50);

      final refunded = await service.reject(
        redemptionId: id,
        resolvedBy: parentId,
      );

      expect(refunded, 50);
      expect((await walletDao.balanceOf(childId)).total, 100);
      expect((await rewardDao.getReward('r1'))!.stock, 2);
    });

    test('hoàn nguyên về hũ Tiêu, không chia lại ba hũ', () async {
      // Chia lại theo tỷ lệ sẽ lặng lẽ chuyển xu sang hũ Để dành và Cho đi; con
      // thấy hũ Tiêu hụt đi sau một lần bị từ chối.
      await giveXu(100);
      final reward = await makeReward();
      final id = await service.redeem(
        familyId: familyId,
        memberId: childId,
        reward: reward,
        clientOpId: 'op-1',
      );

      await service.reject(redemptionId: id, resolvedBy: parentId);

      final balance = await walletDao.balanceOf(childId);
      expect(balance.of(Jar.spend), 100);
      expect(balance.of(Jar.save), 0);
      expect(balance.of(Jar.give), 0);
    });

    test('từ chối hai lần không hoàn xu hai lần', () async {
      await giveXu(100);
      final reward = await makeReward();
      final id = await service.redeem(
        familyId: familyId,
        memberId: childId,
        reward: reward,
        clientOpId: 'op-1',
      );

      await service.reject(redemptionId: id, resolvedBy: parentId);
      final second = await service.reject(
        redemptionId: id,
        resolvedBy: parentId,
      );

      expect(second, 0);
      expect((await walletDao.balanceOf(childId)).total, 100);
    });

    test('phiếu đã duyệt thì từ chối không hoàn xu', () async {
      await giveXu(100);
      final reward = await makeReward();
      final id = await service.redeem(
        familyId: familyId,
        memberId: childId,
        reward: reward,
        clientOpId: 'op-1',
      );
      await service.approve(redemptionId: id, resolvedBy: parentId);

      expect(await service.reject(redemptionId: id, resolvedBy: parentId), 0);
      expect((await walletDao.balanceOf(childId)).total, 50);
    });

    test('phiếu không tồn tại thì hoàn 0, không nổ', () async {
      expect(
        await service.reject(redemptionId: 'không-có', resolvedBy: parentId),
        0,
      );
    });
  });

  group('hàng đợi cho bố mẹ', () {
    test('phiếu chờ duyệt hiện trong hàng đợi, duyệt xong thì hết', () async {
      await giveXu(200);
      final reward = await makeReward();
      final id = await service.redeem(
        familyId: familyId,
        memberId: childId,
        reward: reward,
        clientOpId: 'op-1',
      );

      expect(
        (await rewardDao.watchPendingRedemptions(familyId).first).map(
          (r) => r.id,
        ),
        [id],
      );

      await service.approve(redemptionId: id, resolvedBy: parentId);

      expect(await rewardDao.watchPendingRedemptions(familyId).first, isEmpty);
    });

    test('phần thưởng không cần duyệt không vào hàng đợi', () async {
      await giveXu(100);
      final reward = await makeReward(requiresApproval: false);
      await service.redeem(
        familyId: familyId,
        memberId: childId,
        reward: reward,
        clientOpId: 'op-1',
      );

      expect(await rewardDao.watchPendingRedemptions(familyId).first, isEmpty);
    });
  });
}
