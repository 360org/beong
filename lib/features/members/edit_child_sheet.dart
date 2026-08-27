import 'dart:async';
import 'dart:convert';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
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

/// Chỉnh sửa hoặc xoá hồ sơ bé.
Future<bool?> showEditChildSheet(
  BuildContext context, {
  required Member child,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _EditChildSheet(child: child),
    ),
  );
}

class _EditChildSheet extends ConsumerStatefulWidget {
  const _EditChildSheet({required this.child});

  final Member child;

  @override
  ConsumerState<_EditChildSheet> createState() => _EditChildSheetState();
}

class _EditChildSheetState extends ConsumerState<_EditChildSheet> {
  late final TextEditingController _name;
  late int _colorIndex;
  late String _avatar;
  late int? _birthYear;
  late bool _hasPin;
  JarSplit? _customJarSplit;
  bool _allowSelfAllocation = false;
  Set<String> _selectedPresets = <String>{};
  Map<String, int> _presetPoints = <String, int>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.child.displayName);
    _name.addListener(_onNameChanged);
    _colorIndex = widget.child.colorIndex;
    _avatar = widget.child.avatarKey ?? kAvatarEmojis.first;
    _birthYear = widget.child.birthYear;
    _hasPin = widget.child.pinHash != null && widget.child.pinHash!.isNotEmpty;

    final override = widget.child.jarSplitOverride;
    if (override != null && override.isNotEmpty) {
      try {
        final map = jsonDecode(override) as Map<String, dynamic>;
        _allowSelfAllocation = map['manualAllocation'] == true;
        if (map.containsKey('spend') || map.containsKey('save') || map.containsKey('give')) {
          _customJarSplit = JarSplit.fromJson(map);
        }
      } on Object {
        _customJarSplit = null;
        _allowSelfAllocation = false;
      }
    }
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
        .updateMember(
          widget.child.id,
          MembersCompanion(
            displayName: Value(ten),
            colorIndex: Value(_colorIndex),
            avatarKey: Value(_avatar),
            birthYear: Value(_birthYear),
            jarSplitOverride: Value(jarSplitJson),
            updatedAt: Value(DateTime.now()),
          ),
        );

    // Gán thêm việc mẫu đã chọn nếu có
    if (_selectedPresets.isNotEmpty) {
      final taskDao = ref.read(taskRepositoryProvider);
      for (final presetKey in _selectedPresets) {
        final preset = kTaskPresets.firstWhere((p) => p.key == presetKey);
        final points = _presetPoints[presetKey] ?? preset.defaultPoints;
        final taskId = 'task-preset-$presetKey-${widget.child.id}-${DateTime.now().millisecondsSinceEpoch}';
        await taskDao.createTask(
          TasksCompanion.insert(
            id: taskId,
            familyId: widget.child.familyId,
            title: preset.titleVi,
            iconKey: Value(preset.iconKey),
            presetKey: Value(preset.key),
            points: Value(points),
            dayPart: Value(preset.dayPart),
            repeatType: const Value('daily'),
          ),
          [widget.child.id],
        );
      }
      final clock = FamilyClock(timeZoneOffset: DateTime.now().timeZoneOffset);
      await taskDao.generateInstances(
        familyId: widget.child.familyId,
        today: clock.today(),
      );
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _deleteProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xoá hồ sơ ${widget.child.displayName}?'),
        content: const Text(
          'Toàn bộ lịch sử làm việc, tích luỹ xu và chuỗi của bé sẽ bị xoá khỏi danh sách hoạt động.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('HUỶ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.semantic.danger,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('XOÁ HỒ SƠ'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    await ref.read(memberRepositoryProvider).deleteMember(widget.child.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _handleTogglePin(bool enable) async {
    if (enable) {
      final success = await datMatKhauMoi(
        context,
        memberId: widget.child.id,
        tenHienThi: widget.child.displayName,
        service: ref.read(matKhauHoSoProvider),
        moTa:
            'Bốn chữ số bảo vệ hồ sơ của ${widget.child.displayName}. Bé nhập nó để mở hồ sơ.',
      );
      if (success) {
        setState(() => _hasPin = true);
      }
    } else {
      await ref.read(matKhauHoSoProvider).boMatKhau(widget.child.id);
      setState(() => _hasPin = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tắt mật khẩu hồ sơ của ${widget.child.displayName}')),
        );
      }
    }
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
            title: 'Hồ sơ của bé',
            controller: _name,
            colorIndex: _colorIndex,
            onColorChanged: (i) => setState(() => _colorIndex = i),
            avatar: _avatar,
            onAvatarChanged: (a) => setState(() => _avatar = a),
            birthYear: _birthYear,
            onBirthYearChanged: (y) => setState(() => _birthYear = y),
            autofocus: false,
            onClose: () => Navigator.of(context).pop(false),
            hasPin: _hasPin,
            onTogglePin: _handleTogglePin,
            customJarSplit: _customJarSplit,
            onJarSplitChanged: (split) => setState(() => _customJarSplit = split),
            allowSelfAllocation: _allowSelfAllocation,
            onToggleSelfAllocation: (val) => setState(() => _allowSelfAllocation = val),
            selectedPresetKeys: _selectedPresets,
            onPresetsChanged: (keys) => setState(() => _selectedPresets = keys),
            presetPoints: _presetPoints,
            onPresetPointsChanged: (pts) => setState(() => _presetPoints = pts),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy || _name.text.trim().isEmpty ? null : _save,
              child: const Text('LƯU THAY ĐỔI'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.semantic.danger,
                side: BorderSide(color: context.semantic.danger),
              ),
              onPressed: _busy ? null : _deleteProfile,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('XOÁ HỒ SƠ BÉ NÀY'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
