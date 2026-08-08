import 'dart:async';

import 'package:beong/core/l10n/gen/app_localizations.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/task_card.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final memberId = session.activeMemberId;
    final memberDao = ref.watch(memberDaoProvider);
    final walletDao = ref.watch(walletDaoProvider);
    final taskDao = ref.watch(taskDaoProvider);

    final today = FamilyClock(
      timeZoneOffset: DateTime.now().timeZoneOffset,
    ).today();

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<TaskInstance>>(
          stream: taskDao.watchInstancesForMember(
            memberId: memberId,
            date: today,
          ),
          builder: (context, instSnap) {
            final instances = instSnap.data ?? [];
            final total = instances.length;
            final completedCount = instances
                .where(
                  (i) =>
                      i.status == InstanceStatus.approved.name ||
                      i.status == InstanceStatus.pendingReview.name,
                )
                .length;

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingMobile,
                vertical: AppSpacing.lg,
              ),
              children: [
                StreamBuilder<Member>(
                  stream: memberDao.watchMember(memberId),
                  builder: (context, memberSnap) {
                    final member = memberSnap.data;
                    return _ChildHeader(member: member);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                StreamBuilder<WalletBalance>(
                  stream: walletDao.watchBalance(memberId),
                  builder: (context, balSnap) {
                    final balance = balSnap.data ?? WalletBalance.zero;
                    return StreamBuilder<Streak?>(
                      stream: memberDao.watchStreak(memberId),
                      builder: (context, streakSnap) {
                        return _DashboardCard(
                          points: balance.total,
                          streak: streakSnap.data?.currentLen ?? 0,
                          completed: completedCount,
                          total: total,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (instSnap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xxxl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (instances.isEmpty)
                  _EmptyState(
                    onGenerate: () async {
                      await taskDao.generateInstances(
                        familyId: session.familyId,
                        today: today,
                      );
                    },
                  )
                else
                  ..._buildTaskSections(instances, taskDao),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildTaskSections(
    List<TaskInstance> instances,
    TaskDao taskDao,
  ) {
    final scheduled = instances
        .where((i) => i.status == InstanceStatus.scheduled.name)
        .toList();
    final done = instances
        .where(
          (i) =>
              i.status == InstanceStatus.approved.name ||
              i.status == InstanceStatus.pendingReview.name,
        )
        .toList();
    final missed = instances
        .where((i) => i.status == InstanceStatus.missed.name)
        .toList();

    return [
      if (scheduled.isNotEmpty) ...[
        _SectionHeader(title: 'Cần làm', count: scheduled.length),
        const SizedBox(height: AppSpacing.sm),
        ...scheduled.map(
          (instance) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _InstanceCard(instance: instance, taskDao: taskDao),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
      if (done.isNotEmpty) ...[
        _SectionHeader(title: 'Đã xong', count: done.length),
        const SizedBox(height: AppSpacing.sm),
        ...done.map(
          (instance) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _InstanceCard(instance: instance, taskDao: taskDao),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
      if (missed.isNotEmpty) ...[
        _SectionHeader(title: 'Bỏ lỡ', count: missed.length),
        const SizedBox(height: AppSpacing.sm),
        ...missed.map(
          (instance) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _InstanceCard(instance: instance, taskDao: taskDao),
          ),
        ),
      ],
    ];
  }
}

class _ChildHeader extends StatelessWidget {
  const _ChildHeader({required this.member});

  final Member? member;

  @override
  Widget build(BuildContext context) {
    final member = this.member;
    final color = member == null
        ? context.colors.primary
        : AppColors.profileColor(member.colorIndex);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Text(
            avatarForKey(member?.avatarKey),
            style: const TextStyle(fontSize: 26),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          member?.displayName ?? '',
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.points,
    required this.streak,
    required this.completed,
    required this.total,
  });

  final int points;
  final int streak;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    // Danh hiệu chỉ hiện khi thật sự xong hết — `total > 0` chặn trường hợp
    // ngày chưa có việc nào cũng được khen.
    final allDone = total > 0 && completed == total;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: context.dashboardGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allDone)
            _BusyBeeBadge(label: L10n.of(context).badgeBusyBee)
          else
            Text(
              'DASHBOARD',
              style: context.text.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 1.2,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'ĐIỂM',
                  child: XuBadgeStat(amount: points),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  label: 'STREAK',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        '$streak',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  label: 'HÔM NAY',
                  child: Text(
                    '$completed/$total',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Danh hiệu "Ong chăm chỉ" — slogan của app dùng làm phần thưởng tinh thần
/// khi bé làm xong hết việc trong ngày.
class _BusyBeeBadge extends StatelessWidget {
  const _BusyBeeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.semantic.xu,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🐝', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B1046),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.child, required this.label});

  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Số điểm hiển thị trắng trên nền gradient — dùng emoji 💎 giống XuBadge
/// nhưng cỡ chữ lớn hơn cho thẻ dashboard.
class XuBadgeStat extends StatelessWidget {
  const XuBadgeStat({required this.amount, super.key});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('💎', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 4),
        Text(
          '$amount',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: context.text.titleSmall?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '$count',
            style: context.text.labelSmall?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InstanceCard extends StatefulWidget {
  const _InstanceCard({
    required this.instance,
    required this.taskDao,
  });

  final TaskInstance instance;
  final TaskDao taskDao;

  @override
  State<_InstanceCard> createState() => _InstanceCardState();
}

class _InstanceCardState extends State<_InstanceCard> {
  Task? _task;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTask());
  }

  Future<void> _loadTask() async {
    final task = await widget.taskDao.getTaskById(widget.instance.taskId);
    if (mounted) setState(() => _task = task);
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    if (task == null) return const SizedBox.shrink();

    return TaskCard(
      title: task.title,
      points: task.points,
      iconKey: task.iconKey,
      isCompleted: widget.instance.status == InstanceStatus.approved.name,
      isPending: widget.instance.status == InstanceStatus.pendingReview.name,
      isMissed: widget.instance.status == InstanceStatus.missed.name,
      onToggle: () => widget.taskDao.markCompleted(widget.instance.id),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Chưa có việc nào hôm nay',
              style: context.text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bấm nút bên dưới để tạo việc mới.',
              style: context.text.bodyMedium?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: onGenerate,
              child: const Text('TẠO VIỆC HÔM NAY'),
            ),
          ],
        ),
      ),
    );
  }
}
