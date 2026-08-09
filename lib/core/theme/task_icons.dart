/// Icon emoji cho task/routine — thân thiện với trẻ em hơn Material icon.
///
/// Khoá khớp với `iconKey` trong `TaskPreset`/`RoutinePreset`
/// (`lib/data/seed/presets.dart`). Thêm preset mới thì thêm khoá ở đây,
/// thiếu khoá sẽ rơi về [taskIconFallback].
library;

const Map<String, String> taskIcons = {
  'tooth': '🪥',
  'bed': '🛏️',
  'shirt': '👕',
  'food': '🥣',
  'backpack': '🎒',
  'pencil': '✏️',
  'book': '📖',
  'music': '🎵',
  'broom': '🧹',
  'shower': '🚿',
  'moon': '🌙',
  'hanger': '🧥',
  'dish': '🍽️',
  'table': '🪑',
  'trash': '🗑️',
  'laundry': '🧺',
  'plant': '🌱',
  'paw': '🐾',
  'toy': '🧸',
  'run': '🏃',
  'heart': '❤️',
  'eye_off': '📵',
  'sunrise': '🌅',
  'wb_cloudy': '☁️',

  // Phần thưởng — `lib/data/seed/reward_presets.dart`.
  'phone': '📱',
  'money': '💰',
  'ice_cream': '🍦',
  'pizza': '🍕',
  'popcorn': '🍿',
  'game': '🎮',
  'console': '🕹️',
  'ticket': '🎫',
  'suitcase': '🧳',
};

const String taskIconFallback = '⭐';

String iconForKey(String? iconKey) => taskIcons[iconKey] ?? taskIconFallback;

/// Avatar mặt con vật — chọn lúc thêm bé, lưu vào `members.avatarKey`.
const List<String> kAvatarEmojis = [
  '🦁',
  '🐱',
  '🐶',
  '🐰',
  '🐼',
  '🦊',
  '🐨',
  '🐯',
  '🐸',
  '🦄',
  '🐧',
  '🐵',
];

String avatarForKey(String? avatarKey) =>
    avatarKey != null && kAvatarEmojis.contains(avatarKey)
    ? avatarKey
    : kAvatarEmojis.first;
