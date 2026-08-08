import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/bee_mascot.dart';
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

    // ---- Màu thương hiệu 360 Corp + Bé Ong ----
    //
    // Vai của từng màu suy ra từ ràng buộc tương phản, nên các test dưới đây là
    // hợp đồng của hệ màu, không phải sở thích: đổi màu mà không đổi vai sẽ làm
    // chữ không đọc được.

    test('giữ đúng mã màu thương hiệu, không bị chỉnh trôi', () {
      expect(AppColors.brand360Blue, const Color(0xFF0077CD));
      expect(AppColors.brand360Green, const Color(0xFF00CE2C));
      expect(AppColors.beOngHoney, const Color(0xFFFFC53D));
    });

    test('xanh dương 360 làm primary vì nó gánh được chữ trắng', () {
      expect(AppColors.primaryLight, AppColors.brand360Blue);
      expect(
        _contrast(AppColors.onPrimaryLight, AppColors.primaryLight),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('vàng mật và lá 360 KHÔNG gánh được chữ trắng — cơ sở của hệ màu', () {
      // Nếu ngày nào hai màu này bỗng đạt ngưỡng thì tức là mã màu đã bị đổi,
      // và toàn bộ lý do chia vai ở AppColors không còn đúng.
      expect(_contrast(Colors.white, AppColors.beOngHoney), lessThan(4.5));
      expect(_contrast(Colors.white, AppColors.brand360Green), lessThan(4.5));
    });

    test(
      'nút chính vàng mật + chữ đậm đạt ngưỡng, và hơn trắng-trên-primary',
      () {
        final honeyWithInk = _contrast(
          AppColors.onSurfaceLight,
          AppColors.xuLight,
        );
        expect(honeyWithInk, greaterThanOrEqualTo(4.5));
        expect(
          honeyWithInk,
          greaterThan(
            _contrast(AppColors.onPrimaryLight, AppColors.primaryLight),
          ),
        );
      },
    );

    test('chữ số xu đọc được trên nền badge xu pha mờ 15%', () {
      // Badge xu là `xu` pha alpha 0.15; viết số bằng chính `xu` thì mờ tịt.
      for (final (name, surface, semantic) in [
        ('sáng/trắng', AppColors.surfaceLight, AppSemanticColors.light),
        ('sáng/card', AppColors.surfaceVariantLight, AppSemanticColors.light),
        ('tối/card', AppColors.surfaceVariantDark, AppSemanticColors.dark),
      ]) {
        final pill = Color.alphaBlend(
          semantic.xu.withValues(alpha: 0.15),
          surface,
        );
        expect(
          _contrast(semantic.xuText, pill),
          greaterThanOrEqualTo(4.5),
          reason: 'chữ số xu trên nền badge ($name)',
        );
      }
    });

    test('mọi màu ngữ nghĩa nền sáng gánh được chữ trắng', () {
      // Các màu này đều được dùng làm nền nút hoặc chữ trên nền trắng.
      const light = AppSemanticColors.light;
      for (final (name, color) in [
        ('success', light.success),
        ('warning', light.warning),
        ('danger', light.danger),
      ]) {
        expect(
          _contrast(Colors.white, color),
          greaterThanOrEqualTo(4.5),
          reason: '$name nền sáng',
        );
      }
    });

    test('mọi màu ngữ nghĩa nền tối nổi trên nền tối', () {
      const dark = AppSemanticColors.dark;
      for (final (name, color) in [
        ('success', dark.success),
        ('warning', dark.warning),
        ('danger', dark.danger),
        ('xu', dark.xu),
      ]) {
        expect(
          _contrast(color, AppColors.surfaceDark),
          greaterThanOrEqualTo(4.5),
          reason: '$name nền tối',
        );
      }
    });

    test('cảnh báo tách rõ khỏi vàng xu để không lẫn hai ý nghĩa', () {
      // "Chờ duyệt" và "xu" cạnh nhau trên cùng màn hình bố mẹ.
      expect(
        _contrast(AppSemanticColors.light.warning, AppColors.xuLight),
        greaterThanOrEqualTo(3),
      );
    });

    test('mọi điểm dọc gradient dashboard gánh được chữ trắng', () {
      // Thẻ dashboard chạy dương 360 -> lá 360 và có chữ trắng đè lên; chỉ kiểm
      // hai đầu là không đủ, phải kiểm cả dọc đường.
      final colors = AppColors.dashboardGradient.colors;
      for (var i = 0; i <= 10; i++) {
        final stop = Color.lerp(colors.first, colors.last, i / 10)!;
        expect(
          _contrast(Colors.white, stop),
          greaterThanOrEqualTo(4.5),
          reason: 'gradient tại t=${i / 10}',
        );
      }
    });

    test('gradient dashboard dùng đúng hai màu công ty', () {
      expect(AppColors.dashboardGradient.colors.first, AppColors.brand360Blue);
      // Đầu xanh lá là bản đã hạ độ sáng của lá 360 để gánh được chữ trắng.
      expect(AppColors.dashboardGradient.colors.last, AppColors.successLight);
    });

    test('linh vật tách khỏi nền gradient nhờ viền sticker', () {
      // Thân vàng mật chỉ đạt ~2.94:1 với gradient xanh — dưới ngưỡng 3:1 của
      // WCAG 1.4.11 cho hình mang nghĩa. Viền kem là thứ tiếp giáp nền nên nó
      // phải đạt ngưỡng; nếu ai bỏ viền đi thì test này đỏ.
      for (final stop in AppColors.dashboardGradient.colors) {
        expect(
          _contrast(BeeMascot.outlineColor, stop),
          greaterThanOrEqualTo(3),
          reason: 'viền ong trên $stop',
        );
      }
    });

    // ---- Thanh điều hướng ----

    test('secondaryContainer phải được khai báo, không để Material suy ra', () {
      // Bỏ trống thì ColorScheme của Material 3 trả về màu teal, và nó lọt vào
      // viên nền icon đang chọn ở thanh nav — teal không thuộc bộ màu nào của
      // Bé Ong hay 360. Lỗi này từng có thật từ Sprint 0.
      final teal = const ColorScheme.light().secondaryContainer;
      expect(AppTheme.light().colorScheme.secondaryContainer, isNot(teal));
      expect(
        AppTheme.dark().colorScheme.secondaryContainer,
        isNot(const ColorScheme.dark().secondaryContainer),
      );
    });

    test('icon nav đang chọn đủ tương phản trên viên nền', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final scheme = theme.colorScheme;
        expect(
          _contrast(scheme.primary, scheme.primaryContainer),
          greaterThanOrEqualTo(3),
          reason: 'icon nav (${theme.brightness.name})',
        );
      }
    });

    test('nhãn nav 11px đạt ngưỡng chữ thường, không dùng ngưỡng nhãn mờ', () {
      // Nhãn nav nhỏ hơn 13px nên phải đạt 4.5:1, không được mượn ngưỡng 3:1
      // của onSurfaceMuted.
      expect(
        _contrast(AppColors.navLabelLight, AppColors.surfaceLight),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(AppColors.navLabelDark, AppColors.surfaceDark),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('nhãn nav đang chọn đủ tương phản trên nền thanh', () {
      expect(
        _contrast(AppColors.primaryLight, AppColors.surfaceLight),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(AppColors.primaryDark, AppColors.surfaceDark),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('icon nav to hơn mặc định Material vì nó phải tự mang nghĩa', () {
      // Với bé chưa đọc được nhãn, icon là nội dung duy nhất — 24dp mặc định
      // của Material quá nhỏ cho việc đó.
      expect(AppNavMetrics.iconSize, greaterThan(24));

      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final bar = theme.navigationBarTheme;
        expect(bar.height, AppNavMetrics.barHeight);
        for (final states in [
          <WidgetState>{},
          {WidgetState.selected},
        ]) {
          expect(
            bar.iconTheme?.resolve(states)?.size,
            AppNavMetrics.iconSize,
            reason: 'icon nav (${theme.brightness.name}, $states)',
          );
        }
        final rail = theme.navigationRailTheme;
        expect(rail.selectedIconTheme?.size, AppNavMetrics.iconSize);
        expect(rail.unselectedIconTheme?.size, AppNavMetrics.iconSize);
      }
    });

    test('thanh nav đủ cao để mỗi mục đạt vùng chạm tối thiểu', () {
      // Mỗi mục cao bằng cả thanh, nên chỉ cần thanh đạt ngưỡng.
      expect(
        AppNavMetrics.barHeight,
        greaterThanOrEqualTo(AppSpacing.minTouchTarget),
      );
    });

    test('profileColor lặp vòng khi chỉ số vượt quá bảng màu', () {
      expect(AppColors.profileColor(0), AppColors.profilePalette[0]);
      expect(AppColors.profileColor(8), AppColors.profilePalette[0]);
      expect(AppColors.profileColor(9), AppColors.profilePalette[1]);
    });
  });
}
