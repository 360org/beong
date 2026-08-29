import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/utils/ngay_viet.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:beong/domain/repositories/wallet_repository.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:flutter/material.dart';

/// Modal chi tiết thống kê và lịch sử vuốt ngang theo ngày/tuần phân theo 4 buổi.
class ChildHistoryModal extends StatefulWidget {
  const ChildHistoryModal({
    required this.child,
    required this.taskDao,
    required this.walletDao,
    required this.initialDate,
    super.key,
  });

  final Member child;
  final TaskRepository taskDao;
  final WalletRepository walletDao;
  final CalendarDate initialDate;

  static Future<void> show(
    BuildContext context, {
    required Member child,
    required TaskRepository taskDao,
    required WalletRepository walletDao,
    required CalendarDate initialDate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChildHistoryModal(
        child: child,
        taskDao: taskDao,
        walletDao: walletDao,
        initialDate: initialDate,
      ),
    );
  }

  @override
  State<ChildHistoryModal> createState() => _ChildHistoryModalState();
}

class _ChildHistoryModalState extends State<ChildHistoryModal> {
  late CalendarDate _selectedDate;
  int _dayOffset = 0; // 0 = Hôm nay, -1 = Hôm qua...

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  void _changeDate(int offsetDelta) {
    setState(() {
      _dayOffset += offsetDelta;
      final dt = DateTime(
        widget.initialDate.year,
        widget.initialDate.month,
        widget.initialDate.day,
      ).add(Duration(days: _dayOffset));
      _selectedDate = CalendarDate(dt.year, dt.month, dt.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.profileColor(widget.child.colorIndex);
    final media = MediaQuery.of(context);

    final dateLabel = switch (_dayOffset) {
      0 => 'Hôm nay',
      -1 => 'Hôm qua',
      1 => 'Ngày mai',
      final n when n < 0 => '${n.abs()} ngày trước',
      final n => '$n ngày tới',
    };

    return Container(
      height: media.size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(
                    iconKeyForEmoji(avatarForKey(widget.child.avatarKey)),
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lịch sử: ${widget.child.displayName}',
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Thống kê công việc và tiến độ',
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Đóng',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Thanh chọn ngày vuốt ngang
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _changeDate(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Ngày trước',
                  ),
                  Column(
                    children: [
                      Text(
                        '$dateLabel · ${ngayDayDu(_selectedDate)}',
                        style: context.text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _dayOffset < 7 ? () => _changeDate(1) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Ngày sau',
                  ),
                ],
              ),
            ),
          ),

          // Nội dung công việc theo 4 buổi trong ngày được chọn
          Expanded(
            child: StreamBuilder<List<TaskInstance>>(
              stream: widget.taskDao.watchInstancesForMember(
                memberId: widget.child.id,
                date: _selectedDate,
              ),
              builder: (context, snap) {
                final instances = snap.data ?? [];
                if (instances.isEmpty) {
                  return Center(
                    child: Text(
                      'Không có công việc nào trong ngày này',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.semantic.onSurfaceMuted,
                      ),
                    ),
                  );
                }

                return StreamBuilder<List<Task>>(
                  stream: widget.taskDao.watchActiveTasks(
                    widget.child.familyId,
                  ),
                  builder: (context, taskSnap) {
                    final allTasks = taskSnap.data ?? [];
                    final taskMap = {for (final t in allTasks) t.id: t};

                    // Phân nhóm việc theo buổi
                    final morningList = <TaskInstance>[];
                    final afternoonList = <TaskInstance>[];
                    final eveningList = <TaskInstance>[];
                    final anytimeList = <TaskInstance>[];

                    for (final inst in instances) {
                      final task = taskMap[inst.taskId];
                      final part = task?.dayPart;
                      if (part == 'morning') {
                        morningList.add(inst);
                      } else if (part == 'afternoon') {
                        afternoonList.add(inst);
                      } else if (part == 'evening') {
                        eveningList.add(inst);
                      } else {
                        anytimeList.add(inst);
                      }
                    }

                    final doneCount = instances
                        .where(
                          (i) =>
                              i.status == InstanceStatus.approved.name ||
                              i.status == InstanceStatus.pendingReview.name,
                        )
                        .length;

                    return ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        // Thẻ tóm tắt ngày
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: context.colors.primaryContainer.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _SummaryStat(
                                label: 'Tổng việc',
                                value: '${instances.length}',
                                color: context.colors.primary,
                              ),
                              _SummaryStat(
                                label: 'Đã hoàn thành',
                                value: '$doneCount',
                                color: context.semantic.success,
                              ),
                              _SummaryStat(
                                label: 'Tỷ lệ',
                                value:
                                    '${instances.isNotEmpty ? (doneCount * 100 ~/ instances.length) : 0}%',
                                color: context.colors.secondary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        if (morningList.isNotEmpty)
                          _SessionSection(
                            title: '🌅 Buổi Sáng',
                            instances: morningList,
                            taskMap: taskMap,
                          ),
                        if (afternoonList.isNotEmpty)
                          _SessionSection(
                            title: '☀️ Buổi Trưa / Chiều',
                            instances: afternoonList,
                            taskMap: taskMap,
                          ),
                        if (eveningList.isNotEmpty)
                          _SessionSection(
                            title: '🌙 Buổi Tối',
                            instances: eveningList,
                            taskMap: taskMap,
                          ),
                        if (anytimeList.isNotEmpty)
                          _SessionSection(
                            title: '🔄 Cả Ngày & Thói Quen',
                            instances: anytimeList,
                            taskMap: taskMap,
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: context.text.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: context.text.bodySmall?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}

class _SessionSection extends StatelessWidget {
  const _SessionSection({
    required this.title,
    required this.instances,
    required this.taskMap,
  });

  final String title;
  final List<TaskInstance> instances;
  final Map<String, Task> taskMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final inst in instances) ...[
            _TaskInstanceRow(
              instance: inst,
              task: taskMap[inst.taskId],
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _TaskInstanceRow extends StatelessWidget {
  const _TaskInstanceRow({
    required this.instance,
    required this.task,
  });

  final TaskInstance instance;
  final Task? task;

  @override
  Widget build(BuildContext context) {
    final isDone = instance.status == InstanceStatus.approved.name;
    final isPending = instance.status == InstanceStatus.pendingReview.name;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDone
            ? context.semantic.success.withValues(alpha: 0.15)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          AppIcon.task(task?.iconKey ?? 'star', size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              task?.title ?? 'Nhiệm vụ',
              style: context.text.bodyMedium?.copyWith(
                fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (isDone)
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 20,
            )
          else if (isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Chờ duyệt',
                style: TextStyle(fontSize: 11, color: Colors.amber),
              ),
            )
          else
            XuBadge(amount: instance.pointsSnapshot, pill: true),
        ],
      ),
    );
  }
}
