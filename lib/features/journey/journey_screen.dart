import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/repositories/goal_repository.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/reward_repository.dart';
import 'package:beong/domain/repositories/wallet_repository.dart';
import 'package:beong/domain/services/goal_service.dart';
import 'package:beong/features/goals/goal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Màn hình Hành trình — Trực quan hoá đường tới đích tiết kiệm của con (§13).
///
/// Bản đồ tiến độ với các cột mốc (milestones) dọc đường và vị trí hiện tại của bé.
class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final memberId = session.activeMemberId;
    final familyId = session.familyId;

    final goalDao = ref.watch(goalRepositoryProvider);
    final walletDao = ref.watch(walletRepositoryProvider);
    final memberDao = ref.watch(memberRepositoryProvider);
    final jarDao = ref.watch(jarRepositoryProvider);
    final rewardDao = ref.watch(rewardRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hành trình của con'),
      ),
      body: StreamBuilder<SavingsGoal?>(
        stream: goalDao.watchActiveGoal(memberId),
        builder: (context, goalSnap) {
          final goal = goalSnap.data;

          return StreamBuilder<Member>(
            stream: memberDao.watchMember(memberId),
            builder: (context, memberSnap) {
              final member = memberSnap.data;
              final childName = member?.displayName ?? 'Con';

              if (goal == null) {
                return _NoGoalJourneyView(
                  childName: childName,
                  familyId: familyId,
                  memberId: memberId,
                );
              }

              return StreamBuilder<WalletBalance>(
                stream: walletDao.watchBalance(memberId),
                builder: (context, balanceSnap) {
                  final balance = balanceSnap.data ?? WalletBalance.zero;

                  return StreamBuilder<List<JarDef>>(
                    stream: jarDao.watchActiveJars(familyId),
                    builder: (context, jarSnap) {
                      final hasSaveJar =
                          jarSnap.data?.any((j) => j.key == kJarSave) ?? true;
                      final saved = GoalService.savedIn(
                        balance,
                        hasSaveJar: hasSaveJar,
                      );
                      final target = goal.targetXu;
                      final progress = (saved / (target > 0 ? target : 1))
                          .clamp(0.0, 1.0);

                      return StreamBuilder<List<Reward>>(
                        stream: rewardDao.watchRewards(familyId),
                        builder: (context, rewardSnap) {
                          final rewards = rewardSnap.data ?? const <Reward>[];

                          return ListView(
                            padding: const EdgeInsets.all(
                              AppSpacing.screenPaddingMobile,
                            ),
                            children: [
                              // Thẻ mục tiêu hiện tại
                              _CurrentGoalCard(
                                goal: goal,
                                saved: saved,
                                target: target,
                                progress: progress,
                                onEdit: () => showGoalSheet(
                                  context,
                                  familyId: familyId,
                                  memberId: memberId,
                                  childName: childName,
                                  current: goal,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxl),

                              // Bản đồ hành trình từng mốc
                              Text(
                                'BẢN ĐỒ TIẾN ĐỘ',
                                style: context.text.labelMedium?.copyWith(
                                  color: context.semantic.onSurfaceMuted,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _JourneyMap(
                                goal: goal,
                                saved: saved,
                                target: target,
                                rewards: rewards,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NoGoalJourneyView extends StatelessWidget {
  const _NoGoalJourneyView({
    required this.childName,
    required this.familyId,
    required this.memberId,
  });

  final String childName;
  final String familyId;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIcon('target', size: 64),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Chưa có mục tiêu nào',
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Hãy đặt một mục tiêu để cùng linh vật Bé Ong chinh phục hành trình tiết kiệm!',
              style: context.text.bodyMedium?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton.icon(
              onPressed: () => showGoalSheet(
                context,
                familyId: familyId,
                memberId: memberId,
                childName: childName,
              ),
              icon: const Icon(Icons.flag_rounded),
              label: const Text('ĐẶT MỤC TIÊU NGAY'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentGoalCard extends StatelessWidget {
  const _CurrentGoalCard({
    required this.goal,
    required this.saved,
    required this.target,
    required this.progress,
    required this.onEdit,
  });

  final SavingsGoal goal;
  final int saved;
  final int target;
  final double progress;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final reached = saved >= target;
    final iconKey = goal.iconKey ?? 'target';

    return Card(
      color: reached
          ? context.semantic.success.withValues(alpha: 0.12)
          : context.colors.primaryContainer.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon.task(iconKey, size: 36),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reached
                            ? '🎉 Đã đạt mục tiêu!'
                            : 'Đã tích luỹ được $saved / $target xu',
                        style: context.text.bodySmall?.copyWith(
                          color: reached
                              ? context.semantic.success
                              : context.semantic.onSurfaceMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  tooltip: 'Đổi mục tiêu',
                  onPressed: onEdit,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: context.colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                  reached ? context.semantic.success : context.colors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyMap extends StatelessWidget {
  const _JourneyMap({
    required this.goal,
    required this.saved,
    required this.target,
    required this.rewards,
  });

  final SavingsGoal goal;
  final int saved;
  final int target;
  final List<Reward> rewards;

  @override
  Widget build(BuildContext context) {
    // Xây dựng các mốc hành trình: 25%, 50%, 75%, 100%
    final milestones = <_Milestone>[
      _Milestone(
        percent: 0.25,
        targetXu: (target * 0.25).round(),
        title: 'Khởi động vững chắc',
        iconKey: 'sparkles',
      ),
      _Milestone(
        percent: 0.50,
        targetXu: (target * 0.50).round(),
        title: 'Nửa chặng đường',
        iconKey: 'compass',
      ),
      _Milestone(
        percent: 0.75,
        targetXu: (target * 0.75).round(),
        title: 'Sắp về đích rồi!',
        iconKey: 'fire',
      ),
      _Milestone(
        percent: 1,
        targetXu: target,
        title: goal.title,
        iconKey: goal.iconKey ?? 'trophy',
        isFinal: true,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          children: [
            for (var i = milestones.length - 1; i >= 0; i--) ...[
              _MilestoneTile(
                milestone: milestones[i],
                saved: saved,
                isTop: i == milestones.length - 1,
                isBottom: i == 0,
              ),
              if (i > 0)
                _ConnectingTrack(
                  isPassed: saved >= milestones[i - 1].targetXu,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Milestone {
  const _Milestone({
    required this.percent,
    required this.targetXu,
    required this.title,
    required this.iconKey,
    this.isFinal = false,
  });

  final double percent;
  final int targetXu;
  final String title;
  final String iconKey;
  final bool isFinal;
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.milestone,
    required this.saved,
    required this.isTop,
    required this.isBottom,
  });

  final _Milestone milestone;
  final int saved;
  final bool isTop;
  final bool isBottom;

  @override
  Widget build(BuildContext context) {
    final reached = saved >= milestone.targetXu;
    final isCurrent = !reached &&
        (milestone.targetXu == 0 ||
            saved >= (milestone.targetXu * 0.5).round());

    return Row(
      children: [
        // Điểm mốc dạng hình tròn
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached
                ? context.semantic.success
                : (isCurrent
                    ? context.colors.primary
                    : context.colors.surfaceContainerHighest),
            border: Border.all(
              color: reached
                  ? AppColors.brand360Green
                  : (isCurrent
                      ? context.colors.primary
                      : context.colors.outlineVariant),
              width: 3,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: reached
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
              : AppIcon(milestone.iconKey),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    milestone.title,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: reached
                          ? context.semantic.success
                          : (isCurrent ? context.colors.primary : null),
                    ),
                  ),
                  XuBadge(amount: milestone.targetXu, pill: true),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                reached
                    ? 'Đã vượt qua mốc này'
                    : (isCurrent
                        ? 'Đang tiến về mốc này (còn ${milestone.targetXu - saved} xu)'
                        : 'Mốc ${(milestone.percent * 100).toInt()}%'),
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConnectingTrack extends StatelessWidget {
  const _ConnectingTrack({required this.isPassed});

  final bool isPassed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24),
      alignment: Alignment.centerLeft,
      child: Container(
        width: 4,
        height: 36,
        decoration: BoxDecoration(
          color: isPassed
              ? context.semantic.success
              : context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
