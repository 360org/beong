import 'package:meta/meta.dart';

/// Preset phần thưởng — chọn nhanh khi tạo reward, giống `TaskPreset`.
@immutable
class RewardPreset {
  const RewardPreset({
    required this.key,
    required this.titleVi,
    required this.titleEn,
    required this.iconKey,
    required this.rewardType,
    required this.defaultCost,
  });

  final String key;
  final String titleVi;
  final String titleEn;

  /// Emoji tra trong `taskIcons` (`core/theme/task_icons.dart`).
  final String iconKey;
  final String rewardType;
  final int defaultCost;
}

const kRewardPresets = <RewardPreset>[
  RewardPreset(
    key: 'screen_time',
    titleVi: 'Thời gian màn hình',
    titleEn: 'Screen time',
    iconKey: 'phone',
    rewardType: 'screenTime',
    defaultCost: 50,
  ),
  RewardPreset(
    key: 'pocket_money',
    titleVi: 'Tiền tiêu vặt',
    titleEn: 'Pocket money',
    iconKey: 'money',
    rewardType: 'pocketMoney',
    defaultCost: 100,
  ),
  RewardPreset(
    key: 'new_toy',
    titleVi: 'Đồ chơi mới',
    titleEn: 'New toy',
    iconKey: 'toy',
    rewardType: 'item',
    defaultCost: 150,
  ),
  RewardPreset(
    key: 'ice_cream',
    titleVi: 'Kem',
    titleEn: 'Ice cream',
    iconKey: 'ice_cream',
    rewardType: 'item',
    defaultCost: 30,
  ),
  RewardPreset(
    key: 'pizza_night',
    titleVi: 'Tối ăn pizza',
    titleEn: 'Pizza night',
    iconKey: 'pizza',
    rewardType: 'experience',
    defaultCost: 80,
  ),
  RewardPreset(
    key: 'movie_night',
    titleVi: 'Tối xem phim',
    titleEn: 'Movie night',
    iconKey: 'popcorn',
    rewardType: 'experience',
    defaultCost: 60,
  ),
  RewardPreset(
    key: 'play_game',
    titleVi: 'Chơi game',
    titleEn: 'Play a game',
    iconKey: 'game',
    rewardType: 'screenTime',
    defaultCost: 40,
  ),
  RewardPreset(
    key: 'buy_book',
    titleVi: 'Mua sách',
    titleEn: 'Buy a book',
    iconKey: 'book',
    rewardType: 'item',
    defaultCost: 70,
  ),
  RewardPreset(
    key: 'buy_clothes',
    titleVi: 'Mua quần áo',
    titleEn: 'Buy clothes',
    iconKey: 'shirt',
    rewardType: 'item',
    defaultCost: 200,
  ),
  RewardPreset(
    key: 'buy_game',
    titleVi: 'Mua game',
    titleEn: 'Buy a game',
    iconKey: 'console',
    rewardType: 'item',
    defaultCost: 300,
  ),
  RewardPreset(
    key: 'day_off_chores',
    titleVi: 'Nghỉ việc nhà 1 ngày',
    titleEn: 'Day off chores',
    iconKey: 'ticket',
    rewardType: 'experience',
    defaultCost: 100,
  ),
  RewardPreset(
    key: 'trip',
    titleVi: 'Đi chơi xa',
    titleEn: 'Trip',
    iconKey: 'suitcase',
    rewardType: 'experience',
    defaultCost: 500,
  ),
];

RewardPreset? rewardPresetByKey(String key) {
  for (final p in kRewardPresets) {
    if (p.key == key) return p;
  }
  return null;
}
