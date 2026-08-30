import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/utils/ngay_viet.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/icon_picker.dart';
import 'package:beong/core/widgets/sheet_header.dart';
import 'package:beong/core/widgets/thong_bao.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/task_repository.dart';
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
    final taskDao = ref.read(taskRepositoryProvider);
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
        .read(taskRepositoryProvider)
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
    await ref.read(taskRepositoryProvider).detachTaskFromRoutine(task.id);
    if (!mounted) return;
    hienThongBao(
      context,
      'Đã bỏ "${task.title}" khỏi thói quen',
      hanhDong: SnackBarAction(
        // Bỏ nhầm là chuyện thường; hoàn tác rẻ hơn nhiều so với hỏi xác nhận
        // mỗi lần bỏ.
        label: 'Hoàn tác',
        onPressed: () => unawaited(_attach(task)),
      ),
    );
    await _load();
  }

  Future<void> _attach(Task task) async {
    await ref
        .read(taskRepositoryProvider)
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
          'Các việc bên trong vẫn còn, chuyển sang buổi "Việc khác".',
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

    await ref.read(taskRepositoryProvider).archiveRoutine(widget.routineId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _editInfo(Routine routine) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final children = await ref
        .read(memberRepositoryProvider)
        .children(session.familyId);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _RoutineInfoSheet(
          routine: routine,
          taskDao: ref.read(taskRepositoryProvider),
          children: children,
          onNgungDung: () => unawaited(_confirmArchive(routine)),
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
  const _RoutineInfoSheet({
    required this.routine,
    required this.taskDao,
    required this.children,
    required this.onNgungDung,
  });

  final Routine routine;
  final TaskRepository taskDao;
  final List<Member> children;

  /// Mở hộp xác nhận ngừng dùng. Nằm ở màn cha vì sau khi ngừng dùng thì phải
  /// **thoát cả màn**, không chỉ đóng bảng này.
  final VoidCallback onNgungDung;

  @override
  State<_RoutineInfoSheet> createState() => _RoutineInfoSheetState();
}

class _RoutineInfoSheetState extends State<_RoutineInfoSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.routine.title,
  );
  late String _iconKey = widget.routine.iconKey ?? kDefaultTaskIconKey;
  late int _bonus = widget.routine.completionBonus;

  /// Bé nào đang được giao buổi này. Nạp sau, nên khởi đầu là rỗng và ô chọn
  /// bị khoá cho tới khi biết — chứ không hiện "chưa chọn bé nào" khi chưa đọc
  /// xong, vì đó là lời nói dối gây hoảng.
  Set<String>? _nguoiNhan;

  @override
  void initState() {
    super.initState();
    _title.addListener(_onChanged);
    unawaited(_napNguoiNhan());
  }

  Future<void> _napNguoiNhan() async {
    final ids = await widget.taskDao.routineAssigneesOf(widget.routine.id);
    if (mounted) setState(() => _nguoiNhan = ids.toSet());
  }

  void _onChanged() => setState(() {});

  String _moTaNguoiNhan() {
    final nguoiNhan = _nguoiNhan;
    if (nguoiNhan == null) return 'Đang đọc...';
    if (nguoiNhan.isEmpty) {
      // Buổi không giao cho ai thì `schedulableTasks` bỏ qua **toàn bộ** việc
      // trong đó (`schedule.dart:148`): buổi có mà không bé nào thấy việc.
      return 'Chưa chọn bé nào — buổi này sẽ không hiện với ai cả.';
    }
    return 'Buổi này chỉ hiện với bé đã chọn.';
  }

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
    final nguoiNhan = _nguoiNhan;
    if (nguoiNhan != null) {
      await widget.taskDao.setRoutineAssignees(
        routineId: widget.routine.id,
        memberIds: nguoiNhan.toList(),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // Cuộn được + nút LƯU dính đáy.
      //
      // Bản cũ là một `Column` không cuộn, và `kTaskIconKeys` có **125 hình**.
      // Lưới hình đẩy nút LƯU xuống dưới mép màn hình, không cuộn tới được:
      // ảnh chủ dự án gửi 30/08/2026 thấy đúng cảnh đó — sửa xong không có
      // cách nào lưu. Nút phải nằm ngoài vùng cuộn thì mới luôn với tới được,
      // dù nội dung dài bao nhiêu.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetHeader(title: 'Sửa thói quen'),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Tên thói quen',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Chọn hình', style: context.text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  // Lưới rút gọn kèm đường mở kho đầy đủ, giống bảng tạo buổi.
                  // Đổ thẳng 125 hình ra đây là bắt bố mẹ cuộn qua chúng mỗi
                  // lần chỉ muốn sửa cái tên.
                  IconPickerGrid(
                    iconKeys: kTaskIconKeys,
                    selected: _iconKey,
                    onSelected: (key) => setState(() => _iconKey = key),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Giao cho bé nào', style: context.text.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _moTaNguoiNhan(),
                    style: context.text.bodySmall?.copyWith(
                      color: (_nguoiNhan?.isEmpty ?? false)
                          ? context.semantic.danger
                          : context.semantic.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final child in widget.children)
                        FilterChip(
                          label: Text(child.displayName),
                          selected: _nguoiNhan?.contains(child.id) ?? false,
                          // Chưa nạp xong thì khoá: cho bấm lúc này là bấm vào
                          // một danh sách rỗng giả, và cú bấm đó sẽ ghi đè
                          // người nhận thật khi bấm LƯU.
                          onSelected: _nguoiNhan == null
                              ? null
                              : (chon) => setState(() {
                                  if (chon) {
                                    _nguoiNhan!.add(child.id);
                                  } else {
                                    _nguoiNhan!.remove(child.id);
                                  }
                                }),
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
                        : 'Con làm xong hết việc trong thói quen thì được thêm '
                              '$_bonus xu.',
                    style: context.text.bodySmall?.copyWith(
                      color: context.semantic.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _title.text.trim().isEmpty
                        ? null
                        : () => unawaited(_save()),
                    child: const Text('LƯU'),
                  ),
                ),
                // Đường ngừng dùng cũng có ở nút trên thanh tiêu đề, nhưng ở
                // đó nó là một biểu tượng không nhãn — chủ dự án tìm không ra
                // (30/08/2026). Ở đây nó có chữ, và nằm đúng chỗ người ta đang
                // sửa buổi.
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onNgungDung();
                  },
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Ngừng dùng buổi này'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.semantic.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
