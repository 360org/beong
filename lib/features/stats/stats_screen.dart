import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/reward_dao.dart';
import 'package:beong/data/local/task_dao.dart';
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
    final taskDao = ref.watch(taskDaoProvider);
    final rewardDao = ref.watch(rewardDaoProvider);

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
      taskDao: taskDao,
      rewardDao: rewardDao,
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
    required this.taskDao,
    required this.rewardDao,
  });

  final String memberId;
  final WalletDao walletDao;
  final MemberDao memberDao;
  final TaskDao taskDao;
  final RewardDao rewardDao;

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
          StreamBuilder<List<LedgerEntry>>(
            // Đã gộp: một việc là **một** mục, không phải ba dòng theo hũ.
            stream: walletDao.watchGroupedHistory(memberId),
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
                children: [
                  for (final tx in txns)
                    _TransactionTile(
                      // Key theo nhóm: thiếu key thì State bị tái dùng theo vị
                      // trí và dòng hiện tên của giao dịch cũ.
                      key: ValueKey(tx.groupId),
                      tx: tx,
                      taskDao: taskDao,
                      rewardDao: rewardDao,
                    ),
                ],
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
    super.key,
  });

  final LedgerEntry tx;
  final TaskDao taskDao;
  final RewardDao rewardDao;

  @override
  State<_TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<_TransactionTile> {
  String? _subject;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSubject());
  }

  @override
  void didUpdateWidget(_TransactionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tx.refId != widget.tx.refId) unawaited(_loadSubject());
  }

  /// Tra tên của thứ giao dịch này nói về.
  ///
  /// Không tra được thì để `null` và chỉ hiện nhãn theo lý do — dữ liệu cũ hoặc
  /// việc đã bị xoá không được làm dòng lịch sử biến mất.
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

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final isPositive = tx.delta > 0;
    final subject = _subject;

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
                      subject ?? _reasonLabel(tx.reason),
                      style: context.text.bodyMedium,
                    ),
                    Text(
                      // Dòng phụ: lý do + chi tiết hũ. Trẻ thấy được 10 xu đã
                      // chia đi đâu mà không phải mở thêm màn nào.
                      [
                        if (subject != null) _reasonLabel(tx.reason),
                        if (tx.note != null) tx.note!,
                        if (tx.byJar.length > 1) _jarBreakdown(tx.byJar),
                      ].join(' · '),
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

  /// "Tiêu 5, Để dành 4, Cho đi 1" — gọn, không cần mở thêm.
  ///
  /// Thứ tự **cố định**, không theo thứ tự dòng trả về từ DB: thứ tự đổi giữa
  /// các mục làm sổ trông như dữ liệu lộn xộn, dù số vẫn đúng.
  String _jarBreakdown(Map<String, int> byJar) {
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
      parts.add('${_jarLabel(key)} ${value.abs()}');
    }
    return parts.join(', ');
  }

  String _jarLabel(String jarKey) => switch (jarKey) {
    'spend' => 'Tiêu',
    'save' => 'Để dành',
    'give' => 'Cho đi',
    // Hũ do bố mẹ tự lập (ADR-024): chưa tra được tên nên hiện khoá.
    _ => jarKey,
  };

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
