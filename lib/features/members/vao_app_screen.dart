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
import 'package:beong/features/members/mat_khau_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Một nhà và những người trong nhà đó.
@immutable
class NhaVaThanhVien {
  const NhaVaThanhVien({required this.nha, required this.thanhVien});

  final Family nha;
  final List<Member> thanhVien;

  List<Member> theoVai({required bool laBoMe}) => thanhVien
      .where((m) => (m.kind == MemberKind.parent.name) == laBoMe)
      .toList();
}

enum _Buoc { nha, vai, hoSo }

/// Vào app khi máy đã có dữ liệu nhưng chưa chọn ai đang dùng.
///
/// Bốn bước, đúng luồng chốt ở ADR-027:
///
///     chọn nhà → chọn vai (phụ huynh / con) → chọn hồ sơ → điền mật khẩu
///
/// Bước "chọn nhà" **tự bỏ qua khi máy chỉ có một nhà**, và "chọn hồ sơ" tự bỏ
/// qua khi vai đó chỉ có một người. Một màn hình chỉ có đúng một thứ để bấm thì
/// không phải là một lựa chọn, nó là một cú chạm thừa.
///
/// Màn này liệt kê **mọi** gia đình trong máy: máy nào đăng xuất trước bản sửa
/// §2 (`docs/13-audit-luong-vao-app.md`) đang mang sẵn vài nhà mồ côi, và đây
/// là đường duy nhất mở chúng ra lại.
class VaoAppScreen extends ConsumerStatefulWidget {
  const VaoAppScreen({super.key});

  @override
  ConsumerState<VaoAppScreen> createState() => _VaoAppScreenState();
}

class _VaoAppScreenState extends ConsumerState<VaoAppScreen> {
  late Future<List<NhaVaThanhVien>> _dsNha;

