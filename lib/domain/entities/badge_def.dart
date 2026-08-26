import 'package:meta/meta.dart';

/// Nhóm phân loại huy hiệu.
enum BadgeCategory {
  streak('Chuỗi kiên trì', 'fire'),
  tasksDone('Việc nhà chăm chỉ', 'clipboard'),
  routine('Thói quen vững vàng', 'sunrise'),
  rewards('Phần thưởng & Tiết kiệm', 'jar_gift');

  const BadgeCategory(this.titleVi, this.iconKey);
  final String titleVi;
  final String iconKey;
}

/// Một huy hiệu và điều kiện đạt được — `01-product-spec.md` §4.6 & docs/16 §12, §21.
@immutable
class BadgeDef {
  const BadgeDef({
    required this.key,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.kind,
    required this.category,
    required this.threshold,
  });

  /// Khoá bền, đi vào `badges_earned.badge_key`. Đổi khoá là mất huy hiệu đã
  /// trao — không đổi.
  final String key;

  final String title;

  /// Câu mô tả cho **trẻ** đọc: nói con cần làm gì.
  final String description;

  final String iconKey;
  final BadgeKind kind;
  final BadgeCategory category;

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

/// Danh sách huy hiệu theo nhóm (mỗi nhóm xếp theo bậc thang danh hiệu).
const List<BadgeDef> kBadges = [
  // 1. Chuỗi ngày
  BadgeDef(
    key: 'streak_3',
    title: 'Khởi đầu kiên trì',
    description: 'Làm hết việc 3 ngày liên tiếp — con giỏi lắm, tiếp tục nhé!',
    iconKey: 'fire',
    kind: BadgeKind.streak,
    category: BadgeCategory.streak,
    threshold: 3,
  ),
  BadgeDef(
    key: 'streak_7',
    title: 'Trọn một tuần',
    description: 'Làm hết việc 7 ngày liên tiếp — một tuần trọn vẹn, con thật tuyệt vời!',
    iconKey: 'star',
    kind: BadgeKind.streak,
    category: BadgeCategory.streak,
    threshold: 7,
  ),
  BadgeDef(
    key: 'streak_14',
    title: 'Hai tuần bền bỉ',
    description: 'Làm hết việc 14 ngày liên tiếp — nỗ lực không ngừng nghỉ!',
    iconKey: 'trophy',
    kind: BadgeKind.streak,
    category: BadgeCategory.streak,
    threshold: 14,
  ),
  BadgeDef(
    key: 'streak_30',
    title: 'Chiến binh bất bại',
    description: 'Làm hết việc 30 ngày liên tiếp — con là chiến binh thực thụ rồi đó!',
    iconKey: 'jar_bank',
    kind: BadgeKind.streak,
    category: BadgeCategory.streak,
    threshold: 30,
  ),

  // 2. Số lượng việc nhà
  BadgeDef(
    key: 'tasks_10',
    title: 'Bé con phụ việc',
    description: 'Hoàn thành 10 việc nhà — con đã bắt đầu giúp gia đình rồi!',
    iconKey: 'clipboard',
    kind: BadgeKind.tasksDone,
    category: BadgeCategory.tasksDone,
    threshold: 10,
  ),
  BadgeDef(
    key: 'tasks_25',
    title: 'Đôi tay chăm chỉ',
    description: 'Hoàn thành 25 việc nhà — chăm chỉ từng ngày!',
    iconKey: 'heart',
    kind: BadgeKind.tasksDone,
    category: BadgeCategory.tasksDone,
    threshold: 25,
  ),
  BadgeDef(
    key: 'tasks_50',
    title: 'Tay làm thoăn thoắt',
    description: 'Hoàn thành 50 việc nhà — bàn tay con nay thật khéo léo!',
    iconKey: 'books',
    kind: BadgeKind.tasksDone,
    category: BadgeCategory.tasksDone,
    threshold: 50,
  ),
  BadgeDef(
    key: 'tasks_100',
    title: 'Bậc thầy việc nhà',
    description: 'Hoàn thành 100 việc nhà — con là bậc thầy việc nhà của cả nhà!',
    iconKey: 'jar_circus',
    kind: BadgeKind.tasksDone,
    category: BadgeCategory.tasksDone,
    threshold: 100,
  ),

  // 3. Thói quen nề nếp
  BadgeDef(
    key: 'routine_3',
    title: 'Bước đệm nề nếp',
    description: 'Hoàn thành trọn bộ thói quen 3 ngày — con đang xây thói quen tốt đấy!',
    iconKey: 'sunrise',
    kind: BadgeKind.routinePerfectDays,
    category: BadgeCategory.routine,
    threshold: 3,
  ),
  BadgeDef(
    key: 'routine_7',
    title: 'Thói quen vững vàng',
    description: 'Hoàn thành trọn bộ thói quen 7 ngày — nề nếp của con thật đáng nể!',
    iconKey: 'sunrise',
    kind: BadgeKind.routinePerfectDays,
    category: BadgeCategory.routine,
    threshold: 7,
  ),
  BadgeDef(
    key: 'routine_14',
    title: 'Gia tài thói quen',
    description: 'Hoàn thành trọn bộ thói quen 14 ngày — nề nếp đã thành tự nhiên!',
    iconKey: 'gem',
    kind: BadgeKind.routinePerfectDays,
    category: BadgeCategory.routine,
    threshold: 14,
  ),
  BadgeDef(
    key: 'routine_21',
    title: 'Kỷ luật thép',
    description: 'Hoàn thành trọn bộ thói quen 21 ngày — con đã biến nó thành thói quen thật sự!',
    iconKey: 'party',
    kind: BadgeKind.routinePerfectDays,
    category: BadgeCategory.routine,
    threshold: 21,
  ),

  // 4. Phần thưởng & Tiết kiệm
  BadgeDef(
    key: 'first_reward',
    title: 'Trái ngọt đầu tiên',
    description: 'Đổi phần thưởng lần đầu tiên — con đã biết tiết kiệm và hưởng thành quả!',
    iconKey: 'jar_gift',
    kind: BadgeKind.redemptions,
    category: BadgeCategory.rewards,
    threshold: 1,
  ),
  BadgeDef(
    key: 'reward_3',
    title: 'Nhà tích luỹ tài ba',
    description: 'Đổi thành công 3 phần thưởng — con biết cách quản lý mục tiêu rồi!',
    iconKey: 'jar_bank',
    kind: BadgeKind.redemptions,
    category: BadgeCategory.rewards,
    threshold: 3,
  ),
  BadgeDef(
    key: 'reward_5',
    title: 'Nhà sưu tầm quà',
    description: 'Đổi thành công 5 phần thưởng — bộ sưu tập của con thật ấn tượng!',
    iconKey: 'gem',
    kind: BadgeKind.redemptions,
    category: BadgeCategory.rewards,
    threshold: 5,
  ),
  BadgeDef(
    key: 'reward_10',
    title: 'Chuyên gia đổi thưởng',
    description: 'Đổi thành công 10 phần thưởng — thành quả xứng đáng cho sự nỗ lực!',
    iconKey: 'trophy',
    kind: BadgeKind.redemptions,
    category: BadgeCategory.rewards,
    threshold: 10,
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
List<BadgeDef> earnedBadges(BadgeProgress progress) => [
  for (final badge in kBadges)
    if (progress.valueFor(badge.kind) >= badge.threshold) badge,
];
