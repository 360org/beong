import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/utils/ngay_viet.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sửa một routine: tên, hình, xu thưởng trọn bộ, lịch lặp, và **thứ tự việc**.
///
/// Trước màn này tab Nhiệm vụ chỉ **xem** được routine. Bố mẹ tạo "Buổi sáng" từ
/// onboarding rồi muốn bỏ một việc hay đổi thứ tự thì không có đường nào.
///
/// Thứ tự việc là **nội dung**, không phải chuyện hiển thị: "Buổi sáng" mà đánh
/// răng trước khi ăn sáng là sai quy trình, và trẻ nhỏ làm đúng theo thứ tự nhìn
/// thấy.
class RoutineEditorScreen extends ConsumerStatefulWidget {
  const RoutineEditorScreen({required this.routineId, super.key});

  final String routineId;

  @override
  ConsumerState<RoutineEditorScreen> createState() =>
      _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  Routine? _routine;
  List<Task> _tasks = const [];
  bool _loaded = false;

  /// Thứ tự đang kéo thả, chưa ghi xuống DB.
  ///
  /// Giữ riêng thay vì ghi ngay mỗi lần thả: `ReorderableListView` gọi callback
  /// giữa lúc animation chạy, ghi DB ngay sẽ làm stream phát lại và danh sách
  /// nhảy về giữa chừng.
  List<Task> _draftOrder = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final taskDao = ref.read(taskDaoProvider);
    final session = ref.read(sessionProvider);
    if (session == null) return;

    final routines = await taskDao.activeRoutines(session.familyId);
    final all = await taskDao.activeTasks(session.familyId);
    if (!mounted) return;