  _Buoc _buoc = _Buoc.nha;
  NhaVaThanhVien? _nhaDaChon;
  bool? _laBoMe;

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
    // Một nhà thì không có gì để chọn — vào thẳng bước chọn vai.
    if (ketQua.length == 1) {
      _nhaDaChon = ketQua.first;
      _buoc = _Buoc.vai;
    }
    return ketQua;
  }

  void _chonNha(NhaVaThanhVien nha) => setState(() {
    _nhaDaChon = nha;
    _buoc = _Buoc.vai;
  });

  Future<void> _chonVai({required bool laBoMe}) async {
    final trongVai = _nhaDaChon!.theoVai(laBoMe: laBoMe);
    if (trongVai.isEmpty) return;

    _laBoMe = laBoMe;
    if (trongVai.length == 1) {
      await _moHoSo(trongVai.single);
      return;
    }
    setState(() => _buoc = _Buoc.hoSo);
  }

  void _quayLai() => setState(() {
    if (_buoc == _Buoc.hoSo) {
      _buoc = _Buoc.vai;
      _laBoMe = null;
    } else if (_buoc == _Buoc.vai) {
      _buoc = _Buoc.nha;
      _nhaDaChon = null;
    }
  });

  Future<void> _moHoSo(Member hoSo) async {
    final service = ref.read(matKhauHoSoProvider);
    final familyId = _nhaDaChon!.nha.id;

    final ok = await hoiMatKhau(
      context,
      memberId: hoSo.id,
      tenHienThi: hoSo.displayName,
      service: service,
    );
    if (!ok || !mounted) return;

    // Hồ sơ từ máy cài bản cũ chưa có mật khẩu. ADR-027 nói không hồ sơ nào
    // được để trống, nên bắt đặt ngay tại đây thay vì để nó trống mãi — nhưng
    // **sau** khi đã cho vào, không phải trước: chặn trước là khoá người dùng
    // ra khỏi dữ liệu của chính họ vì một quy tắc mới.
    if (!await service.daDat(hoSo.id)) {
      if (!mounted) return;
      final xong = await datMatKhauMoi(
        context,
        memberId: hoSo.id,
        tenHienThi: hoSo.displayName,
        service: service,
        batBuoc: true,
        moTa:
            'Từ bản này mỗi hồ sơ có mật khẩu riêng. Đặt 4 chữ số cho '
            '${hoSo.displayName} để lần sau mở đúng hồ sơ.',
      );
      if (!xong || !mounted) return;
    }

    await ref
        .read(sessionProvider.notifier)
        .login(
          AppSession(
            familyId: familyId,
            activeMemberId: hoSo.id,
            isParent: hoSo.kind == MemberKind.parent.name,
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
                vertical: AppSpacing.xl,
              ),
              children: [
                // Nút lùi chỉ có nghĩa khi thật sự còn bước phía trước.
                if (_buoc != _Buoc.nha && !(_buoc == _Buoc.vai && !nhieuNha))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _quayLai,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Quay lại'),
                    ),
                  ),
                const Center(child: BeeMascot(size: 80, mood: BeeMood.happy)),
                const SizedBox(height: AppSpacing.lg),
                ..._noiDung(dsNha, nhieuNha: nhieuNha),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _noiDung(
    List<NhaVaThanhVien> dsNha, {
    required bool nhieuNha,
  }) {
    return switch (_buoc) {
      _Buoc.nha => [
        const _TieuDe(
          'Nhà nào?',
          phu: 'Máy này đang giữ dữ liệu của nhiều nhà.',
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final muc in dsNha)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _The(
              icon: const AppIcon('family', size: 28),
              mau: context.colors.primary,
              tieuDe: muc.nha.name,
              phu: _tomTatNha(muc),
              onTap: () => _chonNha(muc),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        const _NutTaoNhaMoi(),
      ],
      _Buoc.vai => [
        _TieuDe(
          'Ai đang dùng máy?',
          phu: nhieuNha
              ? 'Nhà «${_nhaDaChon!.nha.name}»'
              : 'Dữ liệu của cả nhà vẫn còn nguyên trên máy này.',
        ),
        const SizedBox(height: AppSpacing.xl),
        _The(
          icon: const AppIcon('av_parent', size: 28),
          mau: context.colors.primary,
          tieuDe: 'Bố mẹ',
          phu: 'Giao việc, duyệt, và đổi cài đặt của nhà',
          onTap: () => unawaited(_chonVai(laBoMe: true)),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Lấy avatar của bé đầu tiên chứ không vẽ một hình "trẻ em" chung:
        // bé nhận ra con vật của mình nhanh hơn nhận ra chữ.
        _The(
          icon: AppIcon(
            iconKeyForEmoji(
              avatarForKey(
                _nhaDaChon!.theoVai(laBoMe: false).firstOrNull?.avatarKey,
              ),
            ),
            size: 28,
          ),
          mau: AppColors.profileColor(
            _nhaDaChon!.theoVai(laBoMe: false).firstOrNull?.colorIndex ?? 0,
          ),
          tieuDe: 'Con',
          phu: _tenCacCon(_nhaDaChon!),
          onTap: () => unawaited(_chonVai(laBoMe: false)),
        ),
        if (!nhieuNha) ...[
          const SizedBox(height: AppSpacing.lg),
          const _NutTaoNhaMoi(),
        ],
      ],
      _Buoc.hoSo => [
        _TieuDe(
          _laBoMe! ? 'Bố hay mẹ?' : 'Con nào?',
          phu: 'Chọn hồ sơ rồi nhập mật khẩu của hồ sơ đó.',
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final hoSo in _nhaDaChon!.theoVai(laBoMe: _laBoMe!))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _The(
              icon: AppIcon(
                _laBoMe!
                    ? 'av_parent'
                    : iconKeyForEmoji(avatarForKey(hoSo.avatarKey)),
                size: 28,
              ),
              mau: _laBoMe!
                  ? context.colors.primary
                  : AppColors.profileColor(hoSo.colorIndex),
              tieuDe: hoSo.displayName,
              phu: _laBoMe! ? 'Bố mẹ' : 'Trẻ',
              khoa: true,
              onTap: () => unawaited(_moHoSo(hoSo)),
            ),
          ),
      ],
    };
  }
}

/// Một dòng đủ để nhận ra đây là nhà nào — tên các con, hoặc số thành viên.
///
/// Máy dính lỗi §2 thường có hai nhà **trùng tên**, vì onboarding điền sẵn "Nhà
/// mình" cho cả hai lần. Chỉ in tên nhà thì hai khối giống hệt nhau và không ai
/// biết nhà nào là nhà cũ của con mình.
String _tomTatNha(NhaVaThanhVien muc) {
  final con = muc.theoVai(laBoMe: false).map((m) => m.displayName).toList();
  if (con.isEmpty) return '${muc.thanhVien.length} thành viên';
  return 'Con: ${con.join(', ')}';
}

String _tenCacCon(NhaVaThanhVien muc) {
  final con = muc.theoVai(laBoMe: false).map((m) => m.displayName).toList();
  return con.isEmpty ? 'Chưa có bé nào' : con.join(', ');
}

class _TieuDe extends StatelessWidget {
  const _TieuDe(this.chinh, {required this.phu});

  final String chinh;
  final String phu;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          chinh,
          textAlign: TextAlign.center,
          style: context.text.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          phu,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}

/// Máy đã có dữ liệu thì không còn đường nào vào onboarding nữa — đó là bản sửa
/// của §2. Nhưng chặn sạch cũng là một cái bẫy khác: nhà muốn làm lại từ đầu sẽ
/// kẹt vĩnh viễn với dữ liệu cũ. Để lại đúng một đường, đi qua tham số nói rõ ý
/// định, và onboarding còn hỏi lại một lần nữa trước khi ghi.
class _NutTaoNhaMoi extends StatelessWidget {
  const _NutTaoNhaMoi();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => context.go(Routes.taoNhaMoi),
        icon: const Icon(Icons.add_home_outlined),
        label: const Text('Tạo nhà mới'),
      ),
    );
  }
}

class _The extends StatelessWidget {
  const _The({
    required this.icon,
    required this.mau,
    required this.tieuDe,
    required this.phu,
    required this.onTap,
    this.khoa = false,
  });

  final Widget icon;
  final Color mau;
  final String tieuDe;
  final String phu;
  final VoidCallback onTap;

  /// Hiện ổ khoá — nói trước rằng bấm vào sẽ bị hỏi mật khẩu, thay vì để người
  /// ta bấm rồi mới bất ngờ.
  final bool khoa;

  @override
  Widget build(BuildContext context) {
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
                child: icon,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tieuDe, style: context.text.titleSmall),
                    Text(
                      phu,
                      style: context.text.bodySmall?.copyWith(
                        color: context.semantic.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (khoa)
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
