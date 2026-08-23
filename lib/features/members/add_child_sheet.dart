import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/features/members/child_profile_form.dart';
import 'package:beong/features/members/mat_khau_sheet.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Thêm một bé nữa vào gia đình.
///
/// Onboarding chỉ khai được **một** bé, và trước sheet này không có đường nào
/// khác — nhà hai con phải đăng xuất rồi làm lại từ đầu, mất luôn dữ liệu cũ.
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
          ),
        );
    if (!mounted) return;

    // ADR-027: không hồ sơ nào được để trống mật khẩu. Bỏ qua ở đây là thủng
    // ngay quy tắc vừa đặt — bé mới sẽ là hồ sơ duy nhất ai cũng mở được.
    //
    // Đặt **sau** khi ghi bé: hỏng ở giữa thì bé vẫn còn và màn chọn hồ sơ bắt
    // đặt nốt; đặt trước rồi hỏng thì mất cả bé.
    await datMatKhauMoi(
      context,
      memberId: childId,
      tenHienThi: ten,
      service: ref.read(matKhauHoSoProvider),
      batBuoc: true,
      moTa:
          'Bốn chữ số cho hồ sơ của $ten. Bé nhập nó để mở hồ sơ của mình; '
          'bố mẹ đặt lại được bất cứ lúc nào trong Cài đặt.',
    );

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
            // Bàn phím bật sẵn trong sheet sẽ che mất ô chọn con vật và màu
            // ngay khi sheet vừa mở.
            autofocus: false,
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
