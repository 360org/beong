import 'package:beong/core/theme/task_icons.dart';
import 'package:flutter/material.dart';

/// Icon của app, vẽ từ asset PNG trong `assets/icons/` — Fluent Emoji, MIT.
///
/// Thay cho `Text('🪥')`. Emoji hệ thống mỗi nền tảng vẽ một kiểu, và máy không
/// có glyph thì hiện ô vuông ▯ — không kiểm soát được thứ trẻ nhìn thấy, trong khi
/// đây là app mà trẻ đọc hình trước khi đọc chữ. Asset thì mọi máy giống nhau, và
/// ảnh chụp store đúng bằng cái người dùng thấy.
///
/// Xem `assets/icons/README.md` để biết cách thêm icon và vì sao chọn bộ này.
class AppIcon extends StatelessWidget {
  const AppIcon(this.iconKey, {this.size = 24, super.key});

  /// Icon của một nhiệm vụ / phần thưởng — tra theo `tasks.icon_key`.
  const AppIcon.task(String? iconKey, {double size = 24, Key? key})
    : this(iconKey ?? kDefaultTaskIconKey, size: size, key: key);

  /// Khoá icon. Cũng là **tên file** trong `assets/icons/`.
  final String iconKey;

  /// Cạnh của ô vuông chứa icon, tính bằng logical pixel.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPathForIcon(iconKey),
      width: size,
      height: size,
      // Icon là hình trang trí đi kèm chữ ở ngay bên cạnh trong mọi chỗ dùng.
      // Đặt nhãn ở đây sẽ làm trình đọc màn hình đọc hai lần cùng một thứ.
      excludeFromSemantics: true,
      errorBuilder: (context, error, stack) {
        // Khoá không có file: hiện dấu hỏi có viền thay vì ô vuông vô hình.
        // Thiếu asset là lỗi lập trình, phải **thấy được** khi chạy app, nhưng
        // không được làm sập màn hình của trẻ.
        debugPrint('Thiếu asset icon: $iconKey (${assetPathForIcon(iconKey)})');
        return Icon(
          Icons.help_outline_rounded,
          size: size,
          color: Theme.of(context).colorScheme.outline,
        );
      },
    );
  }
}
