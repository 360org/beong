import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/icon_picker.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/data/local/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Đặt hoặc đổi mục tiêu tiết kiệm cho một trẻ.
///
/// Trả `true` nếu có thay đổi (đặt mới hoặc bỏ), `null`/`false` nếu bố mẹ đóng
/// sheet mà không làm gì.
Future<bool?> showGoalSheet(
  BuildContext context, {
  required String familyId,
  required String memberId,
  required String childName,
  SavingsGoal? current,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _GoalSheet(
        familyId: familyId,
        memberId: memberId,
        childName: childName,
        current: current,
      ),
    ),
  );
}

class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet({
    required this.familyId,
    required this.memberId,
    required this.childName,
    required this.current,
  });

  final String familyId;
  final String memberId;
  final String childName;
  final SavingsGoal? current;

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.current?.title ?? '',
  );
  late int _target = widget.current?.targetXu ?? 100;
  late String _iconKey = widget.current?.iconKey ?? kDefaultGoalIconKey;
  bool _busy = false;

  /// Bước tăng/giảm. 10 xu cho mục tiêu vài trăm xu thì bấm mỏi tay, nên bước
  /// to hơn hẳn bước của phần thưởng.
  static const _step = 50;

  @override
  void initState() {
    super.initState();
    // Nút LƯU bật/tắt theo ô tên — thiếu listener này thì gõ tên xong nút vẫn
    // xám, đúng lỗi đã gặp ở sheet hũ và sheet phần thưởng.
    _title.addListener(_onTitleChanged);
  }

  void _onTitleChanged() => setState(() {});

  @override
  void dispose() {
    _title
      ..removeListener(_onTitleChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    await ref
        .read(goalDaoProvider)
        .setGoal(
          familyId: widget.familyId,
          memberId: widget.memberId,
          title: _title.text,
          targetXu: _target,
          iconKey: _iconKey,
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    await ref.read(goalDaoProvider).abandonActive(widget.memberId);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_busy && _title.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.current == null ? 'Mục tiêu để dành' : 'Đổi mục tiêu',
            style: context.text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${widget.childName} để dành đủ số xu này là tới đích. '
            'Xu vẫn nằm trong hũ Để dành, app không trừ đi.',
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Chọn hình', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          IconPickerGrid(
            iconKeys: kGoalIconKeys,
            selected: _iconKey,
            onSelected: (key) => setState(() => _iconKey = key),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Con muốn gì', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Bộ Lego cảnh sát',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Cần bao nhiêu xu', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Bớt 50 xu',
                // Chặn ở đúng một bước: mục tiêu 0 xu thì tới đích ngay lúc
                // đặt, và thanh tiến độ không có gì để nói.
                onPressed: _target > _step
                    ? () => setState(() => _target -= _step)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 120,
                child: Center(child: XuBadge(amount: _target, large: true)),
              ),
              IconButton.filledTonal(
                tooltip: 'Thêm 50 xu',
                onPressed: () => setState(() => _target += _step),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSave ? _save : null,
              child: const Text('LƯU'),
            ),
          ),
          if (widget.current != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _busy ? null : _remove,
                style: TextButton.styleFrom(
                  foregroundColor: context.semantic.danger,
                ),
                child: const Text('BỎ MỤC TIÊU'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
