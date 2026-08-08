import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/responsive_scaffold.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/seed/presets.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _familyNameController = TextEditingController(text: 'Nhà mình');
  final _childNameController = TextEditingController();
  int _childColorIndex = 0;
  String _childAvatar = kAvatarEmojis.first;
  final _selectedRoutines = <String>{'morning', 'bedtime'};

  @override
  void dispose() {
    _pageController.dispose();
    _familyNameController.dispose();
    _childNameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      unawaited(
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
      setState(() => _currentPage++);
    }
  }

  Future<void> _finish() async {
    final familyName = _familyNameController.text.trim();
    final childName = _childNameController.text.trim();
    if (familyName.isEmpty || childName.isEmpty) return;

    final memberDao = ref.read(memberDaoProvider);
    final taskDao = ref.read(taskDaoProvider);

    // UUID sinh ở client, không dùng ID cứng — mỗi lần onboarding phải tạo
    // được family mới (ADR-002). Onboarding lặp lại xảy ra thật: session hiện
    // chưa lưu lại giữa các lần mở app.
    const uuid = Uuid();
    final familyId = uuid.v4();
    final parentId = uuid.v4();
    final childId = uuid.v4();

    await memberDao.createFamily(
      FamiliesCompanion.insert(id: familyId, name: familyName),
    );

    await memberDao.addMember(
      MembersCompanion.insert(
        id: parentId,
        familyId: familyId,
        kind: MemberKind.parent.name,
        displayName: 'Bố mẹ',
      ),
    );

    await memberDao.addMember(
      MembersCompanion.insert(
        id: childId,
        familyId: familyId,
        kind: MemberKind.child.name,
        displayName: childName,
        colorIndex: Value(_childColorIndex),
        avatarKey: Value(_childAvatar),
      ),
    );

    for (final routineKey in _selectedRoutines) {
      final preset = kRoutinePresets.firstWhere((r) => r.key == routineKey);
      final routineId = uuid.v4();

      final routineTasks = <TasksCompanion>[];
      for (var i = 0; i < preset.taskKeys.length; i++) {
        final tp = presetByKey(preset.taskKeys[i]);
        if (tp == null) continue;
        routineTasks.add(
          TasksCompanion.insert(
            id: '$routineId-task-$i',
            familyId: familyId,
            title: tp.titleVi,
            iconKey: Value(tp.iconKey),
            presetKey: Value(tp.key),
            points: Value(tp.defaultPoints),
            routineId: Value(routineId),
            orderIndex: Value(i),
          ),
        );
      }

      await taskDao.createRoutine(
        routine: RoutinesCompanion.insert(
          id: routineId,
          familyId: familyId,
          title: preset.titleVi,
          iconKey: Value(preset.iconKey),
          dayPart: Value(preset.dayPart),
          completionBonus: const Value(10),
        ),
        assigneeIds: [childId],
        routineTasks: routineTasks,
      );
    }

    ref
        .read(sessionProvider.notifier)
        .login(
          AppSession(
            familyId: familyId,
            activeMemberId: parentId,
          ),
        );

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ScreenPadding(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              _StepIndicator(current: _currentPage, total: 3),
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _FamilyStep(controller: _familyNameController),
                    _ChildStep(
                      controller: _childNameController,
                      colorIndex: _childColorIndex,
                      onColorChanged: (i) =>
                          setState(() => _childColorIndex = i),
                      avatar: _childAvatar,
                      onAvatarChanged: (a) => setState(() => _childAvatar = a),
                    ),
                    _RoutineStep(
                      selected: _selectedRoutines,
                      onToggle: (key) {
                        setState(() {
                          if (_selectedRoutines.contains(key)) {
                            _selectedRoutines.remove(key);
                          } else {
                            _selectedRoutines.add(key);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _currentPage < 2 ? _nextPage : _finish,
                  child: Text(
                    _currentPage < 2 ? 'TIEP TUC' : 'BAT DAU',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i <= current;
        return Container(
          width: active ? 32 : 12,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: active ? context.colors.primary : context.colors.outline,
          ),
        );
      }),
    );
  }
}

class _FamilyStep extends StatelessWidget {
  const _FamilyStep({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dat ten gia dinh',
          style: context.text.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Ten nay se hien thi trong app cua ca nha.',
          style: context.text.bodyMedium?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nha minh',
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
      ],
    );
  }
}

class _ChildStep extends StatelessWidget {
  const _ChildStep({
    required this.controller,
    required this.colorIndex,
    required this.onColorChanged,
    required this.avatar,
    required this.onAvatarChanged,
  });

  final TextEditingController controller;
  final int colorIndex;
  final ValueChanged<int> onColorChanged;
  final String avatar;
  final ValueChanged<String> onAvatarChanged;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.profileColor(colorIndex);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Them be', style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nhap ten, chon mau va con vat cho be.',
            style: context.text.bodyMedium?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Text(avatar, style: const TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Ten be'),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'CON VAT',
            style: context.text.labelSmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: kAvatarEmojis.map((emoji) {
              final selected = emoji == avatar;
              return GestureDetector(
                onTap: () => onAvatarChanged(emoji),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.25)
                        : context.colors.primaryContainer,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: color, width: 2.5)
                        : null,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'MAU',
            style: context.text.labelSmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: List.generate(AppColors.profilePalette.length, (i) {
              final swatch = AppColors.profileColor(i);
              final selected = i == colorIndex;
              return GestureDetector(
                onTap: () => onColorChanged(i),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(
                            color: context.colors.onSurface,
                            width: 3,
                          )
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RoutineStep extends StatelessWidget {
  const _RoutineStep({required this.selected, required this.onToggle});
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chon thoi quen', style: context.text.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Chon routine san de bat dau nhanh. '
          'Be co the sua sau.',
          style: context.text.bodyMedium?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ...kRoutinePresets.map((preset) {
          final isSelected = selected.contains(preset.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Card(
              color: isSelected ? context.colors.primaryContainer : null,
              child: InkWell(
                onTap: () => onToggle(preset.key),
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Icon(
                        _routineIcon(preset.dayPart),
                        color: isSelected
                            ? context.colors.primary
                            : context.semantic.onSurfaceMuted,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.titleVi,
                              style: context.text.titleMedium,
                            ),
                            Text(
                              '${preset.taskKeys.length} viec',
                              style: context.text.bodySmall?.copyWith(
                                color: context.semantic.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: context.colors.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  IconData _routineIcon(String dayPart) => switch (dayPart) {
    'morning' => Icons.wb_sunny_rounded,
    'afternoon' => Icons.wb_cloudy_rounded,
    'evening' => Icons.nightlight_round,
    _ => Icons.schedule,
  };
}
