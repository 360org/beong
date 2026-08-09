import 'package:meta/meta.dart';

/// Khoá của ba hũ mặc định. Giữ nguyên chuỗi cũ để sổ cái đã ghi vẫn đọc được.
const String kJarSpend = 'spend';
const String kJarSave = 'save';
const String kJarGive = 'give';

/// Hũ chờ chia — **không phải hũ thật**.
///
/// Ở chế độ `manual`, xu kiếm được vào đây trước, rồi con tự chia sang các hũ.
/// Không nằm trong bảng `jars` và không tính vào tổng 100%: nó là nơi trung
/// chuyển, không phải một giá trị mà gia đình muốn dạy.
const String kJarInbox = 'inbox';

/// Xu vào hũ thế nào — ADR-024.
enum AllocationMode {
  /// Chia ngay theo tỷ lệ khi kiếm được (ADR-016). Mặc định.
  auto,

  /// Vào hũ chờ, con tự chia. Dạy con phân bổ giá trị, đổi lại con phải chủ
  /// động — hũ chờ đầy lên mà không ai chia thì xu nằm im.
  manual,
}

AllocationMode allocationModeFromDb(String? raw) => AllocationMode.values
    .firstWhere((m) => m.name == raw, orElse: () => AllocationMode.auto);

/// Định nghĩa một hũ, ở dạng thuần domain — không phụ thuộc drift.
@immutable
class JarDef {
  const JarDef({
    required this.key,
    required this.title,
    required this.emoji,
    required this.pct,
    this.orderIndex = 0,
  });

  /// Khoá bền, đi vào `point_transactions.jar`.
  final String key;
  final String title;
  final String emoji;

  /// Tỷ lệ chia mặc định, phần trăm.
  final int pct;
  final int orderIndex;

  JarDef copyWith({String? title, String? emoji, int? pct, int? orderIndex}) =>
      JarDef(
        key: key,
        title: title ?? this.title,
        emoji: emoji ?? this.emoji,
        pct: pct ?? this.pct,
        orderIndex: orderIndex ?? this.orderIndex,
      );

  @override
  bool operator ==(Object other) =>
      other is JarDef &&
      other.key == key &&
      other.title == title &&
      other.emoji == emoji &&
      other.pct == pct &&
      other.orderIndex == orderIndex;

  @override
  int get hashCode => Object.hash(key, title, emoji, pct, orderIndex);

  @override
  String toString() => 'JarDef($key "$title" $emoji $pct%)';
}

/// Ba hũ dựng sẵn cho gia đình mới — ADR-016 vẫn là mặc định tốt.
///
/// Thứ tự quan trọng ngoài chuyện hiển thị: khoản trừ xu lấy theo thứ tự này,
/// nên hũ "Cho đi" nằm cuối để được bảo vệ tới cùng (ADR-022).
const List<JarDef> kDefaultJars = [
  JarDef(key: kJarSpend, title: 'Tiêu', emoji: '🛍️', pct: 50),
  JarDef(key: kJarSave, title: 'Để dành', emoji: '🐷', pct: 40, orderIndex: 1),
  JarDef(key: kJarGive, title: 'Cho đi', emoji: '💝', pct: 10, orderIndex: 2),
];

/// Bộ emoji gợi ý khi bố mẹ lập hũ mới. Chọn mặt ngộ nghĩnh, dễ phân biệt ở cỡ
/// nhỏ, và tránh emoji người để không gợi giới tính hay màu da nào.
const List<String> kJarEmojis = [
  '🛍️',
  '🐷',
  '💝',
  '📚',
  '🎮',
  '⚽',
  '🎨',
  '🎁',
  '🍦',
  '🚲',
  '🎸',
  '🧸',
  '🌱',
  '🏦',
  '✈️',
  '🎪',
];

/// Kế hoạch chia xu của một gia đình: các hũ đang dùng và tỷ lệ của chúng.
@immutable
class JarPlan {
  const JarPlan(this.jars);

  /// Mặc định của gia đình mới.
  static const JarPlan defaultPlan = JarPlan(kDefaultJars);

  final List<JarDef> jars;

  int get totalPct => jars.fold(0, (sum, j) => sum + j.pct);

  bool get isValid =>
      jars.isNotEmpty &&
      totalPct == 100 &&
      jars.every((j) => j.pct >= 0) &&
      jars.map((j) => j.key).toSet().length == jars.length;

  /// Hũ theo thứ tự hiển thị, cũng là thứ tự bị trừ khi phạt (ADR-022).
  List<JarDef> get ordered =>
      [...jars]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  JarDef? byKey(String key) {
    for (final j in jars) {
      if (j.key == key) return j;
    }
    return null;
  }
}

/// Chia [amount] xu theo [plan].
///
/// Ràng buộc **bắt buộc**: tổng các phần luôn đúng bằng [amount]. Xu là thứ trẻ
/// đếm được; lệch một xu vì làm tròn là mất niềm tin.
///
/// Phần dư sau khi làm tròn xuống được dồn vào hũ **đầu tiên** theo thứ tự — hũ
/// dễ hiểu nhất với trẻ và không phải hũ bị ràng buộc.
///
/// Số âm cũng chia theo cùng tỷ lệ, để hoàn tác một giao dịch đưa các hũ về
/// đúng trạng thái trước đó.
Map<String, int> splitByPlan(int amount, JarPlan plan) {
  if (!plan.isValid) {
    throw ArgumentError.value(plan, 'plan', 'Tổng tỷ lệ các hũ phải bằng 100');
  }
  final ordered = plan.ordered;
  if (amount == 0) return {for (final j in ordered) j.key: 0};

  final result = <String, int>{};
  var assigned = 0;
  // Bỏ qua hũ đầu: nó nhận phần còn lại, nên phần dư luôn cùng dấu với amount.
  for (final jar in ordered.skip(1)) {
    final part = (amount * jar.pct) ~/ 100;
    result[jar.key] = part;
    assigned += part;
  }
  result[ordered.first.key] = amount - assigned;

  return result;
}
