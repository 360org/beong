import 'package:meta/meta.dart';

/// Một huy hiệu và điều kiện đạt được — `01-product-spec.md` §4.6.
@immutable
class BadgeDef {
  const BadgeDef({
    required this.key,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.kind,
    required this.threshold,
  });

  /// Khoá bền, đi vào `badges_earned.badge_key`. Đổi khoá là mất huy hiệu đã
  /// trao — không đổi.
  final String key;

  final String title;

  /// Câu mô tả cho **trẻ** đọc, không phải cho lập trình viên: nói con cần làm gì
  /// chứ không tả công thức.
  final String description;

  final String iconKey;
  final BadgeKind kind;

  /// Mốc cần đạt của [kind].
  final int threshold;
}

/// Loại điều kiện. Mỗi loại đọc một con số khác nhau ở tầng dữ liệu.
enum BadgeKind {
  /// Số ngày liên tiếp làm hết việc.
  streak,

  /// Tổng số việc đã hoàn thành từ trước tới nay.
  tasksDone,

  /// Số ngày làm **trọn bộ** một routine.
  routinePerfectDays,

  /// Số lần đã đổi thưởng.
  redemptions,
}

/// 8 huy hiệu MVP, đúng danh sách ở `01-product-spec.md` §4.6.
///
/// Mốc chọn thưa dần (3 → 7 → 30, 10 → 50 → 100): huy hiệu quá dày thì mất giá
/// trị, quá thưa thì trẻ nhỏ không bao giờ chạm tới cái đầu tiên.
const List<BadgeDef> kBadges = [
  BadgeDef(
    key: 'streak_3',
    title: 'Ba ngày liền',
    description: 'Làm hết việc 3 ngày liên tiếp',
    iconKey: 'fire',
    kind: BadgeKind.streak,
    threshold: 3,
  ),
  BadgeDef(
    key: 'streak_7',
    title: 'Trọn một tuần',
    description: 'Làm hết việc 7 ngày liên tiếp',
    iconKey: 'star',
    kind: BadgeKind.streak,
    threshold: 7,
  ),
  BadgeDef(
    key: 'streak_30',
    title: 'Cả tháng chăm chỉ',
    description: 'Làm hết việc 30 ngày liên tiếp',
    iconKey: 'jar_bank',
    kind: BadgeKind.streak,
    threshold: 30,
  ),
  BadgeDef(
    key: 'tasks_10',
    title: 'Mười việc đầu tiên',
    description: 'Hoàn thành 10 việc',
    iconKey: 'clipboard',
    kind: BadgeKind.tasksDone,
    threshold: 10,
  ),
  BadgeDef(
    key: 'tasks_50',
    title: 'Năm mươi việc',
    description: 'Hoàn thành 50 việc',
    iconKey: 'books',
    kind: BadgeKind.tasksDone,
    threshold: 50,
  ),
  BadgeDef(
    key: 'tasks_100',
    title: 'Một trăm việc',
    description: 'Hoàn thành 100 việc',
    iconKey: 'jar_circus',
    kind: BadgeKind.tasksDone,
    threshold: 100,
  ),
  BadgeDef(
    key: 'routine_7',
    title: 'Thói quen vững',
    description: 'Làm trọn bộ một thói quen 7 ngày',
    iconKey: 'sunrise',
    kind: BadgeKind.routinePerfectDays,
    threshold: 7,
  ),
  BadgeDef(
    key: 'first_reward',
    title: 'Phần thưởng đầu tiên',
    description: 'Đổi phần thưởng lần đầu',
    iconKey: 'jar_gift',
    kind: BadgeKind.redemptions,
    threshold: 1,
  ),
];

/// Số liệu của một trẻ, đủ để xét mọi huy hiệu.
@immutable
class BadgeProgress {
  const BadgeProgress({
    required this.streakDays,
    required this.tasksDone,
    required this.routinePerfectDays,
    required this.redemptions,
  });

  final int streakDays;
  final int tasksDone;
  final int routinePerfectDays;
  final int redemptions;

  int valueFor(BadgeKind kind) => switch (kind) {
    BadgeKind.streak => streakDays,
    BadgeKind.tasksDone => tasksDone,
    BadgeKind.routinePerfectDays => routinePerfectDays,
    BadgeKind.redemptions => redemptions,
  };
}

/// Huy hiệu đã đạt theo [progress].
///
/// Thuần hàm, không đụng DB: nhờ vậy quy tắc trao huy hiệu test được mà không
/// cần dựng cả cơ sở dữ liệu, và chỗ ghi vào DB chỉ còn việc lưu.
List<BadgeDef> earnedBadges(BadgeProgress progress) => [
  for (final badge in kBadges)
    if (progress.valueFor(badge.kind) >= badge.threshold) badge,
];
