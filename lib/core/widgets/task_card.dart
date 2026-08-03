import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.title,
    required this.points,
    required this.isCompleted,
    required this.onToggle,
    super.key,
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
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final profileColor = AppColors.profileColor(colorIndex);
    final isDone = isCompleted || isPending;

    return Card(
      child: InkWell(
        onTap: isDone || isMissed ? null : onToggle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              _Checkbox(
                checked: isDone,
                missed: isMissed,
                color: profileColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: context.text.bodyLarge?.copyWith(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone
                        ? context.semantic.onSurfaceMuted
                        : context.colors.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: context.semantic.xu.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '+$points',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.semantic.xu,
                  ),
                ),
              ),
            ],
          ),
        ),
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
