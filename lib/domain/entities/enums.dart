/// Các kiểu liệt kê dùng chung trong domain.
///
/// Mọi enum lưu xuống DB dưới dạng chuỗi `name` — đừng đổi tên hằng đã phát hành,
/// dữ liệu cũ sẽ không đọc được. Thêm mới thì thêm ở cuối.
library;

enum MemberKind { parent, child }

enum MembershipRole { owner, parent }

/// Kiểu lặp của task/routine.
enum RepeatType {
  /// Một lần vào một ngày cụ thể.
  once,

  /// Mọi ngày.
  daily,

  /// Các thứ được chọn trong tuần.
  custom,
}

/// Buổi trong ngày. Đặt tên là `DayPart` chứ không phải `TimeOfDay` để không
/// đụng với `TimeOfDay` của Flutter khi tầng UI import cả hai.
enum DayPart { morning, afternoon, evening }

enum ApprovalMode {
  /// Trẻ bấm xong là cộng xu ngay.
  auto,

  /// Chờ bố mẹ duyệt. Mặc định — ADR-009.
  manual,
}

enum ProofMode { none, photo, note }

/// Trạng thái của một lượt làm việc trong ngày.
enum InstanceStatus {
  scheduled,
  pendingReview,
  approved,
  rejected,
  missed,
}

/// Ba hũ — ADR-016. Xu được chia ngay khi kiếm được, không chia phần còn lại.
enum Jar {
  /// Tiêu — đổi phần thưởng nhỏ ngay.
  spend,

  /// Để dành — dồn cho mục tiêu lớn, không tiêu vặt được.
  save,

  /// Cho đi — việc tử tế, quà tặng, quyên góp.
  give,
}

/// Lý do một dòng xuất hiện trong sổ cái.
enum TxReason {
  taskApproved,
  routineBonus,
  streakBonus,
  rewardRedeemed,
  rewardRefund,
  manualAdjust,
  bonus,
  penalty,
}

enum RewardType { screenTime, pocketMoney, experience, item, custom }

enum RedemptionStatus { pending, fulfilled, rejected, used }

enum GoalStatus { active, reached, abandoned }
