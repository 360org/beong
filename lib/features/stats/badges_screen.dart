import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/progress_ring.dart';
import 'package:beong/core/widgets/sheet_header.dart';
import 'package:beong/domain/entities/badge_def.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bảng huy hiệu của con — phong cách gamification đồ họa trực quan (Chore Rewards style).
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final badgeDao = ref.watch(badgeRepositoryProvider);
    final memberId = session.activeMemberId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bộ sưu tập huy hiệu'),
      ),
      body: FutureBuilder<BadgeProgress>(
        future: badgeDao.progressOf(memberId),
        builder: (context, progressSnap) {
          final progress = progressSnap.data;
          return StreamBuilder<Set<String>>(
            stream: badgeDao.watchEarnedKeys(memberId),
            builder: (context, earnedSnap) {
              final earned = earnedSnap.data ?? const <String>{};

              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingMobile,
                  vertical: AppSpacing.lg,
                ),
                children: [
                  _CollectionSummary(
                    earned: earned.length,
                    total: kBadges.length,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Lưới huy hiệu theo từng danh mục
                  for (final category in BadgeCategory.values) ...[
                    _CategorySection(
                      category: category,
                      badges: kBadges
                          .where((b) => b.category == category)
                          .toList(),
                      earned: earned,
                      progress: progress,
                    ),
                    const SizedBox(height: AppSpacing.xl),
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

/// Thẻ tổng quan bộ sưu tập phong cách "Collected 4 of 29" của Chore Rewards.
class _CollectionSummary extends StatelessWidget {
  const _CollectionSummary({required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? earned / total : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: context.dashboardGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          // Vòng cung tiến độ tổng thể
          ProgressRing(
            progress: ratio,
            size: 64,
            strokeWidth: 6,
            trackColor: Colors.white.withValues(alpha: 0.25),
            valueColor: Colors.white,
            child: const AppIcon('trophy', size: 30),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ĐÃ THU THẬP $earned / $total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  earned == total
                      ? 'Tuyệt đỉnh! Đã mở khóa tất cả!'
                      : 'Chạm vào từng huy hiệu để xem cách mở khoá!',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

/// Khối danh mục hiển thị dạng Grid icon huy hiệu.
class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.badges,
    required this.earned,
    required this.progress,
  });

  final BadgeCategory category;
  final List<BadgeDef> badges;
  final Set<String> earned;
  final BadgeProgress? progress;

  @override
  Widget build(BuildContext context) {
    final earnedInCategory = badges.where((b) => earned.contains(b.key)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AppIcon(category.iconKey, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  category.titleVi.toUpperCase(),
                  style: context.text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.semantic.onSurfaceMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Text(
              '$earnedInCategory / ${badges.length}',
              style: context.text.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.semantic.onSurfaceMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.88,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            final isEarned = earned.contains(badge.key);
            final current = progress?.valueFor(badge.kind) ?? 0;

            return _BadgeGridTile(
              badge: badge,
              earned: isEarned,
              current: current,
            );
          },
        ),
      ],
    );
  }
}

/// Từng ô huy hiệu dạng lưới (Grid Item) đồ hoạ trực quan cho trẻ nhỏ.
class _BadgeGridTile extends StatelessWidget {
  const _BadgeGridTile({
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

    return Card(
      elevation: earned ? 2 : 0,
      color: earned
          ? context.colors.primaryContainer.withValues(alpha: 0.5)
          : context.colors.surfaceContainerHighest.withValues(alpha: 0.35),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => _showBadgeDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon với vòng tiến độ bao quanh
              ProgressRing(
                progress: earned ? 1.0 : ratio,
                size: 54,
                strokeWidth: 4,
                trackColor: context.colors.surfaceContainerHighest,
                valueColor: earned
                    ? context.semantic.success
                    : context.colors.primary,
                child: Opacity(
                  opacity: earned ? 1.0 : 0.38,
                  child: AppIcon(badge.iconKey, size: 28),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                badge.title,
                style: context.text.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: earned ? null : context.semantic.onSurfaceMuted,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              if (earned)
                Text(
                  'Đã đạt',
                  style: context.text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.semantic.success,
                    fontSize: 10,
                  ),
                )
              else
                Text(
                  '$current/${badge.threshold}',
                  style: context.text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.primary,
                    fontSize: 10,
                  ),
                ),
            ],
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
                SheetHeader(title: badge.title),
                const SizedBox(height: AppSpacing.md),
                ProgressRing(
                  progress: earned ? 1.0 : ratio,
                  size: 80,
                  strokeWidth: 6,
                  trackColor: ctx.colors.surfaceContainerHighest,
                  valueColor: earned
                      ? ctx.semantic.success
                      : ctx.colors.primary,
                  child: Opacity(
                    opacity: earned ? 1.0 : 0.55,
                    child: AppIcon(badge.iconKey, size: 40),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
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
