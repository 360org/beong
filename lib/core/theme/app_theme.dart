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
    navLabel: AppColors.navLabelLight,
    scheme: const ColorScheme.light(
      primary: AppColors.primaryLight,
      primaryContainer: AppColors.primaryContainerLight,
      onPrimaryContainer: AppColors.onSurfaceLight,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.onSecondaryLight,
      secondaryContainer: AppColors.secondaryContainerLight,
      onSecondaryContainer: AppColors.onSecondaryContainerLight,
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
    navLabel: AppColors.navLabelDark,
    scheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      primaryContainer: AppColors.primaryContainerDark,
      onPrimaryContainer: AppColors.onSurfaceDark,
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.onSecondaryDark,
      secondaryContainer: AppColors.secondaryContainerDark,
      onSecondaryContainer: AppColors.onSecondaryContainerDark,
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
    required Color navLabel,
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

      // Thanh điều hướng — hình học gọn, không dùng viên thuốc mặc định của
      // Material. Viên nền bo 14 (squircle) đọc "công nghệ" hơn pill tròn hẳn,
      // và icon đang chọn dùng dương 360 nên khớp bộ màu thương hiệu.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        height: 68,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.primary : navLabel,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.2,
            color: selected ? scheme.primary : navLabel,
          );
        }),
      ),

      // Rail trên desktop dùng cùng ngôn ngữ hình học với thanh dưới.
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        selectedIconTheme: IconThemeData(size: 24, color: scheme.primary),
        unselectedIconTheme: IconThemeData(size: 24, color: navLabel),
        selectedLabelTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: scheme.primary,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: navLabel,
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
