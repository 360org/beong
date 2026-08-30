import 'dart:async';

import 'package:beong/app/router.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/utils/ngay_viet.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/loi_man_hinh.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/domain/entities/badge_def.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/repositories/goal_repository.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/reward_repository.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:beong/domain/repositories/wallet_repository.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/money_exchange.dart';
import 'package:beong/features/goals/goal_section.dart';
import 'package:beong/features/goals/goal_sheet.dart';
import 'package:beong/features/rewards/allocate_xu_sheet.dart';
import 'package:beong/features/stats/adjust_xu_sheet.dart';
import 'package:beong/features/stats/jar_add_sheet.dart';
import 'package:beong/features/stats/jar_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final memberDao = ref.watch(memberRepositoryProvider);
    final walletDao = ref.watch(walletRepositoryProvider);
    final taskDao = ref.watch(taskRepositoryProvider);
    final rewardDao = ref.watch(rewardRepositoryProvider);

    if (session.isParent) {
      return _ParentStats(
        session: session,
        memberDao: memberDao,
        walletDao: walletDao,
      );
    }

    return _ChildStats(
      memberId: session.activeMemberId,
      familyId: session.familyId,
      walletDao: walletDao,
      memberDao: memberDao,
      taskDao: taskDao,
      rewardDao: rewardDao,
    );
  }
}

class _WeeklyOverviewCard extends StatelessWidget {
  const _WeeklyOverviewCard({
    required this.txns,
    required this.currentWeekOffset,
    required this.onPrevWeek,
    required this.onNextWeek,
  });

  final List<LedgerEntry> txns;
  final int currentWeekOffset;
  final VoidCallback onPrevWeek;
  final VoidCallback? onNextWeek;

