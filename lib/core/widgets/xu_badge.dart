import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Badge xu hình viên kim cương 💎 — đơn vị điểm gọi là "xu" (ADR-015).
///
/// Dùng emoji thay icon vẽ tay: trẻ nhận ra ngay không cần học ký hiệu mới,
/// và rẻ hơn nhúng font/asset riêng.
class XuBadge extends StatelessWidget {
  const XuBadge({
    required this.amount,
    super.key,
    this.large = false,
    this.pill = false,
    this.color,
  });

  final int amount;
  final bool large;

  /// Bọc trong nền pill màu hổ phách nhạt — dùng khi badge đứng độc lập
  /// (danh sách reward). Khi nằm cạnh chữ khác (dashboard) thì để `false`.
  final bool pill;

  /// Ép màu chữ — dùng trên nền gradient tối (thẻ dashboard) nơi màu ngữ
  /// nghĩa mặc định không đủ tương phản.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fontSize = large ? 22.0 : 15.0;
    final emojiSize = large ? 22.0 : 16.0;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('💎', style: TextStyle(fontSize: emojiSize)),
        const SizedBox(width: 5),
        Text(
          '$amount',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color:
                color ??
                (pill ? context.semantic.xuText : context.colors.onSurface),
          ),
        ),
      ],
    );

    if (!pill) return content;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.semantic.xu.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: content,
    );
  }
}
