import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/repositories/goal_repository.dart';
import 'package:beong/domain/repositories/wallet_repository.dart';
import 'package:beong/domain/services/goal_service.dart';
import 'package:beong/features/goals/goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thẻ mục tiêu của một trẻ, tự cập nhật theo số dư hũ Để dành.
class GoalSection extends ConsumerWidget {
  const GoalSection({required this.memberId, this.onTap, super.key});

  final String memberId;

  /// Bấm vào thẻ để đặt hoặc sửa mục tiêu.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<SavingsGoal?>(
      stream: ref.watch(goalRepositoryProvider).watchActiveGoal(memberId),
      builder: (context, goalSnap) {
        final goal = goalSnap.data;
        if (goal == null) {
          if (onTap == null) return const SizedBox.shrink();
          return Card(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    const AppIcon('target', size: 32),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đặt mục tiêu tiết kiệm',
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Chọn phần thưởng hoặc điều ước con thích',
                            style: context.text.bodySmall?.copyWith(
                              color: context.semantic.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: context.colors.primary,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return StreamBuilder<WalletBalance>(
          stream: ref.watch(walletRepositoryProvider).watchBalance(memberId),
          builder: (context, balanceSnap) {
            final balance = balanceSnap.data ?? WalletBalance.zero;
            return StreamBuilder<List<JarDef>>(
              stream: ref
                  .watch(jarRepositoryProvider)
                  .watchActiveJars(goal.familyId, memberId: memberId),
              builder: (context, jarSnap) {
                // Chưa biết danh sách hũ thì coi như còn hũ Để dành
                final hasSaveJar =
                    jarSnap.data?.any((j) => j.key == kJarSave) ?? true;
                return GoalCard(
                  progress: GoalProgress(
                    goal: goal,
                    saved: GoalService.savedIn(
                      balance,
                      hasSaveJar: hasSaveJar,
                    ),
                  ),
                  onTap: onTap,
                );
              },
            );
          },
        );
      },
    );
  }
}