  @override
  Widget build(BuildContext context) {
    final completedCount = txns
        .where((t) => t.reason == 'taskApproved' || t.reason == 'routineBonus')
        .length;
    final totalDelta = txns.fold<int>(0, (sum, t) => sum + t.delta);
    final rewardRedeemedCount = txns
        .where((t) => t.reason == 'rewardRedeemed')
        .length;

    final weekLabel = switch (currentWeekOffset) {
      0 => 'Tuần này',
      -1 => 'Tuần trước',
      final n => '${n.abs()} tuần trước',
    };

    return Card(
      color: context.colors.primaryContainer.withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỔNG KẾT TUẦN',
                      style: context.text.labelSmall?.copyWith(
                        color: context.semantic.onSurfaceMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      weekLabel,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      tooltip: 'Tuần trước',
                      onPressed: onPrevWeek,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      tooltip: 'Tuần sau',
                      onPressed: onNextWeek,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.field),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Việc đã xong',
                          style: context.text.bodySmall?.copyWith(
                            color: context.semantic.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$completedCount việc',
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.semantic.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.field),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xu tích lũy',
                          style: context.text.bodySmall?.copyWith(
                            color: context.semantic.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          totalDelta >= 0
                              ? '+$totalDelta xu'
                              : '$totalDelta xu',
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.semantic.xuText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (rewardRedeemedCount > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.field),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quà đã đổi',
                            style: context.text.bodySmall?.copyWith(
                              color: context.semantic.onSurfaceMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$rewardRedeemedCount quà',
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentStats extends ConsumerWidget {
  const _ParentStats({
    required this.session,
    required this.memberDao,
    required this.walletDao,
  });

  final AppSession session;
  final MemberRepository memberDao;
  final WalletRepository walletDao;

  Future<void> _moThemHu(BuildContext context, WidgetRef ref) async {
    final children = await memberDao.children(session.familyId);
    if (!context.mounted) return;
    await showJarAddSheet(
      context,
      jarDao: ref.read(jarRepositoryProvider),
      familyId: session.familyId,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thống kê', style: context.text.titleLarge),
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Thêm hũ',
        icon: const Icon(Icons.add),
        label: const Text('THÊM HŨ'),
        // Nạp danh sách bé ngay trước khi mở bảng, chứ không đọc từ
        // `StreamBuilder` phía dưới: nút nổi nằm **ngoài** cây con đó nên
        // không với tới biến của nó.
        onPressed: () => unawaited(_moThemHu(context, ref)),
      ),
      body: StreamBuilder<List<Member>>(
        stream: memberDao.watchMembers(session.familyId),
        builder: (context, snap) {
          final members = snap.data ?? [];
          final children = members
              .where((m) => m.kind == MemberKind.child.name)
              .toList();

          if (children.isEmpty) {
            return Center(
              child: Text(
                'Chưa có bé nào.',
                style: context.text.bodyMedium?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingMobile,
              vertical: AppSpacing.lg,
            ),
            children: children.map((child) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: _ChildStatsCard(
                  child: child,
                  walletDao: walletDao,
                  memberDao: memberDao,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ChildStatsCard extends ConsumerWidget {
  const _ChildStatsCard({
    required this.child,
    required this.walletDao,
    required this.memberDao,
  });

  final Member child;
  final WalletRepository walletDao;
  final MemberRepository memberDao;

  Future<void> _editGoal(BuildContext context, WidgetRef ref) async {
    final current = await ref.read(goalRepositoryProvider).activeGoal(child.id);
    if (!context.mounted) return;
    await showGoalSheet(
      context,
      familyId: child.familyId,
      memberId: child.id,
      childName: child.displayName,
      current: current,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Một luồng số dư cho **cả** dòng tên lẫn các ô hũ. Mở hai luồng thì
        // có khoảnh khắc tổng ở trên và các hũ ở dưới không cộng ra nhau.
        StreamBuilder<WalletBalance>(
          stream: walletDao.watchBalance(child.id),
          builder: (context, snap) {
            final balance = snap.data ?? WalletBalance.zero;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        child.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Tổng xu đứng ngay cạnh tên. Chủ dự án nêu 30/08/2026:
                    // *"phần thống kê trên header profile nên show total xu."*
                    // Trước đó con số này chỉ hiện ở dòng quy đổi tiền — mà
                    // dòng đó **ẩn hẳn** khi nhà tắt quy đổi (mặc định là
                    // tắt), nên tổng xu của con không hiện ở đâu cả: bố mẹ
                    // phải tự cộng nhẩm 5 ô hũ.
                    XuBadge(amount: balance.total),
                    const Spacer(),
                    if (session != null)
                      TextButton.icon(
                        onPressed: () => unawaited(
                          showAdjustXuSheet(
                            context,
                            familyId: child.familyId,
                            memberId: child.id,
                            childName: child.displayName,
                            reviewerId: session.activeMemberId,
                          ),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Sửa xu'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _JarOverview(
                  balance: balance,
                  familyId: child.familyId,
                  memberId: child.id,
                  tenBe: child.displayName,
                  choPhepSua: true,
                  hienDongTong: false,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<Streak?>(
          stream: memberDao.watchStreak(child.id),
          builder: (context, snap) {
            final streak = snap.data;
            if (streak == null) return const SizedBox.shrink();
            return _StreakCard(streak: streak);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        GoalSection(
          memberId: child.id,
          onTap: () => unawaited(_editGoal(context, ref)),
        ),
        // Nút riêng khi chưa có mục tiêu: [GoalSection] cố ý không hiện gì lúc
        // đó, nên không có chỗ nào bấm vào để đặt mục tiêu đầu tiên.
        StreamBuilder<SavingsGoal?>(
          stream: ref.watch(goalRepositoryProvider).watchActiveGoal(child.id),
          builder: (context, snap) {
            if (snap.data != null) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => unawaited(_editGoal(context, ref)),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Đặt mục tiêu để dành'),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ChildStats extends StatefulWidget {
  const _ChildStats({
    required this.memberId,
    required this.familyId,
    required this.walletDao,
    required this.memberDao,
    required this.taskDao,
    required this.rewardDao,
  });

  final String memberId;
  final String familyId;
  final WalletRepository walletDao;
  final MemberRepository memberDao;
  final TaskRepository taskDao;
  final RewardRepository rewardDao;

  @override
  State<_ChildStats> createState() => _ChildStatsState();
}

class _ChildStatsState extends State<_ChildStats> {
  int _weekOffset = 0; // 0 = tuần này, -1 = tuần trước...

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final targetMonday = currentMonday.add(Duration(days: _weekOffset * 7));
    final targetNextMonday = targetMonday.add(const Duration(days: 7));

    return Scaffold(
      appBar: AppBar(
        title: Text('Sổ của con', style: context.text.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingMobile,
          vertical: AppSpacing.lg,
        ),
        children: [
          StreamBuilder<WalletBalance>(
            stream: widget.walletDao.watchBalance(widget.memberId),
            builder: (context, snap) {
              final balance = snap.data ?? WalletBalance.zero;
              return _JarOverview(
                balance: balance,
                familyId: widget.familyId,
                memberId: widget.memberId,
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
          StreamBuilder<Streak?>(
            stream: widget.memberDao.watchStreak(widget.memberId),
            builder: (context, snap) {
              final streak = snap.data;
              if (streak == null) return const SizedBox.shrink();
              return _StreakCard(streak: streak);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          // Không truyền `onTap`: con xem được tiến độ nhưng không tự đổi mục
          // tiêu. Đổi mục tiêu mỗi khi thấy còn xa là đúng cái thói quen tính
          // năng này muốn dạy ngược lại.
          GoalSection(memberId: widget.memberId),
          const SizedBox(height: AppSpacing.xl),
          _BadgesEntry(memberId: widget.memberId),
          const SizedBox(height: AppSpacing.xxl),
          _JarTitles(
            familyId: widget.familyId,
            builder: (context, jarTitles) => LuongDuLieu<List<LedgerEntry>>(
              stream: widget.walletDao.watchGroupedHistory(widget.memberId),
              builder: (context, allTxns) {
                // Lọc giao dịch trong tuần được chọn
                final weekTxns = allTxns.where((tx) {
                  return !tx.createdAt.isBefore(targetMonday) &&
                      tx.createdAt.isBefore(targetNextMonday);
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WeeklyOverviewCard(
                      txns: weekTxns,
                      currentWeekOffset: _weekOffset,
                      onPrevWeek: () => setState(() => _weekOffset--),
                      onNextWeek: _weekOffset < 0
                          ? () => setState(() => _weekOffset++)
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Lịch sử theo ngày', style: context.text.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    if (weekTxns.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Center(
                          child: Text(
                            _weekOffset == 0
                                ? 'Chưa có hoạt động nào trong tuần này.'
                                : 'Không có hoạt động nào trong tuần này.',
                            style: context.text.bodyMedium?.copyWith(
                              color: context.semantic.onSurfaceMuted,
                            ),
                          ),
                        ),
                      )
                    else
                      _DailyHistoryList(
                        txns: weekTxns,
                        targetMonday: targetMonday,
                        isCurrentWeek: _weekOffset == 0,
                        taskDao: widget.taskDao,
                        rewardDao: widget.rewardDao,
                        jarTitles: jarTitles,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Lối vào bảng huy hiệu, kèm số đã đạt.
///
/// Đặt ngay trên "Lịch sử" chứ không giấu trong Cài đặt: huy hiệu là phần thưởng
/// tinh thần, phải nằm ở chỗ con hay nhìn.
class _BadgesEntry extends ConsumerWidget {
  const _BadgesEntry({required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Set<String>>(
      stream: ref.watch(badgeRepositoryProvider).watchEarnedKeys(memberId),
      builder: (context, snap) {
        final earned = snap.data?.length ?? 0;
        return Card(
          child: InkWell(
            onTap: () => context.go(Routes.badges),
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const AppIcon('star', size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Huy hiệu · $earned/${kBadges.length}',
                      style: context.text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bảng tra `jar_key` -> tên hũ, đọc từ bảng `jars`.
class _JarTitles extends ConsumerWidget {
  const _JarTitles({required this.familyId, required this.builder});

  final String familyId;
  final Widget Function(BuildContext, Map<String, String>) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<JarDef>>(
      // Lấy **cả hũ đã xếp lại**: sổ cái vẫn còn dòng của chúng, và một hũ xếp
      // lại rồi vẫn phải đọc được tên trong lịch sử.
      stream: ref
          .watch(jarRepositoryProvider)
          .watchAllJars(familyId)
          .map((rows) => [for (final r in rows) r.jar]),
      builder: (context, snap) => builder(context, {
        for (final jar in snap.data ?? kDefaultJars) jar.key: jar.title,
      }),
    );
  }
}

/// Số dư từng hũ của gia đình.
///
/// Đọc danh sách hũ từ bảng `jars` chứ không dựng cứng ba ô: bản trước hiện đúng
/// Tiêu / Để dành / Cho đi, nên hũ do bố mẹ tự lập **không có ô nào** và xu trong
/// đó mất khỏi màn hình. Con cộng ba ô lại thấy 11 trong khi tổng ghi 25 — không
/// có cách nào hiểu được chuyện gì xảy ra.
class _JarOverview extends ConsumerWidget {
  const _JarOverview({
    required this.balance,
    required this.familyId,
    this.memberId,
    this.tenBe,
    this.choPhepSua = false,
    this.hienDongTong = true,
  });

  final WalletBalance balance;
  final String familyId;
  final String? memberId;

  /// Tên bé, để bảng sửa nói rõ đang sửa hũ của ai.
  final String? tenBe;

  /// Bấm vào thẻ hũ để sửa / ngừng dùng. Chỉ bật ở màn của **bố mẹ**: con xem
  /// được số dư của mình nhưng không tự đổi luật chia xu.
  final bool choPhepSua;

  /// Hiện dòng tổng dưới các ô hũ. Tắt ở màn bố mẹ vì tổng đã nằm ngay cạnh
  /// tên bé trên đầu — cùng một con số in hai lần cách nhau nửa gang tay thì
  /// người đọc phải dừng lại kiểm xem có phải hai thứ khác nhau không.
  final bool hienDongTong;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletDao = ref.watch(walletRepositoryProvider);
    final jarDao = ref.watch(jarRepositoryProvider);

    return StreamBuilder<List<JarDef>>(
      // Bộ hũ **của bé này**, không phải bộ chung: từ v9 mỗi bé có thể có bộ
      // riêng, và thẻ hũ ở đây chính là chỗ bố mẹ trông chờ thấy điều đó.
      stream: jarDao.watchActiveJars(familyId, memberId: memberId),
      builder: (context, snap) {
        final jars = snap.data ?? kDefaultJars;

        final tiles = <Widget>[
          for (final jar in jars)
            _JarCard(
              label: jar.title,
              iconKey: iconKeyForEmoji(jar.emoji),
              amount: balance.ofKey(jar.key),
              onTap: choPhepSua && memberId != null
                  ? () => unawaited(
                      showJarEditSheet(
                        context,
                        jarDao: jarDao,
                        familyId: familyId,
                        memberId: memberId!,
                        tenBe: tenBe ?? 'bé',
                        hu: jar,
                        tatCaHu: jars,
                      ),
                    )
                  : null,
            ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (balance.inbox > 0) ...[
              _UnallocatedBanner(
                inbox: balance.inbox,
                onAllocate: memberId == null
                    ? null
                    : () async {
                        final activeJars = await jarDao.activeJars(familyId);
                        if (!context.mounted) return;
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => AllocateXuSheet(
                            familyId: familyId,
                            memberId: memberId!,
                            inbox: balance.inbox,
                            walletDao: walletDao,
                            jars: activeJars,
                          ),
                        );
                      },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = AppSpacing.sm;
                final perRow = tiles.length <= 3 ? tiles.length : 3;
                final width =
                    (constraints.maxWidth - gap * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final tile in tiles)
                      SizedBox(width: width, child: tile),
                  ],
                );
              },
            ),
            if (hienDongTong) _DongTong(familyId: familyId, xu: balance.total),
          ],
        );
      },
    );
  }
}

/// Banner xu chưa chia (ADR-024, §12) — nằm tách riêng phía trên các hũ thật.
class _UnallocatedBanner extends StatelessWidget {
  const _UnallocatedBanner({
    required this.inbox,
    this.onAllocate,
  });

  final int inbox;
  final VoidCallback? onAllocate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.semantic.xu.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.semantic.xuText, width: 1.5),
      ),
      child: Row(
        children: [
          const AppIcon('jar_inbox', size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$inbox xu chờ chia',
                  style: context.text.titleSmall?.copyWith(
                    color: context.semantic.xuText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Con chia xu vào các hũ để dùng và để dành.',
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onAllocate != null)
            FilledButton.tonal(
              onPressed: onAllocate,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Chia ngay'),
            ),
        ],
      ),
    );
  }
}

/// Dòng tổng dưới các ô hũ, kèm giá trị tiền thật khi nhà đã bật quy đổi
/// (ADR-017).
///
/// Tổng **luôn** hiện. Trước 30/08/2026 cả dòng này ẩn khi tắt quy đổi — mà
/// quy đổi mặc định tắt — nên tổng xu của con không hiện ở đâu cả, và muốn
/// biết thì phải tự cộng nhẩm năm ô hũ. Giá trị tiền mới là phần tuỳ chọn,
/// không phải cái tổng.
///
/// Tiền đặt dưới **tổng** chứ không gắn vào từng hũ: năm ô mỗi ô hai con số
/// thì màn hình thành bảng kế toán, mà đây là màn hình cho trẻ con đọc.
/// Chữ của dòng tổng. `null` [tien] = nhà chưa bật quy đổi.
///
/// Tách ra để kiểm được điều quan trọng nhất ở đây: **tổng không bao giờ biến
/// mất**. Lỗi cũ là cả dòng ẩn đi khi tắt quy đổi, mà quy đổi mặc định tắt.
String dongTongXu(int xu, String? tien) =>
    tien == null ? 'Tổng $xu xu' : 'Tổng $xu xu  $tien';

class _DongTong extends ConsumerWidget {
  const _DongTong({required this.familyId, required this.xu});

  final String familyId;
  final int xu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<MoneyExchange>(
      stream: ref.watch(memberRepositoryProvider).watchExchangeRate(familyId),
      builder: (context, snap) {
        final tien = snap.data?.labelFor(xu);
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            dongTongXu(xu, tien),
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
        );
      },
    );
  }
}

class _JarCard extends StatelessWidget {
  const _JarCard({
    required this.label,
    required this.amount,
    required this.iconKey,
    this.onTap,
  });

  final String label;
  final int amount;

  /// Khoá icon của hũ, suy từ emoji bố mẹ đã chọn.
  final String iconKey;

  /// Mở bảng sửa hũ. `null` với vai con — thẻ vẫn hiện nhưng không bấm được.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          AppIcon(iconKey, size: 26),
          const SizedBox(height: AppSpacing.sm),
          XuBadge(amount: amount),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );

    // Chỉ còn hũ **thật** đi qua đây. Xu chưa chia nay là `_UnallocatedBanner`
    // riêng phía trên (audit §12), nên nhánh `pending` cũ bỏ hẳn thay vì để
    // lại một cờ không ai truyền — đúng loại code chết dự án dọn nhiều lần.
    if (onTap == null) return Card(child: body);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.card)),
        child: body,
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final Streak streak;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: context.semantic.warning,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${streak.currentLen} ngày liên tiếp',
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Kỷ lục: ${streak.bestLen} ngày',
                    style: context.text.bodySmall?.copyWith(
                      color: context.semantic.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Danh sách lịch sử nhóm theo ngày (ADR-024, §11).
///
/// Mỗi ngày là một thẻ gập/mở, hiển thị thứ/ngày, số việc xong, và tổng xu thay đổi.
class _DailyHistoryList extends StatelessWidget {
  const _DailyHistoryList({
    required this.txns,
    required this.targetMonday,
    required this.isCurrentWeek,
    required this.taskDao,
    required this.rewardDao,
    required this.jarTitles,
  });

  final List<LedgerEntry> txns;
  final DateTime targetMonday;
  final bool isCurrentWeek;
  final TaskRepository taskDao;
  final RewardRepository rewardDao;
  final Map<String, String> jarTitles;

  @override
  Widget build(BuildContext context) {
    // Nhóm các giao dịch theo ngày (CalendarDate)
    final grouped = <CalendarDate, List<LedgerEntry>>{};
    for (final tx in txns) {
      final date = CalendarDate.fromDateTime(tx.createdAt);
      grouped.putIfAbsent(date, () => []).add(tx);
    }

    final today = CalendarDate.fromDateTime(DateTime.now());

    // 7 ngày trong tuần được chọn (từ Thứ 2 đến Chủ nhật)
    final weekDays = List.generate(7, (i) {
      final dt = targetMonday.add(Duration(days: i));
      return CalendarDate.fromDateTime(dt);
    });

    return Column(
      children: [
        for (final date in weekDays.reversed) ...[
          if (grouped.containsKey(date))
            _DayHistoryGroup(
              key: ValueKey(date.toString()),
              date: date,
              txns: grouped[date] ?? const [],
              isExpandedByDefault: date == today,
              taskDao: taskDao,
              rewardDao: rewardDao,
              jarTitles: jarTitles,
            )
          else
            _EmptyDayTile(
              date: date,
              isFuture: isCurrentWeek && date > today,
            ),
        ],
      ],
    );
  }
}

/// Dòng hiển thị ngày không có hoạt động — phân biệt ngày chưa tới vs ngày đã qua (§6).
class _EmptyDayTile extends StatelessWidget {
  const _EmptyDayTile({
    required this.date,
    required this.isFuture,
  });

  final CalendarDate date;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final title = '${thuNganGon(date.weekday)}, ${ngayNganGon(date)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        color: isFuture
            ? context.colors.surfaceContainerLowest.withValues(alpha: 0.5)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Text(
                title,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isFuture
                      ? context.semantic.onSurfaceMuted.withValues(alpha: 0.5)
                      : context.semantic.onSurfaceMuted,
                ),
              ),
              const Spacer(),
              Text(
                isFuture ? '—' : 'Không có hoạt động',
                style: context.text.bodySmall?.copyWith(
                  color: isFuture
                      ? context.semantic.onSurfaceMuted.withValues(alpha: 0.4)
                      : context.semantic.onSurfaceMuted,
                  fontStyle: isFuture ? null : FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayHistoryGroup extends StatelessWidget {
  const _DayHistoryGroup({
    required this.date,
    required this.txns,
    required this.isExpandedByDefault,
    required this.taskDao,
    required this.rewardDao,
    required this.jarTitles,
    super.key,
  });

  final CalendarDate date;
  final List<LedgerEntry> txns;
  final bool isExpandedByDefault;
  final TaskRepository taskDao;
  final RewardRepository rewardDao;
  final Map<String, String> jarTitles;

  @override
  Widget build(BuildContext context) {
    final completedCount = txns
        .where((t) => t.reason == 'taskApproved' || t.reason == 'routineBonus')
        .length;
    final totalDelta = txns.fold<int>(0, (sum, t) => sum + t.delta);
    final deltaLabel = switch (totalDelta) {
      0 => '0 xu',
      final d when d > 0 => '+$d xu',
      final d => '$d xu',
    };

    final title = '${thuNganGon(date.weekday)}, ${ngayNganGon(date)}';
    final subtitle = [
      if (completedCount > 0) '$completedCount việc xong',
      deltaLabel,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: isExpandedByDefault,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            childrenPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
            ),
            title: Text(
              title,
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: context.text.bodySmall?.copyWith(
                color: totalDelta > 0
                    ? context.semantic.success
                    : totalDelta < 0
                    ? context.semantic.danger
                    : context.semantic.onSurfaceMuted,
                fontWeight: totalDelta != 0 ? FontWeight.w600 : null,
              ),
            ),
            children: [
              for (final tx in txns)
                _TransactionTile(
                  key: ValueKey(tx.groupId),
                  tx: tx,
                  taskDao: taskDao,
                  rewardDao: rewardDao,
                  jarTitles: jarTitles,
                ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một mục trong Sổ của con.
///
/// Hiện **tên việc / tên phần thưởng** chứ không chỉ "Hoàn thành việc": trước
/// đây mọi dòng đều mang cùng một chữ, nên sổ chín việc trông như chín dòng
/// giống hệt nhau và trẻ không tra được xu đến từ đâu.
class _TransactionTile extends StatefulWidget {
  const _TransactionTile({
    required this.tx,
    required this.taskDao,
    required this.rewardDao,
    required this.jarTitles,
    super.key,
  });

  final LedgerEntry tx;
  final TaskRepository taskDao;
  final RewardRepository rewardDao;

  /// `jar_key` -> tên hũ do bố mẹ đặt.
  final Map<String, String> jarTitles;

  @override
  State<_TransactionTile> createState() => _TransactionTileState();
}

/// Trạng thái của mục lịch sử, để cột bên trái nói được điều gì.
@immutable
class _EntryStatus {
  const _EntryStatus(this.label, this.icon, this.tone);

  final String label;
  final IconData icon;

  /// Sắc thái: `ok` xanh, `wait` cam, `bad` đỏ, `neutral` xám.
  final String tone;
}

class _TransactionTileState extends State<_TransactionTile> {
  String? _subject;

  /// Tạo **một lần**, không tạo trong `build`.
  ///
  /// `StreamBuilder` nhận stream mới là huỷ đăng ký cũ rồi đăng ký lại; gọi
  /// `_statusStream()` trong `build` nghĩa là mỗi lần dựng lại chạy lại truy vấn
  /// drift và nháy về trạng thái rỗng một khung hình.
  late Stream<_EntryStatus?> _status = _statusStream();

  @override
  void initState() {
    super.initState();
    unawaited(_loadSubject());
  }

  @override
  void didUpdateWidget(_TransactionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tx.refId == widget.tx.refId) return;
    unawaited(_loadSubject());
    setState(() => _status = _statusStream());
  }

  /// Trạng thái đọc từ **thực thể gốc**, không đoán từ lý do giao dịch.
  ///
  /// Một dòng `rewardRedeemed` không nói được phiếu đó đã được duyệt hay chưa —
  /// chỉ bảng `redemptions` biết. Đó là lý do phải tra ngược, và cũng là lý do
  /// dòng lịch sử phải giữ `ref_type` / `ref_id`.
  _EntryStatus? _statusOf(String? instanceStatus, String? redemptionStatus) {
    if (instanceStatus != null) {
      return switch (instanceStatus) {
        'approved' => const _EntryStatus('Đã xong', Icons.check_circle, 'ok'),
        'pendingReview' => const _EntryStatus(
          'Chờ duyệt',
          Icons.hourglass_bottom_rounded,
          'wait',
        ),
        // Lượt đã bị bố mẹ mở lại: xu vẫn còn nhưng việc phải làm lại (ADR-022).
        'scheduled' => const _EntryStatus(
          'Phải làm lại',
          Icons.replay_rounded,
          'wait',
        ),
        'missed' => const _EntryStatus(
          'Bỏ lỡ',
          Icons.remove_circle_outline,
          'bad',
        ),
        'rejected' => const _EntryStatus(
          'Bị từ chối',
          Icons.close_rounded,
          'bad',
        ),
        _ => null,
      };
    }

    if (redemptionStatus != null) {
      return switch (redemptionStatus) {
        'pending' => const _EntryStatus(
          'Chờ bố mẹ duyệt',
          Icons.hourglass_bottom_rounded,
          'wait',
        ),
        'fulfilled' => const _EntryStatus(
          'Dùng được',
          Icons.check_circle,
          'ok',
        ),
        'used' => const _EntryStatus(
          'Đã dùng',
          Icons.task_alt_rounded,
          'neutral',
        ),
        'rejected' => const _EntryStatus(
          'Bị từ chối',
          Icons.close_rounded,
          'bad',
        ),
        _ => null,
      };
    }

    return null;
  }

  /// Tra tên của thứ giao dịch này nói về.
  ///
  /// Không tra được thì để `null` và chỉ hiện nhãn theo lý do — dữ liệu cũ hoặc
  /// việc đã bị xoá không được làm dòng lịch sử biến mất.
  /// Tên thì tra một lần (không đổi), còn **trạng thái phải theo dõi**.
  ///
  /// Bố mẹ duyệt hoặc mở lại không ghi dòng sổ cái nào, nên stream lịch sử
  /// không phát lại và widget không dựng lại. Tra một lần là cách chắc chắn để
  /// dòng "Chờ bố mẹ duyệt" đứng nguyên sau khi phiếu đã bị từ chối — đúng lỗi
  /// đã gặp.
  Stream<_EntryStatus?> _statusStream() {
    final tx = widget.tx;
    final refId = tx.refId;
    if (refId == null) return Stream.value(null);

    switch (tx.refType) {
      case 'task_instance':
        return widget.taskDao
            .watchInstance(refId)
            .map((i) => _statusOf(i?.status, null));
      case 'reward':
        // Dòng trừ xu khi đổi thưởng trỏ vào `reward`, nhưng trạng thái nằm ở
        // phiếu — mà phiếu dùng chính `client_op_id` làm id, tức `groupId`.
        return widget.rewardDao
            .watchRedemption(tx.groupId)
            .map((r) => _statusOf(null, r?.status));
      case 'redemption':
        return widget.rewardDao
            .watchRedemption(refId)
            .map((r) => _statusOf(null, r?.status));
      default:
        return Stream.value(null);
    }
  }

  Future<void> _loadSubject() async {
    final tx = widget.tx;
    final refId = tx.refId;
    if (refId == null) return;

    String? name;
    switch (tx.refType) {
      case 'task_instance':
        final instance = await widget.taskDao.getInstanceById(refId);
        if (instance != null) {
          name = (await widget.taskDao.getTaskById(instance.taskId)).title;
        }
      case 'reward':
        name = (await widget.rewardDao.getReward(refId))?.title;
      case 'redemption':
        final redemption = await widget.rewardDao.getRedemption(refId);
        if (redemption != null) {
          name = (await widget.rewardDao.getReward(redemption.rewardId))?.title;
        }
      default:
        name = null;
    }

    if (mounted && name != null) setState(() => _subject = name);
  }

  Color _toneColor(BuildContext context, String tone) => switch (tone) {
    'ok' => context.semantic.success,
    'wait' => context.semantic.warning,
    'bad' => context.semantic.danger,
    _ => context.semantic.onSurfaceMuted,
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<_EntryStatus?>(
      stream: _status,
      builder: (context, snap) => _buildRow(context, snap.data),
    );
  }

  Widget _buildRow(BuildContext context, _EntryStatus? status) {
    final tx = widget.tx;
    final isPositive = tx.delta > 0;
    final subject = _subject;
    // Ghép trước để biết dòng phụ có nội dung hay không: dòng phụ rỗng vẫn
    // chiếm chỗ và làm các thẻ cao thấp không đều.
    final subtitle = [
      // Mốc thời gian đứng đầu dòng phụ: một quyển sổ không có ngày thì không tra
      // được "hôm qua con được bao nhiêu". Ghi `10/08 14:05` chứ không ghi cả năm
      // — gần như mọi dòng đều của năm nay, thêm năm chỉ chiếm chỗ.
      ngayGio(tx.createdAt),
      if (status == null && subject != null) _reasonLabel(tx.reason),
      if (tx.note != null) tx.note!,
      if (tx.byJar.length > 1)
        _jarBreakdown(
          tx.byJar,
          // Lần chia xu có hai chân bù nhau; hiện cả hai thành
          // "Tiêu 5, Chờ chia 5" làm người đọc tưởng có 10 xu.
          onlyPositive: tx.reason == 'jarTransfer',
        ),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // Cột trạng thái: icon + màu nói ngay việc/phiếu này đang thế
              // nào. Trước đây cột này chỉ nhắc lại lý do giao dịch, tức là
              // lặp lại thông tin đã có ở dòng chữ bên cạnh.
              Icon(
                status?.icon ?? _reasonIcon(tx.reason),
                color: status == null
                    ? context.semantic.onSurfaceMuted
                    : _toneColor(context, status.tone),
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject ?? _reasonLabel(tx.reason),
                      style: context.text.bodyMedium,
                    ),
                    if (subtitle.isNotEmpty || status != null)
                      Text.rich(
                        // Trạng thái trước, rồi lý do và chi tiết hũ. Trạng thái
                        // tô màu **và** có chữ: icon 22px một mình không đủ, và
                        // màu một mình cũng không đủ (WCAG 1.4.1 — không dùng
                        // màu hay hình làm phương tiện truyền đạt duy nhất).
                        TextSpan(
                          children: [
                            if (status != null)
                              TextSpan(
                                text: status.label,
                                style: context.text.bodySmall?.copyWith(
                                  color: _toneColor(context, status.tone),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (subtitle.isNotEmpty)
                              TextSpan(
                                text: status == null
                                    ? subtitle
                                    : ' · $subtitle',
                              ),
                          ],
                        ),
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.onSurfaceMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                // Chuyển hũ có delta 0: không cộng cũng không mất, nên không
                // dùng màu xanh hay đỏ — tô đỏ số 0 làm con tưởng bị trừ.
                switch (tx.delta) {
                  0 => '↔',
                  final d when d > 0 => '+$d',
                  final d => '$d',
                },
                style: context.text.titleSmall?.copyWith(
                  color: tx.delta == 0
                      ? context.semantic.onSurfaceMuted
                      : isPositive
                      ? context.semantic.success
                      : context.semantic.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Tiêu 5, Để dành 4, Cho đi 1" — gọn, không cần mở thêm.
  ///
  /// Thứ tự **cố định**, không theo thứ tự dòng trả về từ DB: thứ tự đổi giữa
  /// các mục làm sổ trông như dữ liệu lộn xộn, dù số vẫn đúng.
  String _jarBreakdown(Map<String, int> byJar, {bool onlyPositive = false}) {
    const order = ['spend', 'save', 'give'];
    final keys = [
      ...order.where(byJar.containsKey),
      // Hũ do bố mẹ tự lập (ADR-024) xếp sau, theo thứ tự chữ cái cho ổn định.
      ...byJar.keys.where((k) => !order.contains(k)).toList()..sort(),
    ];

    final parts = <String>[];
    for (final key in keys) {
      final value = byJar[key] ?? 0;
      if (value == 0) continue;
      // Với lần chia xu, chân trừ ở hũ chờ chỉ là mặt sau của chân cộng — hiện
      // cả hai thành "Tiêu 5, Chờ chia 5" làm người đọc tưởng có 10 xu.
      if (onlyPositive && value < 0) continue;
      parts.add('${_jarLabel(key)} ${value.abs()}');
    }
    return parts.join(', ');
  }

  /// Tên hũ để hiện trong sổ.
  ///
  /// Ưu tiên tên bố mẹ đặt trong bảng `jars`; ba hũ dựng sẵn có tên cố định để
  /// dòng cũ vẫn đọc được kể cả khi hũ đã bị xếp lại và đổi tên.
  String _jarLabel(String jarKey) {
    final title = widget.jarTitles[jarKey];
    if (title != null && title.isNotEmpty) return title;
    return switch (jarKey) {
      kJarSpend => 'Tiêu',
      kJarSave => 'Để dành',
      kJarGive => 'Cho đi',
      kJarInbox => 'Chờ chia',
      // Hũ đã bị xoá khỏi bảng bằng tay: thà hiện khoá còn hơn hiện chuỗi rỗng.
      _ => jarKey,
    };
  }

  IconData _reasonIcon(String reason) => switch (reason) {
    'taskApproved' => Icons.check_circle_outline,
    'routineBonus' => Icons.stars_rounded,
    'streakBonus' => Icons.local_fire_department,
    'rewardRedeemed' => Icons.card_giftcard,
    'rewardRefund' => Icons.replay,
    'manualAdjust' => Icons.edit,
    'bonus' => Icons.add_circle_outline,
    'penalty' => Icons.remove_circle_outline,
    'jarTransfer' => Icons.pie_chart_outline_rounded,
    _ => Icons.receipt_long,
  };

  String _reasonLabel(String reason) => switch (reason) {
    'taskApproved' => 'Hoàn thành việc',
    'routineBonus' => 'Thưởng trọn bộ',
    'streakBonus' => 'Thưởng liên tiếp',
    'rewardRedeemed' => 'Đổi thưởng',
    'rewardRefund' => 'Hoàn xu',
    'manualAdjust' => 'Điều chỉnh',
    'bonus' => 'Thưởng thêm',
    'penalty' => 'Trừ xu',
    'jarTransfer' => 'Con chia xu vào hũ',
    _ => reason,
  };
}
