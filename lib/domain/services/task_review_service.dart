import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/services/approval_rule.dart';
import 'package:beong/domain/services/penalty_service.dart';

/// Vòng đời "con bấm xong → xu vào ví" — ADR-023.
///
/// Trước đây việc cộng xu nằm **trong nút duyệt ở UI**, nên đường tự động duyệt
/// đổi trạng thái sang `approved` mà không cộng xu cho ai. Lỗi đó không lộ ra
/// khi mặc định là phải duyệt, nhưng đổi mặc định sang "xong luôn" thì nó thành
/// lỗi nghiêm trọng: con bấm xong được 0 xu.
///
/// Vì vậy toàn bộ quy tắc cộng xu tập trung ở đây, và **UI không tự gọi
/// `WalletDao.credit`** cho việc nhà nữa.
class TaskReviewService {
  const TaskReviewService({
    required TaskDao taskDao,
    required WalletDao walletDao,
    required MemberDao memberDao,
    required PenaltyService penaltyService,
  }) : _tasks = taskDao,
       _wallet = walletDao,
       _members = memberDao,
       _penalties = penaltyService;

  final TaskDao _tasks;
  final WalletDao _wallet;
  final MemberDao _members;
  final PenaltyService _penalties;

  /// Con bấm xong một việc.
  ///
  /// Trả về `true` nếu việc **xong luôn** (đã cộng xu), `false` nếu vào hàng
  /// đợi duyệt.
  Future<bool> complete(String instanceId) async {
    final instance = await _tasks.getInstanceById(instanceId);
    if (instance == null) return false;
    if (instance.status != InstanceStatus.scheduled.name) return false;

    final task = await _tasks.getTaskById(instance.taskId);
    final family = await _members.getFamily(instance.familyId);

    final mustReview = needsApproval(
      familyRequiresApproval: family.requireApproval,
      taskMode: approvalModeFromDb(task.approvalMode),
    );

    if (mustReview) {
      await _tasks.markPendingReview(instanceId);
      return false;
    }

    await _tasks.markApproved(instanceId: instanceId, reviewerId: null);
    await _creditFor(instance);
    return true;
  }

  /// Bố mẹ duyệt một việc trong hàng đợi.
  Future<void> approve({
    required String instanceId,
    required String reviewerId,
  }) async {
    final instance = await _tasks.getInstanceById(instanceId);
    if (instance == null) return;
    if (instance.status == InstanceStatus.approved.name) return;

    await _tasks.markApproved(instanceId: instanceId, reviewerId: reviewerId);
    await _creditFor(instance);
  }

  /// Duyệt tất cả việc đang chờ của một gia đình.
  ///
  /// Trả về số việc đã duyệt. Duyệt tuần tự chứ không song song: mỗi lần cộng
  /// xu đọc số dư trong transaction, và phần thưởng trọn bộ routine cần thấy
  /// trạng thái sau khi việc trước đã duyệt xong.
  Future<int> approveAll({
    required String familyId,
    required String reviewerId,
  }) async {
    final pending = await _tasks.pendingReview(familyId);
    for (final instance in pending) {
      await approve(instanceId: instance.id, reviewerId: reviewerId);
    }
    return pending.length;
  }

  /// Bố mẹ mở lại một việc — ADR-022. Ở đây chỉ chuyển tiếp để UI có **một**
  /// cửa duy nhất cho cả vòng đời việc nhà.
  Future<({TaskInstance instance, int xuDeducted})> reopen({
    required String instanceId,
    required String reviewerId,
  }) => _penalties.reopenInstance(
    instanceId: instanceId,
    reviewerId: reviewerId,
  );

  /// Bố mẹ từ chối: đóng lượt lại, không cộng xu, không trừ xu.
  Future<void> reject({
    required String instanceId,
    required String reviewerId,
  }) => _tasks.reject(instanceId: instanceId, reviewerId: reviewerId);

  Future<void> _creditFor(TaskInstance instance) async {
    // `pointsSnapshot` chứ không phải `tasks.points`: bố mẹ đổi giá task không
    // được làm thay đổi lượt đã sinh (ADR-007).
    if (instance.pointsSnapshot > 0) {
      final family = await _members.getFamily(instance.familyId);
      final mode = allocationModeFromDb(family.allocationMode);

      if (mode == AllocationMode.manual) {
        // Con tự chia: xu vào **hũ chờ**, chưa thuộc hũ nào (ADR-024). Vẫn tính
        // vào tổng điểm của con — xu là của con ngay khi làm xong việc, việc
        // chia là chuyện sau.
        await _wallet.creditToJar(
          familyId: instance.familyId,
          memberId: instance.memberId,
          jar: Jar.inbox,
          amount: instance.pointsSnapshot,
          reason: TxReason.taskApproved,
          clientOpId: 'task-approved:${instance.id}',
          opGroupId: 'task-approved:${instance.id}',
          refType: 'task_instance',
          refId: instance.id,
        );
      } else {
        await _wallet.credit(
          familyId: instance.familyId,
          memberId: instance.memberId,
          amount: instance.pointsSnapshot,
          reason: TxReason.taskApproved,
          clientOpId: 'task-approved:${instance.id}',
          refType: 'task_instance',
          refId: instance.id,
        );
      }
    }

    await _tasks.checkAndAwardRoutineBonus(
      instanceId: instance.id,
      familyId: instance.familyId,
    );
  }
}
