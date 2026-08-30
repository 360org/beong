import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/icon_picker.dart';
import 'package:beong/core/widgets/sheet_header.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:flutter/material.dart';

/// Sửa một việc đã tạo.
///
/// Trước v0.3.2 việc tạo xong là **không sửa được gì**: thẻ việc không có
/// `onTap`, không `InkWell`, không vuốt. Đặt sai tên hay sai xu thì cách duy
/// nhất là tạo việc mới — và việc cũ vẫn nằm đó, tiếp tục sinh lượt mỗi ngày.
///
/// Đổi buổi cũng nằm ở đây: đó là cách một việc còn sót ngoài buổi tìm được
/// chỗ ở, và cũng là cách chuyển một việc từ buổi sáng sang buổi tối mà không
/// phải xoá đi làm lại.
Future<bool?> showTaskEditSheet(
  BuildContext context, {
  required TaskRepository taskDao,
  required Task task,
  required List<Routine> routines,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _TaskEditSheet(
        taskDao: taskDao,
        task: task,
        routines: routines,
      ),
    ),
  );
}

class _TaskEditSheet extends StatefulWidget {
  const _TaskEditSheet({
    required this.taskDao,
    required this.task,
    required this.routines,
  });

  final TaskRepository taskDao;
  final Task task;
  final List<Routine> routines;

  @override
  State<_TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<_TaskEditSheet> {
  late final _titleController = TextEditingController(text: widget.task.title);
  late String _iconKey = widget.task.iconKey ?? kTaskIconKeys.first;
  late int _points = widget.task.points;
  late String? _routineId = widget.task.routineId;
  bool _busy = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _luu() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _routineId == null) return;
    setState(() => _busy = true);
    await widget.taskDao.updateTask(
      taskId: widget.task.id,
      title: title,
      iconKey: _iconKey,
      points: _points,
      routineId: _routineId,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _ngungDung() async {
    final chac = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ngừng dùng việc này?'),
        content: Text(
          'Bé sẽ không nhận "${widget.task.title}" từ ngày mai nữa. '
          'Những lần con đã làm và số xu đã nhận vẫn giữ nguyên trong Sổ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ngừng dùng'),
          ),
        ],
      ),
    );
    if (chac != true || !mounted) return;
    await widget.taskDao.setTaskActive(taskId: widget.task.id, active: false);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final coTheLuu =
        !_busy && _titleController.text.trim().isNotEmpty && _routineId != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              title: 'Sửa việc',
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Ngừng dùng việc này',
                  onPressed: _busy ? null : _ngungDung,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            Text('Tên việc', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _titleController,
              maxLength: 60,
              onChanged: (_) => setState(() {}),
            ),

            Text('Điểm thưởng', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.remove_rounded),
                  tooltip: 'Bớt 5 xu',
                  onPressed: _points <= 0
                      ? null
                      : () => setState(
                          () => _points = (_points - 5).clamp(0, _points),
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text('$_points xu', style: context.text.titleMedium),
                const SizedBox(width: AppSpacing.md),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Thêm 5 xu',
                  onPressed: () => setState(() => _points += 5),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            Text('Chọn hình', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            IconPickerGrid(
              iconKeys: kTaskIconKeys,
              selected: _iconKey,
              onSelected: (key) => setState(() => _iconKey = key),
            ),

            const SizedBox(height: AppSpacing.lg),
            Text('Xếp vào buổi', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _routineId == null
                  ? 'Việc chưa thuộc buổi nào nên chưa bé nào nhìn thấy.'
                  : 'Việc hiện với những bé đã được gán vào buổi này.',
              style: context.text.bodySmall?.copyWith(
                color: _routineId == null
                    ? context.semantic.danger
                    : context.semantic.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final routine in widget.routines)
                  ChoiceChip(
                    avatar: AppIcon.task(routine.iconKey, size: 20),
                    label: Text(routine.title),
                    selected: _routineId == routine.id,
                    onSelected: (chon) => setState(
                      () => _routineId = chon ? routine.id : null,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: coTheLuu ? _luu : null,
                child: const Text('LƯU'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
