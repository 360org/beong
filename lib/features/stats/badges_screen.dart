import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/progress_ring.dart';
import 'package:beong/domain/entities/badge_def.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bảng huy hiệu của con — phân nhóm & có vòng cung tiến độ (docs/16 §12, §15, §21).
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final badgeDao = ref.watch(badgeRepositoryProvider);
    final memberId = session.activeMemberId;

    return Scaffold(
      appBar: AppBar(title: const Text('Huy hiệu')),
      body: FutureBuilder<BadgeProgress>(
        future: badgeDao.progressOf(memberId),
        builder: (context, progressSnap) {
          final progress = progressSnap.data;
          return StreamBuilder<Set<String>>(
            stream: badgeDao.watchEarnedKeys(memberId),
            builder: (context, earnedSnap) {
              final earned = earnedSnap.data ?? const <String>{};

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  _Summary(earned: earned.length, total: kBadges.length),
                  const SizedBox(height: AppSpacing.xxl),

                  // Chia danh sách theo nhóm danh mục
                  for (final category in BadgeCategory.values) ...[
                    _CategoryHeader(category: category),
                    const SizedBox(height: AppSpacing.sm),
                    for (final badge in kBadges.where(
                      (b) => b.category == category,
                    ))
                      _BadgeTile(
                        badge: badge,
                        earned: earned.contains(badge.key),
                        current: progress?.valueFor(badge.kind) ?? 0,
                      ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});
  final BadgeCategory category;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(category.iconKey, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Text(
          category.titleVi.toUpperCase(),
          style: context.text.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.semantic.onSurfaceMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.card)),
      ),
      child: Row(
        children: [
          const AppIcon('star', size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Con đã có $earned trên $total huy hiệu',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cố gắng làm việc nhà mỗi ngày để mở thêm nhé!',
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.earned,
    required this.current,
  });

  final BadgeDef badge;
  final bool earned;
  final int current;

  @override
  Widget build(BuildContext context) {
    final ratio = (current / badge.threshold).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => _showBadgeDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                // Vòng cung tiến độ ôm quanh icon huy hiệu (§15)
                ProgressRing(
                  progress: earned ? 1.0 : ratio,
                  size: 52,
                  strokeWidth: 4,
                  trackColor: context.colors.surfaceContainerHighest,
                  valueColor: earned
                      ? context.semantic.success
                      : context.colors.primary,
                  child: Opacity(
                    opacity: earned ? 1.0 : 0.45,
                    child: AppIcon(badge.iconKey, size: 26),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badge.title,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: earned
                              ? null
                              : context.semantic.onSurfaceMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badge.description,
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.onSurfaceMuted,
                        ),
                      ),
                      if (!earned) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tiến độ: $current / ${badge.threshold}',
                          style: context.text.labelSmall?.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (earned)
                  Icon(
                    Icons.check_circle_rounded,
                    color: context.semantic.success,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context) {
    final ratio = (current / badge.threshold).clamp(0.0, 1.0);

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ProgressRing(
                  progress: earned ? 1.0 : ratio,
                  size: 80,
                  strokeWidth: 6,
                  trackColor: ctx.colors.surfaceContainerHighest,
                  valueColor: earned
                      ? ctx.semantic.success
                      : ctx.colors.primary,
                  child: Opacity(
                    opacity: earned ? 1.0 : 0.6,
                    child: AppIcon(badge.iconKey, size: 40),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  badge.title,
                  style: ctx.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: earned
                        ? ctx.semantic.success.withValues(alpha: 0.15)
                        : ctx.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    earned ? 'ĐÃ ĐẠT ĐƯỢC' : 'ĐANG CHINH PHỤC',
                    style: ctx.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: earned ? ctx.semantic.success : ctx.colors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  badge.description,
                  style: ctx.text.bodyMedium?.copyWith(
                    color: ctx.semantic.onSurfaceMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: ctx.colors.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tiến độ thực tế', style: ctx.text.bodySmall),
                      Text(
                        '$current / ${badge.threshold}',
                        style: ctx.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: ctx.colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('ĐÓNG'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
