import 'dart:async';

import 'package:beong/app/router.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/bee_mascot.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/features/settings/parent_pin_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Một nhà và những người trong nhà đó — thứ màn này cần để vẽ một khối.
@immutable
class NhaVaThanhVien {
  const NhaVaThanhVien({required this.nha, required this.thanhVien});

  final Family nha;
  final List<Member> thanhVien;

  /// Nhà này có đặt PIN không — quyết định thẻ "Bố mẹ" có hiện ổ khoá.
  ///
  /// Suy ra từ chính dữ liệu chứ không vẽ cứng: ổ khoá vẽ cứng vẫn nằm đó sau
  /// khi bố mẹ gỡ PIN, tức là hứa một bước hỏi PIN không bao giờ xảy ra.
  bool get coPin => thanhVien
      .where((m) => m.kind == MemberKind.parent.name)
      .any((m) => (m.pinHash ?? '').isNotEmpty);
}

/// Máy đã có dữ liệu nhưng chưa chọn ai đang dùng.
///
/// Đây là màn hình thiếu suốt từ đầu: bấm KHOÁ LẠI (trước đây là ĐĂNG XUẤT) là
/// rơi thẳng vào onboarding, và onboarding thì chỉ biết **tạo nhà mới**. Dữ
/// liệu nhà cũ vẫn nằm nguyên trong máy nhưng không màn hình nào mở tới được
/// (`docs/13-audit-luong-vao-app.md` §2).
///
/// Màn này liệt kê **mọi** gia đình trong máy chứ không chỉ một, đúng vì lý do
/// đó: máy nào đã dính lỗi trước khi cập nhật thì đang có sẵn vài nhà mồ côi,
/// và đây là đường duy nhất mở chúng ra lại.
class ChonNguoiDungScreen extends ConsumerStatefulWidget {
  const ChonNguoiDungScreen({super.key});

  @override
  ConsumerState<ChonNguoiDungScreen> createState() =>
      _ChonNguoiDungScreenState();
}

class _ChonNguoiDungScreenState extends ConsumerState<ChonNguoiDungScreen> {
  late Future<List<NhaVaThanhVien>> _dsNha;

  @override
  void initState() {
    super.initState();
    _dsNha = _tai();
  }

  Future<List<NhaVaThanhVien>> _tai() async {
    final repo = ref.read(memberRepositoryProvider);
    final ketQua = <NhaVaThanhVien>[];
    for (final nha in await repo.allFamilies()) {
      ketQua.add(
        NhaVaThanhVien(
          nha: nha,
          thanhVien: await repo.watchMembers(nha.id).first,
        ),
      );
    }
    return ketQua;
  }

  Future<void> _chon(Member thanhVien, String familyId) async {
    final laBoMe = thanhVien.kind == MemberKind.parent.name;
    if (laBoMe) {
      final ok = await askParentPin(
        context,
        familyId: familyId,
        service: ref.read(parentPinServiceProvider),
      );
      if (!ok) return;
    }
    await ref
        .read(sessionProvider.notifier)
        .login(
          AppSession(
            familyId: familyId,
            activeMemberId: thanhVien.id,
            isParent: laBoMe,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<NhaVaThanhVien>>(
          future: _dsNha,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final dsNha = snap.data!;
            final nhieuNha = dsNha.length > 1;

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingMobile,
                vertical: AppSpacing.xxl,
              ),
              children: [
                const Center(child: BeeMascot(size: 88, mood: BeeMood.happy)),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Ai đang dùng máy?',
                  textAlign: TextAlign.center,
                  style: context.text.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Dữ liệu của cả nhà vẫn còn nguyên trên máy này.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.semantic.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                for (final muc in dsNha) ...[
                  // Tên nhà chỉ hiện khi máy có nhiều hơn một nhà. Một nhà mà
                  // vẫn in tiêu đề "Nhà mình" thì chỉ là chữ thừa.
                  if (nhieuNha) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.md,
                        top: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(muc.nha.name, style: context.text.titleMedium),
                          // Máy dính lỗi §2 thường có hai nhà **trùng tên**, vì
                          // onboarding điền sẵn "Nhà mình" cho cả hai lần. Chỉ
                          // in tên nhà thì hai khối giống hệt nhau và không ai
                          // biết nhà nào là nhà cũ của con mình.
                          Text(
                            _tomTatNha(muc),
                            style: context.text.bodySmall?.copyWith(
                              color: context.semantic.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  for (final thanhVien in muc.thanhVien)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _TheNguoiDung(
                        thanhVien: thanhVien,
                        coPin: muc.coPin,
                        onTap: () => unawaited(_chon(thanhVien, muc.nha.id)),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                const SizedBox(height: AppSpacing.lg),
                // Máy đã có dữ liệu thì không còn đường nào vào onboarding nữa
                // — đó là bản sửa của §2. Nhưng chặn sạch cũng là một cái bẫy
                // khác: nhà muốn làm lại từ đầu sẽ kẹt vĩnh viễn với dữ liệu
                // cũ. Để lại đúng một đường, đi qua tham số nói rõ ý định, và
                // onboarding còn hỏi lại một lần nữa trước khi ghi.
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.go(Routes.taoNhaMoi),
                    icon: const Icon(Icons.add_home_outlined),
                    label: const Text('Tạo nhà mới'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Một dòng đủ để nhận ra đây là nhà nào — tên các con, hoặc số thành viên.
String _tomTatNha(NhaVaThanhVien muc) {
  final con = muc.thanhVien
      .where((m) => m.kind == MemberKind.child.name)
      .map((m) => m.displayName)
      .toList();
  if (con.isEmpty) return '${muc.thanhVien.length} thành viên';
  return 'Con: ${con.join(', ')}';
}

class _TheNguoiDung extends StatelessWidget {
  const _TheNguoiDung({
    required this.thanhVien,
    required this.coPin,
    required this.onTap,
  });

  final Member thanhVien;
  final bool coPin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final laBoMe = thanhVien.kind == MemberKind.parent.name;
    final mau = laBoMe
        ? context.colors.primary
        : AppColors.profileColor(thanhVien.colorIndex);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: mau.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  laBoMe
                      ? 'av_parent'
                      : iconKeyForEmoji(avatarForKey(thanhVien.avatarKey)),
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thanhVien.displayName,
                      style: context.text.titleSmall,
                    ),
                    Text(
                      laBoMe ? 'Bố mẹ' : 'Trẻ',
                      style: context.text.bodySmall?.copyWith(
                        color: context.semantic.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Ổ khoá nói trước rằng vào vai này sẽ bị hỏi PIN, thay vì để
              // người ta bấm rồi mới bất ngờ. Nhà chưa đặt PIN thì không vẽ —
              // một ổ khoá không khoá gì chỉ là chữ thừa gây hiểu nhầm.
              if (laBoMe && coPin)
                Icon(
                  Icons.lock_outline_rounded,
                  color: context.semantic.onSurfaceMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
