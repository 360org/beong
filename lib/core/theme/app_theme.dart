import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Dựng [ThemeData] sáng/tối từ design token.
///
/// Mọi tinh chỉnh giao diện phải nằm ở đây hoặc trong token, không rải
/// `Container(color: ...)` khắp widget.
abstract final class AppTheme {
  static ThemeData light() => _build(
    // `surface` và `onPrimary` trùng mặc định của ColorScheme.light nên bỏ qua.
    // Các trường còn lại phải khai báo — mặc định của Material cho onSurface và
    // outlineVariant là đen thuần, không phải màu thương hiệu.
    ctaBackground: AppColors.xuLight,
    ctaForeground: AppColors.onSurfaceLight,
    scheme: const ColorScheme.light(
      primary: AppColors.primaryLight,
      primaryContainer: AppColors.primaryContainerLight,
      onPrimaryContainer: AppColors.onSurfaceLight,
      onSurface: AppColors.onSurfaceLight,
      surfaceContainerHighest: AppColors.surfaceVariantLight,
      outlineVariant: AppColors.outlineLight,
      error: AppColors.dangerLight,
    ),
    semantic: AppSemanticColors.light,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    ctaBackground: AppColors.xuDark,
    ctaForeground: AppColors.onPrimaryDark,
    scheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      primaryContainer: AppColors.primaryContainerDark,
      onPrimaryContainer: AppColors.onSurfaceDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      surfaceContainerHighest: AppColors.surfaceVariantDark,
      outlineVariant: AppColors.outlineDark,
      error: AppColors.dangerDark,
    ),
    semantic: AppSemanticColors.dark,
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required AppSemanticColors semantic,
    required Color ctaBackground,
    required Color ctaForeground,
    Brightness brightness = Brightness.light,
  }) {
    final textTheme = AppTypography.textTheme(scheme.onSurface);

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      // Đặt cả ở đây để `TextStyle(...)` viết tay trong widget (không dựa vào
      // textTheme) vẫn thừa hưởng Nunito qua DefaultTextStyle.
      fontFamily: AppTypography.fontFamily,
      extensions: [semantic],

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleL.copyWith(color: scheme.onSurface),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),

      // Nút chính: full-width, cao 56, bo tròn — §4 design system.
      //
      // Nền vàng mật + chữ đậm, **không** dùng trắng-trên-primary: nút là khối
      // màu lớn nhất màn hình nên để vàng ở đây thì màu Bé Ong mới thật sự chủ
      // đạo, và cặp này đạt 11.00:1 so với 4.65:1 của trắng-trên-dương.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ctaBackground,
          foregroundColor: ctaForeground,
          minimumSize: const Size.fromHeight(AppSpacing.giant),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
          ),
          textStyle: AppTypography.body.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHighest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        border: _fieldBorder(scheme.outlineVariant),
        enabledBorder: _fieldBorder(scheme.outlineVariant),
        focusedBorder: _fieldBorder(scheme.primary, width: 2),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: semantic.onSurfaceMuted,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Chỉ một mức đổ bóng trong toàn app — §3.
      shadowColor: const Color(0x141B1046),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.field)),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Truy cập nhanh màu ngữ nghĩa: `context.semantic.xu`.
extension AppThemeContext on BuildContext {
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get text => Theme.of(this).textTheme;

  /// Một gradient cho cả hai chế độ — xem [AppColors.dashboardGradient].
  Gradient get dashboardGradient => AppColors.dashboardGradient;
}
