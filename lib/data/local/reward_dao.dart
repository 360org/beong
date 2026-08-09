import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/tables/tables.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:drift/drift.dart';

part 'reward_dao.g.dart';

@DriftAccessor(tables: [Rewards, Redemptions])
class RewardDao extends DatabaseAccessor<AppDatabase> with _$RewardDaoMixin {
  RewardDao(super.attachedDatabase);

  /// Phần thưởng active của gia đình.
  Stream<List<Reward>> watchRewards(String familyId) {
    return (select(rewards)
          ..where(
            (r) =>
                r.familyId.equals(familyId) &
                r.active.equals(true) &
                r.deletedAt.isNull(),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.costPoints)]))
        .watch();
  }

  Future<void> createReward(RewardsCompanion reward) {
    return into(rewards).insert(reward);
  }

  Future<void> updateReward(String id, RewardsCompanion companion) {
    return (update(rewards)..where((r) => r.id.equals(id))).write(companion);
  }

  /// Soft delete.
  Future<void> deleteReward(String id) {
    return (update(rewards)..where((r) => r.id.equals(id))).write(
      RewardsCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  /// Trẻ đổi thưởng → tạo redemption pending.
  Future<void> redeem({
    required RedemptionsCompanion redemption,
  }) async {
    await transaction(() async {
      final reward = await (select(
        rewards,
      )..where((r) => r.id.equals(redemption.rewardId.value))).getSingle();

      if (reward.stock != null && reward.stock! <= 0) {
        throw StateError('Phần thưởng đã hết');
      }

      await into(redemptions).insert(redemption);

      if (reward.stock != null) {
        await (update(rewards)..where((r) => r.id.equals(reward.id))).write(
          RewardsCompanion(stock: Value(reward.stock! - 1)),
        );
      }
    });
  }

  /// Bố mẹ duyệt phiếu đổi thưởng.
  Future<void> fulfillRedemption({
    required String redemptionId,
    required String resolvedBy,
  }) {
    return (update(redemptions)..where((r) => r.id.equals(redemptionId))).write(
      RedemptionsCompanion(
        status: Value(RedemptionStatus.fulfilled.name),
        resolvedAt: Value(DateTime.now()),
        resolvedBy: Value(resolvedBy),
      ),
    );
  }

  /// Bố mẹ từ chối → hoàn lại stock.
  Future<void> rejectRedemption({
    required String redemptionId,
    required String resolvedBy,
  }) {
    return transaction(() async {
      final redemption = await (select(
        redemptions,
      )..where((r) => r.id.equals(redemptionId))).getSingle();

      await (update(
        redemptions,
      )..where((r) => r.id.equals(redemptionId))).write(
        RedemptionsCompanion(
          status: Value(RedemptionStatus.rejected.name),
          resolvedAt: Value(DateTime.now()),
          resolvedBy: Value(resolvedBy),
        ),
      );

      final reward = await (select(
        rewards,
      )..where((r) => r.id.equals(redemption.rewardId))).getSingleOrNull();
      if (reward != null && reward.stock != null) {
        await (update(rewards)..where((r) => r.id.equals(reward.id))).write(
          RewardsCompanion(stock: Value(reward.stock! + 1)),
        );
      }
    });
  }

  Future<Redemption?> getRedemption(String id) {
    return (select(
      redemptions,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  /// Theo dõi một phiếu. Cùng lý do với `TaskDao.watchInstance`: duyệt hay từ
  /// chối phiếu không ghi dòng sổ cái nào (trừ khoản hoàn xu), nên trạng thái
  /// hiển thị phải theo dõi chứ không tra một lần.
  Stream<Redemption?> watchRedemption(String id) {
    return (select(
      redemptions,
    )..where((r) => r.id.equals(id))).watchSingleOrNull();
  }

  Stream<List<Redemption>> watchPendingRedemptions(String familyId) {
    return (select(redemptions)
          ..where(
            (r) =>
                r.familyId.equals(familyId) &
                r.status.equals(RedemptionStatus.pending.name),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.createdAt)]))
        .watch();
  }

  Future<Reward?> getReward(String id) {
    return (select(rewards)..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  /// Trẻ bấm "đã dùng" trên phiếu.
  Future<void> markUsed(String redemptionId) {
    return (update(redemptions)..where((r) => r.id.equals(redemptionId))).write(
      RedemptionsCompanion(
        status: Value(RedemptionStatus.used.name),
        usedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Phiếu của con — lịch sử đổi thưởng.
  Stream<List<Redemption>> watchRedemptions(String memberId) {
    return (select(redemptions)
          ..where((r) => r.memberId.equals(memberId))
          ..orderBy([
            (r) => OrderingTerm(
              expression: r.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  /// Phiếu chờ duyệt của gia đình.
  Future<List<Redemption>> pendingRedemptions(String familyId) {
    return (select(redemptions)
          ..where(
            (r) =>
                r.familyId.equals(familyId) &
                r.status.equals(RedemptionStatus.pending.name),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.createdAt)]))
        .get();
  }
}
