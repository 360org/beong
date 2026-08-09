import 'dart:async';

import 'package:beong/core/l10n/gen/app_localizations.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/preset_chip.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/seed/presets.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final taskDao = ref.watch(taskDaoProvider);
    final memberDao = ref.watch(memberDaoProvider);

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
        memberDao: ref.watch(memberDaoProvider),
        isParent: session.isParent,
      ),
      floatingActionButton: session.isParent
          ? FloatingActionButton(
              onPressed: () async {
                final children = await memberDao.children(session.familyId);
                if (!context.mounted) return;
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => _AddTaskSheet(
                    taskDao: taskDao,
                    familyId: session.familyId,
                    children: children,
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
  final TaskDao taskDao;
  final MemberDao memberDao;
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
    // Không cần nạp lại tay: `watchActiveTasks` tự phát lại.
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: _taskStream,
      builder: (context, taskSnap) {
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
    final standaloneTasks = <Task>[];

    for (final task in allTasks) {
      if (task.routineId != null) {
        routineTasks.putIfAbsent(task.routineId!, () => []).add(task);
      } else {
        standaloneTasks.add(task);
      }
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
          Text('Routine', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...routineTasks.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _RoutineGroupCard(
                title: routinesById[entry.key]?.title ?? entry.key,
                tasks: entry.value,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (standaloneTasks.isNotEmpty) ...[
          Text('Việc lẻ', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...standaloneTasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _TaskTile(task: task),
            ),
          ),
        ],
      ],
    );
  }
}

class _RoutineGroupCard extends StatelessWidget {
  const _RoutineGroupCard({
    required this.title,
    required this.tasks,
  });

  final String title;
  final List<Task> tasks;

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
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  child: const Text('📋', style: TextStyle(fontSize: 18)),
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
            const SizedBox(height: AppSpacing.md),
            ...sorted.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Text(
                      iconForKey(task.iconKey),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(task.title, style: context.text.bodyMedium),
                    ),
                    XuBadge(amount: task.points, pill: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.field),
              ),
              child: Text(
                iconForKey(task.iconKey),
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _repeatLabel(task),
                    style: context.text.bodySmall?.copyWith(
                      color: context.semantic.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            XuBadge(amount: task.points, pill: true),
          ],
        ),
      ),
    );
  }

  String _repeatLabel(Task task) {
    final type = RepeatType.values.firstWhere((e) => e.name == task.repeatType);
    return switch (type) {
      RepeatType.daily => 'Hằng ngày',
      // "Tuỳ chọn" không trả lời được câu bố mẹ đang hỏi — *thứ nào?* — nên liệt
      // kê thẳng các thứ đã chọn.
      RepeatType.custom => _weekdaysLabel(task.repeatDays),
      RepeatType.once =>
        task.onceDate == null ? 'Một lần' : 'Một lần · ${task.onceDate}',
    };
  }

  /// `'1,3,5'` -> `'T2, T4, T6'`.
  String _weekdaysLabel(String repeatDays) {
    final days =
        repeatDays
            .split(',')
            .where((s) => s.isNotEmpty)
            .map(int.tryParse)
            .whereType<int>()
            .toList()
          ..sort();
    if (days.isEmpty) return 'Chưa chọn thứ';
    if (days.length == 7) return 'Hằng ngày';
    return days.map(_shortWeekday).join(', ');
  }

  String _shortWeekday(int weekday) => switch (weekday) {
    1 => 'T2',
    2 => 'T3',
    3 => 'T4',
    4 => 'T5',
    5 => 'T6',
    6 => 'T7',
    _ => 'CN',
  };
}

/// Một hình để chọn. Vùng chạm đủ 48dp theo `AppSpacing.minTouchTarget` — ô nhỏ
/// hơn thì ngón tay trẻ bấm trượt sang hình bên cạnh.
class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
          // không phân biệt màu tốt sẽ không thấy ô nào đang chọn (WCAG 1.4.1).
          border: selected
              ? Border.all(color: context.colors.primary, width: 2)
              : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({
    required this.taskDao,
    required this.familyId,
    required this.children,
  });

  final TaskDao taskDao;
  final String familyId;
  final List<Member> children;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  final _pointsController = TextEditingController(text: '10');
  final _selectedChildren = <String>{};
  String? _selectedPreset;

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

  String _repeatTypeLabel(RepeatType type) => switch (type) {
    RepeatType.daily => 'Hằng ngày',
    RepeatType.custom => 'Chọn thứ',
    RepeatType.once => 'Một lần',
  };

  /// 1 = thứ Hai … 7 = Chủ nhật.
  String _weekdayLabel(int weekday) => switch (weekday) {
    1 => 'T2',
    2 => 'T3',
    3 => 'T4',
    4 => 'T5',
    5 => 'T6',
    6 => 'T7',
    _ => 'CN',
  };

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final points = int.tryParse(_pointsController.text.trim()) ?? 10;
    if (title.isEmpty || _selectedChildren.isEmpty) return;

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
        // Icon bố mẹ đang chọn, không phải icon của preset: bố mẹ có thể chọn
        // template rồi đổi hình, và lần đổi sau cùng mới là ý của họ.
        iconKey: Value(_iconKey),
        repeatType: Value(effectiveRepeat.name),
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
      ),
      _selectedChildren.toList(),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPaddingMobile,
        right: AppSpacing.screenPaddingMobile,
        top: AppSpacing.xxl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thêm việc mới', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            Text('Chọn nhanh', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: kTaskPresets.map((preset) {
                final selected = _selectedPreset == preset.key;
                return PresetChip(
                  emoji: iconForKey(preset.iconKey),
                  label: preset.titleVi,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _selectedPreset = selected ? null : preset.key;
                      if (!selected) {
                        _titleController.text = preset.titleVi;
                        _pointsController.text = preset.defaultPoints
                            .toString();
                        // Lấy luôn icon của template: bố mẹ chọn "Đánh răng" thì
                        // không phải đi tìm 🪥 lần nữa.
                        _iconKey = preset.iconKey;
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Tên việc'),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _pointsController,
              decoration: const InputDecoration(
                hintText: 'Điểm',
                suffixText: 'xu',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Chọn hình', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final key in kTaskIconKeys)
                  _IconChoice(
                    emoji: iconForKey(key),
                    selected: key == _iconKey,
                    onTap: () => setState(() => _iconKey = key),
                  ),
              ],
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
                      label: Text(_weekdayLabel(day)),
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
            Text('Giao cho', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: widget.children.map((child) {
                final selected = _selectedChildren.contains(child.id);
                return FilterChip(
                  label: Text(child.displayName),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedChildren.add(child.id);
                      } else {
                        _selectedChildren.remove(child.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('LƯU'),
              ),
            ),
          ],
        ),
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
                      Text(
                        iconForKey(preset.iconKey),
                        style: const TextStyle(fontSize: 18),
                      ),
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
