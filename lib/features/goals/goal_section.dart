import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/services/goal_service.dart';
import 'package:beong/features/goals/goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thẻ mục tiêu của một trẻ, tự cập nhật theo số dư hũ Để dành.
///
/// Chưa đặt mục tiêu thì **không hiện gì** (trả [SizedBox.shrink]) chứ không
/// hiện ô trống mời gọi: màn hình chính của con nên là danh sách việc, không
/// phải một quảng cáo cho tính năng bố mẹ chưa bật.
class GoalSection extends ConsumerWidget {
  const GoalSection({required this.memberId, this.onTap, super.key});

  final String memberId;

  /// Bấm vào thẻ. Để `null` ở màn của con — con không sửa mục tiêu của mình.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<SavingsGoal?>(
      stream: ref.watch(goalDaoProvider).watchActiveGoal(memberId),
      builder: (context, goalSnap) {
        final goal = goalSnap.data;
        if (goal == null) return const SizedBox.shrink();

        return StreamBuilder<WalletBalance>(
          stream: ref.watch(walletDaoProvider).watchBalance(memberId),
          builder: (context, balanceSnap) {
            final balance = balanceSnap.data ?? WalletBalance.zero;
            return StreamBuilder<List<JarDef>>(
              stream: ref.watch(jarDaoProvider).watchActiveJars(goal.familyId),
              builder: (context, jarSnap) {
                // Chưa biết danh sách hũ thì coi như còn hũ Để dành: đoán
                // ngược lại sẽ hiện tổng xu trong một nhịp rồi tụt xuống, thanh
                // tiến độ giật lùi ngay trước mắt con.
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
