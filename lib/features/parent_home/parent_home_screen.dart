import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
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
        title: Text('Trang chính', style: context.text.titleLarge),
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
              Text('Con của bạn', style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              ...children.map(
                (child) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ChildSummaryCard(
                    child: child,
                    taskDao: taskDao,
                    walletDao: walletDao,
                  ),
                ),
              ),
              if (children.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Text(
                      'Chưa thêm bé nào.',
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
    unawaited(_load());
  }

  Future<void> _load() async {
    final pending = await widget.taskDao.pendingReview(widget.familyId);
    if (mounted) {
      setState(() {
        _pending = pending;
        _loaded = true;
      });
    }
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
              const Text('📖', style: TextStyle(fontSize: 22)),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Không có việc nào chờ duyệt',
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
            Text('Chờ duyệt', style: context.text.titleMedium),
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
        ..._pending.map(
          (instance) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _PendingCard(
              // Key theo id: không có key, Flutter tái dùng State theo vị trí
              // khi hàng đợi duyệt ngắn lại và thẻ hiện tên của việc cũ.
              key: ValueKey(instance.id),
              instance: instance,
              taskDao: widget.taskDao,
              walletDao: widget.walletDao,
              reviewerId: widget.reviewerId,
              onActioned: _load,
            ),
          ),
        ),
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
    super.key,
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
    unawaited(_loadTask());
  }

  @override
  void didUpdateWidget(_PendingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Xem chú thích cùng loại ở `_InstanceCardState`.
    if (oldWidget.instance.taskId != widget.instance.taskId) {
      unawaited(_loadTask());
    }
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
                      color: context.semantic.xuText,
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
              tooltip: 'Từ chối',
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
              tooltip: 'Duyệt',
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
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Text(
                avatarForKey(child.avatarKey),
                style: const TextStyle(fontSize: 24),
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
                          .where(
                            (i) =>
                                i.status == InstanceStatus.approved.name ||
                                i.status == InstanceStatus.pendingReview.name,
                          )
                          .length;
                      return Text(
                        '$done / ${instances.length} việc hôm nay',
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
