import 'dart:async';

import 'package:beong/core/l10n/gen/app_localizations.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/bee_mascot.dart';
import 'package:beong/core/widgets/responsive_scaffold.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/seed/presets.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/age_band.dart';
import 'package:beong/domain/services/family_clock.dart';
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

  /// Không chọn sẵn năm nào: đoán tuổi của trẻ là bịa dữ liệu, và
  /// [ageBandFor] đã có sẵn nhóm mặc định cho trường hợp `null`.
  int? _childBirthYear;
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
    // được family mới (ADR-002). Onboarding lặp lại vẫn xảy ra sau khi đăng
    // xuất, nên không được dùng ID cố định.
    const uuid = Uuid();
    final familyId = uuid.v4();
    final parentId = uuid.v4();
    final childId = uuid.v4();

    await memberDao.createFamily(
      FamiliesCompanion.insert(id: familyId, name: familyName),
    );

    // Ba hũ mặc định vào **bảng** `jars` ngay từ đầu (ADR-024), để màn quản lý hũ
    // có thứ thật mà sửa. Không gieo thì gia đình mới chạy bằng đường rơi về
    // `kDefaultJars`, và bố mẹ sửa tỷ lệ xong thấy không có gì thay đổi.
    await ref.read(jarDaoProvider).seedDefaults(familyId);

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
        birthYear: Value(_childBirthYear),
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

    await ref
        .read(sessionProvider.notifier)
        .login(
          AppSession(
            familyId: familyId,
            activeMemberId: parentId,
          ),
        );

    // Sinh việc cho hôm nay ngay, `force` vì routine vừa được tạo xong: chờ tới
    // lần mở app sau thì bố mẹ thấy "0 / 0 việc hôm nay" ngay sau onboarding.
    await ref
        .read(dayStartServiceProvider)
        .runIfNeeded(familyId: familyId, force: true);

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
                      birthYear: _childBirthYear,
                      onBirthYearChanged: (y) =>
                          setState(() => _childBirthYear = y),
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
                    _currentPage < 2 ? 'TIẾP TỤC' : 'BẮT ĐẦU',
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
    final l10n = L10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Màn hình đầu tiên là chỗ duy nhất trong app hiện tên thương hiệu
        // kèm slogan — các màn sau chỉ nói việc của gia đình.
        Center(
          child: Column(
            children: [
              // Linh vật vẽ tay, không dùng emoji 🐝: emoji đổi hình theo nền
              // tảng nên không dùng được ở chỗ nhận diện thương hiệu.
              const BeeMascot(mood: BeeMood.happy, size: 84),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.appTitle,
                style: context.text.displayLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.appSlogan,
                style: context.text.bodyMedium?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          'Đặt tên gia đình',
          style: context.text.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tên này sẽ hiển thị trong app của cả nhà.',
          style: context.text.bodyMedium?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhà mình',
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
    required this.birthYear,
    required this.onBirthYearChanged,
  });

  final TextEditingController controller;
  final int colorIndex;
  final ValueChanged<int> onColorChanged;
  final String avatar;
  final ValueChanged<String> onAvatarChanged;
  final int? birthYear;
  final ValueChanged<int?> onBirthYearChanged;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.profileColor(colorIndex);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thêm bé', style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nhập tên, tuổi, chọn màu và con vật cho bé.',
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
            decoration: const InputDecoration(hintText: 'Tên bé'),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'BÉ MẤY TUỔI',
            style: context.text.labelSmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Giao diện tự điều chỉnh theo tuổi: bé nhỏ thì chữ và icon to hơn, '
            'bé lớn thì gọn gàng hơn.',
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AgePicker(
            birthYear: birthYear,
            onChanged: onBirthYearChanged,
            color: color,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'CON VẬT',
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
                  child: AppIcon(iconKeyForEmoji(emoji), size: 28),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'MÀU',
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

/// Hàng chip chọn tuổi, cuộn ngang. Lưu **năm sinh** chứ không lưu tuổi.
///
/// Lưu tuổi thì sang năm dữ liệu sai; lưu năm sinh thì nhóm tuổi tự chuyển khi
/// bé lớn lên — xem `ageBandFor`. Bố mẹ nghĩ theo tuổi nên chip hiện tuổi, còn
/// năm sinh chỉ là thứ được lưu xuống DB.
class _AgePicker extends StatelessWidget {
  const _AgePicker({
    required this.birthYear,
    required this.onChanged,
    required this.color,
  });

  final int? birthYear;
  final ValueChanged<int?> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final currentYear = FamilyClock(
      timeZoneOffset: DateTime.now().timeZoneOffset,
    ).today().year;
    final years = birthYearOptions(currentYear: currentYear);

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: years.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final year = years[index];
          final selected = year == birthYear;

          return GestureDetector(
            // Bấm lại chip đang chọn để bỏ chọn — bố mẹ không muốn khai tuổi
            // thì vẫn đi tiếp được.
            onTap: () => onChanged(selected ? null : year),
            child: Container(
              width: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.25)
                    : context.colors.primaryContainer,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.field),
                ),
                border: selected ? Border.all(color: color, width: 2.5) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${currentYear - year}',
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'tuổi',
                    style: context.text.labelSmall?.copyWith(
                      color: context.semantic.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
        Text('Chọn thói quen', style: context.text.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Chọn routine sẵn để bắt đầu nhanh. '
          'Bé có thể sửa sau.',
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
                      // Icon của chính routine (`preset.iconKey`), không phải
                      // Material icon suy từ buổi trong ngày: cả app dùng một bộ
                      // hình, trộn hai kiểu ở đúng màn đầu tiên người dùng thấy
                      // là mất ngay cảm giác đồng bộ.
                      Opacity(
                        opacity: isSelected ? 1 : 0.55,
                        child: AppIcon(preset.iconKey, size: 26),
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
                              '${preset.taskKeys.length} việc',
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
}
