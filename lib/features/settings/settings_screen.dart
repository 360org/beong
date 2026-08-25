import 'dart:async';
import 'package:beong/app/router.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/du_lieu_may_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/providers/theme_mode_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/services/money_exchange.dart';
import 'package:beong/domain/services/penalty_policy.dart';
import 'package:beong/features/members/add_child_sheet.dart';
import 'package:beong/features/members/edit_child_sheet.dart';
import 'package:beong/features/members/mat_khau_sheet.dart';
import 'package:beong/features/members/pairing_sheet.dart';
import 'package:beong/features/settings/bao_loi_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final memberDao = ref.watch(memberRepositoryProvider);

    Future<void> deleteFamily(Family family) async {
      // 1. Yêu cầu nhập mật khẩu bố mẹ trước khi xoá gia đình
      final hopLe = await hoiMatKhau(
        context,
        memberId: session.activeMemberId,
        tenHienThi: 'Bố mẹ',
        service: ref.read(matKhauHoSoProvider),
        moTa: 'Nhập mật khẩu phụ huynh để xác nhận xoá toàn bộ gia đình',
      );
      if (!hopLe || !context.mounted) return;

      // 2. Hộp thoại cảnh báo lần cuối
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Xoá gia đình «${family.name}»?'),
          content: const Text(
            'Toàn bộ hồ sơ thành viên, danh sách nhiệm vụ, thói quen, lịch sử làm việc '
            'và tích luỹ xu của gia đình này sẽ bị xoá hoàn toàn khỏi máy.',
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
              child: const Text('XOÁ TOÀN BỘ'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      // 3. Thực hiện xoá và đăng xuất
      await ref.read(memberRepositoryProvider).deleteFamily(family.id);
      await ref.read(sessionProvider.notifier).logout();
      await ref.read(mayDaCoDuLieuProvider.notifier).nap();

      if (context.mounted) {
        context.go(Routes.chonNguoiDung);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt', style: context.text.titleLarge),
      ),
      body: StreamBuilder<List<Member>>(
        stream: memberDao.watchMembers(session.familyId),
        builder: (context, snap) {
          final members = snap.data ?? [];

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingMobile,
              vertical: AppSpacing.lg,
            ),
            children: [
              StreamBuilder<Family>(
                stream: memberDao.watchFamily(session.familyId),
                builder: (context, familySnap) {
                  final family = familySnap.data;
                  if (family == null) return const SizedBox.shrink();
                  return _FamilyInfoCard(
                    family: family,
                    onDelete: () => unawaited(deleteFamily(family)),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Gia đình', style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              ...members.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _MemberTile(
                    member: member,
                    isActive: member.id == session.activeMemberId,
                    onTap: () {
                      if (member.kind == MemberKind.child.name) {
                        unawaited(showEditChildSheet(context, child: member));
                      } else {
                        unawaited(
                          _switchMember(context, ref, member: member),
                        );
                      }
                    },
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => unawaited(
                    showAddChildSheet(
                      context,
                      familyId: session.familyId,
                      nextColorIndex: nextFreeColorIndex(members),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_alt_rounded),
                  label: const Text('Thêm bé'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SettingsSection(
                children: [
                  _TimezoneTile(familyId: session.familyId),
                  _RolloverTile(familyId: session.familyId),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Quy tắc xu', style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _SettingsSection(
                children: [
                  _ApprovalTile(familyId: session.familyId),
                  _AllocationTile(familyId: session.familyId),
                  _JarsTile(familyId: session.familyId),
                  _PenaltyTile(familyId: session.familyId),
                  _ExchangeRateTile(familyId: session.familyId),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Ứng dụng', style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _SettingsSection(
                children: [
                  const _ThemeTile(),
                  _MatKhauTile(familyId: session.familyId),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Thông tin & Hỗ trợ', style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _SettingsSection(
                children: [
                  _SettingsTile(
                    icon: Icons.shield_outlined,
                    title: 'Chính sách quyền riêng tư',
                    subtitle: 'beong.net/quyen-rieng-tu.html',
                    onTap: () => unawaited(
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Quyền riêng tư'),
                          content: const Text(
                            'Bé Ong là ứng dụng offline-first, tôn trọng tuyệt đối dữ liệu của gia đình.\n\n'
                            '• Không thu thập thông tin cá nhân của trẻ\n'
                            '• Dữ liệu lưu trữ an toàn trên thiết bị của bạn\n'
                            '• Chi tiết tại: https://beong.net/quyen-rieng-tu.html',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('ĐÓNG'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Điều khoản sử dụng',
                    subtitle: 'beong.net/dieu-khoan.html',
                    onTap: () => unawaited(
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Điều khoản sử dụng'),
                          content: const Text(
                            'Bé Ong được phát triển phi lợi nhuận vì cộng đồng bởi 360 CORP.\n\n'
                            '• Miễn phí 100% không quảng cáo\n'
                            '• Xem đầy đủ tại: https://beong.net/dieu-khoan.html',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('ĐÓNG'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.mail_outline_rounded,
                    title: 'Liên hệ hỗ trợ',
                    subtitle: 'info@beong.net',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.bug_report_outlined,
                    title: 'Báo lỗi',
                    subtitle: 'Gửi cho nhà phát triển',
                    onTap: () => unawaited(moManBaoLoi(context)),
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'Phiên bản',
                    subtitle: kPhienBanApp,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Trước đây nút này ghi "ĐĂNG XUẤT" — chữ sai với việc nó làm:
              // app không có tài khoản nào để xuất ra. Nó chỉ bỏ lựa chọn "ai
              // đang dùng máy" rồi hỏi lại. Chữ cũ khiến bố mẹ tưởng bấm vào là
              // mất dữ liệu, mà thật ra dữ liệu vẫn còn nguyên.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    unawaited(ref.read(sessionProvider.notifier).logout());
                  },
                  icon: const Icon(Icons.lock_outline_rounded),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSpacing.giant),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  label: const Text('KHOÁ LẠI'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Máy sẽ hỏi lại ai đang dùng. Dữ liệu của cả nhà vẫn còn nguyên '
                'trên máy này.',
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          );
        },
      ),
    );
  }
}

class _FamilyInfoCard extends StatelessWidget {
  const _FamilyInfoCard({
    required this.family,
    required this.onDelete,
  });

  final Family family;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const AppIcon('family', size: 28),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(family.name, style: context.text.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Múi giờ: ${family.timezone}',
                    style: context.text.bodySmall?.copyWith(
                      color: context.semantic.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: context.semantic.danger,
              tooltip: 'Xoá gia đình này',
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isActive,
    required this.onTap,
  });

  final Member member;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isParent = member.kind == MemberKind.parent.name;
    final color = isParent
        ? context.colors.primary
        : AppColors.profileColor(member.colorIndex);

    return Card(
      color: isActive ? context.colors.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  // Vai bố mẹ không chọn avatar con vật; dùng hình người bóng
                  // đen trung tính, không mang giới tính hay màu da.
                  isParent
                      ? 'av_parent'
                      : iconKeyForEmoji(avatarForKey(member.avatarKey)),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.displayName, style: context.text.titleSmall),
                    if (isParent)
                      Text(
                        'Bố mẹ',
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.onSurfaceMuted,
                        ),
                      )
                    else
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: context.semantic.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Chưa kết nối máy',
                            style: context.text.bodySmall?.copyWith(
                              color: context.semantic.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (!isParent) ...[
                IconButton(
                  icon: const Icon(Icons.qr_code_rounded),
                  tooltip: 'Ghép cặp máy',
                  onPressed: () => unawaited(
                    showPairingCodeSheet(
                      context,
                      childName: member.displayName,
                      childMemberId: member.id,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              if (isActive)
                Icon(Icons.check_circle, color: context.colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: context.semantic.onSurfaceMuted),
            const SizedBox(width: AppSpacing.lg),
            // Tiêu đề `Expanded` để đẩy giá trị sang sát mép phải; giá trị
            // `Flexible` để nó chỉ rộng bằng chữ của nó. Trần một nửa chiều
            // rộng là phần quan trọng: không có trần thì phụ đề dài chiếm hết
            // chỗ và ép tiêu đề còn **0 chiều rộng**, chữ xuống dòng mỗi dòng
            // một ký tự. Đã xảy ra thật với dòng "PIN của bố mẹ".
            Expanded(
              child: Text(
                title,
                style: context.text.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                subtitle,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right,
              color: context.semantic.onSurfaceMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Đổi hồ sơ — hỏi mật khẩu của **chính hồ sơ đích** (ADR-027).
///
/// Trước ADR-027 chỗ này chỉ hỏi khi đích đến là vai bố mẹ, vì PIN là của cả
/// nhà và chỉ để chặn trẻ vào Cài đặt. Nay mật khẩu là thứ định danh từng
/// người, nên mở hồ sơ nào cũng phải qua mật khẩu của hồ sơ đó — kể cả từ trong
/// Cài đặt, nơi bố mẹ đưa máy cho con rồi quên đổi vai lại là chuyện thường.
Future<void> _switchMember(
  BuildContext context,
  WidgetRef ref, {
  required Member member,
}) async {
  final ok = await hoiMatKhau(
    context,
    memberId: member.id,
    tenHienThi: member.displayName,
    service: ref.read(matKhauHoSoProvider),
  );
  if (!ok) return;

  await ref
      .read(sessionProvider.notifier)
      .switchMember(
        member.id,
        isParent: member.kind == MemberKind.parent.name,
      );
}

/// Chọn giao diện sáng / tối / theo hệ thống.
class _ThemeTile extends ConsumerWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeSettingProvider);
    return _SettingsTile(
      icon: Icons.dark_mode_outlined,
      title: 'Giao diện',
      subtitle: tenCheDoGiaoDien(mode),
      onTap: () => unawaited(_pick(context, ref, mode)),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final chosen = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in ThemeMode.values)
              ListTile(
                leading: Icon(
                  switch (mode) {
                    ThemeMode.system => Icons.brightness_auto_rounded,
                    ThemeMode.light => Icons.light_mode_rounded,
                    ThemeMode.dark => Icons.dark_mode_rounded,
                  },
                ),
                title: Text(tenCheDoGiaoDien(mode)),
                // Dấu tích, không phải chỉ tô màu chữ: WCAG 1.4.1 — không được
                // dùng mỗi màu để phân biệt.
                trailing: mode == current
                    ? Icon(Icons.check_circle, color: context.colors.primary)
                    : null,
                onTap: () => Navigator.pop(sheetContext, mode),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await ref.read(themeModeSettingProvider.notifier).set(chosen);
  }
}

/// Quy đổi xu ra tiền thật — ADR-017.
///
/// **Mặc định tắt.** Gắn việc nhà với tiền là chủ đề gây tranh cãi trong nuôi
/// dạy con, và mặc định của app là một lời khuyên ngầm; nhà nào muốn thì tự bật.
/// Ô này cũng không dụ bật: không có huy hiệu, không có gợi ý, chỉ là một dòng.
class _ExchangeRateTile extends ConsumerWidget {
  const _ExchangeRateTile({required this.familyId});

  final String familyId;

  /// Các mức cho chọn, tính bằng **xu đổi được 1.000 đ**.
  static const _choices = <int>[1, 2, 5, 10, 20, 50];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<MoneyExchange>(
      stream: ref.watch(memberRepositoryProvider).watchExchangeRate(familyId),
      builder: (context, snap) {
        final rate = snap.data;
        return _SettingsTile(
          icon: Icons.payments_outlined,
          title: 'Quy đổi tiền thật',
          subtitle: rate == null
              ? '…'
              : rate.enabled
              ? '${rate.xuPerUnit} xu = 1.000 đ'
              : 'Đang tắt',
          onTap: () => unawaited(_pick(context, ref, rate?.xuPerUnit)),
        );
      },
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    int? current,
  ) async {
    // `-1` là "tắt": `null` đã mang nghĩa "bố mẹ đóng sheet, không chọn gì".
    const off = -1;
    final chosen = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Bật thì con thấy số xu của mình đáng bao nhiêu tiền. Xu vẫn '
                  'là xu — app không trả tiền hộ, bố mẹ tự quy đổi ngoài đời.',
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.onSurfaceMuted,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.money_off_rounded),
                title: const Text('Tắt quy đổi'),
                trailing: current == null
                    ? Icon(Icons.check_circle, color: context.colors.primary)
                    : null,
                onTap: () => Navigator.pop(sheetContext, off),
              ),
              for (final rate in _choices)
                ListTile(
                  leading: const Icon(Icons.payments_rounded),
                  title: Text('$rate xu = 1.000 đ'),
                  trailing: rate == current
                      ? Icon(Icons.check_circle, color: context.colors.primary)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, rate),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    await ref
        .read(memberRepositoryProvider)
        .setExchangeRate(familyId, chosen == off ? null : chosen);
  }
}

/// Cấu hình Múi giờ của gia đình.
class _TimezoneTile extends ConsumerWidget {
  const _TimezoneTile({required this.familyId});

  final String familyId;

  static const _commonTimezones = <String, String>{
    'Asia/Ho_Chi_Minh': 'Việt Nam (GMT+7)',
    'Asia/Bangkok': 'Bangkok (GMT+7)',
    'Asia/Tokyo': 'Tokyo (GMT+9)',
    'Asia/Seoul': 'Seoul (GMT+9)',
    'Asia/Singapore': 'Singapore (GMT+8)',
    'Australia/Sydney': 'Sydney (GMT+10)',
    'Europe/London': 'London (GMT+0)',
    'Europe/Paris': 'Paris (GMT+1)',
    'America/New_York': 'New York (GMT-5)',
    'America/Los_Angeles': 'Los Angeles (GMT-8)',
    'UTC': 'UTC',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Family>(
      stream: ref.watch(memberRepositoryProvider).watchFamily(familyId),
      builder: (context, snap) {
        final family = snap.data;
        final tz = family?.timezone ?? 'Asia/Ho_Chi_Minh';
        return _SettingsTile(
          icon: Icons.public_rounded,
          title: 'Múi giờ',
          subtitle: _commonTimezones[tz] ?? tz,
          onTap: () => unawaited(_pick(context, ref, tz)),
        );
      },
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: 400,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Chọn múi giờ để tính ngày và thời hạn nhiệm vụ chính xác.',
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.onSurfaceMuted,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final entry in _commonTimezones.entries)
                      ListTile(
                        title: Text(entry.value),
                        subtitle: Text(entry.key),
                        trailing: entry.key == current
                            ? Icon(
                                Icons.check_circle,
                                color: context.colors.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(sheetContext, entry.key),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null || chosen.isEmpty) return;
    await ref.read(memberRepositoryProvider).setTimezone(familyId, chosen);
  }
}

/// Giờ đổi ngày của gia đình.
///
/// Không phải chi tiết kỹ thuật: giờ này quyết định lúc nào việc chưa làm bị
/// tính là bỏ lỡ. Nhà cho con thức khuya làm bài mà để 0 giờ thì việc làm lúc
/// 00:10 rơi sang ngày hôm sau và ngày hôm trước bị đánh bỏ lỡ.
class _RolloverTile extends ConsumerWidget {
  const _RolloverTile({required this.familyId});

  final String familyId;

  /// Các mốc cho chọn. Không cho gõ số tuỳ ý: 0–12 là khoảng `FamilyClock` chấp
  /// nhận, và các mốc này phủ hết các kiểu sinh hoạt thật.
  static const _choices = <int, String>{
    0: 'Nửa đêm',
    3: '3 giờ sáng',
    4: '4 giờ sáng',
    5: '5 giờ sáng',
    6: '6 giờ sáng',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<int>(
      stream: ref
          .watch(memberRepositoryProvider)
          .watchDayRolloverHour(familyId),
      builder: (context, snap) {
        final hour = snap.data;
        return _SettingsTile(
          icon: Icons.schedule_rounded,
          title: 'Giờ đổi ngày',
          subtitle: hour == null ? '…' : (_choices[hour] ?? '$hour giờ'),
          onTap: () => unawaited(_pick(context, ref, hour ?? 4)),
        );
      },
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, int current) async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Việc chưa làm xong trước giờ này tính là bỏ lỡ của hôm trước.',
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
            ),
            for (final entry in _choices.entries)
              ListTile(
                title: Text(entry.value),
                trailing: entry.key == current
                    ? Icon(Icons.check_circle, color: context.colors.primary)
                    : null,
                onTap: () => Navigator.pop(sheetContext, entry.key),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await ref
        .read(memberRepositoryProvider)
        .setDayRolloverHour(familyId, chosen);
  }
}

/// Bật/tắt PIN phụ huynh.
/// Dòng "Mật khẩu hồ sơ" trong Cài đặt.
///
/// Đọc trạng thái bằng **stream**, không giữ bản sao. Bản trước đọc một lần lúc
/// dựng rồi chỉ tự nạp lại khi chính nó mở sheet — nên gỡ mật khẩu ở chỗ khác
/// xong, dòng này vẫn ghi "Đang bật" trong khi DB đã sạch. Đây là loại lỗi lặp
/// đi lặp lại của dự án: thứ hiện ra mà không ai cập nhật.
class _MatKhauTile extends ConsumerWidget {
  const _MatKhauTile({required this.familyId});

  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Member>>(
      stream: ref.watch(memberRepositoryProvider).watchMembers(familyId),
      builder: (context, snap) {
        final members = snap.data;
        final thieu = members?.where((m) => (m.pinHash ?? '').isEmpty).length;

        return _SettingsTile(
          icon: Icons.lock_outline_rounded,
          title: 'Mật khẩu hồ sơ',
          // ADR-027 nói không hồ sơ nào được để trống. Nếu còn thiếu thì nói
          // thẳng ra đây chứ không im lặng — máy cài từ bản cũ đang có đúng
          // loại đó, và im lặng thì không ai biết mà đặt.
          // Ngắn cho vừa cột: "2 hồ sơ, đều đã đặt" bị cắt thành "2 hồ sơ,
          // đều đã …" — dòng bị cắt thì nói ít hơn cả dòng ngắn.
          subtitle: switch (thieu) {
            null => '…',
            0 => 'Đã đặt đủ',
            final n => '$n chưa đặt',
          },
          onTap: members == null
              ? () {}
              : () => unawaited(_chonHoSo(context, ref, members)),
        );
      },
    );
  }

  /// Đổi mật khẩu cho một hồ sơ bất kỳ trong nhà.
  ///
  /// Không hỏi mật khẩu cũ: người đang đứng đây đã qua mật khẩu của một hồ sơ
  /// bố mẹ để vào được Cài đặt. Đây cũng chính là đường bố mẹ đặt lại mật khẩu
  /// cho con khi bé quên — thiếu nó là con quên mật khẩu thì mất luôn đường
  /// vào, đúng cái bẫy §3 vừa gỡ, chỉ đổi chiều.
  Future<void> _chonHoSo(
    BuildContext context,
    WidgetRef ref,
    List<Member> members,
  ) async {
    final chon = await showModalBottomSheet<Member>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final member in members)
              ListTile(
                leading: Icon(
                  (member.pinHash ?? '').isEmpty
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                ),
                title: Text(member.displayName),
                subtitle: Text(
                  (member.pinHash ?? '').isEmpty
                      ? 'Chưa đặt mật khẩu'
                      : 'Đổi mật khẩu',
                ),
                onTap: () => Navigator.pop(sheetContext, member),
              ),
          ],
        ),
      ),
    );
    if (chon == null || !context.mounted) return;

    await datMatKhauMoi(
      context,
      memberId: chon.id,
      tenHienThi: chon.displayName,
      service: ref.read(matKhauHoSoProvider),
      batBuoc: (chon.pinHash ?? '').isEmpty,
    );
  }
}

/// Lối vào màn quản lý hũ, kèm tổng tỷ lệ ngay trên dòng.
///
/// Hiện tổng ở đây vì tổng khác 100% làm việc chia xu **âm thầm** rơi về ba hũ
/// mặc định — bố mẹ cần thấy sai sót mà không phải mở màn con ra kiểm.
class _JarsTile extends ConsumerWidget {
  const _JarsTile({required this.familyId});

  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jarDao = ref.watch(jarRepositoryProvider);

    return StreamBuilder<List<JarDef>>(
      stream: jarDao.watchActiveJars(familyId),
      builder: (context, snap) {
        final jars = snap.data ?? const <JarDef>[];
        final total = jars.fold(0, (sum, j) => sum + j.pct);
        return _SettingsTile(
          icon: Icons.savings_outlined,
          title: 'Các hũ',
          subtitle: jars.isEmpty
              ? 'Đang tải…'
              : total == 100
              ? '${jars.length} hũ · đủ 100%'
              : '${jars.length} hũ · mới $total%',
          onTap: () => context.go(Routes.jarSettings),
        );
      },
    );
  }
}

/// Ô "Trừ xu" trong Cài đặt.
///
/// Hiện luôn mức đang đặt ngay ở dòng phụ, không chỉ ghi "Cấu hình": bố mẹ phải
/// thấy được nhà mình đang bật trừ xu hay không mà không cần bấm vào.
class _PenaltyTile extends ConsumerWidget {
  const _PenaltyTile({required this.familyId});

  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberDao = ref.watch(memberRepositoryProvider);

    return StreamBuilder<PenaltyPolicy>(
      stream: memberDao.watchPenaltyPolicy(familyId),
      builder: (context, snap) {
        final policy = snap.data ?? PenaltyPolicy.off;
        return _SettingsTile(
          icon: Icons.remove_circle_outline,
          title: 'Trừ xu',
          subtitle: policy.isEnabled
              ? 'Chưa làm ${policy.missedPct}% · Làm lại ${policy.reopenPct}%'
              : 'Đang tắt',
          onTap: () => context.go(Routes.penaltySettings),
        );
      },
    );
  }
}

/// Công tắc "Cần bố mẹ duyệt" — ADR-023.
///
/// Mặc định **tắt**: con bấm xong là xong, xu cộng ngay. Bật lên thì mọi việc
/// con bấm xong vào hàng đợi ở Trang chính.
class _ApprovalTile extends ConsumerWidget {
  const _ApprovalTile({required this.familyId});

  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberDao = ref.watch(memberRepositoryProvider);

    return StreamBuilder<bool>(
      stream: memberDao.watchRequireApproval(familyId),
      builder: (context, snap) {
        final on = snap.data ?? false;
        return SwitchListTile(
          value: on,
          onChanged: (v) => unawaited(
            memberDao.setRequireApproval(familyId, value: v),
          ),
          secondary: Icon(
            Icons.verified_outlined,
            color: context.colors.primary,
          ),
          title: Text('Cần bố mẹ duyệt', style: context.text.bodyLarge),
          subtitle: Text(
            on
                ? 'Việc con bấm xong chờ bố mẹ duyệt mới được cộng xu'
                : 'Con bấm xong là xong, xu cộng ngay',
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
          ),
        );
      },
    );
  }
}

/// Chọn cách xu vào hũ — ADR-024.
///
/// Mặc định `auto` (chia ngay theo tỷ lệ). Bật "con tự chia" thì xu dồn vào hũ
/// chờ và con quyết định cuối ngày — bản thân việc chia mới là bài học.
class _AllocationTile extends ConsumerWidget {
  const _AllocationTile({required this.familyId});

  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberDao = ref.watch(memberRepositoryProvider);

    return StreamBuilder<AllocationMode>(
      stream: memberDao.watchAllocationMode(familyId),
      builder: (context, snap) {
        final mode = snap.data ?? AllocationMode.auto;
        final manual = mode == AllocationMode.manual;

        return SwitchListTile(
          value: manual,
          onChanged: (v) => unawaited(
            memberDao.setAllocationMode(
              familyId,
              v ? AllocationMode.manual : AllocationMode.auto,
            ),
          ),
          secondary: Icon(
            Icons.pie_chart_outline_rounded,
            color: context.colors.primary,
          ),
          title: Text('Con tự chia xu', style: context.text.bodyLarge),
          subtitle: Text(
            manual
                ? 'Xu dồn lại, con tự chia vào các hũ cuối ngày'
                : 'Xu tự chia vào các hũ theo tỷ lệ đã đặt',
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
          ),
        );
      },
    );
  }
}
