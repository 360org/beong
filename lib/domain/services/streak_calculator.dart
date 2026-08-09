import 'package:beong/domain/services/family_clock.dart';

/// Tổng kết một ngày của trẻ, đủ để tính streak.
class DayTally {
  const DayTally({
    required this.date,
    required this.due,
    required this.approved,
  });

  final CalendarDate date;

  /// Số lượt việc đến hạn trong ngày.
  final int due;

  /// Số lượt đã được duyệt.
  final int approved;

  /// Ngày không có việc nào đến hạn — **không cộng streak, cũng không làm đứt**.
  /// Chủ nhật không giao việc thì không phải lỗi của đứa trẻ.
  bool get isNeutral => due == 0;

  double get ratio => due == 0 ? 1 : approved / due;
}

class StreakResult {
  const StreakResult({
    required this.current,
    required this.graceUsedInMonth,
    required this.graceMonthKey,
  });

  static const empty = StreakResult(
    current: 0,
    graceUsedInMonth: 0,
    graceMonthKey: '',
  );

  final int current;

  /// Số ngày ân hạn đã dùng trong [graceMonthKey].
  final int graceUsedInMonth;
  final String graceMonthKey;

  @override
  String toString() =>
      'StreakResult($current ngày, ân hạn $graceUsedInMonth/$graceMonthKey)';
}

/// Ngưỡng hoàn thành để một ngày được tính vào streak.
const kStreakThreshold = 0.8;

/// Số ngày ân hạn mỗi tháng — ADR-013.
const kGracePerMonth = 1;

/// Tính streak hiện tại của một trẻ.
///
/// [tallies] là tổng kết từng ngày, **sắp xếp giảm dần theo ngày** và bắt đầu
/// từ ngày gần nhất cần xét. Thường là hôm qua trở về trước: hôm nay chưa kết
/// thúc nên chưa phán xét được.
///
/// Quy tắc — ADR-013:
/// - Ngày không có việc đến hạn: bỏ qua, streak không đứt
/// - Đạt >= [kStreakThreshold]: streak + 1
/// - Không đạt: dùng ngày ân hạn của tháng đó nếu còn, hết thì dừng
///
/// Streak ở đây cố ý "dễ" hơn đối thủ. Mục tiêu là xây thói quen, không phải
/// trừng phạt đứa trẻ vì bị ốm hay đi chơi xa — xem `docs/00-brand-values.md`.
StreakResult calculateStreak(List<DayTally> tallies) {
  var streak = 0;
  final graceByMonth = <String, int>{};

  for (final tally in tallies) {
    if (tally.isNeutral) continue;

    if (tally.ratio >= kStreakThreshold) {
      streak++;
      continue;
    }

    final month = tally.date.monthKey;
    final used = graceByMonth[month] ?? 0;
    if (used < kGracePerMonth) {
      graceByMonth[month] = used + 1;
      streak++;
      continue;
    }

    break;
  }

  final currentMonth = tallies.isEmpty ? '' : tallies.first.date.monthKey;
  return StreakResult(
    current: streak,
    graceUsedInMonth: graceByMonth[currentMonth] ?? 0,
    graceMonthKey: currentMonth,
  );
}
