// Tầng repository — xem `README.md` cùng thư mục để biết vì sao có tầng này và
// vì sao mặt cắt của nó chỉ bằng thứ `lib/features` thật sự dùng.

import 'package:beong/data/local/wallet_dao.dart';

// Kiểu dữ liệu tầng UI cần cùng với các phương thức dưới đây. Xuất lại từ đây để
// `lib/features` chỉ phải import một chỗ, và để ràng buộc "features không import
// lib/data" giữ được.
export 'package:beong/data/local/wallet_dao.dart'
    show LedgerEntry, WalletBalance, WalletException;

/// Ví xu — chỉ phần **đọc** và thao tác con tự chia.
///
/// Cộng và trừ xu **không** nằm ở đây: chúng đi qua `TaskReviewService`,
/// `PenaltyService`, `RedemptionService`, vì mỗi lần ghi sổ phải nằm trong cùng
/// một transaction với việc đổi trạng thái lượt việc hay phiếu thưởng. Mở đường
/// cộng xu ra cho tầng UI chính là lỗi ADR-023 đã phải đi dọn.
abstract interface class WalletRepository {
  Future<void> moveFromInboxToKey({
    required String familyId,
    required String memberId,
    required String toJarKey,
    required int amount,
    required String clientOpId,
  });
  Future<WalletBalance> balanceOf(String memberId);
  Stream<WalletBalance> watchBalance(String memberId);
  Stream<List<LedgerEntry>> watchGroupedHistory(String memberId);
  Future<void> manualAdjustToJarKey({
    required String familyId,
    required String memberId,
    required String jarKey,
    required int delta,
    required String reasonNote,
    required String clientOpId,
    required String createdBy,
  });
}

/// Bản chạy trên máy: đọc ghi thẳng SQLite qua [WalletDao].
///
/// Sprint 3 sẽ có bản thứ hai đứng cạnh bản này, và **chỉ chỗ đó** phải quyết
/// định đọc local hay đọc máy chủ. Tầng UI không đổi một dòng nào.
final class LocalWalletRepository implements WalletRepository {
  const LocalWalletRepository(this._dao);

  final WalletDao _dao;

  @override
  Future<void> moveFromInboxToKey({
    required String familyId,
    required String memberId,
    required String toJarKey,
    required int amount,
    required String clientOpId,
  }) => _dao.moveFromInboxToKey(
    familyId: familyId,
    memberId: memberId,
    toJarKey: toJarKey,
    amount: amount,
    clientOpId: clientOpId,
  );

  @override
  Future<WalletBalance> balanceOf(String memberId) => _dao.balanceOf(memberId);

  @override
  Stream<WalletBalance> watchBalance(String memberId) =>
      _dao.watchBalance(memberId);

  @override
  Stream<List<LedgerEntry>> watchGroupedHistory(String memberId) =>
      _dao.watchGroupedHistory(memberId);

  @override
  Future<void> manualAdjustToJarKey({
    required String familyId,
    required String memberId,
    required String jarKey,
    required int delta,
    required String reasonNote,
    required String clientOpId,
    required String createdBy,
  }) => _dao.manualAdjustToJarKey(
    familyId: familyId,
    memberId: memberId,
    jarKey: jarKey,
    delta: delta,
    reasonNote: reasonNote,
    clientOpId: clientOpId,
    createdBy: createdBy,
  );
}
