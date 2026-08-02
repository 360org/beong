import 'package:flutter/material.dart';

/// Bảng màu của Bé Ong.
///
/// Token lấy từ `docs/04-design-system.md` §1. Không hard-code màu ở nơi khác —
/// mọi widget đọc màu qua [Theme.of] hoặc [AppColors].
abstract final class AppColors {
  // ---- Light ----
  static const primaryLight = Color(0xFF6B4EFF);
  static const onPrimaryLight = Color(0xFFFFFFFF);
  static const primaryContainerLight = Color(0xFFEFEBFF);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceVariantLight = Color(0xFFF6F5FC);
  static const onSurfaceLight = Color(0xFF1B1046);
  static const onSurfaceMutedLight = Color(0xFF8E8AA8);
  static const outlineLight = Color(0xFFE4E1F2);

  // ---- Dark ----
  static const primaryDark = Color(0xFF8B72FF);
  static const onPrimaryDark = Color(0xFF12082E);
  static const primaryContainerDark = Color(0xFF2A1E5C);
  static const surfaceDark = Color(0xFF14102A);
  static const surfaceVariantDark = Color(0xFF1E1940);
  static const onSurfaceDark = Color(0xFFF2F0FF);
  static const onSurfaceMutedDark = Color(0xFFA7A2C4);
  static const outlineDark = Color(0xFF332C5E);

  // ---- Ngữ nghĩa ----
  static const successLight = Color(0xFF22C55E);
  static const successDark = Color(0xFF4ADE80);
  static const warningLight = Color(0xFFF59E0B);
  static const warningDark = Color(0xFFFBBF24);
  static const dangerLight = Color(0xFFEF4444);
  static const dangerDark = Color(0xFFF87171);
  static const gemLight = Color(0xFFFFC53D);
  static const gemDark = Color(0xFFFFD166);

  /// Màu hồ sơ trẻ — dùng làm nền avatar, viền card, cột biểu đồ.
  ///
  /// Mỗi màu đạt contrast >= 4.8:1 với chữ trắng (ngưỡng WCAG AA là 4.5, chừa
  /// biên an toàn). Giá trị được tính bằng cách giữ nguyên hue/saturation của
  /// bảng màu thiết kế rồi hạ độ sáng đến khi đạt ngưỡng — `app_theme_test.dart`
  /// kiểm tra lại ràng buộc này, đừng sửa tay mà không chạy test.
  ///
  /// Thứ tự cố định — `members.color` lưu chỉ số, đổi thứ tự sẽ đổi màu của
  /// những trẻ đã tạo trước đó.
  static const profilePalette = <Color>[
    Color(0xFF6B4EFF), // tím
    Color(0xFFE3004D), // hồng
    Color(0xFF17833F), // lục
    Color(0xFF9E6606), // cam
    Color(0xFF047D92), // lam
    Color(0xFF9B3CF6), // mận
    Color(0xFFE31313), // đỏ
    Color(0xFF0E8074), // ngọc
  ];

  static Color profileColor(int index) =>
      profilePalette[index % profilePalette.length];
}

/// Màu không nằm trong [ColorScheme] của Material nhưng dùng xuyên suốt app.
///
/// Truy cập qua `Theme.of(context).extension<AppSemanticColors>()!`, hoặc tiện hơn
/// là `context.semanticColors` trong `core/theme/theme_extensions.dart`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.gem,
    required this.onSurfaceMuted,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color gem;
  final Color onSurfaceMuted;

  static const light = AppSemanticColors(
    success: AppColors.successLight,
    warning: AppColors.warningLight,
    danger: AppColors.dangerLight,
    gem: AppColors.gemLight,
    onSurfaceMuted: AppColors.onSurfaceMutedLight,
  );

  static const dark = AppSemanticColors(
    success: AppColors.successDark,
    warning: AppColors.warningDark,
    danger: AppColors.dangerDark,
    gem: AppColors.gemDark,
    onSurfaceMuted: AppColors.onSurfaceMutedDark,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? gem,
    Color? onSurfaceMuted,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      gem: gem ?? this.gem,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      gem: Color.lerp(gem, other.gem, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
    );
  }
}
