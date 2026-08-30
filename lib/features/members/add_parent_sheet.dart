import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/sheet_header.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/features/members/mat_khau_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Thêm một **người lớn** nữa cùng quản lý.
///
/// Chủ dự án nêu 30/08/2026: *"có thể tạo thêm profile cùng quản lý parent ví
/// dụ: bố / mẹ / ông / bà."* Trước đó nhà chỉ tạo được đúng một hồ sơ bố mẹ ở
/// onboarding, và không có đường nào thêm người thứ hai — trong khi việc trông
/// cháu và duyệt việc nhà thường do nhiều người lớn cùng làm.
///
/// Mọi hồ sơ người lớn có **cùng quyền**: duyệt việc, sửa thói quen, đổi cài
/// đặt. Không có bậc "chủ nhà": phân quyền giữa những người lớn trong cùng một
/// nhà là thứ app này không nên đứng ra phân xử.
Future<bool?> showAddParentSheet(
  BuildContext context, {
  required String familyId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _AddParentSheet(familyId: familyId),
    ),
  );
}

/// Cách xưng hô gợi ý sẵn. Bấm một cái là xong, khỏi gõ.
///
/// Đây chỉ là **gợi ý điền nhanh**, không phải danh sách đóng: nhà nào gọi
/// "Ba", "Má", "Cậu", "Dì" thì gõ thẳng vào ô tên.
const kGoiYTenNguoiLon = <String>['Bố', 'Mẹ', 'Ông', 'Bà'];

class _AddParentSheet extends ConsumerStatefulWidget {
  const _AddParentSheet({required this.familyId});

  final String familyId;

  @override
  ConsumerState<_AddParentSheet> createState() => _AddParentSheetState();
}

class _AddParentSheetState extends ConsumerState<_AddParentSheet> {
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ten = _name.text.trim();
    if (ten.isEmpty) return;
    setState(() => _busy = true);

    final memberId = const Uuid().v4();
    await ref
        .read(memberRepositoryProvider)
        .addMember(
          MembersCompanion.insert(
            id: memberId,
            familyId: widget.familyId,
            kind: MemberKind.parent.name,
            displayName: ten,
          ),
        );

    if (!mounted) return;
    // ADR-027: hồ sơ người lớn **bắt buộc** có mật khẩu. Hồ sơ này duyệt việc
    // và cộng xu được, nên để trống là mở cửa cho bất kỳ ai cầm máy — kể cả
    // chính đứa trẻ đang chờ được duyệt.
    await datMatKhauMoi(
      context,
      memberId: memberId,
      tenHienThi: ten,
      service: ref.read(matKhauHoSoProvider),
      batBuoc: true,
      moTa:
          'Bốn chữ số cho hồ sơ của $ten. Hồ sơ người lớn duyệt việc và cộng '
          'xu được, nên bắt buộc phải có mật khẩu.',
    );

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              title: 'Thêm người lớn',
              subtitle:
                  'Ông bà, bố mẹ — ai cùng trông các bé thì có hồ sơ riêng. '
                  'Mọi hồ sơ người lớn có cùng quyền.',
              onClose: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Gọi là gì', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final goiY in kGoiYTenNguoiLon)
                  ActionChip(
                    avatar: const AppIcon('av_parent', size: 18),
                    label: Text(goiY),
                    onPressed: () => _name.text = goiY,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Tên hiển thị',
                hintText: 'Ví dụ: Bà ngoại',
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy || _name.text.trim().isEmpty ? null : _save,
                child: const Text('THÊM NGƯỜI LỚN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
