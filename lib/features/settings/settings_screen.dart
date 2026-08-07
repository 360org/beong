import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final memberDao = ref.watch(memberDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cai dat', style: context.text.titleLarge),
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
              Text('Thanh vien', style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.md),
              ...members.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _MemberTile(
                    member: member,
                    isActive: member.id == session.activeMemberId,
                    onTap: () {
                      ref
                          .read(sessionProvider.notifier)
                          .switchMember(
                            member.id,
                            isParent: member.kind == MemberKind.parent.name,
                          );
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _SettingsSection(
                children: [
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Giao dien',
                    subtitle: 'Theo he thong',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Thong bao',
                    subtitle: 'Bat',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'Phien ban',
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
                    ref.read(sessionProvider.notifier).logout();
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
                  child: const Text('DANG XUAT'),
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
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.family_restroom_rounded,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(family.name, style: context.text.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Mui gio: ${family.timezone}',
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
              CircleAvatar(
                backgroundColor: color,
                radius: 20,
                child: Text(
                  member.displayName.isNotEmpty
                      ? member.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.displayName, style: context.text.titleSmall),
                    Text(
                      isParent ? 'Bo me' : 'Tre',
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
            Expanded(
              child: Text(title, style: context.text.bodyLarge),
            ),
            Text(
              subtitle,
              style: context.text.bodyMedium?.copyWith(
                color: context.semantic.onSurfaceMuted,
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
