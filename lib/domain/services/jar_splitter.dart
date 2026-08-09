import 'package:beong/domain/entities/enums.dart';
import 'package:meta/meta.dart';

/// Tỷ lệ chia ba hũ — ADR-016.
///
/// Chia **ngay khi kiếm được**, không phải chia phần còn lại sau khi tiêu.
/// Chia sau thì hũ Để dành luôn rỗng — đó là lý do người lớn cũng không tiết
/// kiệm được, và là cả bài học mà app này muốn dạy.
@immutable
class JarSplit {
  const JarSplit({
    required this.spend,
    required this.save,
    required this.give,
  });

  factory JarSplit.fromJson(Map<String, dynamic> json) => JarSplit(
    spend: (json['spend'] as num?)?.toInt() ?? 100,
    save: (json['save'] as num?)?.toInt() ?? 0,
    give: (json['give'] as num?)?.toInt() ?? 0,
  );

  /// Mặc định của gia đình: 50 tiêu / 40 để dành / 10 cho đi.
  static const defaultSplit = JarSplit(spend: 50, save: 40, give: 10);

  /// Toàn bộ vào hũ Tiêu — dùng khi gia đình tắt tính năng ba hũ.
  static const spendOnly = JarSplit(spend: 100, save: 0, give: 0);

  final int spend;
  final int save;
  final int give;

  int get total => spend + save + give;

  bool get isValid => total == 100 && spend >= 0 && save >= 0 && give >= 0;

  int percentOf(Jar jar) => switch (jar) {
    Jar.spend => spend,
    Jar.save => save,
    Jar.give => give,
    // Hũ chờ không có tỷ lệ: nó là nơi trung chuyển, không phải một phần của
    // kế hoạch chia (ADR-024).
    Jar.inbox => 0,
  };

  Map<String, int> toJson() => {'spend': spend, 'save': save, 'give': give};

  @override
  bool operator ==(Object other) =>
      other is JarSplit &&
      other.spend == spend &&
      other.save == save &&
      other.give == give;

  @override
  int get hashCode => Object.hash(spend, save, give);

  @override
  String toString() => 'JarSplit($spend/$save/$give)';
}

/// Chia [amount] xu vào ba hũ theo [split].
///
/// Ràng buộc **bắt buộc**: tổng ba phần luôn đúng bằng [amount]. Xu là thứ trẻ
/// đếm được; lệch một xu vì làm tròn là mất niềm tin, và mất niềm tin thì giá
/// trị "minh bạch" chỉ còn là khẩu hiệu.
///
/// Phần dư sau khi làm tròn xuống được dồn vào hũ **Tiêu** — hũ dễ hiểu nhất
/// với trẻ và không phải hũ bị ràng buộc.
///
/// Số âm (hoàn xu, trừ xu) cũng chia theo cùng tỷ lệ, để hoàn tác một giao dịch
/// đưa các hũ về đúng trạng thái trước đó.
Map<Jar, int> splitAmount(int amount, JarSplit split) {
  if (!split.isValid) {
    throw ArgumentError.value(split, 'split', 'Tổng ba hũ phải bằng 100');
  }
  if (amount == 0) return const {Jar.spend: 0, Jar.save: 0, Jar.give: 0};

  // Làm tròn về 0 để phần dư luôn cùng dấu với amount.
  final save = (amount * split.save) ~/ 100;
  final give = (amount * split.give) ~/ 100;
  final spend = amount - save - give;

  return {Jar.spend: spend, Jar.save: save, Jar.give: give};
}
