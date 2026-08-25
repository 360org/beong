import 'dart:async';

import 'package:beong/app/router.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/family_clock_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/loi_man_hinh.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/reward_repository.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:beong/domain/repositories/wallet_repository.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/task_review_service.dart';
import 'package:beong/features/members/mat_khau_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final memberDao = ref.watch(memberRepositoryProvider);
    final taskDao = ref.watch(taskRepositoryProvider);
    final walletDao = ref.watch(walletRepositoryProvider);
    final reviewService = ref.watch(taskReviewServiceProvider);

    Future<void> switchMember(Member member) async {
      final hopLe = await hoiMatKhau(
        context,
        memberId: member.id,
        tenHienThi: member.displayName,
        service: ref.read(matKhauHoSoProvider),
        moTa: 'Bốn chữ số của ${member.displayName}',
      );
      if (!hopLe || !context.mounted) return;

      await ref
          .read(sessionProvider.notifier)
          .switchMember(
            member.id,
            isParent: member.kind == MemberKind.parent.name,
          );
      if (context.mounted) context.go('/');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Trang chính', style: context.text.titleLarge),
      ),
      body: StreamBuilder<List<Member>>(
        stream: memberDao.watchMembers(session.familyId),
        builder: (context, membersSnap) {
          // Không có thành viên nào **có thể** là lỗi luồng chứ không phải nhà
          // trống: rơi về rỗng lặng lẽ thì bố mẹ tưởng hồ sơ con bị mất.
          if (membersSnap.hasError) {
            return LoiManHinh(error: membersSnap.error!);
          }
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
                reviewService: reviewService,
                reviewerId: session.activeMemberId,
              ),
              _PendingRedemptionBanner(familyId: session.familyId),
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
                    reviewService: reviewService,
                    reviewerId: session.activeMemberId,
                    onTapProfile: () => unawaited(switchMember(child)),
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

/// Nhắc bố mẹ có phiếu đổi thưởng đang chờ.
///
/// Hàng chờ phiếu nằm ở tab **Phần thưởng**, đúng về mặt phân loại, nhưng bố mẹ
/// mở app là vào Trang chính — không có dòng này thì họ **không biết** có việc
/// cần mình, và con thì cứ chờ. Chỉ hiện khi thật sự có phiếu chờ, để trang chính
/// không thêm một dòng luôn nằm đó mà chẳng nói gì.
class _PendingRedemptionBanner extends ConsumerWidget {
  const _PendingRedemptionBanner({required this.familyId});

  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Redemption>>(
      stream: ref
          .watch(rewardRepositoryProvider)
          .watchPendingRedemptions(familyId),
      builder: (context, snap) {
        final count = snap.data?.length ?? 0;
        if (count == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Card(
            color: context.colors.primaryContainer,
            child: InkWell(
              onTap: () => context.go(Routes.rewards),
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    const AppIcon('jar_gift', size: 26),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        count == 1
                            ? 'Con xin đổi 1 phần thưởng'
                            : 'Con xin đổi $count phần thưởng',
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
          ),
        );
      },
    );
  }
}

class _PendingReviewSection extends StatefulWidget {
  const _PendingReviewSection({
    required this.familyId,
    required this.taskDao,
    required this.walletDao,
    required this.reviewService,
    required this.reviewerId,
  });

  final String familyId;
  final TaskRepository taskDao;
  final WalletRepository walletDao;
  final TaskReviewService reviewService;
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

  /// Duyệt cả hàng đợi. Xác nhận trước vì đây là thao tác cộng xu cho nhiều
  /// việc cùng lúc và không có nút hoàn tác.
  Future<void> _approveAll() async {
    final count = _pending.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duyệt tất cả?'),
        content: Text('$count việc sẽ được duyệt và cộng xu cho con.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Thôi'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Duyệt hết'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final done = await widget.reviewService.approveAll(
      familyId: widget.familyId,
      reviewerId: widget.reviewerId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã duyệt $done việc.')));
    await _load();
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
              const AppIcon('book'),
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
        const SizedBox(height: AppSpacing.sm),
        if (_pending.length > 1)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _approveAll,
              icon: const Icon(Icons.done_all_rounded, size: 20),
              label: Text('Duyệt tất cả (${_pending.length})'),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
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
              reviewService: widget.reviewService,
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
    required this.reviewService,
    required this.reviewerId,
    required this.onActioned,
    super.key,
  });

  final TaskInstance instance;
  final TaskRepository taskDao;
  final WalletRepository walletDao;
  final TaskReviewService reviewService;
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

  /// Bố mẹ phát hiện con bấm xong nhưng chưa làm — ADR-022.
  Future<void> _reopen() async {
    final result = await widget.reviewService.reopen(
      instanceId: widget.instance.id,
      reviewerId: widget.reviewerId,
    );
    if (!mounted) return;

    // Nói rõ đã trừ bao nhiêu. Xu biến mất mà không ai giải thích là đúng thứ
    // làm trẻ mất niềm tin vào app.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.xuDeducted > 0
              ? 'Đã mở lại việc. Trừ ${result.xuDeducted} xu.'
              : 'Đã mở lại việc cho con làm lại.',
        ),
      ),
    );
    widget.onActioned();
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    if (task == null) return const SizedBox.shrink();

    final proofUrl = widget.instance.proofUrl;
    final proofNote = widget.instance.proofNote;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    await widget.reviewService.reject(
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
                IconButton(
                  onPressed: _reopen,
                  icon: Icon(
                    Icons.replay_rounded,
                    color: context.semantic.warning,
                  ),
                  // "Chưa làm" chứ không phải "Từ chối": từ chối là đóng lượt lại,
                  // còn mở lại là trả việc về cho con làm tiếp.
                  tooltip: 'Chưa làm — mở lại',
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filled(
                  onPressed: () async {
                    // Cộng xu và thưởng trọn bộ routine nằm trong service, không
                    // rải ở UI: đường tự động duyệt cũng phải chạy đúng logic đó.
                    await widget.reviewService.approve(
                      instanceId: widget.instance.id,
                      reviewerId: widget.reviewerId,
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
            if (proofNote != null && proofNote.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        proofNote,
                        style: context.text.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (proofUrl != null && proofUrl.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.photo_camera_rounded, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Đã chụp ảnh bằng chứng: $proofUrl',
                        style: context.text.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChildSummaryCard extends ConsumerWidget {
  const _ChildSummaryCard({
    required this.child,
    required this.taskDao,
    required this.walletDao,
    required this.reviewService,
    required this.reviewerId,
    required this.onTapProfile,
  });

  final Member child;
  final TaskRepository taskDao;
  final WalletRepository walletDao;
  final TaskReviewService reviewService;
  final String reviewerId;
  final VoidCallback onTapProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.profileColor(child.colorIndex);

    final today =
        (ref.watch(familyClockProvider(child.familyId)).value ??
                fallbackFamilyClock())
            .today();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTapProfile,
              borderRadius: BorderRadius.circular(AppRadius.card),
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
                    child: AppIcon(
                      iconKeyForEmoji(avatarForKey(child.avatarKey)),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              child.displayName,
                              style: context.text.titleMedium,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: context.semantic.onSurfaceMuted,
                            ),
                          ],
                        ),
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
                                      i.status ==
                                          InstanceStatus.approved.name ||
                                      i.status ==
                                          InstanceStatus.pendingReview.name,
                                )
                                .length;
                            return Text(
                              '$done / ${instances.length} việc hôm nay · Chạm để vào hồ sơ',
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
            const SizedBox(height: AppSpacing.xs),
            _IncompleteTodayList(
              memberId: child.id,
              date: today,
              taskDao: taskDao,
            ),
            _DoneTodayList(
              memberId: child.id,
              date: today,
              taskDao: taskDao,
              reviewService: reviewService,
              reviewerId: reviewerId,
            ),
          ],
        ),
      ),
    );
  }
}

