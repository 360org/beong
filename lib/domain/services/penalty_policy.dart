import 'package:meta/meta.dart';

/// Cấu hình trừ xu của một gia đình — ADR-022.
///
/// **Mặc định tắt.** Nhiều tài liệu nuôi dạy phản đối trừ điểm vì nó biến động
/// lực bên trong ("mình muốn làm") thành sợ mất mát ("làm không thì bị trừ").
/// App không quyết thay bố mẹ, nhưng cũng không bật sẵn: gia đình nào muốn thì
/// tự bật, và lúc bật phải đọc cảnh báo.
@immutable
class PenaltyPolicy {
  const PenaltyPolicy({required this.missedPct, required this.reopenPct});

  /// Không trừ xu — trạng thái mặc định của một gia đình mới.
  static const off = PenaltyPolicy(missedPct: 0, reopenPct: 0);

  /// Phần trăm điểm của việc bị trừ khi **hết ngày mà không làm**.
  final int missedPct;

  /// Phần trăm điểm của việc bị trừ khi bố mẹ **mở lại** việc con đã bấm xong
  /// nhưng thực tế chưa làm.
  final int reopenPct;

  bool get isEnabled => missedPct > 0 || reopenPct > 0;

  bool get isValid =>
      missedPct >= 0 && missedPct <= 100 && reopenPct >= 0 && reopenPct <= 100;

  PenaltyPolicy copyWith({int? missedPct, int? reopenPct}) => PenaltyPolicy(
    missedPct: missedPct ?? this.missedPct,
    reopenPct: reopenPct ?? this.reopenPct,
  );

  @override
  bool operator ==(Object other) =>
      other is PenaltyPolicy &&
      other.missedPct == missedPct &&
      other.reopenPct == reopenPct;

  @override
  int get hashCode => Object.hash(missedPct, reopenPct);

  @override
  String toString() =>
      'PenaltyPolicy(bỏ việc $missedPct%, làm lại $reopenPct%)';
}

/// Số xu bị trừ cho **một** việc đáng giá [taskPoints], với mức [pct].
///
/// Làm tròn **xuống** (về 0), tức là nghiêng về phía trẻ: 50% của 15 xu ra 7,
/// không phải 8. Xu là thứ trẻ đếm được, và chỗ nào phải chọn thì chọn bên
/// không làm trẻ cảm thấy bị xử ép.
///
/// [taskPoints] âm được coi là 0: một việc không đáng xu nào thì cũng không có
/// gì để trừ.
int penaltyFor({required int taskPoints, required int pct}) {
  if (pct <= 0 || taskPoints <= 0) return 0;
  final capped = pct > 100 ? 100 : pct;
  return (taskPoints * capped) ~/ 100;
}

/// Một việc trong ngày, đủ thông tin để tính xu — dùng cho [summarizeDay].
@immutable
class DayTaskOutcome {
  const DayTaskOutcome({
    required this.points,
    required this.completed,
    this.reopenCount = 0,
  });

  /// Điểm của việc (đã chốt trên instance — `points_snapshot`).
  final int points;

  /// Cuối ngày việc này có được duyệt xong hay không.
  final bool completed;

  /// Số lần bố mẹ mở lại việc này. Mỗi lần mở lại là một lần bị trừ.
  final int reopenCount;
}

/// Tổng kết xu một ngày của một trẻ.
@immutable
class DayPenaltySummary {
  const DayPenaltySummary({
    required this.earned,
    required this.missedPenalty,
    required this.reopenPenalty,
  });

  /// Xu kiếm được từ những việc đã xong.
  final int earned;

  /// Xu bị trừ vì hết ngày không làm.
  final int missedPenalty;

  /// Xu bị trừ vì phải làm lại.
  final int reopenPenalty;

  int get totalPenalty => missedPenalty + reopenPenalty;

  /// Thay đổi ròng của ngày. Có thể âm nếu bỏ nhiều việc.
  int get net => earned - totalPenalty;

  @override
  bool operator ==(Object other) =>
      other is DayPenaltySummary &&
      other.earned == earned &&
      other.missedPenalty == missedPenalty &&
      other.reopenPenalty == reopenPenalty;

  @override
  int get hashCode => Object.hash(earned, missedPenalty, reopenPenalty);

  @override
  String toString() =>
      'DayPenaltySummary(kiếm $earned, bỏ việc -$missedPenalty, '
      'làm lại -$reopenPenalty, ròng $net)';
}

/// Tổng kết một ngày: kiếm được bao nhiêu, bị trừ bao nhiêu.
///
/// Hàm thuần, không đọc DB — để con số trong app và con số bố mẹ tự tính ra
/// giấy luôn khớp, và để test được bằng đúng ví dụ bố mẹ đưa.
///
/// Lưu ý về việc bị mở lại: việc đó **vẫn được tính xu đầy đủ** khi cuối cùng
/// làm xong, chỉ cộng thêm một khoản trừ cho mỗi lần phải làm lại. Trừ cả xu
/// kiếm được lẫn phạt sẽ thành trừ hai lần cho một lỗi.
DayPenaltySummary summarizeDay({
  required List<DayTaskOutcome> tasks,
  required PenaltyPolicy policy,
}) {
  var earned = 0;
  var missed = 0;
  var reopen = 0;

  for (final t in tasks) {
    if (t.completed) {
      earned += t.points > 0 ? t.points : 0;
    } else {
      missed += penaltyFor(taskPoints: t.points, pct: policy.missedPct);
    }
    if (t.reopenCount > 0) {
      reopen +=
          penaltyFor(taskPoints: t.points, pct: policy.reopenPct) *
          t.reopenCount;
    }
  }

  return DayPenaltySummary(
    earned: earned,
    missedPenalty: missed,
    reopenPenalty: reopen,
  );
}
