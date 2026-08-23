// Tầng repository — xem `README.md` cùng thư mục để biết vì sao có tầng này và
// vì sao mặt cắt của nó chỉ bằng thứ `lib/features` thật sự dùng.

import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/reward_dao.dart';

// Kiểu dữ liệu tầng UI nhận về từ các phương thức dưới đây. Xuất lại từ đây để
// `lib/features` chỉ import một chỗ, và để ràng buộc "features không import
// lib/data" giữ được (`test/unit/kien_truc_test.dart`).
export 'package:beong/data/local/database.dart'
    show Redemption, Reward, RewardsCompanion;

/// Phần thưởng và phiếu đổi thưởng.
///
/// Đổi thưởng và duyệt đi qua `RedemptionService` chứ không qua đây — cùng lý do
/// như ví xu ().
abstract interface class RewardRepository {
  Future<void> createReward(RewardsCompanion reward);
  Future<void> updateReward(String id, RewardsCompanion reward);
  Future<void> deleteReward(String id);
  Future<Redemption?> getRedemption(String id);
  Future<Reward?> getReward(String id);
  Stream<List<Redemption>> watchPendingRedemptions(String familyId);
  Stream<List<Redemption>> watchRedemptions(String memberId);
  Stream<List<Reward>> watchRewards(String familyId);
  Stream<Redemption?> watchRedemption(String id);
}

/// Bản chạy trên máy: đọc ghi thẳng SQLite qua [RewardDao].
///
/// Sprint 3 sẽ có bản thứ hai đứng cạnh bản này, và **chỉ chỗ đó** phải quyết
/// định đọc local hay đọc máy chủ. Tầng UI không đổi một dòng nào.
final class LocalRewardRepository implements RewardRepository {
  const LocalRewardRepository(this._dao);

  final RewardDao _dao;

  @override
  Future<void> createReward(RewardsCompanion reward) =>
      _dao.createReward(reward);

  @override
  Future<void> updateReward(String id, RewardsCompanion reward) =>
      _dao.updateReward(id, reward);

  @override
  Future<void> deleteReward(String id) => _dao.deleteReward(id);

  @override
  Future<Redemption?> getRedemption(String id) => _dao.getRedemption(id);

  @override
  Future<Reward?> getReward(String id) => _dao.getReward(id);

  @override
  Stream<List<Redemption>> watchPendingRedemptions(String familyId) =>
      _dao.watchPendingRedemptions(familyId);

  @override
  Stream<List<Redemption>> watchRedemptions(String memberId) =>
      _dao.watchRedemptions(memberId);

  @override
  Stream<List<Reward>> watchRewards(String familyId) =>
      _dao.watchRewards(familyId);

  @override
  Stream<Redemption?> watchRedemption(String id) => _dao.watchRedemption(id);
}
