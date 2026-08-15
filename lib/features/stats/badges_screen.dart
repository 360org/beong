import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/domain/entities/badge_def.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bảng huy hiệu của con — `01-product-spec.md` §4.6.
///
/// Hiện **cả huy hiệu chưa đạt**, làm mờ và kèm tiến độ, chứ không chỉ hiện cái
/// đã có. Một bảng chỉ có huy hiệu đã đạt thì không nói được "còn bao xa nữa",
/// mà chính khoảng cách đó mới là thứ kéo trẻ làm tiếp.
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final badgeDao = ref.watch(badgeDaoProvider);
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
                  const SizedBox(height: AppSpacing.xl),
                  for (final badge in kBadges)
                    _BadgeTile(
                      badge: badge,
                      earned: earned.contains(badge.key),
                      current: progress?.valueFor(badge.kind) ?? 0,
                    ),
                ],
              );
            },
          );
        },
      ),
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
          const AppIcon('star', size: 30),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Con đã có $earned trên $total huy hiệu',
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
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

  /// Số hiện tại của loại điều kiện này.
  final int current;

  @override
  Widget build(BuildContext context) {
    final ratio = (current / badge.threshold).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Huy hiệu chưa đạt vẫn hiện hình, chỉ mờ đi: giấu hình thì trẻ
              // không biết mình đang cố đạt cái gì.
              Opacity(
                opacity: earned ? 1 : 0.35,
                child: AppIcon(badge.iconKey, size: 40),
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
                        color: earned ? null : context.semantic.onSurfaceMuted,
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
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor:
                              context.colors.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$current / ${badge.threshold}',
                        style: context.text.labelSmall?.copyWith(
                          color: context.semantic.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (earned)
                // Đã đạt: có **cả** dấu tích lẫn hình rõ nét, không chỉ dựa vào
                // độ mờ để phân biệt (WCAG 1.4.1).
                Icon(
                  Icons.check_circle_rounded,
                  color: context.semantic.success,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
