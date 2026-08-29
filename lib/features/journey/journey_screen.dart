import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/bee_mascot.dart';
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

/// Màn hình Hành trình — Bản đồ leo núi chinh phục đỉnh cao (Mountain Climbing Summit Adventure).
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
        title: const Text('Bản đồ leo núi chinh phục'),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenPaddingMobile,
                              vertical: AppSpacing.lg,
                            ),
                            children: [
                              // Thẻ đỉnh núi mục tiêu vinh quang
                              _PeakGoalCard(
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
                              const SizedBox(height: AppSpacing.xl),

                              // Header bản đồ
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const AppIcon('compass', size: 20),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        '5 TRẠM CHINH PHỤC ĐỈNH CAO',
                                        style: context.text.labelMedium
                                            ?.copyWith(
                                              color: context
                                                  .semantic
                                                  .onSurfaceMuted,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.colors.primaryContainer,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                    child: Text(
                                      '${(progress * 100).toInt()}% độ cao',
                                      style: context.text.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: context.colors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Bản đồ nấc thang phiêu lưu leo núi
                              _AdventureMountainMap(
                                goal: goal,
                                saved: saved,
                                target: target,
                                progress: progress,
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
            const BeeMascot(mood: BeeMood.happy, size: 96),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Chưa có hành trình leo núi nào',
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Hãy đặt một mục tiêu để cùng Bé Ong bắt đầu cuộc phiêu lưu chinh phục đỉnh núi và nhận phần thưởng nhé!',
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
              label: const Text('BẮT ĐẦU HÀNH TRÌNH'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ đỉnh núi mục tiêu với tiến độ và nút sửa.
class _PeakGoalCard extends StatelessWidget {
  const _PeakGoalCard({
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
    final iconKey = goal.iconKey ?? 'trophy';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: context.dashboardGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: AppIcon.task(iconKey, size: 36),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏔️ ĐỈNH NÚI MỤC TIÊU: ${goal.title.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reached
                          ? '🎉 ĐÃ CHINH PHỤC ĐỈNH NÚI!'
                          : '$saved / $target xu',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'Đổi mục tiêu',
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bản đồ nấc thang leo núi phiêu lưu từ chân núi lên đỉnh núi.
class _AdventureMountainMap extends StatelessWidget {
  const _AdventureMountainMap({
    required this.goal,
    required this.saved,
    required this.target,
    required this.progress,
    required this.rewards,
  });

  final SavingsGoal goal;
  final int saved;
  final int target;
  final double progress;
  final List<Reward> rewards;

  @override
  Widget build(BuildContext context) {
    // 5 mốc bậc thang từ chân núi (0%) lên đỉnh núi (100%)
    final milestones = <_AdventureMilestone>[
      _AdventureMilestone(
        level: 4,
        percent: 1,
        targetXu: target,
        title: '👑 ĐỈNH VINH QUANG: ${goal.title}',
        subtitle: 'Chạm tay vào phần thưởng mơ ước!',
        iconKey: goal.iconKey ?? 'trophy',
        isSummit: true,
      ),
      _AdventureMilestone(
        level: 3,
        percent: 0.75,
        targetXu: (target * 0.75).round(),
        title: '🏔️ Trạm Băng Tuyết (75%)',
        subtitle: 'Sắp tới đỉnh núi rồi, cố thêm một chút nữa!',
        iconKey: 'sparkles',
      ),
      _AdventureMilestone(
        level: 2,
        percent: 0.50,
        targetXu: (target * 0.50).round(),
        title: '🏕️ Lưng Chừng Núi (50%)',
        subtitle: 'Đã hoàn thành xuất sắc nửa chặng đường!',
        iconKey: 'compass',
      ),
      _AdventureMilestone(
        level: 1,
        percent: 0.25,
        targetXu: (target * 0.25).round(),
        title: '🌲 Trạm Rừng Thông (25%)',
        subtitle: 'Khởi động vững vàng, tự tin sải bước!',
        iconKey: 'tree',
      ),
      const _AdventureMilestone(
        level: 0,
        percent: 0,
        targetXu: 0,
        title: '⛺ Chân Núi Khởi Đầu',
        subtitle: 'Bắt đầu tích luỹ xu chăm chỉ từ việc nhà!',
        iconKey: 'sunrise',
        isBase: true,
      ),
    ];

    // Xác định mốc hiện tại bé đang đứng
    var currentStepIndex = milestones.length - 1;
    for (var i = 0; i < milestones.length; i++) {
      if (saved >= milestones[i].targetXu) {
        currentStepIndex = i;
        break;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          children: [
            for (var i = 0; i < milestones.length; i++) ...[
              _AdventureMilestoneStep(
                milestone: milestones[i],
                saved: saved,
                isCurrentPosition: i == currentStepIndex,
                alignRight: i.isOdd,
              ),
              if (i < milestones.length - 1)
                _SteppedClimbingPath(
                  isPassed: saved >= milestones[i + 1].targetXu,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdventureMilestone {
  const _AdventureMilestone({
    required this.level,
    required this.percent,
    required this.targetXu,
    required this.title,
    required this.subtitle,
    required this.iconKey,
    this.isSummit = false,
    this.isBase = false,
  });

  final int level;
  final double percent;
  final int targetXu;
  final String title;
  final String subtitle;
  final String iconKey;
  final bool isSummit;
  final bool isBase;
}

/// Từng trạm dừng chân trên con đường leo núi.
class _AdventureMilestoneStep extends StatelessWidget {
  const _AdventureMilestoneStep({
    required this.milestone,
    required this.saved,
    required this.isCurrentPosition,
    required this.alignRight,
  });

  final _AdventureMilestone milestone;
  final int saved;
  final bool isCurrentPosition;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final reached = saved >= milestone.targetXu;

    return Row(
      children: [
        // Marker icon nấc thang
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: milestone.isSummit ? 64 : 52,
              height: milestone.isSummit ? 64 : 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reached
                    ? (milestone.isSummit
                          ? AppColors.beOngHoney
                          : context.semantic.success)
                    : (isCurrentPosition
                          ? context.colors.primaryContainer
                          : context.colors.surfaceContainerHighest.withValues(
                              alpha: 0.6,
                            )),
                border: Border.all(
                  color: reached
                      ? (milestone.isSummit
                            ? AppColors.brand360Blue
                            : AppColors.brand360Green)
                      : (isCurrentPosition
                            ? context.colors.primary
                            : context.colors.outlineVariant),
                  width: milestone.isSummit ? 4 : 3,
                ),
                boxShadow: isCurrentPosition
                    ? [
                        BoxShadow(
                          color: context.colors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: reached && !milestone.isSummit && !milestone.isBase
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 28,
                    )
                  : AppIcon(
                      milestone.iconKey,
                      size: milestone.isSummit ? 34 : 26,
                    ),
            ),
            // Linh vật Bé Ong xuất hiện tại vị trí hiện tại của bé
            if (isCurrentPosition)
              const Positioned(
                top: -18,
                right: -14,
                child: BeeMascot(mood: BeeMood.happy, size: 36),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.lg),

        // Thông tin trạm dừng
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      milestone.title,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: reached
                            ? context.semantic.success
                            : (isCurrentPosition
                                  ? context.colors.primary
                                  : null),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (milestone.targetXu > 0)
                    XuBadge(amount: milestone.targetXu, pill: true),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                milestone.subtitle,
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

/// Nối các bậc thang leo núi
class _SteppedClimbingPath extends StatelessWidget {
  const _SteppedClimbingPath({
    required this.isPassed,
  });

  final bool isPassed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 25, top: 4, bottom: 4),
      alignment: Alignment.centerLeft,
      child: Container(
        width: 4,
        height: 38,
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
