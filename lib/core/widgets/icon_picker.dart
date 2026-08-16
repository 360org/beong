import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';

/// Lưới chọn icon, dùng chung cho việc / phần thưởng / mục tiêu.
///
/// Trước đây mỗi màn tự chép một bản `_IconChoice` giống hệt nhau; bản thứ ba
/// là lúc phải gộp lại. Chép tiếp thì sửa cách thể hiện "ô đang chọn" ở một chỗ
/// sẽ lệch với hai chỗ kia.
class IconPickerGrid extends StatelessWidget {
  const IconPickerGrid({
    required this.iconKeys,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> iconKeys;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final key in iconKeys)
          _IconChoice(
            iconKey: key,
            selected: key == selected,
            onTap: () => onSelected(key),
          ),
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
