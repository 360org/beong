import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/task_card.dart';
import 'package:beong/core/widgets/xu_badge.dart';
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
    final walletDao = ref.watch(walletDaoProvider);
    final taskDao = ref.watch(taskDaoProvider);

    final today = FamilyClock(
      timeZoneOffset: DateTime.now().timeZoneOffset,
    ).today();

    return Scaffold(
      appBar: AppBar(
        title: Text('Viec cua con', style: context.text.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: StreamBuilder<WalletBalance>(
              stream: walletDao.watchBalance(memberId),
              builder: (context, snap) {
                final balance = snap.data ?? WalletBalance.zero;
                return XuBadge(amount: balance.total);
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<TaskInstance>>(
        stream: taskDao.watchInstancesForMember(
          memberId: memberId,
          date: today,
        ),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final instances = snap.data ?? [];
          if (instances.isEmpty) {
            return _EmptyState(
              onGenerate: () async {
                await taskDao.generateInstances(
                  familyId: session.familyId,
                  today: today,
                );
              },
            );
          }

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

          final total = instances.length;
          final completedCount = done.length;

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingMobile,
              vertical: AppSpacing.lg,
            ),
            children: [
              _ProgressHeader(
                completed: completedCount,
                total: total,
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (scheduled.isNotEmpty) ...[
                _SectionHeader(title: 'Can lam', count: scheduled.length),
                const SizedBox(height: AppSpacing.sm),
                ...scheduled.map(
                  (instance) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _InstanceCard(
                      instance: instance,
                      taskDao: taskDao,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (done.isNotEmpty) ...[
                _SectionHeader(title: 'Da xong', count: done.length),
                const SizedBox(height: AppSpacing.sm),
                ...done.map(
                  (instance) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _InstanceCard(
                      instance: instance,
                      taskDao: taskDao,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (missed.isNotEmpty) ...[
                _SectionHeader(title: 'Bo lo', count: missed.length),
                const SizedBox(height: AppSpacing.sm),
                ...missed.map(
                  (instance) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _InstanceCard(
                      instance: instance,
                      taskDao: taskDao,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completed / $total viec',
                  style: context.text.titleMedium,
                ),
                if (completed == total && total > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: context.semantic.success,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Hoan thanh!',
                      style: context.text.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: context.colors.outlineVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completed == total && total > 0
                      ? context.semantic.success
                      : context.colors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
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
            Icon(
              Icons.task_alt_rounded,
              size: 64,
              color: context.semantic.onSurfaceMuted,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Chua co viec nao hom nay',
              style: context.text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bam nut ben duoi de tao viec moi.',
              style: context.text.bodyMedium?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: onGenerate,
              child: const Text('TAO VIEC HOM NAY'),
            ),
          ],
        ),
      ),
    );
  }
}
