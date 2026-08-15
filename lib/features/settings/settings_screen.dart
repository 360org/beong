import 'dart:async';

import 'package:beong/app/router.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/services/penalty_policy.dart';
import 'package:beong/features/settings/parent_pin_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final memberDao = ref.watch(memberDaoProvider);

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
                  return _FamilyInfoCard(family: family);
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Thành viên', style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              ...members.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _MemberTile(
                    member: member,
                    isActive: member.id == session.activeMemberId,
                    onTap: () => unawaited(
                      _switchMember(
                        context,
                        ref,
                        member: member,
                        familyId: session.familyId,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _SettingsSection(
                children: [
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Giao diện',
                    subtitle: 'Theo hệ thống',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Thông báo',
                    subtitle: 'Bật',
                    onTap: () {},
                  ),
                  _PinTile(familyId: session.familyId),
                  _ApprovalTile(familyId: session.familyId),
                  _AllocationTile(familyId: session.familyId),
                  _JarsTile(familyId: session.familyId),
                  _PenaltyTile(familyId: session.familyId),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'Phiên bản',
                    subtitle: '0.2.0',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    unawaited(ref.read(sessionProvider.notifier).logout());
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.semantic.danger,
                    side: BorderSide(color: context.semantic.danger),
                    minimumSize: const Size.fromHeight(AppSpacing.giant),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  child: const Text('ĐĂNG XUẤT'),
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
  const _FamilyInfoCard({required this.family});

  final Family family;

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
                    Text(
                      isParent ? 'Bố mẹ' : 'Trẻ',
                      style: context.text.bodySmall?.copyWith(
                        color: context.semantic.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
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

/// Đổi hồ sơ, hỏi PIN nếu đích đến là vai bố mẹ.
///
/// Màn Cài đặt chỉ vai bố mẹ mới vào được, nhưng chỗ này vẫn phải hỏi: bố mẹ đưa
/// máy cho con rồi quên đổi lại vai là chuyện thường, và lúc đó con vẫn đang
/// đứng trong Cài đặt.
Future<void> _switchMember(
  BuildContext context,
  WidgetRef ref, {
  required Member member,
  required String familyId,
}) async {
  final isParent = member.kind == MemberKind.parent.name;
  if (isParent) {
    final ok = await askParentPin(
      context,
      familyId: familyId,
      service: ref.read(parentPinServiceProvider),
    );
    if (!ok) return;
  }
  await ref
      .read(sessionProvider.notifier)
      .switchMember(member.id, isParent: isParent);
}

/// Bật/tắt PIN phụ huynh.
class _PinTile extends ConsumerStatefulWidget {
  const _PinTile({required this.familyId});

  final String familyId;

  @override
  ConsumerState<_PinTile> createState() => _PinTileState();
}

class _PinTileState extends ConsumerState<_PinTile> {
  bool? _isSet;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final isSet = await ref
        .read(parentPinServiceProvider)
        .isSet(widget.familyId);
    if (mounted) setState(() => _isSet = isSet);
  }

  @override
  Widget build(BuildContext context) {
    final isSet = _isSet;
    return _SettingsTile(
      icon: Icons.lock_outline_rounded,
      title: 'PIN của bố mẹ',
      // Chữ ngắn như các dòng khác; lời giải thích dài nằm trong sheet, không
      // nhét vào một hàng cao 48px.
      subtitle: isSet == null
          ? '…'
          : isSet
          ? 'Đang bật'
          : 'Chưa đặt',
      onTap: () => unawaited(_open(isSet ?? false)),
    );
  }

  Future<void> _open(bool isSet) async {
    final service = ref.read(parentPinServiceProvider);

    if (!isSet) {
      await askNewParentPin(
        context,
        familyId: widget.familyId,
        service: service,
      );
      await _load();
      return;
    }

    // Đã có PIN: phải nhập PIN cũ trước khi đổi hay bỏ. Không hỏi thì đứa trẻ
    // đang cầm máy chỉ việc bấm "Bỏ PIN" là xong.
    if (!await askParentPin(
      context,
      familyId: widget.familyId,
      service: service,
    )) {
      return;
    }
    if (!mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.password_rounded),
              title: const Text('Đổi PIN'),
              onTap: () => Navigator.pop(sheetContext, 'change'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_open_rounded),
              title: const Text('Bỏ PIN'),
              onTap: () => Navigator.pop(sheetContext, 'clear'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;

    if (action == 'change') {
      await askNewParentPin(
        context,
        familyId: widget.familyId,
        service: service,
      );
    } else if (action == 'clear') {
      await service.clearPin(widget.familyId);
    }
    await _load();
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
    final jarDao = ref.watch(jarDaoProvider);

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
    final memberDao = ref.watch(memberDaoProvider);

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
    final memberDao = ref.watch(memberDaoProvider);

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
    final memberDao = ref.watch(memberDaoProvider);

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
