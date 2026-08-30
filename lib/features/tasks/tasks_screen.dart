import 'dart:async';

import 'package:beong/app/router.dart';
import 'package:beong/core/l10n/gen/app_localizations.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/utils/ngay_viet.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/icon_picker.dart';
import 'package:beong/core/widgets/loi_man_hinh.dart';
import 'package:beong/core/widgets/preset_chip.dart';
import 'package:beong/core/widgets/sheet_header.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/presets.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/penalty_policy.dart';
import 'package:beong/features/tasks/routine_create_sheet.dart';
import 'package:beong/features/tasks/task_edit_sheet.dart';
import 'package:beong/features/tasks/task_row.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final taskDao = ref.watch(taskRepositoryProvider);
    final memberDao = ref.watch(memberRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          L10n.of(context).tasksTitle,
          style: context.text.titleLarge,
        ),
      ),
      body: _TaskList(
        familyId: session.familyId,
        taskDao: taskDao,
        memberDao: ref.watch(memberRepositoryProvider),
        isParent: session.isParent,
      ),
      floatingActionButton: session.isParent
          ? FloatingActionButton(
              tooltip: 'Thêm việc',
              // Nút "+" mở thẳng bảng thêm việc, không hỏi "thêm gì?" nữa.
              //
              // Bản trước hỏi vì nút này làm được hai thứ. Nhưng từ khi có
              // dòng "Tạo thêm thói quen" ở cuối danh sách buổi, đường tạo
              // buổi đã đứng đúng chỗ của nó — giữ thêm một câu hỏi ở đây là
              // bắt bố mẹ trả lời một câu họ đã trả lời bằng cách bấm vào đâu
              // (chủ dự án nêu 30/08/2026).
              onPressed: () async {
                final children = await memberDao.children(session.familyId);
                if (!context.mounted) return;
                final routines = await taskDao.activeRoutines(
                  session.familyId,
                );
                if (!context.mounted) return;
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => _AddTaskSheet(
                    taskDao: taskDao,
                    memberDao: memberDao,
                    familyId: session.familyId,
                    children: children,
                    routines: routines,
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _TaskList extends StatefulWidget {
  const _TaskList({
    required this.familyId,
    required this.taskDao,
    required this.memberDao,
    required this.isParent,
  });

  final String familyId;
  final TaskRepository taskDao;
  final MemberRepository memberDao;
  final bool isParent;

  @override
  State<_TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<_TaskList> {
  /// Hai stream tạo **một lần** và giữ trong field. Tạo trong `build()` thì mỗi
  /// lần dựng lại là một lần đăng ký mới: truy vấn chạy lại và danh sách nháy
  /// rỗng một khung hình.
  late final Stream<List<Task>> _taskStream = widget.taskDao.watchActiveTasks(
    widget.familyId,
  );
  late final Stream<List<Routine>> _routineStream = widget.taskDao
      .watchActiveRoutines(widget.familyId);

  /// Chỉnh xu ngay tại dòng việc.
  ///
  /// Ghi thẳng chứ không mở hộp thoại xác nhận: sai một bước 5 xu thì bấm nút
  /// bên cạnh là về, còn một hộp thoại cho mỗi lần bấm thì chỉnh từ 10 lên 25
  /// mất ba lần xác nhận.
  Future<void> _doiXu(Task task, int xuMoi) =>
      widget.taskDao.updateTask(taskId: task.id, points: xuMoi);

  /// Mở bảng tạo buổi thói quen mới.
  Future<void> _taoThoiQuen() async {
    final children = await widget.memberDao.children(widget.familyId);
    if (!mounted) return;
    await showRoutineCreateSheet(
      context,
      taskDao: widget.taskDao,
      familyId: widget.familyId,
      children: children,
    );
  }

  /// Sửa một việc đã tạo: tên, hình, xu, và buổi nó thuộc về.
  Future<void> _suaViec(Task task) async {
    final routines = await widget.taskDao.activeRoutines(widget.familyId);
    if (!mounted) return;
    await showTaskEditSheet(
      context,
      taskDao: widget.taskDao,
      task: task,
      routines: routines,
    );
  }

  /// Tạo nhiệm vụ ngay từ template, gán cho mọi bé trong nhà.
  ///
  /// Gán cho tất cả là mặc định đúng ở đây: bố mẹ đang ở trang trống, chưa nghĩ
  /// tới việc chia người. Sửa lại được ở màn chi tiết.
  Future<void> _createFromPreset(TaskPreset preset) async {
    final children = await widget.memberDao.children(widget.familyId);
    await widget.taskDao.createTask(
      TasksCompanion.insert(
        id: 'task-${preset.key}-${DateTime.now().millisecondsSinceEpoch}',
        familyId: widget.familyId,
        title: preset.titleVi,
        points: Value(preset.defaultPoints),
        iconKey: Value(preset.iconKey),
        presetKey: Value(preset.key),
      ),
      [for (final c in children) c.id],
    );
    // Sinh ngay instance cho hôm nay để việc mới hiện ngay trên hồ sơ con
    final today = FamilyClock(
      timeZoneOffset: DateTime.now().timeZoneOffset,
    ).today();
    await widget.taskDao.generateInstances(
      familyId: widget.familyId,
      today: today,
    );
    // Không cần nạp lại tay: `watchActiveTasks` tự phát lại.
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: _taskStream,
      builder: (context, taskSnap) {
        if (taskSnap.hasError) return LoiManHinh(error: taskSnap.error!);
        if (!taskSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<List<Routine>>(
          stream: _routineStream,
          builder: (context, routineSnap) => _buildList(
            context,
            taskSnap.data!,
            {
              for (final r in routineSnap.data ?? const <Routine>[]) r.id: r,
            },
          ),
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Task> allTasks,
    Map<String, Routine> routinesById,
  ) {
    if (allTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.checklist_rounded,
                size: 64,
                color: context.semantic.onSurfaceMuted,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Chưa có việc nào',
                style: context.text.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.isParent
                    ? 'Chọn nhanh một nhiệm vụ có sẵn, hoặc bấm + để tự tạo.'
                    : 'Bố mẹ chưa tạo nhiệm vụ.',
                style: context.text.bodyMedium?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.isParent) ...[
                const SizedBox(height: AppSpacing.xxxl),
                // Cùng lý do với màn Phần thưởng: 25 template đang bị chôn
                // trong bottom sheet sau nút "+", nên trang trống trông như
                // app không có gì. Đưa vài cái ra ngoài.
                _TaskPresetSuggestions(onPick: _createFromPreset),
              ],
            ],
          ),
        ),
      );
    }

    final routineTasks = <String, List<Task>>{};
    for (final task in allTasks) {
      // Việc lẻ không hiện ở đây nữa (30/08/2026). `DonViecLe.nhanNuoi` chạy
      // mỗi lần mở app và đưa chúng về buổi "Việc khác", nên chỗ này chỉ bỏ
      // qua phần còn sót giữa hai lần chạy — không phải giấu chúng đi.
      if (task.routineId == null) continue;
      routineTasks.putIfAbsent(task.routineId!, () => []).add(task);
    }

    return ListView(
      // Đệm đáy dư ra một khoảng: nút "+" nổi ở góc phải dưới **che mất thẻ việc
      // cuối cùng** nếu danh sách chỉ đệm bằng khoảng thường.
      padding: const EdgeInsets.only(
        left: AppSpacing.screenPaddingMobile,
        right: AppSpacing.screenPaddingMobile,
        top: AppSpacing.lg,
        bottom: AppSpacing.xxxl * 2,
      ),
      children: [
        if (routineTasks.isNotEmpty) ...[
          // "Routine" là chữ tiếng Anh duy nhất còn lọt vào UI. App cho gia đình
          // Việt thì nhãn phải là tiếng Việt, và onboarding đã gọi đây là "thói
          // quen" — hai chỗ phải dùng cùng một từ.
          Text('Thói quen', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...routineTasks.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _RoutineGroupCard(
                title: routinesById[entry.key]?.title ?? entry.key,
                iconKey: routinesById[entry.key]?.iconKey,
                tasks: entry.value,
                // Chỉ bố mẹ sửa được thói quen; con chỉ xem.
                onEdit: widget.isParent
                    ? () => context.go(Routes.routineEditor(entry.key))
                    : null,
                onEditTask: widget.isParent ? _suaViec : null,
                onPointsChanged: widget.isParent ? _doiXu : null,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        // Đường tạo buổi mới nằm ngay dưới danh sách buổi, không chỉ trong nút
        // "+" nổi: chủ dự án nêu 30/08/2026. Đứng ở đây thì nó nói được nó tạo
        // ra cái gì — một dòng nữa cùng loại với những thẻ ngay trên.
        if (widget.isParent)
          _ThemThoiQuenRow(onTap: () => unawaited(_taoThoiQuen())),
      ],
    );
  }
}

/// Dòng "Tạo thêm thói quen" đóng danh sách buổi.
class _ThemThoiQuenRow extends StatelessWidget {
  const _ThemThoiQuenRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      // Viền đứt: phân biệt "chỗ để thêm" với "thứ đã có". Cùng khối đặc như
      // thẻ buổi thì mắt đọc nó thành một buổi tên là "Tạo thêm thói quen".
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.card)),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.card)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(Icons.add_rounded, color: context.colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Tạo thêm thói quen',
                  style: context.text.titleSmall?.copyWith(
                    color: context.colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineGroupCard extends StatelessWidget {
  const _RoutineGroupCard({
    required this.title,
    required this.tasks,
    required this.iconKey,
    required this.onEdit,
    required this.onEditTask,
    required this.onPointsChanged,
  });

  final String title;
  final List<Task> tasks;
  final String? iconKey;

  /// `null` với vai con — thẻ vẫn hiện nhưng không bấm vào sửa được.
  final VoidCallback? onEdit;

  /// Sửa một việc bên trong buổi. `null` với vai con.
  final void Function(Task task)? onEditTask;

  /// Chỉnh xu ngay tại dòng. `null` với vai con.
  final void Function(Task task, int xuMoi)? onPointsChanged;

  @override
  Widget build(BuildContext context) {
    final sorted = List.of(tasks)
      ..sort((a, b) => (a.orderIndex ?? 0).compareTo(b.orderIndex ?? 0));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chỉ phần tiêu đề mở màn sửa buổi. Bọc `InkWell` quanh cả thẻ như
            // trước thì chạm vào một dòng việc lại nhảy sang sửa buổi — và tệ
            // hơn, hai nút −/+ nằm trong vùng chạm của nó.
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(AppRadius.field),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.field),
                    ),
                    child: AppIcon(iconKey ?? 'clipboard', size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${tasks.length} việc',
                      style: context.text.labelSmall?.copyWith(
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...sorted.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: TaskRow(
                  task: task,
                  onTap: onEditTask == null ? null : () => onEditTask!(task),
                  onPointsChanged: onPointsChanged == null
                      ? null
                      : (xu) => onPointsChanged!(task, xu),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({
    required this.taskDao,
    required this.memberDao,
    required this.familyId,
    required this.children,
    required this.routines,
  });

  final TaskRepository taskDao;
  final MemberRepository memberDao;
  final String familyId;
  final List<Member> children;

  /// Các buổi thói quen đang có. Việc mới **phải** vào một buổi (chủ dự án
  /// chốt 26/08/2026), nên danh sách rỗng nghĩa là chưa tạo được việc.
  final List<Routine> routines;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  String? _routineId;
  final _titleController = TextEditingController();
  final _pointsController = TextEditingController(text: '10');
  final _selectedChildren = <String>{};
  String? _selectedPreset;
  DayPart? _dayPart;

  @override
  void initState() {
    super.initState();
    for (final child in widget.children) {
      _selectedChildren.add(child.id);
    }
  }

  /// Icon của việc. Luôn có một giá trị — không có đường nào tạo ra việc không
  /// icon, vì thẻ việc của con đọc bằng hình trước khi đọc chữ.
  String _iconKey = kDefaultTaskIconKey;

  /// Mức trừ xu riêng cho việc này — ADR-022. `null` là theo mức chung.
  int? _penaltyPct;

  /// Việc này có cần bố mẹ duyệt riêng không — ADR-023.
  ///
  /// Chỉ có tác dụng khi gia đình **bật** duyệt: nhà tắt duyệt thì
  /// `needsApproval` không đọc tới giá trị này. Mặc định `manual` khớp default
  /// của cột trong DB.
  ApprovalMode _approval = ApprovalMode.manual;

  /// Chế độ bằng chứng khi làm việc (none / photo / note).
  ProofMode _proofMode = ProofMode.none;

  /// Lịch lặp. Mặc định hằng ngày — đúng với phần lớn việc nhà, và là hành vi
  /// duy nhất app có trước khi khối này tồn tại.
  RepeatType _repeat = RepeatType.daily;

  /// Thứ trong tuần khi [_repeat] là `custom`. 1 = thứ Hai … 7 = Chủ nhật, khớp
  /// `DateTime.weekday` để tầng lịch không phải quy đổi.
  final Set<int> _repeatDays = {};

  @override
  void dispose() {
    _titleController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  String _approvalLabel(ApprovalMode mode) => switch (mode) {
    ApprovalMode.auto => 'Xong là xong',
    ApprovalMode.manual => 'Bố mẹ duyệt',
  };

  String _proofModeLabel(ProofMode mode) => switch (mode) {
    ProofMode.none => 'Không cần',
    ProofMode.photo => 'Chụp ảnh 📸',
    ProofMode.note => 'Ghi chú ✍️',
  };

  String _repeatTypeLabel(RepeatType type) => switch (type) {
    RepeatType.daily => 'Hằng ngày',
    RepeatType.custom => 'Chọn thứ',
    RepeatType.once => 'Một lần',
  };

  String _dayPartLabel(DayPart part) => switch (part) {
    DayPart.morning => 'Sáng 🌅',
    DayPart.afternoon => 'Chiều ☀️',
    DayPart.evening => 'Tối 🌙',
  };

  void _stepPoints(int delta) {
    final current = int.tryParse(_pointsController.text.trim()) ?? 10;
    final next = (current + delta).clamp(1, 1000);
    setState(() {
      _pointsController.text = next.toString();
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final points = int.tryParse(_pointsController.text.trim()) ?? 10;
    final routineId = _routineId;
    // Việc không thuộc buổi nào thì không bé nào nhìn thấy nó
    // (`schedule.dart:148`) — chặn ở đây thay vì tạo ra một việc im lặng.
    if (title.isEmpty || routineId == null) return;

    final id = 'task-${DateTime.now().millisecondsSinceEpoch}';
    // `custom` mà không chọn thứ nào thì không sinh được lượt nào — việc tạo ra
    // sẽ không bao giờ xuất hiện. Coi như hằng ngày thay vì tạo một việc chết.
    final effectiveRepeat = _repeat == RepeatType.custom && _repeatDays.isEmpty
        ? RepeatType.daily
        : _repeat;

    await widget.taskDao.createTask(
      TasksCompanion.insert(
        id: id,
        familyId: widget.familyId,
        title: title,
        points: Value(points),
        presetKey: Value(_selectedPreset),
        iconKey: Value(_iconKey),
        approvalMode: Value(_approval.name),
        proofMode: Value(_proofMode.name),
        missedPenaltyPct: Value(_penaltyPct),
        repeatType: Value(effectiveRepeat.name),
        dayPart: Value(_dayPart?.name),
        repeatDays: Value(
          effectiveRepeat == RepeatType.custom
              ? (_repeatDays.toList()..sort()).join(',')
              : '',
        ),
        onceDate: Value(
          effectiveRepeat == RepeatType.once
              ? DateTime.now().toIso8601String().substring(0, 10)
              : null,
        ),
        routineId: Value(routineId),
      ),
      // Người nhận lấy từ buổi, không truyền ở đây: với việc trong buổi,
      // `schedulableTasks` đọc `RoutineAssignees` chứ không đọc `TaskAssignees`
      // (`task_dao.dart:151`). Ghi vào đây chỉ tạo ra một danh sách không ai
      // đọc — đúng loại dữ liệu chết dự án đã dọn nhiều lần.
      const [],
    );

    // Sinh ngay instance cho hôm nay để việc mới phản ánh ngay trên hồ sơ con
    final today = FamilyClock(
      timeZoneOffset: DateTime.now().timeZoneOffset,
    ).today();
    await widget.taskDao.generateInstances(
      familyId: widget.familyId,
      today: today,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.screenPaddingMobile,
              right: AppSpacing.screenPaddingMobile,
              top: AppSpacing.xl,
              bottom: AppSpacing.md,
            ),
            child: SheetHeader(title: 'Thêm việc mới'),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingMobile,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chọn nhanh mẫu việc', style: context.text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  _QuickPresetPicker(
                    selectedPreset: _selectedPreset,
                    onSelectPreset: (preset) {
                      setState(() {
                        if (_selectedPreset == preset.key) {
                          _selectedPreset = null;
                        } else {
                          _selectedPreset = preset.key;
                          _titleController.text = preset.titleVi;
                          _pointsController.text = preset.defaultPoints
                              .toString();
                          _iconKey = preset.iconKey;
                          _dayPart = preset.dayPart != null
                              ? DayPart.values.firstWhere(
                                  (d) => d.name == preset.dayPart,
                                  orElse: () => DayPart.morning,
                                )
                              : null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Tên việc'),
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Điểm thưởng', style: context.text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove_rounded),
                        tooltip: 'Giảm 5 xu',
                        onPressed: () => _stepPoints(-5),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _pointsController,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: 'Điểm',
                            suffixText: 'xu',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'Tăng 5 xu',
                        onPressed: () => _stepPoints(5),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Buổi trong ngày (tuỳ chọn)',
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      ChoiceChip(
                        label: const Text('Cả ngày'),
                        selected: _dayPart == null,
                        onSelected: (on) => setState(() => _dayPart = null),
                      ),
                      for (final part in DayPart.values)
                        ChoiceChip(
                          label: Text(_dayPartLabel(part)),
                          selected: _dayPart == part,
                          onSelected: (on) => setState(
                            () => _dayPart = on ? part : null,
                          ),
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
                  Text('Lặp lại', style: context.text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final type in RepeatType.values)
                        ChoiceChip(
                          label: Text(_repeatTypeLabel(type)),
                          selected: _repeat == type,
                          onSelected: (_) => setState(() => _repeat = type),
                        ),
                    ],
                  ),
                  if (_repeat == RepeatType.custom) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (var day = 1; day <= 7; day++)
                          FilterChip(
                            label: Text(thuNganGon(day)),
                            selected: _repeatDays.contains(day),
                            onSelected: (on) => setState(() {
                              if (on) {
                                _repeatDays.add(day);
                              } else {
                                _repeatDays.remove(day);
                              }
                            }),
                          ),
                      ],
                    ),
                    if (_repeatDays.isEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Chưa chọn thứ nào — việc sẽ lặp hằng ngày.',
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  // Không còn ô "Giao cho" ở đây: việc thuộc về một **buổi**,
                  // và buổi mới là thứ gán cho bé. Hỏi cả hai chỗ thì hai câu
                  // trả lời mâu thuẫn nhau được, mà chỉ một câu có tác dụng
                  // thật (`schedule.dart:151` đọc người nhận của buổi).
                  Text('Xếp vào buổi', style: context.text.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.routines.isEmpty
                        ? 'Chưa có buổi nào. Tạo một buổi trước rồi thêm việc vào.'
                        : 'Việc sẽ hiện với những bé đã được gán vào buổi này.',
                    style: context.text.bodySmall?.copyWith(
                      color: widget.routines.isEmpty
                          ? context.semantic.danger
                          : context.semantic.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: widget.routines.map((routine) {
                      return ChoiceChip(
                        avatar: AppIcon.task(routine.iconKey, size: 20),
                        label: Text(routine.title),
                        selected: _routineId == routine.id,
                        onSelected: (chon) => setState(
                          () => _routineId = chon ? routine.id : null,
                        ),
                      );
                    }).toList(),
                  ),
                  _PenaltyOverrideBlock(
                    familyId: widget.familyId,
                    memberDao: widget.memberDao,
                    value: _penaltyPct,
                    onChanged: (pct) => setState(() => _penaltyPct = pct),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Cần bố mẹ duyệt', style: context.text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final mode in ApprovalMode.values)
                        ChoiceChip(
                          label: Text(_approvalLabel(mode)),
                          selected: _approval == mode,
                          onSelected: (_) => setState(() => _approval = mode),
                        ),
                    ],
                  ),
                  StreamBuilder<bool>(
                    stream: widget.memberDao.watchRequireApproval(
                      widget.familyId,
                    ),
                    builder: (context, snap) {
                      if (snap.data ?? false) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'Nhà đang tắt duyệt nên con bấm xong là xong. '
                          'Bật trong Cài đặt thì lựa chọn này mới có tác dụng.',
                          style: context.text.bodySmall?.copyWith(
                            color: context.semantic.onSurfaceMuted,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Yêu cầu bằng chứng', style: context.text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final mode in ProofMode.values)
                        ChoiceChip(
                          label: Text(_proofModeLabel(mode)),
                          selected: _proofMode == mode,
                          onSelected: (_) => setState(() => _proofMode = mode),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
          // Nút LƯU cố định dính đáy (Sticky bottom)
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.screenPaddingMobile,
              right: AppSpacing.screenPaddingMobile,
              top: AppSpacing.md,
              bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: context.colors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Mờ đi khi chưa đủ điều kiện: nói trước còn hơn cho bấm rồi
                // im lặng không tạo ra gì.
                onPressed:
                    _routineId == null || _titleController.text.trim().isEmpty
                    ? null
                    : _save,
                child: const Text('LƯU'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vài template nhiệm vụ gợi ý ngay trên trang trống.
class _TaskPresetSuggestions extends StatelessWidget {
  const _TaskPresetSuggestions({required this.onPick});

  final Future<void> Function(TaskPreset) onPick;

  @override
  Widget build(BuildContext context) {
    final suggestions = kTaskPresets.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHỌN NHANH',
          style: context.text.labelSmall?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            for (final preset in suggestions)
              GestureDetector(
                onTap: () => unawaited(onPick(preset)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppRadius.field),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon.task(preset.iconKey, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        preset.titleVi,
                        style: context.text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${preset.defaultPoints}',
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.xuText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Mức trừ xu riêng cho một việc — ADR-022.
///
/// Chỉ hiện khi nhà **đang bật** trừ xu. Nhà tắt thì khối này không có tác dụng
/// gì, mà một ô cấu hình không có tác dụng còn tệ hơn không có ô nào: bố mẹ đặt
/// xong rồi tin là nó đang chạy.
class _PenaltyOverrideBlock extends StatelessWidget {
  const _PenaltyOverrideBlock({
    required this.familyId,
    required this.memberDao,
    required this.value,
    required this.onChanged,
  });

  final String familyId;
  final MemberRepository memberDao;

  /// `null` = theo mức chung của gia đình.
  final int? value;
  final ValueChanged<int?> onChanged;

  static const _choices = <int>[0, 25, 50, 100];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PenaltyPolicy>(
      stream: memberDao.watchPenaltyPolicy(familyId),
      builder: (context, snap) {
        final policy = snap.data;
        if (policy == null || !policy.isEnabled) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text('Bỏ việc này thì trừ', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: Text('Như cả nhà (${policy.missedPct}%)'),
                  selected: value == null,
                  onSelected: (_) => onChanged(null),
                ),
                for (final pct in _choices)
                  ChoiceChip(
                    // 0% đọc ra "không trừ việc này" rõ hơn hẳn con số 0 trần,
                    // và đó là lựa chọn bố mẹ hay cần nhất: một việc khó mà
                    // không muốn phạt.
                    label: Text(pct == 0 ? 'Không trừ' : '$pct%'),
                    selected: value == pct,
                    onSelected: (_) => onChanged(pct),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _QuickPresetPicker extends StatefulWidget {
  const _QuickPresetPicker({
    required this.selectedPreset,
    required this.onSelectPreset,
  });

  final String? selectedPreset;
  final ValueChanged<TaskPreset> onSelectPreset;

  @override
  State<_QuickPresetPicker> createState() => _QuickPresetPickerState();
}

class _QuickPresetPickerState extends State<_QuickPresetPicker> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const presets = kTaskPresets;
    final visible = _expanded ? presets : presets.take(8).toList();

    if (widget.selectedPreset != null &&
        !visible.any((p) => p.key == widget.selectedPreset)) {
      final selectedObj = presets.firstWhere(
        (p) => p.key == widget.selectedPreset,
      );
      visible.add(selectedObj);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: visible.map((preset) {
            final selected = widget.selectedPreset == preset.key;
            return PresetChip(
              iconKey: preset.iconKey,
              label: preset.titleVi,
              selected: selected,
              onTap: () => widget.onSelectPreset(preset),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(
            _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            size: 18,
          ),
          label: Text(
            _expanded
                ? 'Thu gọn'
                : 'Xem thêm mẫu việc (${presets.length - 8}+)',
            style: context.text.bodySmall?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
