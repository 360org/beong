import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final memberDao = ref.watch(memberDaoProvider);
    final walletDao = ref.watch(walletDaoProvider);

    if (session.isParent) {
      return _ParentStats(
        session: session,
        memberDao: memberDao,
        walletDao: walletDao,
      );
    }

    return _ChildStats(
      memberId: session.activeMemberId,
      walletDao: walletDao,
      memberDao: memberDao,
    );
  }
}

class _ParentStats extends StatelessWidget {
  const _ParentStats({
    required this.session,
    required this.memberDao,
    required this.walletDao,
  });

  final AppSession session;
  final MemberDao memberDao;
  final WalletDao walletDao;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thống kê', style: context.text.titleLarge),
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

class _ChildStatsCard extends StatelessWidget {
  const _ChildStatsCard({
    required this.child,
    required this.walletDao,
    required this.memberDao,
  });

  final Member child;
  final WalletDao walletDao;
  final MemberDao memberDao;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(child.displayName, style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<WalletBalance>(
          stream: walletDao.watchBalance(child.id),
          builder: (context, snap) {
            final balance = snap.data ?? WalletBalance.zero;
            return _JarOverview(balance: balance);
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
      ],
    );
  }
}

class _ChildStats extends StatelessWidget {
  const _ChildStats({
    required this.memberId,
    required this.walletDao,
    required this.memberDao,
  });

  final String memberId;
  final WalletDao walletDao;
  final MemberDao memberDao;

  @override
  Widget build(BuildContext context) {
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
            stream: walletDao.watchBalance(memberId),
            builder: (context, snap) {
              final balance = snap.data ?? WalletBalance.zero;
              return _JarOverview(balance: balance);
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
          StreamBuilder<Streak?>(
            stream: memberDao.watchStreak(memberId),
            builder: (context, snap) {
              final streak = snap.data;
              if (streak == null) return const SizedBox.shrink();
              return _StreakCard(streak: streak);
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Lịch sử', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          StreamBuilder<List<PointTransaction>>(
            stream: walletDao.watchHistory(memberId),
            builder: (context, snap) {
              final txns = snap.data ?? [];
              if (txns.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Center(
                    child: Text(
                      'Chưa có giao dịch nào.',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.semantic.onSurfaceMuted,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: txns.map((tx) => _TransactionTile(tx: tx)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _JarOverview extends StatelessWidget {
  const _JarOverview({required this.balance});

  final WalletBalance balance;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _JarCard(label: 'Tiêu', amount: balance.spend, jar: Jar.spend),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _JarCard(
            label: 'Để dành',
            amount: balance.save,
            jar: Jar.save,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _JarCard(label: 'Cho đi', amount: balance.give, jar: Jar.give),
        ),
      ],
    );
  }
}

class _JarCard extends StatelessWidget {
  const _JarCard({
    required this.label,
    required this.amount,
    required this.jar,
  });

  final String label;
  final int amount;
  final Jar jar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              _jarIcon(jar),
              color: context.colors.primary,
            ),
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
      ),
    );
  }

  IconData _jarIcon(Jar jar) => switch (jar) {
    Jar.spend => Icons.shopping_bag_rounded,
    Jar.save => Icons.savings_rounded,
    Jar.give => Icons.volunteer_activism_rounded,
  };
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

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final PointTransaction tx;

  @override
  Widget build(BuildContext context) {
    final isPositive = tx.delta > 0;

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
              Icon(
                _reasonIcon(tx.reason),
                color: context.semantic.onSurfaceMuted,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _reasonLabel(tx.reason),
                      style: context.text.bodyMedium,
                    ),
                    if (tx.note != null)
                      Text(
                        tx.note!,
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.onSurfaceMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}${tx.delta}',
                style: context.text.titleSmall?.copyWith(
                  color: isPositive
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

  IconData _reasonIcon(String reason) => switch (reason) {
    'taskApproved' => Icons.check_circle_outline,
    'routineBonus' => Icons.stars_rounded,
    'streakBonus' => Icons.local_fire_department,
    'rewardRedeemed' => Icons.card_giftcard,
    'rewardRefund' => Icons.replay,
    'manualAdjust' => Icons.edit,
    'bonus' => Icons.add_circle_outline,
    'penalty' => Icons.remove_circle_outline,
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
    _ => reason,
  };
}
