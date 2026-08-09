import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/kid_scale.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.title,
    required this.points,
    required this.isCompleted,
    required this.onToggle,
    super.key,
    this.iconKey,
    this.colorIndex = 0,
    this.isPending = false,
    this.isMissed = false,
  });

  final String title;
  final int points;
  final bool isCompleted;
  final bool isPending;
  final bool isMissed;
  final int colorIndex;

  /// Khoá emoji trong `task_icons.dart`. NULL → icon mặc định ⭐.
  final String? iconKey;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scale = KidScaleScope.of(context);
    final profileColor = AppColors.profileColor(colorIndex);
    final isDone = isCompleted || isPending;
    final avatarSize = scale.tapTarget - AppSpacing.lg;

    return Card(
      child: InkWell(
        onTap: isDone || isMissed ? null : onToggle,
        borderRadius: BorderRadius.circular(scale.cardRadius),
        child: ConstrainedBox(
          // Vùng chạm rộng theo tuổi — ngón tay trẻ nhỏ kém chính xác.
          constraints: BoxConstraints(minHeight: scale.tapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                _EmojiAvatar(
                  emoji: iconForKey(iconKey),
                  faded: isDone,
                  boxSize: avatarSize,
                  emojiSize: scale.taskEmojiSize,
                  radius: scale.cardRadius * 0.7,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: context.text.bodyLarge?.copyWith(
                      fontSize:
                          (context.text.bodyLarge?.fontSize ?? 16) *
                          scale.textScale,
                      fontWeight: FontWeight.w700,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? context.semantic.onSurfaceMuted
                          : context.colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                XuBadge(amount: points, pill: true),
                const SizedBox(width: AppSpacing.sm),
                _Checkbox(
                  checked: isDone,
                  missed: isMissed,
                  color: profileColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiAvatar extends StatelessWidget {
  const _EmojiAvatar({
    required this.emoji,
    required this.faded,
    required this.boxSize,
    required this.emojiSize,
    required this.radius,
  });

  final String emoji;
  final bool faded;
  final double boxSize;
  final double emojiSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.5 : 1,
      child: Container(
        width: boxSize,
        height: boxSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.primaryContainer,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({
    required this.checked,
    required this.missed,
    required this.color,
  });

  final bool checked;
  final bool missed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (missed) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.semantic.danger, width: 2),
        ),
        child: Icon(Icons.close, size: 18, color: context.semantic.danger),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? color : Colors.transparent,
        border: Border.all(
          color: checked ? color : context.semantic.onSurfaceMuted,
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : null,
    );
  }
}
