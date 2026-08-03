import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final memberDao = ref.watch(memberDaoProvider);
    final taskDao = ref.watch(taskDaoProvider);
    final walletDao = ref.watch(walletDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Trang chinh', style: context.text.titleLarge),
      ),
      body: StreamBuilder<List<Member>>(
        stream: memberDao.watchMembers(session.familyId),
        builder: (context, membersSnap) {
          final members = membersSnap.data ?? [];
          final children = members
              .where((m) => m.kind == MemberKind.child.name)
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingMobile,
              vertical: AppSpacing.lg,
            ),
            children: [
              _PendingReviewSection(
                familyId: session.familyId,
                taskDao: taskDao,
                walletDao: walletDao,
                reviewerId: session.activeMemberId,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Con cua ban', style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              ...children.map((child) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ChildSummaryCard(
                      child: child,
                      taskDao: taskDao,
                      walletDao: walletDao,
                    ),
                  )),
              if (children.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Text(
                      'Chua them be nao.',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.semantic.onSurfaceMuted,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PendingReviewSection extends StatefulWidget {
  const _PendingReviewSection({
    required this.familyId,
    required this.taskDao,
    required this.walletDao,
    required this.reviewerId,
  });

  final String familyId;
  final TaskDao taskDao;
  final WalletDao walletDao;
  final String reviewerId;

  @override
  State<_PendingReviewSection> createState() => _PendingReviewSectionState();
}

class _PendingReviewSectionState extends State<_PendingReviewSection> {
  List<TaskInstance> _pending = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pending = await widget.taskDao.pendingReview(widget.familyId);
    if (mounted) setState(() { _pending = pending; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    if (_pending.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: context.semantic.success,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Khong co viec nao cho duyet',
                style: context.text.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Cho duyet', style: context.text.titleMedium),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: context.semantic.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '${_pending.length}',
                style: context.text.labelSmall?.copyWith(
                  color: context.semantic.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ..._pending.map((instance) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PendingCard(
                instance: instance,
                taskDao: widget.taskDao,
                walletDao: widget.walletDao,
                reviewerId: widget.reviewerId,
                onActioned: _load,
              ),
            )),
      ],
    );
  }
}

class _PendingCard extends StatefulWidget {
  const _PendingCard({
    required this.instance,
    required this.taskDao,
    required this.walletDao,
    required this.reviewerId,
    required this.onActioned,
  });

  final TaskInstance instance;
  final TaskDao taskDao;
  final WalletDao walletDao;
  final String reviewerId;
  final VoidCallback onActioned;

  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard> {
  Task? _task;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    final task = await widget.taskDao.getTaskById(widget.instance.taskId);
    if (mounted) setState(() => _task = task);
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    if (task == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: context.text.bodyLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '+${task.points} xu',
                    style: context.text.bodySmall?.copyWith(
                      color: context.semantic.xu,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                await widget.taskDao.reject(
                  instanceId: widget.instance.id,
                  reviewerId: widget.reviewerId,
                );
                widget.onActioned();
              },
              icon: Icon(
                Icons.close_rounded,
                color: context.semantic.danger,
              ),
              tooltip: 'Tu choi',
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton.filled(
              onPressed: () async {
                await widget.taskDao.approve(
                  instanceId: widget.instance.id,
                  reviewerId: widget.reviewerId,
                );
                await widget.walletDao.credit(
                  familyId: widget.instance.familyId,
                  memberId: widget.instance.memberId,
                  amount: task.points,
                  reason: TxReason.taskApproved,
                  clientOpId: 'task-approved:${widget.instance.id}',
                );
                await widget.taskDao.checkAndAwardRoutineBonus(
                  instanceId: widget.instance.id,
                  familyId: widget.instance.familyId,
                );
                widget.onActioned();
              },
              icon: const Icon(Icons.check_rounded),
              style: IconButton.styleFrom(
                backgroundColor: context.semantic.success,
                foregroundColor: Colors.white,
              ),
              tooltip: 'Duyet',
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildSummaryCard extends StatelessWidget {
  const _ChildSummaryCard({
    required this.child,
    required this.taskDao,
    required this.walletDao,
  });

  final Member child;
  final TaskDao taskDao;
  final WalletDao walletDao;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.profileColor(child.colorIndex);

    final today = FamilyClock(
      timeZoneOffset: DateTime.now().timeZoneOffset,
    ).today();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 24,
              child: Text(
                child.displayName.isNotEmpty
                    ? child.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(child.displayName, style: context.text.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  StreamBuilder<List<TaskInstance>>(
                    stream: taskDao.watchInstancesForMember(
                      memberId: child.id,
                      date: today,
                    ),
                    builder: (context, snap) {
                      final instances = snap.data ?? [];
                      final done = instances
                          .where((i) =>
                              i.status == InstanceStatus.approved.name ||
                              i.status == InstanceStatus.pendingReview.name)
                          .length;
                      return Text(
                        '$done / ${instances.length} viec hom nay',
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.onSurfaceMuted,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            StreamBuilder<WalletBalance>(
              stream: walletDao.watchBalance(child.id),
              builder: (context, snap) {
                final balance = snap.data ?? WalletBalance.zero;
                return XuBadge(amount: balance.total);
              },
            ),
          ],
        ),
      ),
    );
  }
}