/// Việc con chưa xong hôm nay, mở ra xem chi tiết.
class _IncompleteTodayList extends StatelessWidget {
  const _IncompleteTodayList({
    required this.memberId,
    required this.date,
    required this.taskDao,
  });

  final String memberId;
  final CalendarDate date;
  final TaskRepository taskDao;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskInstance>>(
      stream: taskDao.watchInstancesForMember(memberId: memberId, date: date),
      builder: (context, snap) {
        final all = snap.data ?? const <TaskInstance>[];
        final pending = all
            .where((i) => i.status == InstanceStatus.scheduled.name)
            .toList();
        if (pending.isEmpty) return const SizedBox.shrink();

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              'Chưa hoàn thành (${pending.length})',
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
            children: pending
                .map(
                  (instance) => _IncompleteRow(
                    key: ValueKey(instance.id),
                    instance: instance,
                    taskDao: taskDao,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _IncompleteRow extends StatefulWidget {
  const _IncompleteRow({
    required this.instance,
    required this.taskDao,
    super.key,
  });

  final TaskInstance instance;
  final TaskRepository taskDao;

  @override
  State<_IncompleteRow> createState() => _IncompleteRowState();
}

class _IncompleteRowState extends State<_IncompleteRow> {
  Task? _task;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTask());
  }

  @override
  void didUpdateWidget(_IncompleteRow oldWidget) {
    super.didUpdateWidget(oldWidget);
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          AppIcon.task(task.iconKey, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(task.title, style: context.text.bodyMedium)),
          Text(
            '+${task.points} xu',
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.xuText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Việc con đã xong hôm nay, thu gọn lại, mỗi việc có nút mở lại.
class _DoneTodayList extends StatelessWidget {
  const _DoneTodayList({
    required this.memberId,
    required this.date,
    required this.taskDao,
    required this.reviewService,
    required this.reviewerId,
  });

  final String memberId;
  final CalendarDate date;
  final TaskRepository taskDao;
  final TaskReviewService reviewService;
  final String reviewerId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskInstance>>(
      stream: taskDao.watchApprovedForMember(memberId: memberId, date: date),
      builder: (context, snap) {
        final done = snap.data ?? const <TaskInstance>[];
        if (done.isEmpty) return const SizedBox.shrink();

        return Theme(
          // Bỏ đường kẻ của ExpansionTile để nó không cắt ngang thẻ.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              'Đã xong hôm nay (${done.length})',
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
            children: done
                .map(
                  (instance) => _DoneRow(
                    // Cùng lý do với hàng đợi duyệt: thiếu key thì State bị
                    // tái dùng theo vị trí và hàng hiện tên việc cũ.
                    key: ValueKey(instance.id),
                    instance: instance,
                    taskDao: taskDao,
                    reviewService: reviewService,
                    reviewerId: reviewerId,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _DoneRow extends StatefulWidget {
  const _DoneRow({
    required this.instance,
    required this.taskDao,
    required this.reviewService,
    required this.reviewerId,
    super.key,
  });

  final TaskInstance instance;
  final TaskRepository taskDao;
  final TaskReviewService reviewService;
  final String reviewerId;

  @override
  State<_DoneRow> createState() => _DoneRowState();
}

class _DoneRowState extends State<_DoneRow> {
  Task? _task;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTask());
  }

  @override
  void didUpdateWidget(_DoneRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instance.taskId != widget.instance.taskId) {
      unawaited(_loadTask());
    }
  }

  Future<void> _loadTask() async {
    final task = await widget.taskDao.getTaskById(widget.instance.taskId);
    if (mounted) setState(() => _task = task);
  }

  Future<void> _reopen() async {
    final result = await widget.reviewService.reopen(
      instanceId: widget.instance.id,
      reviewerId: widget.reviewerId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.xuDeducted > 0
              ? 'Đã mở lại việc. Trừ ${result.xuDeducted} xu.'
              : 'Đã mở lại việc cho con làm lại.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    if (task == null) return const SizedBox.shrink();

    return Row(
      children: [
        AppIcon.task(task.iconKey, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(task.title, style: context.text.bodyMedium)),
        if (widget.instance.reopenCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Text(
              'làm lại ${widget.instance.reopenCount}x',
              style: context.text.labelSmall?.copyWith(
                color: context.semantic.warning,
              ),
            ),
          ),
        IconButton(
          onPressed: _reopen,
          icon: Icon(Icons.replay_rounded, color: context.semantic.warning),
          tooltip: 'Chưa làm — mở lại',
        ),
      ],
    );
  }
}
