import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/domain/services/goal_service.dart';
import 'package:flutter/material.dart';

/// Thẻ mục tiêu tiết kiệm kèm thanh tiến độ.
///
/// Nói bằng **số xu còn thiếu**, không chỉ bằng phần trăm: "còn 120 xu nữa" là
/// một con số trẻ con đối chiếu được với số xu mỗi việc, còn "76%" thì phải
/// tính mới ra ý nghĩa.
class GoalCard extends StatelessWidget {
  const GoalCard({required this.progress, this.onTap, super.key});

  final GoalProgress progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final goal = progress.goal;
    final reached = progress.reached;

    return Card(
      color: reached ? context.colors.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon(goal.iconKey ?? kDefaultGoalIconKey, size: 32),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: context.text.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          reached
                              ? 'Đủ xu rồi!'
                              : 'Còn ${progress.remaining} xu nữa',
                          style: context.text.bodySmall?.copyWith(
                            color: context.semantic.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chữ số bên cạnh thanh, không để mỗi thanh màu: thanh dài
                  // ngắn là tín hiệu nhìn, còn "80 / 200" là tín hiệu đọc được
                  // (WCAG 1.4.1) và cũng chính xác hơn.
                  Text(
                    '${progress.saved} / ${progress.target}',
                    style: context.text.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.pill),
                ),
                child: LinearProgressIndicator(
                  value: progress.ratio,
                  minHeight: 12,
                  backgroundColor: context.colors.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
