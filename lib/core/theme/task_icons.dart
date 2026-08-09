/// Khoá icon của task/routine/phần thưởng, và đường dẫn asset tương ứng.
///
/// Hình vẽ từ **asset PNG** trong `assets/icons/` (Fluent Emoji, MIT) qua
/// `AppIcon`, không phải emoji của hệ thống nữa — xem `assets/icons/README.md`.
/// Map [taskIcons] vẫn giữ emoji tương ứng vì nó còn dùng được ở chỗ chỉ nhận
/// chuỗi (nhãn accessibility, log, test đối chiếu), nhưng **UI thì dùng
/// `AppIcon`**.
///
/// Khoá khớp với `iconKey` trong `TaskPreset`/`RoutinePreset`
/// (`lib/data/seed/presets.dart`) và với **tên file** trong `assets/icons/`.
library;

/// Thư mục chứa asset icon.
const String kIconAssetDir = 'assets/icons';

/// Đường dẫn asset của một khoá icon.
///
/// Khoá lạ vẫn trả về đường dẫn (không có file), để `AppIcon` hiện dấu hỏi và in
/// cảnh báo — thà thấy một chỗ sai còn hơn im lặng vẽ ⭐ giống mọi việc khác.
String assetPathForIcon(String iconKey) => '$kIconAssetDir/$iconKey.png';

/// Emoji -> khoá asset, cho hai chỗ **đã lưu ký tự emoji vào DB**: `jars.emoji`
/// và `members.avatar_key`.
///
/// Đổi hai cột đó sang khoá sẽ cần một migration cho dữ liệu người dùng, mà giá
/// trị trong đó luôn đến từ hai danh sách cố định (`kJarEmojis`,
/// `kAvatarEmojis`) nên tra ngược là đủ và không rủi ro. Nếu về sau cần thêm
/// emoji ngoài hai danh sách đó thì lúc ấy mới phải migrate.
const Map<String, String> kEmojiIconKeys = {
  // Hũ — `kJarEmojis` trong `lib/domain/entities/jar_def.dart`.
  '🛍️': 'jar_spend',
  '🐷': 'jar_save',
  '💝': 'jar_give',
  '📚': 'books',
  '🎮': 'game',
  '⚽': 'soccer',
  '🎨': 'palette',
  '🎁': 'jar_gift',
  '🍦': 'ice_cream',
  '🚲': 'bike',
  '🎸': 'jar_guitar',
  '🧸': 'toy',
  '🌱': 'plant',
  '🏦': 'jar_bank',
  '✈️': 'jar_plane',
  '🎪': 'jar_circus',
  '📥': 'jar_inbox',

  // Avatar — `kAvatarEmojis` dưới đây.
  '🦁': 'av_lion',
  '🐱': 'av_cat',
  '🐶': 'av_dog',
  '🐰': 'av_rabbit',
  '🐼': 'av_panda',
  '🦊': 'av_fox',
  '🐨': 'av_koala',
  '🐯': 'av_tiger',
  '🐸': 'av_frog',
  '🦄': 'av_unicorn',
  '🐧': 'av_penguin',
  '🐵': 'av_monkey',
};

/// Khoá asset cho một emoji đã lưu trong DB.
///
/// Không tra được thì trả về [kDefaultTaskIconKey] chứ không trả chuỗi rỗng: ô
/// icon trống giữa một danh sách đọc ra như dữ liệu bị hỏng.
String iconKeyForEmoji(String? emoji) =>
    kEmojiIconKeys[emoji] ?? kDefaultTaskIconKey;

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
  'park': '🏞️',
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
