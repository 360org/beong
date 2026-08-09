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

  // Thêm cho nhiệm vụ ngoài việc nhà: app dùng cho cả học bài, đi chơi, thể dục
  // (đó là lý do tab được đổi tên thành "Nhiệm vụ").
  'books': '📚',
  'abacus': '🧮',
  'palette': '🎨',
  'soccer': '⚽',
  'bike': '🚲',
  'swim': '🏊',
  'park': '🏞️',
  'gift': '🎁',
  'phone_off': '🔇',
  'clock': '⏰',
  'star': '⭐',

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

/// Icon mặc định khi bố mẹ chưa chọn gì, và khi bù icon cho dữ liệu cũ.
///
/// ✏️ đọc ra "có việc cần làm" và đúng với hầu hết nhiệm vụ. Không dùng `star`:
/// ⭐ là dấu hiệu **thiếu** icon, không phải một lựa chọn.
const String kDefaultTaskIconKey = 'pencil';

String iconForKey(String? iconKey) => taskIcons[iconKey] ?? taskIconFallback;

/// Icon chọn được khi bố mẹ tự tạo nhiệm vụ.
///
/// Chỉ gồm khoá phù hợp với **việc cần làm** — cố ý bỏ nhóm khoá của phần thưởng
/// (`phone`, `money`, `ice_cream`…): chọn 🍦 cho một việc nhà thì thẻ việc trông
/// như một phần thưởng, và trẻ đọc icon nhanh hơn đọc chữ.
///
/// Không có emoji người: giới tính và màu da của một hình người luôn nói điều gì
/// đó về ai làm việc đó, mà đây là icon dùng chung cho mọi bé.
///
/// Cũng không có `star`: emoji của nó đúng bằng [taskIconFallback], nên một việc
/// chọn hình đó trông **giống hệt** một việc có khoá icon sai. Giữ ⭐ chỉ cho
/// đường rơi, để thấy ⭐ là biết có gì chưa đúng.
const List<String> kTaskIconKeys = [
  'tooth',
  'bed',
  'shirt',
  'food',
  'backpack',
  'pencil',
  'book',
  'books',
  'abacus',
  'music',
  'palette',
  'soccer',
  'bike',
  'park',
  'broom',
  'shower',
  'moon',
  'hanger',
  'dish',
  'table',
  'trash',
  'laundry',
  'plant',
  'paw',
  'toy',
  'heart',
  'phone_off',
  'clock',
];

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