    setState(() {
      _routine = routines.where((r) => r.id == widget.routineId).firstOrNull;
      _tasks = all;
      _draftOrder = all.where((t) => t.routineId == widget.routineId).toList()
        ..sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));
      _loaded = true;
    });
  }

  Future<void> _saveOrder() async {
    await ref
        .read(taskDaoProvider)
        .reorderRoutineTasks(
          routineId: widget.routineId,
          taskIds: [for (final t in _draftOrder) t.id],
        );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final routine = _routine;
    if (routine == null) {
      // Routine bị ngừng dùng ở màn khác trong lúc màn này đang mở.
      return Scaffold(
        appBar: AppBar(title: const Text('Thói quen')),
        body: const Center(child: Text('Thói quen này không còn nữa.')),
      );
    }

    final outside = _tasks
        .where((t) => t.routineId == null)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(routine.title),
        actions: [
          IconButton(
            tooltip: 'Ngừng dùng',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => unawaited(_confirmArchive(routine)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          left: AppSpacing.screenPaddingMobile,
          right: AppSpacing.screenPaddingMobile,
          top: AppSpacing.lg,
          bottom: AppSpacing.xxxl,
        ),
        children: [
          _RoutineHeaderCard(
            routine: routine,
            onEdit: () => unawaited(_editInfo(routine)),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Thứ tự việc',
                  style: context.text.titleMedium,
                ),
              ),
              Text(
                '${_draftOrder.length} việc',
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Giữ và kéo để đổi thứ tự. Con làm theo đúng thứ tự này.',
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_draftOrder.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'Chưa có việc nào trong thói quen này.',
                style: context.text.bodyMedium?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              // `onReorderItem` chứ không phải `onReorder`: bản cũ báo chỉ số
              // **trước khi** gỡ phần tử ra nên kéo xuống phải tự trừ 1 — một
              // phép trừ ai cũng quên và lỗi thì lệch đúng một ô, rất khó thấy.
              // `onReorderItem` đã chỉnh sẵn.
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final moved = _draftOrder.removeAt(oldIndex);
                  _draftOrder = [..._draftOrder]..insert(newIndex, moved);
                });
                unawaited(_saveOrder());
              },
              children: [
                for (var i = 0; i < _draftOrder.length; i++)
                  _RoutineTaskTile(
                    key: ValueKey(_draftOrder[i].id),
                    index: i,
                    task: _draftOrder[i],
                    onRemove: () => unawaited(_detach(_draftOrder[i])),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Thêm việc lẻ vào đây', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            outside.isEmpty
                ? 'Không còn việc lẻ nào.'
                : 'Bấm để đưa việc vào cuối thói quen.',
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final task in outside)
                ActionChip(
                  avatar: AppIcon.task(task.iconKey, size: 20),
                  label: Text(task.title),
                  onPressed: () => unawaited(_attach(task)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _detach(Task task) async {
    await ref.read(taskDaoProvider).detachTaskFromRoutine(task.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã bỏ "${task.title}" khỏi thói quen'),
        action: SnackBarAction(
          // Bỏ nhầm là chuyện thường; hoàn tác rẻ hơn nhiều so với hỏi xác nhận
          // mỗi lần bỏ.
          label: 'Hoàn tác',
          onPressed: () => unawaited(_attach(task)),
        ),
      ),
    );
    await _load();
  }

  Future<void> _attach(Task task) async {
    await ref
        .read(taskDaoProvider)
        .attachTaskToRoutine(taskId: task.id, routineId: widget.routineId);
    await _load();
  }

  Future<void> _confirmArchive(Routine routine) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ngừng dùng thói quen?'),
        // Nói rõ **việc không mất**: bố mẹ ngại bấm vì sợ mất luôn cả việc bên
        // trong, và nỗi sợ đó là hợp lý nếu không ai nói gì.
        content: Text(
          '"${routine.title}" sẽ không hiện nữa. '
          'Các việc bên trong vẫn còn, chuyển thành việc lẻ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ngừng dùng'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await ref.read(taskDaoProvider).archiveRoutine(widget.routineId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _editInfo(Routine routine) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _RoutineInfoSheet(
          routine: routine,
          taskDao: ref.read(taskDaoProvider),
        ),
      ),
    );
    await _load();
  }
}

class _RoutineHeaderCard extends StatelessWidget {
  const _RoutineHeaderCard({required this.routine, required this.onEdit});

  final Routine routine;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final repeat = routine.repeatType == RepeatType.custom.name
        ? thuTuChuoi(routine.repeatDays) ?? 'Chưa chọn thứ'
        : 'Hằng ngày';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            AppIcon.task(routine.iconKey, size: 34),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(routine.title, style: context.text.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    repeat,
                    style: context.text.bodySmall?.copyWith(
                      color: context.semantic.onSurfaceMuted,
                    ),
                  ),
                  if (routine.completionBonus > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          'Xong trọn bộ thưởng thêm ',
                          style: context.text.bodySmall?.copyWith(
                            color: context.semantic.onSurfaceMuted,
                          ),
                        ),
                        XuBadge(amount: routine.completionBonus),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Sửa',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineTaskTile extends StatelessWidget {
  const _RoutineTaskTile({
    required this.index,
    required this.task,
    required this.onRemove,
    super.key,
  });

  final int index;
  final Task task;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Số thứ tự: cách duy nhất để thấy thứ tự đã đổi đúng chưa mà
              // không phải đếm bằng mắt.
              SizedBox(
                width: 22,
                child: Text(
                  '${index + 1}',
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.onSurfaceMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppIcon.task(task.iconKey),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(task.title)),
              XuBadge(amount: task.points),
              IconButton(
                tooltip: 'Bỏ khỏi thói quen',
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onRemove,
              ),
              // Tay cầm riêng thay vì kéo cả thẻ: cả thẻ kéo được thì bấm nút
              // "bỏ" hay cuộn trang đều dễ thành thao tác kéo nhầm.
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Icon(Icons.drag_handle_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineInfoSheet extends StatefulWidget {
  const _RoutineInfoSheet({required this.routine, required this.taskDao});

  final Routine routine;
  final TaskDao taskDao;

  @override
  State<_RoutineInfoSheet> createState() => _RoutineInfoSheetState();
}

class _RoutineInfoSheetState extends State<_RoutineInfoSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.routine.title,
  );
  late String _iconKey = widget.routine.iconKey ?? kDefaultTaskIconKey;
  late int _bonus = widget.routine.completionBonus;

  @override
  void initState() {
    super.initState();
    _title.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _title
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.taskDao.updateRoutine(
      routineId: widget.routine.id,
      title: _title.text,
      iconKey: _iconKey,
      completionBonus: _bonus,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sửa thói quen', style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Tên thói quen'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Chọn hình', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final key in kTaskIconKeys)
                GestureDetector(
                  onTap: () => setState(() => _iconKey = key),
                  child: Container(
                    width: AppSpacing.minTouchTarget,
                    height: AppSpacing.minTouchTarget,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: key == _iconKey
                          ? context.colors.primaryContainer
                          : context.colors.surfaceContainerHighest,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppRadius.field),
                      ),
                      border: key == _iconKey
                          ? Border.all(color: context.colors.primary, width: 2)
                          : null,
                    ),
                    child: AppIcon(key, size: 26),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Thưởng khi làm trọn bộ: $_bonus xu',
            style: context.text.titleSmall,
          ),
          Slider(
            value: _bonus.toDouble(),
            max: 50,
            divisions: 10,
            label: '$_bonus xu',
            onChanged: (v) => setState(() => _bonus = v.round()),
          ),
          Text(
            _bonus == 0
                ? 'Đang tắt — con không được thưởng thêm khi xong cả bộ.'
                : 'Con làm xong hết việc trong thói quen thì được thêm $_bonus xu.',
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _title.text.trim().isEmpty
                  ? null
                  : () => unawaited(_save()),
              child: const Text('LƯU'),
            ),
          ),
        ],
      ),
    );
  }
}
