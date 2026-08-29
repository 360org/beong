import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:flutter/material.dart';

/// Một dòng việc, dùng **chung** cho mọi chỗ liệt kê việc ở màn bố mẹ.
///
/// Trước v0.3.2 có hai hình thức cho cùng một thứ: việc trong buổi vẽ thành
/// dòng gọn bên trong thẻ nhóm, việc lẻ vẽ thành thẻ riêng có avatar tròn và
/// nhãn "Hằng ngày". Cùng là một việc nhà mà mắt phải học hai lần, và chỉ một
/// trong hai bấm vào sửa được.
///
/// Nút −/+ chỉnh xu ngay tại dòng: màn gán việc mẫu đã cho chỉnh kiểu đó từ
/// lâu, còn ở đây thì phải mở hẳn một màn khác — cùng một việc, hai cách sửa,
/// bố mẹ phải nhớ đi đường nào.
class TaskRow extends StatelessWidget {
  const TaskRow({
    required this.task,
    required this.onTap,
    required this.onPointsChanged,
    super.key,
  });

  final Task task;

  /// `null` với vai con — dòng vẫn hiện nhưng không sửa được.
  final VoidCallback? onTap;

  /// `null` thì ẩn hẳn cặp nút −/+ thay vì hiện nút bấm không ăn.
  final ValueChanged<int>? onPointsChanged;

  /// Xu nhảy theo bước 5: giá trị này gần như luôn là bội của 5, và bước 1 thì
  /// bấm mười lần mới đi được từ 10 lên 20.
  static const _buoc = 5;

  @override
  Widget build(BuildContext context) {
    final doiXu = onPointsChanged;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            AppIcon.task(task.iconKey, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(task.title, style: context.text.bodyMedium)),
            if (doiXu == null)
              XuBadge(amount: task.points, pill: true)
            else ...[
              _NutXu(
                icon: Icons.remove_rounded,
                // Xu không xuống dưới 0 — một việc thưởng số âm là thứ không
                // giải thích được cho trẻ con.
                onPressed: task.points <= 0
                    ? null
                    : () => doiXu(
                        (task.points - _buoc).clamp(0, task.points),
                      ),
                tooltip: 'Bớt xu',
              ),
              SizedBox(
                width: 56,
                child: Center(
                  child: XuBadge(amount: task.points, pill: true),
                ),
              ),
              _NutXu(
                icon: Icons.add_rounded,
                onPressed: () => doiXu(task.points + _buoc),
                tooltip: 'Thêm xu',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NutXu extends StatelessWidget {
  const _NutXu({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      // Vùng chạm giữ đủ 48dp dù hình nhỏ — ngón tay người lớn cũng trượt khi
      // hai nút nằm sát nhau.
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minTouchTarget,
        minHeight: AppSpacing.minTouchTarget,
      ),
    );
  }
}
