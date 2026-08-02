import 'package:dailychildren/core/l10n/gen/app_localizations.dart';
import 'package:dailychildren/core/theme/app_spacing.dart';
import 'package:dailychildren/core/theme/app_theme.dart';
import 'package:dailychildren/core/widgets/responsive_scaffold.dart';
import 'package:flutter/material.dart';

/// Khung màn hình tạm cho Sprint 0.
///
/// Mỗi feature sẽ thay bằng màn hình thật ở sprint tương ứng; giữ nguyên
/// chữ ký `title` để router không phải đổi.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, required this.icon, super.key});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        ScreenPadding(child: Text(title, style: context.text.titleLarge)),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: context.semantic.onSurfaceMuted),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.comingSoon,
                  style: context.text.bodyLarge?.copyWith(
                    color: context.semantic.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
