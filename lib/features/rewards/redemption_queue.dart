import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/thong_bao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/reward_repository.dart';
import 'package:beong/domain/services/redemption_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hàng đợi phiếu đổi thưởng chờ bố mẹ duyệt.
///
/// Trước commit này `pendingRedemptions` / `fulfillRedemption` không được gọi từ
/// bất kỳ màn nào, nên phiếu con đổi nằm `pending` **mãi mãi**: xu đã trừ mà
/// không ai duyệt, và không có chỗ nào cho bố mẹ thấy.
class RedemptionQueue extends StatelessWidget {
  const RedemptionQueue({
    required this.familyId,
    required this.reviewerId,
    required this.rewardDao,
    required this.redemptionService,
    super.key,
  });

  final String familyId;
  final String reviewerId;
  final RewardRepository rewardDao;
  final RedemptionService redemptionService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Redemption>>(
      stream: rewardDao.watchPendingRedemptions(familyId),
      builder: (context, snap) {
        final pending = snap.data ?? const <Redemption>[];
        if (pending.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Xin đổi thưởng', style: context.text.titleMedium),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.semantic.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${pending.length}',
                    style: context.text.labelSmall?.copyWith(
                      color: context.semantic.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...pending.map(
              (redemption) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _RedemptionCard(
                  key: ValueKey(redemption.id),
                  redemption: redemption,
                  rewardDao: rewardDao,
                  redemptionService: redemptionService,
                  reviewerId: reviewerId,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        );
      },
    );
  }
}

class _RedemptionCard extends ConsumerStatefulWidget {
  const _RedemptionCard({
    required this.redemption,
    required this.rewardDao,
    required this.redemptionService,
    required this.reviewerId,
    super.key,
  });

  final Redemption redemption;
  final RewardRepository rewardDao;
  final RedemptionService redemptionService;
  final String reviewerId;

  @override
  ConsumerState<_RedemptionCard> createState() => _RedemptionCardState();
}

class _RedemptionCardState extends ConsumerState<_RedemptionCard> {
  Reward? _reward;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(_RedemptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.redemption.rewardId != widget.redemption.rewardId) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final reward = await widget.rewardDao.getReward(widget.redemption.rewardId);
    if (mounted) setState(() => _reward = reward);
  }

  Future<void> _approve() async {
    await widget.redemptionService.approve(
      redemptionId: widget.redemption.id,
      resolvedBy: widget.reviewerId,
    );
    if (!mounted) return;
    hienThongBao(context, 'Đã duyệt. Con nhận được phiếu.');
  }

  Future<void> _reject() async {
    final refunded = await widget.redemptionService.reject(
      redemptionId: widget.redemption.id,
      resolvedBy: widget.reviewerId,
    );
    if (!mounted) return;
    // Nói rõ đã hoàn bao nhiêu xu: bản cũ từ chối mà **không hoàn xu**, con mất
    // xu cho một phần thưởng không được nhận.
    hienThongBao(context, 'Đã từ chối. Hoàn lại $refunded xu cho con.');
  }

  @override
  Widget build(BuildContext context) {
    final reward = _reward;
    if (reward == null) return const SizedBox.shrink();

    final memberDao = ref.watch(memberRepositoryProvider);

    return StreamBuilder<Member>(
      stream: memberDao.watchMember(widget.redemption.memberId),
      builder: (context, memberSnap) {
        final member = memberSnap.data;
        final childName = member?.displayName ?? 'Bé';
        final avatar = member?.avatarKey ?? '👶';
        final childColor = member != null
            ? AppColors.profileColor(member.colorIndex)
            : AppColors.beOngHoney;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: childColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Text(avatar, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: childColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              childName,
                              style: context.text.labelSmall?.copyWith(
                                color: childColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Text('xin đổi'),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          AppIcon.task(reward.iconKey, size: 20),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              reward.title,
                              style: context.text.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${widget.redemption.costSnapshot} xu',
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.xuText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => unawaited(_reject()),
                  icon: Icon(
                    Icons.close_rounded,
                    color: context.semantic.danger,
                  ),
                  tooltip: 'Từ chối và hoàn xu',
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filled(
                  onPressed: () => unawaited(_approve()),
                  icon: const Icon(Icons.check_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: context.semantic.success,
                    foregroundColor: Colors.white,
                  ),
                  tooltip: 'Duyệt',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Phiếu của con: những phần thưởng đã đổi, kèm nút "Đã dùng".
///
/// Phiếu chứ không phải cưỡng chế kỹ thuật — ADR-012. App không khoá hay mở
/// khoá gì; bố mẹ duyệt rồi tự cho phép, con bấm "đã dùng" để đóng phiếu.
class MyVouchers extends StatelessWidget {
  const MyVouchers({
    required this.memberId,
    required this.rewardDao,
    required this.redemptionService,
    super.key,
  });

  final String memberId;
  final RewardRepository rewardDao;
  final RedemptionService redemptionService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Redemption>>(
      stream: rewardDao.watchRedemptions(memberId),
      builder: (context, snap) {
        final all = snap.data ?? const <Redemption>[];
        // Phiếu đã dùng và phiếu bị từ chối không còn là việc phải làm, nên bỏ
        // khỏi danh sách này — lịch sử đầy đủ nằm ở "Sổ của con".
        final open = all
            .where(
              (r) =>
                  r.usedAt == null &&
                  r.status != RedemptionStatus.rejected.name,
            )
            .toList();
        if (open.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phiếu của con', style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ...open.map(
              (redemption) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _VoucherCard(
                  key: ValueKey(redemption.id),
                  redemption: redemption,
                  rewardDao: rewardDao,
                  redemptionService: redemptionService,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        );
      },
    );
  }
}

class _VoucherCard extends StatefulWidget {
  const _VoucherCard({
    required this.redemption,
    required this.rewardDao,
    required this.redemptionService,
    super.key,
  });

  final Redemption redemption;
  final RewardRepository rewardDao;
  final RedemptionService redemptionService;

  @override
  State<_VoucherCard> createState() => _VoucherCardState();
}

class _VoucherCardState extends State<_VoucherCard> {
  Reward? _reward;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(_VoucherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.redemption.rewardId != widget.redemption.rewardId) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final reward = await widget.rewardDao.getReward(widget.redemption.rewardId);
    if (mounted) setState(() => _reward = reward);
  }

  @override
  Widget build(BuildContext context) {
    final reward = _reward;
    if (reward == null) return const SizedBox.shrink();

    final isPending = widget.redemption.status == RedemptionStatus.pending.name;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            AppIcon.task(reward.iconKey, size: 26),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reward.title, style: context.text.bodyLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isPending ? 'Đang chờ bố mẹ duyệt' : 'Dùng được rồi!',
                    style: context.text.bodySmall?.copyWith(
                      color: isPending
                          ? context.semantic.warning
                          : context.semantic.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (!isPending)
              TextButton(
                onPressed: () => unawaited(
                  widget.redemptionService.markUsed(widget.redemption.id),
                ),
                child: const Text('Đã dùng'),
              ),
          ],
        ),
      ),
    );
  }
}
