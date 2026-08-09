import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/reward_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/jar_splitter.dart';
import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

/// Lỗi khi đổi thưởng, có câu giải thích đọc được cho trẻ.
class RedemptionException implements Exception {
  const RedemptionException(this.message);
  final String message;

  @override
  String toString() => 'RedemptionException: $message';
}

/// Vòng đời đổi thưởng: con đổi → bố mẹ duyệt → con dùng phiếu.
///
/// Tồn tại vì luồng cũ có ba lỗi thật, và cả ba đều làm mất xu của trẻ:
///
/// 1. **Không nguyên tử.** UI trừ xu trước rồi gọi DAO ghi phiếu. Phần thưởng
///    hết hàng thì DAO ném lỗi *sau khi* xu đã bị trừ — con mất xu mà không có
///    phiếu nào.
/// 2. **Từ chối không hoàn xu.** `rejectRedemption` hoàn lại `stock` nhưng
///    không hoàn xu, dù `05-roadmap.md` ghi rõ "hoàn điểm khi từ chối".
/// 3. **Không có đường duyệt.** `pendingRedemptions`/`fulfillRedemption` không
///    được gọi từ bất kỳ màn nào, nên phiếu nằm `pending` mãi mãi.
@immutable
class RedemptionService {
  const RedemptionService({
    required RewardDao rewardDao,
    required WalletDao walletDao,
  }) : _rewards = rewardDao,
       _wallet = walletDao;

  final RewardDao _rewards;
  final WalletDao _wallet;

  /// Con đổi một phần thưởng.
  ///
  /// Kiểm **trước khi** trừ xu: còn hàng không, đủ xu không. Nếu thiếu thì báo
  /// lỗi và không có gì xảy ra cả — không phiếu, không trừ xu.
  ///
  /// Trả về id phiếu.
  Future<String> redeem({
    required String familyId,
    required String memberId,
    required Reward reward,
    required String clientOpId,
  }) async {
    if (!reward.active) {
      throw const RedemptionException('Phần thưởng này đang tạm ẩn');
    }
    if (reward.stock != null && reward.stock! <= 0) {
      throw const RedemptionException('Phần thưởng đã hết');
    }

    // Trừ ở hũ Tiêu: hũ Để dành và Cho đi có mục đích riêng, không dùng để mua
    // thưởng (ADR-016). `debit` tự báo lỗi khi không đủ xu.
    final balance = await _wallet.balanceOf(memberId);
    if (balance.of(Jar.spend) < reward.costPoints) {
      throw RedemptionException(
        'Hũ Tiêu còn ${balance.of(Jar.spend)} xu, cần ${reward.costPoints} xu',
      );
    }

    await _wallet.debit(
      familyId: familyId,
      memberId: memberId,
      jar: Jar.spend,
      amount: reward.costPoints,
      reason: TxReason.rewardRedeemed,
      clientOpId: clientOpId,
      refType: 'reward',
      refId: reward.id,
    );

    await _rewards.redeem(
      redemption: RedemptionsCompanion.insert(
        id: clientOpId,
        familyId: familyId,
        rewardId: reward.id,
        memberId: memberId,
        costSnapshot: reward.costPoints,
        metaSnapshot: Value(reward.metaJson),
        // Phần thưởng không cần duyệt thì thành phiếu dùng được ngay.
        status: Value(
          reward.requiresApproval
              ? RedemptionStatus.pending.name
              : RedemptionStatus.fulfilled.name,
        ),
      ),
    );

    return clientOpId;
  }

  /// Bố mẹ duyệt phiếu.
  Future<void> approve({
    required String redemptionId,
    required String resolvedBy,
  }) => _rewards.fulfillRedemption(
    redemptionId: redemptionId,
    resolvedBy: resolvedBy,
  );

  /// Bố mẹ từ chối phiếu → **hoàn xu** và hoàn số lượng.
  ///
  /// Hoàn bằng một dòng sổ cái mới (`rewardRefund`), không sửa dòng cũ — ADR-005.
  /// `clientOpId` gắn với phiếu nên từ chối hai lần không hoàn xu hai lần.
  ///
  /// Trả về số xu đã hoàn.
  Future<int> reject({
    required String redemptionId,
    required String resolvedBy,
    String? note,
  }) async {
    final redemption = await _rewards.getRedemption(redemptionId);
    if (redemption == null) return 0;
    if (redemption.status != RedemptionStatus.pending.name) {
      // Phiếu đã duyệt hoặc đã từ chối: không hoàn thêm lần nữa.
      return 0;
    }

    await _rewards.rejectRedemption(
      redemptionId: redemptionId,
      resolvedBy: resolvedBy,
    );

    await _wallet.credit(
      familyId: redemption.familyId,
      memberId: redemption.memberId,
      amount: redemption.costSnapshot,
      reason: TxReason.rewardRefund,
      clientOpId: 'reward-refund:$redemptionId',
      refType: 'redemption',
      refId: redemptionId,
      note: note,
      // Hoàn **nguyên vẹn về hũ Tiêu**, không chia lại theo tỷ lệ ba hũ: xu này
      // đã bị trừ từ hũ Tiêu, nên chia lại sẽ lặng lẽ chuyển xu sang hũ Để dành
      // và Cho đi. Con sẽ thấy hũ Tiêu hụt đi sau một lần bị từ chối.
      split: JarSplit.spendOnly,
    );

    return redemption.costSnapshot;
  }

  /// Con bấm "đã dùng" trên phiếu.
  Future<void> markUsed(String redemptionId) => _rewards.markUsed(redemptionId);
}
