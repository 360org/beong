import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';

/// Lưới chọn icon, dùng chung cho việc / phần thưởng / mục tiêu.
///
/// Mặc định hiển thị một hàng icon (kèm icon đang chọn nếu nó nằm ngoài hàng đầu),
/// và nút "Xem thêm (N hình)" để mở rộng toàn bộ bảng chọn (§8).
class IconPickerGrid extends StatefulWidget {
  const IconPickerGrid({
    required this.iconKeys,
    required this.selected,
    required this.onSelected,
    this.initialCount = 6,
    super.key,
  });

  final List<String> iconKeys;
  final String selected;
  final ValueChanged<String> onSelected;
  final int initialCount;

  @override
  State<IconPickerGrid> createState() => _IconPickerGridState();
}

class _IconPickerGridState extends State<IconPickerGrid> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final keys = widget.iconKeys;
    final total = keys.length;
    final initialCount = widget.initialCount;

    // Nếu số icon ít hơn ngưỡng, luôn hiện đủ không cần nút toggle.
    final needsExpand = total > initialCount;

    List<String> visibleKeys;
    if (!_expanded && needsExpand) {
      final sub = keys.take(initialCount).toList();
      // Đảm bảo icon đang chọn luôn xuất hiện trong danh sách hiển thị
      if (widget.selected.isNotEmpty &&
          !sub.contains(widget.selected) &&
          keys.contains(widget.selected)) {
        sub.add(widget.selected);
      }
      visibleKeys = sub;
    } else {
      visibleKeys = keys;
    }

    final hiddenCount = total - visibleKeys.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final key in visibleKeys)
              _IconChoice(
                iconKey: key,
                selected: key == widget.selected,
                onTap: () => widget.onSelected(key),
              ),
          ],
        ),
        if (needsExpand) ...[
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 18,
            ),
            label: Text(
              _expanded ? 'Thu gọn' : 'Xem thêm ($hiddenCount hình)',
              style: context.text.bodySmall?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.iconKey,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? context.colors.primaryContainer
                : context.colors.surfaceContainerHighest,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.field),
            ),
            // Viền chứ không chỉ đổi màu nền: nền đậm nhạt một chút thì người
            // không phân biệt màu tốt sẽ không thấy ô nào đang chọn
            // (WCAG 1.4.1).
            border: selected
                ? Border.all(color: context.colors.primary, width: 2)
                : null,
          ),
          child: AppIcon(iconKey, size: 26),
        ),
      ),
    );
  }
}
