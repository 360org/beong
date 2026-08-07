import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/data/local/database.dart';
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
        title: Text('Viec nha', style: context.text.titleLarge),
      ),
      body: _TaskList(
        familyId: session.familyId,
        taskDao: taskDao,
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
    required this.isParent,
  });

  final String familyId;
  final TaskDao taskDao;
  final bool isParent;

  @override
  State<_TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<_TaskList> {
  List<Task> _tasks = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final tasks = await widget.taskDao.activeTasks(widget.familyId);
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tasks.isEmpty) {
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
                'Chua co viec nao',
                style: context.text.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.isParent
                    ? 'Bam + de them viec moi cho be.'
                    : 'Bo me chua tao viec.',
                style: context.text.bodyMedium?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final routineTasks = <String, List<Task>>{};
    final standaloneTasks = <Task>[];

    for (final task in _tasks) {
      if (task.routineId != null) {
        routineTasks.putIfAbsent(task.routineId!, () => []).add(task);
      } else {
        standaloneTasks.add(task);
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingMobile,
        vertical: AppSpacing.lg,
      ),
      children: [
        if (routineTasks.isNotEmpty) ...[
          Text('Routine', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...routineTasks.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _RoutineGroupCard(
                routineId: entry.key,
                tasks: entry.value,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (standaloneTasks.isNotEmpty) ...[
          Text('Viec le', style: context.text.titleMedium),
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
    required this.routineId,
    required this.tasks,
  });

  final String routineId;
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
                Icon(Icons.list_alt_rounded, color: context.colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(routineId, style: context.text.titleSmall),
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
                    '${tasks.length} viec',
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
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: context.semantic.onSurfaceMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(task.title, style: context.text.bodyMedium),
                    ),
                    XuBadge(amount: task.points),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: context.text.bodyLarge),
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
            XuBadge(amount: task.points),
          ],
        ),
      ),
    );
  }

  String _repeatLabel(Task task) {
    final type = RepeatType.values.firstWhere((e) => e.name == task.repeatType);
    return switch (type) {
      RepeatType.daily => 'Hang ngay',
      RepeatType.custom => 'Tuy chon',
      RepeatType.once => 'Mot lan',
    };
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

  @override
  void dispose() {
    _titleController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final points = int.tryParse(_pointsController.text.trim()) ?? 10;
    if (title.isEmpty || _selectedChildren.isEmpty) return;

    final id = 'task-${DateTime.now().millisecondsSinceEpoch}';
    await widget.taskDao.createTask(
      TasksCompanion.insert(
        id: id,
        familyId: widget.familyId,
        title: title,
        points: Value(points),
        presetKey: Value(_selectedPreset),
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
            Text('Them viec moi', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            Text('Chon nhanh', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: kTaskPresets.map((preset) {
                  final selected = _selectedPreset == preset.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(preset.titleVi),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedPreset = selected ? null : preset.key;
                          if (!selected) {
                            _titleController.text = preset.titleVi;
                            _pointsController.text = preset.defaultPoints
                                .toString();
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Ten viec'),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _pointsController,
              decoration: const InputDecoration(
                hintText: 'Diem',
                suffixText: 'xu',
              ),
              keyboardType: TextInputType.number,
            ),
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
                child: const Text('LUU'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
