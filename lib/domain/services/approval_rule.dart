import 'package:beong/domain/entities/enums.dart';

/// Con bấm xong việc này thì vào hàng đợi duyệt, hay xong luôn? — ADR-023.
///
/// Hai tầng, và thứ tự ưu tiên là chỗ dễ nhầm:
///
/// 1. **Gia đình tắt duyệt** (mặc định) → mọi việc xong luôn. Không đọc tới
///    `approvalMode` của task nữa.
/// 2. **Gia đình bật duyệt** → tôn trọng cấu hình từng task, mà mặc định của
///    task là `manual`. Một task được đặt riêng `auto` thì vẫn xong luôn dù nhà
///    đang bật duyệt — bố mẹ đã nói rõ ý mình ở mức cụ thể hơn.
///
/// Tách thành hàm thuần để quy tắc này chỉ tồn tại **một** chỗ. Rải
/// `if (family.requireApproval && task.approvalMode == ...)` ở UI và DAO là
/// cách chắc chắn nhất để hai chỗ lệch nhau.
bool needsApproval({
  required bool familyRequiresApproval,
  required ApprovalMode taskMode,
}) {
  if (!familyRequiresApproval) return false;
  return taskMode == ApprovalMode.manual;
}

/// Đọc `tasks.approval_mode` từ DB về enum, an toàn với giá trị lạ.
///
/// Giá trị không nhận ra được coi là [ApprovalMode.manual] — hướng chặt hơn.
/// Dữ liệu hỏng thì thà bắt bố mẹ duyệt còn hơn tự cộng xu.
ApprovalMode approvalModeFromDb(String? raw) {
  return ApprovalMode.values.firstWhere(
    (m) => m.name == raw,
    orElse: () => ApprovalMode.manual,
  );
}
