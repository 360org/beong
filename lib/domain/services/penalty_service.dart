import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/services/penalty_policy.dart';
import 'package:meta/meta.dart';

/// Kết quả một lần chạy trừ xu, để UI nói cho bố mẹ biết đã xảy ra chuyện gì.
@immutable
class PenaltyOutcome {
  const PenaltyOutcome({required this.instanceCount, required this.xuDeducted});

  static const none = PenaltyOutcome(instanceCount: 0, xuDeducted: 0);

  /// Số lượt việc bị áp khoản trừ.
  final int instanceCount;

  /// Tổng xu **thực sự** bị trừ. Nhỏ hơn mức lý thuyết nếu con đã hết xu.
  final int xuDeducted;

  bool get isEmpty => instanceCount == 0 && xuDeducted == 0;

  @override
  bool operator ==(Object other) =>
      other is PenaltyOutcome &&
      other.instanceCount == instanceCount &&
      other.xuDeducted == xuDeducted;

  @override
  int get hashCode => Object.hash(instanceCount, xuDeducted);

  @override
  String toString() => 'PenaltyOutcome($instanceCount lượt, -$xuDeducted xu)';
}

/// Ghép chính sách trừ xu (ADR-022) với sổ cái.
///
/// Đặt ở tầng domain chứ không nhồi vào DAO: một khoản trừ đụng tới ba bảng
/// (`families` để đọc mức, `task_instances` để biết lượt nào, `point_transactions`
/// để ghi sổ), và cái quyết định *có trừ hay không* là quy tắc nghiệp vụ, không
/// phải câu truy vấn.
class PenaltyService {
  const PenaltyService({
    required TaskDao taskDao,
    required WalletDao walletDao,
    required MemberDao memberDao,
  }) : _tasks = taskDao,
       _wallet = walletDao,
       _members = memberDao;

  final TaskDao _tasks;
  final WalletDao _wallet;
  final MemberDao _members;

  /// Áp khoản trừ cho mọi lượt đã bỏ mà chưa xử lý.
  ///
  /// Gọi sau khi bộ lập lịch đánh dấu missed (hết ngày, mở app sang ngày mới).
  /// An toàn khi gọi lại nhiều lần: mỗi lượt được đánh dấu đã xử lý, và
  /// `clientOpId` của dòng sổ cái là tất định nên không trừ hai lần.
  ///
  /// Chính sách tắt thì vẫn đánh dấu đã xử lý — nếu không, ngày bố mẹ bật tính
  /// năng lên là toàn bộ việc bỏ từ trước bị trừ hồi tố một lượt. Trừ hồi tố
  /// cho hành vi xảy ra khi luật chưa có là điều không gia đình nào muốn.
  Future<PenaltyOutcome> applyMissedPenalties({
    required String familyId,
    String? createdBy,
  }) async {
    final pending = await _tasks.pendingMissedPenalties(familyId);
    if (pending.isEmpty) return PenaltyOutcome.none;

    final policy = await _members.penaltyPolicyOf(familyId);

    var count = 0;
    var total = 0;

    for (final instance in pending) {
      // Mức riêng của việc thắng mức chung — nhưng chỉ khi nhà **đang bật**
      // trừ xu. Để mức riêng vượt qua cả công tắc chung thì bố mẹ tắt trừ xu ở
      // Cài đặt xong vẫn thấy con bị trừ, và không hiểu vì sao.
      final pct = instance.missedPenaltyPct ?? policy.missedPct;
      final amount = policy.isEnabled
          ? penaltyFor(taskPoints: instance.pointsSnapshot, pct: pct)
          : 0;

      if (amount > 0) {
        final deducted = await _wallet.penalize(
          familyId: familyId,
          memberId: instance.memberId,
          amount: amount,
          clientOpId: 'missed-penalty:${instance.id}',
          refType: 'task_instance',
          refId: instance.id,
          note: 'Hết ngày chưa làm',
          createdBy: createdBy,
        );
        if (deducted > 0) {
          count++;
          total += deducted;
        }
      }

      await _tasks.markMissedPenaltyApplied(instance.id);
    }

    return PenaltyOutcome(instanceCount: count, xuDeducted: total);
  }

  /// Bố mẹ mở lại một lượt con đã bấm xong nhưng chưa làm — ADR-022.
  ///
  /// Trả về lượt sau khi mở lại kèm số xu đã trừ.
  Future<({TaskInstance instance, int xuDeducted})> reopenInstance({
    required String instanceId,
    required String reviewerId,
  }) async {
    final instance = await _tasks.reopen(
      instanceId: instanceId,
      reviewerId: reviewerId,
    );

    final policy = await _members.penaltyPolicyOf(instance.familyId);
    final amount = penaltyFor(
      taskPoints: instance.pointsSnapshot,
      pct: policy.reopenPct,
    );
    if (amount == 0) return (instance: instance, xuDeducted: 0);

    // `clientOpId` gắn với **lần** mở lại, không chỉ với lượt việc: mở lại hai
    // lần thì phải trừ hai lần, nhưng bấm nút hai lần trong cùng một lần mở lại
    // thì không.
    final deducted = await _wallet.penalize(
      familyId: instance.familyId,
      memberId: instance.memberId,
      amount: amount,
      clientOpId: 'reopen-penalty:$instanceId:${instance.reopenCount}',
      refType: 'task_instance',
      refId: instanceId,
      note: 'Bố mẹ mở lại việc — làm lại lần ${instance.reopenCount}',
      createdBy: reviewerId,
    );

    return (instance: instance, xuDeducted: deducted);
  }
}
