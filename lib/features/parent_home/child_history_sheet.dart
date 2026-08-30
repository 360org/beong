import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/utils/ngay_viet.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/sheet_header.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:beong/domain/repositories/wallet_repository.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/features/parent_home/ngay_cua_con.dart';
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
                  child: SheetHeader(
                    title: 'Lịch sử: ${widget.child.displayName}',
                    subtitle: 'Thống kê công việc và tiến độ',
                  ),
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

          // Nội dung một ngày — **cùng một widget** với thẻ con ở Trang
          // chính. Hai chỗ dựng lại cùng bố cục bằng hai đoạn code khác nhau
          // là cách chắc chắn để chúng lệch nhau sau vài lần sửa.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                NgayCuaCon(
                  memberId: widget.child.id,
                  familyId: widget.child.familyId,
                  date: _selectedDate,
                  taskDao: widget.taskDao,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
