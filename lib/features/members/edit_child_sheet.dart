import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/domain/repositories/member_repository.dart';
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
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.child.displayName);
    _name.addListener(_onNameChanged);
    _colorIndex = widget.child.colorIndex;
    _avatar = widget.child.avatarKey ?? kAvatarEmojis.first;
    _birthYear = widget.child.birthYear;
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

    await ref
        .read(memberRepositoryProvider)
        .updateMember(
          widget.child.id,
          MembersCompanion(
            displayName: Value(ten),
            colorIndex: Value(_colorIndex),
            avatarKey: Value(_avatar),
            birthYear: Value(_birthYear),
            updatedAt: Value(DateTime.now()),
          ),
        );

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

  Future<void> _changePassword() async {
    await datMatKhauMoi(
      context,
      memberId: widget.child.id,
      tenHienThi: widget.child.displayName,
      service: ref.read(matKhauHoSoProvider),
      moTa:
          'Bốn chữ số mới cho hồ sơ của ${widget.child.displayName}. Bấm HUỶ nếu muốn bỏ mật khẩu.',
    );
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
          ),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_reset_rounded),
            title: const Text('Đổi hoặc bỏ mật khẩu bé'),
            subtitle: const Text('Tuỳ chỉnh mã 4 số bảo vệ hồ sơ này'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _changePassword,
          ),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
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
