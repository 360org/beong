import 'dart:convert';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/presets.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/jar_splitter.dart';
import 'package:beong/features/members/child_profile_form.dart';
import 'package:beong/features/members/mat_khau_sheet.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Thêm một bé nữa vào gia đình.
Future<bool?> showAddChildSheet(
  BuildContext context, {
  required String familyId,
  required int nextColorIndex,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _AddChildSheet(
        familyId: familyId,
        nextColorIndex: nextColorIndex,
      ),
    ),
  );
}

class _AddChildSheet extends ConsumerStatefulWidget {
  const _AddChildSheet({required this.familyId, required this.nextColorIndex});

  final String familyId;

  /// Màu gợi ý sẵn, chọn sao cho khác các bé đã có.
  final int nextColorIndex;

  @override
  ConsumerState<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends ConsumerState<_AddChildSheet> {
  final _name = TextEditingController();
  late int _colorIndex = widget.nextColorIndex;
  String _avatar = kAvatarEmojis.first;
  int? _birthYear;
  bool _busy = false;

  // Bật/tắt mã PIN
  bool _enablePin = false;

  // Tuỳ chỉnh hũ riêng
  JarSplit? _customJarSplit;
  bool _allowSelfAllocation = false;

  // Gán việc mẫu hàng loạt kèm điểm xu tuỳ chỉnh
  Set<String> _selectedPresets = <String>{};
  Map<String, int> _presetPoints = <String, int>{};

  @override
  void initState() {
    super.initState();
    _name.addListener(_onNameChanged);
  }

  void _onNameChanged() => setState(() {});

  @override
  void dispose() {
    _name
      ..removeListener(_onNameChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final childId = const Uuid().v4();
    final ten = _name.text.trim();

    Map<String, dynamic>? overrideMap;
    if (_customJarSplit != null) {
      overrideMap = _customJarSplit!.toJson();
    }
    if (_allowSelfAllocation) {
      overrideMap ??= <String, dynamic>{};
      overrideMap['manualAllocation'] = true;
    }
    final jarSplitJson = overrideMap != null ? jsonEncode(overrideMap) : null;

    await ref
        .read(memberRepositoryProvider)
        .addMember(
          MembersCompanion.insert(
            id: childId,
            familyId: widget.familyId,
            kind: MemberKind.child.name,
            displayName: ten,
            colorIndex: Value(_colorIndex),
            avatarKey: Value(_avatar),
            birthYear: Value(_birthYear),
            jarSplitOverride: Value(jarSplitJson),
          ),
        );

    // Tự động tạo và gán các việc mẫu đã chọn cho bé kèm số xu tuỳ chỉnh
    if (_selectedPresets.isNotEmpty) {
      final taskDao = ref.read(taskRepositoryProvider);
      for (final presetKey in _selectedPresets) {
        final preset = kTaskPresets.firstWhere((p) => p.key == presetKey);
        final points = _presetPoints[presetKey] ?? preset.defaultPoints;
        final taskId = 'task-preset-$presetKey-$childId-${DateTime.now().millisecondsSinceEpoch}';
        await taskDao.createTask(
          TasksCompanion.insert(
            id: taskId,
            familyId: widget.familyId,
            title: preset.titleVi,
            iconKey: Value(preset.iconKey),
            presetKey: Value(preset.key),
            points: Value(points),
            dayPart: Value(preset.dayPart),
            repeatType: const Value('daily'),
          ),
          [childId],
        );
      }
      // Tự động sinh luôn instance hôm nay cho bé
      final clock = FamilyClock(timeZoneOffset: DateTime.now().timeZoneOffset);
      await taskDao.generateInstances(
        familyId: widget.familyId,
        today: clock.today(),
      );
    }

    if (!mounted) return;

    if (_enablePin) {
      await datMatKhauMoi(
        context,
        memberId: childId,
        tenHienThi: ten,
        service: ref.read(matKhauHoSoProvider),
        moTa:
            'Bốn chữ số cho hồ sơ của $ten. Bé nhập nó để mở hồ sơ của mình; '
            'bố mẹ có thể đổi hoặc tắt lại bất cứ lúc nào.',
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChildProfileForm(
            controller: _name,
            colorIndex: _colorIndex,
            onColorChanged: (i) => setState(() => _colorIndex = i),
            avatar: _avatar,
            onAvatarChanged: (a) => setState(() => _avatar = a),
            birthYear: _birthYear,
            onBirthYearChanged: (y) => setState(() => _birthYear = y),
            autofocus: false,
            onClose: () => Navigator.of(context).pop(false),
            hasPin: _enablePin,
            onTogglePin: (val) => setState(() => _enablePin = val),
            customJarSplit: _customJarSplit,
            onJarSplitChanged: (split) => setState(() => _customJarSplit = split),
            allowSelfAllocation: _allowSelfAllocation,
            onToggleSelfAllocation: (val) => setState(() => _allowSelfAllocation = val),
            selectedPresetKeys: _selectedPresets,
            onPresetsChanged: (keys) => setState(() => _selectedPresets = keys),
            presetPoints: _presetPoints,
            onPresetPointsChanged: (pts) => setState(() => _presetPoints = pts),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy || _name.text.trim().isEmpty ? null : _save,
              child: const Text('THÊM BÉ'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// Màu chưa bé nào dùng, để hai bé không trùng màu hồ sơ.
///
/// Trùng màu thì avatar và thẻ việc của hai bé trông y hệt nhau, mà màu là thứ
/// đầu tiên trẻ chưa đọc thạo dùng để nhận ra phần của mình.
int nextFreeColorIndex(List<Member> members) {
  final used = members.map((m) => m.colorIndex).toSet();
  for (var i = 0; i < AppColors.profilePalette.length; i++) {
    if (!used.contains(i)) return i;
  }
  // Hết màu thì quay vòng — thà trùng còn hơn chặn không cho thêm bé.
  return members.length % AppColors.profilePalette.length;
}
