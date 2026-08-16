import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/goal_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:meta/meta.dart';

/// Tiến độ của một mục tiêu tiết kiệm.
@immutable
class GoalProgress {
  const GoalProgress({required this.goal, required this.saved});

  final SavingsGoal goal;

  /// Số xu con đang có trong hũ Để dành.
  final int saved;

  int get target => goal.targetXu;

  /// Còn thiếu bao nhiêu xu. Không âm — tới đích rồi thì là 0.
  int get remaining => saved >= target ? 0 : target - saved;

  /// Tỷ lệ 0.0–1.0, đã chặn trên ở 1.0 để thanh tiến độ không tràn.
  double get ratio => target <= 0 ? 0 : (saved / target).clamp(0.0, 1.0);

  /// Phần trăm làm tròn, để hiện chữ.
  int get percent => (ratio * 100).round();

  bool get reached => saved >= target;
}

/// Mục tiêu tiết kiệm — `01-product-spec.md` §4.5.
///
/// Tiến độ đo bằng **hũ Để dành**, không phải tổng số xu. Đó là cả ý nghĩa của
/// tính năng: con để dành được bao nhiêu, chứ không phải con kiếm được bao
/// nhiêu. Đo bằng tổng thì mục tiêu tự tới đích nhờ xu trong hũ Tiêu — số xu con
/// sắp tiêu đi — và thanh tiến độ sẽ tụt xuống mỗi lần con đổi phần thưởng.
class GoalService {
  const GoalService({required GoalDao goalDao, required WalletDao walletDao})
    : _goals = goalDao,
      _wallet = walletDao;

  final GoalDao _goals;
  final WalletDao _wallet;

  /// Số xu tính vào mục tiêu.
  ///
  /// Nhà xếp hũ Để dành lại thì không còn chỗ nào đo được "để dành" nữa; lúc đó
  /// lấy tổng xu đã chia, còn hơn là thanh tiến độ đứng yên ở 0 mãi mãi mà
  /// không nói vì sao.
  static int savedIn(WalletBalance balance, {required bool hasSaveJar}) =>
      hasSaveJar ? balance.ofKey(kJarSave) : balance.allocated;

  /// Tiến độ mục tiêu đang chạy, `null` nếu con chưa có mục tiêu nào.
  Future<GoalProgress?> progressFor(
    String memberId, {
    bool hasSaveJar = true,
  }) async {
    final goal = await _goals.activeGoal(memberId);
    if (goal == null) return null;
    final balance = await _wallet.balanceOf(memberId);
    return GoalProgress(
      goal: goal,
      saved: savedIn(balance, hasSaveJar: hasSaveJar),
    );
  }

  /// Nếu mục tiêu đã đủ xu thì đánh dấu tới đích và trả về nó, để chỗ gọi ăn
  /// mừng. Chưa đủ thì trả `null`.
  ///
  /// **Không trừ xu.** Tới đích chỉ là một cái mốc; xu vẫn nằm trong hũ Để dành
  /// cho tới khi bố mẹ và con thật sự mua món đồ đó ngoài đời. Tự trừ ở đây là
  /// xoá tiền của con để đổi lấy một dòng chữ trong app.
  Future<SavingsGoal?> checkReached(
    String memberId, {
    bool hasSaveJar = true,
  }) async {
    final progress = await progressFor(memberId, hasSaveJar: hasSaveJar);
    if (progress == null || !progress.reached) return null;
    await _goals.markReached(progress.goal.id);
    return progress.goal;
  }
}
