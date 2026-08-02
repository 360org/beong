import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tỉ lệ tương phản theo WCAG 2.1.
double _contrast(Color a, Color b) {
  double luminance(Color c) => c.computeLuminance();
  final l1 = luminance(a);
  final l2 = luminance(b);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppTheme', () {
    test('theme sáng và tối đều gắn kèm AppSemanticColors', () {
      expect(
        AppTheme.light().extension<AppSemanticColors>(),
        AppSemanticColors.light,
      );
      expect(
        AppTheme.dark().extension<AppSemanticColors>(),
        AppSemanticColors.dark,
      );
    });

    test('brightness đúng với từng theme', () {
      expect(AppTheme.light().brightness, Brightness.light);
      expect(AppTheme.dark().brightness, Brightness.dark);
    });

    // ColorScheme.light() mặc định trả onSurface và outlineVariant là đen thuần.
    // Nếu ai đó bỏ hai dòng khai báo này khỏi theme (ví dụ vì lint báo "redundant"),
    // app sẽ âm thầm mất màu thương hiệu mà không có lỗi nào.
    test(
      'màu chữ và đường viền là màu thương hiệu, không phải đen mặc định',
      () {
        final light = AppTheme.light().colorScheme;
        expect(light.onSurface, AppColors.onSurfaceLight);
        expect(light.onSurface, isNot(const Color(0xFF000000)));
        expect(light.outlineVariant, AppColors.outlineLight);
        expect(light.outlineVariant, isNot(const Color(0xFF000000)));

        final dark = AppTheme.dark().colorScheme;
        expect(dark.onSurface, AppColors.onSurfaceDark);
        expect(dark.outlineVariant, AppColors.outlineDark);
      },
    );

    test('nút chính cao đúng 56 theo design system', () {
      final style = AppTheme.light().elevatedButtonTheme.style!;
      final size = style.minimumSize!.resolve({});
      expect(size!.height, 56);
    });
  });

  group('Khả dụng — docs/04-design-system.md §8', () {
    test('chữ chính đạt contrast >= 4.5:1 trên nền, cả sáng lẫn tối', () {
      expect(
        _contrast(AppColors.onSurfaceLight, AppColors.surfaceLight),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(AppColors.onSurfaceDark, AppColors.surfaceDark),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('chữ trên nút chính đạt contrast >= 4.5:1', () {
      expect(
        _contrast(AppColors.onPrimaryLight, AppColors.primaryLight),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('nhãn mờ đạt tối thiểu 3:1 (chỉ dùng cho chữ đậm >= 13px)', () {
      expect(
        _contrast(AppColors.onSurfaceMutedLight, AppColors.surfaceLight),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contrast(AppColors.onSurfaceMutedDark, AppColors.surfaceDark),
        greaterThanOrEqualTo(3),
      );
    });

    test('mọi màu hồ sơ trẻ đạt contrast >= 4.5:1 với chữ trắng', () {
      for (final color in AppColors.profilePalette) {
        expect(
          _contrast(Colors.white, color),
          greaterThanOrEqualTo(4.5),
          reason: 'Màu hồ sơ $color không đủ tương phản với chữ trắng',
        );
      }
    });

    test('profileColor lặp vòng khi chỉ số vượt quá bảng màu', () {
      expect(AppColors.profileColor(0), AppColors.profilePalette[0]);
      expect(AppColors.profileColor(8), AppColors.profilePalette[0]);
      expect(AppColors.profileColor(9), AppColors.profilePalette[1]);
    });
  });
}
