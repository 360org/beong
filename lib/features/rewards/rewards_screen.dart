import 'dart:async';
import 'dart:convert';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/icon_picker.dart';
import 'package:beong/core/widgets/loi_man_hinh.dart';
import 'package:beong/core/widgets/preset_chip.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/entities/reward_presets.dart';
import 'package:beong/domain/repositories/jar_repository.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/reward_repository.dart';
import 'package:beong/domain/repositories/wallet_repository.dart';
import 'package:beong/domain/services/redemption_service.dart';
import 'package:beong/features/rewards/allocate_xu_sheet.dart';
import 'package:beong/features/rewards/redemption_queue.dart';
import 'package:beong/features/rewards/wish_sheet.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  String? _selectedMemberFilter;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final rewardDao = ref.watch(rewardRepositoryProvider);
    final walletDao = ref.watch(walletRepositoryProvider);
    final jarDao = ref.watch(jarRepositoryProvider);
    final memberDao = ref.watch(memberRepositoryProvider);
    final redemptionService = ref.watch(redemptionServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Phần thưởng', style: context.text.titleLarge),
        actions: [
          if (session.isParent)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: StreamBuilder<WalletBalance>(
                stream: walletDao.watchBalance(session.activeMemberId),
                builder: (context, snap) {
                  final balance = snap.data ?? WalletBalance.zero;
                  return XuBadge(amount: balance.spend);
                },
              ),
            ),
        ],
      ),
      // `LuongDuLieu` chứ không `StreamBuilder` trần: luồng hỏng mà rơi về
      // danh sách rỗng thì màn hình nói "chưa có phần thưởng nào" — người dùng
      // thấy dữ liệu **sai** chứ không thấy lỗi.
      body: LuongDuLieu<List<Reward>>(
        stream: rewardDao.watchRewards(session.familyId),
        builder: (context, allRewards) {
          // Lọc phần thưởng:
          // - Con: Chỉ thấy quà cho tất cả hoặc quà gán đích danh cho mình
          // - Bố mẹ: Xem theo bộ lọc chọn bé
          final rewards = allRewards.where((r) {
            String? targetId;
            if (r.metaJson != null && r.metaJson!.isNotEmpty) {
              try {
                final map = jsonDecode(r.metaJson!) as Map<String, dynamic>;
                targetId = map['targetMemberId'] as String?;
              } on Object {
                targetId = null;
              }
            }

            if (!session.isParent) {
              return targetId == null || targetId == session.activeMemberId;
            }

            if (_selectedMemberFilter != null) {
              return targetId == _selectedMemberFilter;
            }
            return true;
          }).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingMobile,
              vertical: AppSpacing.lg,
            ),
            children: [
              // Vai con: Banner xu tổng + lưới các hũ xu trên cùng
              if (!session.isParent) ...[
                StreamBuilder<WalletBalance>(
                  stream: walletDao.watchBalance(session.activeMemberId),
                  builder: (context, balSnap) {
                    final balance = balSnap.data ?? WalletBalance.zero;

                    return StreamBuilder<List<JarDef>>(
                      stream: jarDao.watchActiveJars(session.familyId),
                      builder: (context, jarsSnap) {
                        final jars = jarsSnap.data ?? const <JarDef>[];

                        return _ChildWalletJarsBanner(
                          balance: balance,
                          jars: jars,
                          onAllocate: balance.inbox > 0
                              ? () => unawaited(
                                  _openAllocateSheet(
                                    context: context,
                                    familyId: session.familyId,
                                    memberId: session.activeMemberId,
                                    inbox: balance.inbox,
                                    walletDao: walletDao,
                                    jarDao: jarDao,
                                  ),
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Hàng đợi/phiếu hiện trên danh sách phần thưởng
              if (session.isParent)
                RedemptionQueue(
                  familyId: session.familyId,
                  reviewerId: session.activeMemberId,
                  rewardDao: rewardDao,
                  redemptionService: redemptionService,
                )
              else
                MyVouchers(
                  memberId: session.activeMemberId,
                  rewardDao: rewardDao,
                  redemptionService: redemptionService,
                ),

              if (session.isParent) ...[
                // Bộ lọc phần thưởng theo từng bé cho phụ huynh
                StreamBuilder<List<Member>>(
                  stream: memberDao.watchMembers(session.familyId),
                  builder: (context, snap) {
                    final children = (snap.data ?? const <Member>[])
                        .where((m) => m.kind == MemberKind.child.name)
                        .toList();
                    if (children.length <= 1) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
                              child: FilterChip(
                                label: const Text('Tất cả'),
                                selected: _selectedMemberFilter == null,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(
                                      () => _selectedMemberFilter = null,
                                    );
                                  }
                                },
                              ),
                            ),
                            ...children.map((child) {
                              final isSel = _selectedMemberFilter == child.id;
                              final childColor = AppColors.profileColor(
                                child.colorIndex,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.xs,
                                ),
                                child: FilterChip(
                                  avatar: CircleAvatar(
                                    backgroundColor: childColor.withValues(
                                      alpha: 0.25,
                                    ),
                                    child: Text(
                                      child.avatarKey ?? '👶',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  label: Text(child.displayName),
                                  selected: isSel,
                                  onSelected: (sel) {
                                    setState(() {
                                      _selectedMemberFilter = sel
                                          ? child.id
                                          : null;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],

              if (!session.isParent) ...[
                Text(
                  'CÁC PHẦN THƯỞNG CÓ THỂ ĐỔI',
                  style: context.text.labelMedium?.copyWith(
                    color: context.semantic.onSurfaceMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (rewards.isEmpty)
                _EmptyState(
                  isParent: session.isParent,
                  onAdd: () =>
                      _showRewardEditor(context, rewardDao, session.familyId),
                  onPickPreset: (preset) => unawaited(
                    _createFromPreset(rewardDao, session.familyId, preset),
                  ),
                ),
              ...rewards.map(
                (reward) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _RewardCard(
                    reward: reward,
                    session: session,
                    rewardDao: rewardDao,
                    walletDao: walletDao,
                    redemptionService: redemptionService,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: session.isParent
          ? FloatingActionButton(
              onPressed: () =>
                  _showRewardEditor(context, rewardDao, session.familyId),
              child: const Icon(Icons.add),
            )
          : FloatingActionButton.extended(
              onPressed: () => showWishSheet(
                context,
                familyId: session.familyId,
                memberId: session.activeMemberId,
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('ĐIỀU ƯỚC'),
            ),
    );
  }

  Future<void> _openAllocateSheet({
    required BuildContext context,
    required String familyId,
    required String memberId,
    required int inbox,
    required WalletRepository walletDao,
    required JarRepository jarDao,
  }) async {
    final activeJars = await jarDao.activeJars(familyId);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) => AllocateXuSheet(
        familyId: familyId,
        memberId: memberId,
        inbox: inbox,
        walletDao: walletDao,
        jars: activeJars,
      ),
    );
  }

  /// Tạo phần thưởng trực tiếp từ template, không mở thêm màn nào.
  ///
  /// Bố mẹ sửa lại tên/giá sau được — mục đích là để trang không còn trống sau
  /// **một** cú chạm.
  Future<void> _createFromPreset(
    RewardRepository rewardDao,
    String familyId,
    RewardPreset preset,
  ) async {
    await rewardDao.createReward(
      RewardsCompanion.insert(
        id: 'reward-${preset.key}-${DateTime.now().millisecondsSinceEpoch}',
        familyId: familyId,
        title: preset.titleVi,
        costPoints: preset.defaultCost,
        iconKey: Value(preset.iconKey),
        rewardType: Value(preset.rewardType),
      ),
    );
  }
}

/// Banner xu và lưới các hũ xu dành cho trẻ em trong tab Rewards.
class _ChildWalletJarsBanner extends StatelessWidget {
  const _ChildWalletJarsBanner({
    required this.balance,
    required this.jars,
    this.onAllocate,
  });

  final WalletBalance balance;
  final List<JarDef> jars;
  final VoidCallback? onAllocate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thẻ gradient tổng xu
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: context.dashboardGradient,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TỔNG XU CỦA CON',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const AppIcon('gem'),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${balance.total} xu',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              if (balance.inbox > 0) ...[
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: onAllocate,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon('jar_inbox', size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Có ${balance.inbox} xu chưa chia vào hũ ›',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Lưới các hũ xu
        Text(
          'CÁC HŨ XU CỦA CON',
          style: context.text.labelMedium?.copyWith(
            color: context.semantic.onSurfaceMuted,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        if (jars.isEmpty)
          // Fallback nếu chưa tải xong jars
          Row(
            children: [
              Expanded(
                child: _JarItemCard(
                  title: 'Chi tiêu',
                  emoji: '🛒',
                  amount: balance.spend,
                  isSpendable: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _JarItemCard(
                  title: 'Tiết kiệm',
                  emoji: '🐷',
                  amount: balance.save,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _JarItemCard(
                  title: 'Chia sẻ',
                  emoji: '❤️',
                  amount: balance.give,
                ),
              ),
            ],
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: jars.map((j) {
              final jarBalance = balance.ofKey(j.key);
              final isSpendable = j.key == kJarSpend;
              return SizedBox(
                width:
                    (MediaQuery.of(context).size.width -
                        AppSpacing.screenPaddingMobile * 2 -
                        AppSpacing.sm * 2) /
                    (jars.length <= 3 ? jars.length : 3),
                child: _JarItemCard(
                  title: j.title,
                  emoji: j.emoji,
                  amount: jarBalance,
                  isSpendable: isSpendable,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _JarItemCard extends StatelessWidget {
  const _JarItemCard({
    required this.title,
    required this.emoji,
    required this.amount,
    this.isSpendable = false,
  });

  final String title;
  final String emoji;
  final int amount;
  final bool isSpendable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isSpendable
            ? context.colors.primaryContainer.withValues(alpha: 0.65)
            : context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isSpendable
              ? context.colors.primary.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppIcon(iconKeyForEmoji(emoji)),
              if (isSpendable)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'Đổi quà',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: context.text.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.semantic.onSurfaceMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$amount xu',
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: isSpendable
                  ? context.semantic.xuText
                  : context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

void _showRewardEditor(
  BuildContext context,
  RewardRepository rewardDao,
  String familyId, [
  Reward? reward,
]) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RewardEditorSheet(
        rewardDao: rewardDao,
        familyId: familyId,
        reward: reward,
      ),
    ),
  );
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.session,
    required this.rewardDao,
    required this.walletDao,
    required this.redemptionService,
  });

  final Reward reward;
  final AppSession session;
  final RewardRepository rewardDao;
  final WalletRepository walletDao;
  final RedemptionService redemptionService;

  @override
  Widget build(BuildContext context) {
    final isChild = !session.isParent;

    String? targetMemberId;
    if (reward.metaJson != null && reward.metaJson!.isNotEmpty) {
      try {
        final map = jsonDecode(reward.metaJson!) as Map<String, dynamic>;
        targetMemberId = map['targetMemberId'] as String?;
      } on Object {
        targetMemberId = null;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.field),
              ),
              child: AppIcon.task(reward.iconKey, size: 26),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.title,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.xs,
                    runSpacing: 4,
                    children: [
                      XuBadge(amount: reward.costPoints, pill: true),
                      if (targetMemberId != null && session.isParent)
                        Consumer(
                          builder: (context, ref, _) {
                            final memberDao = ref.watch(
                              memberRepositoryProvider,
                            );
                            return StreamBuilder<Member>(
                              stream: memberDao.watchMember(targetMemberId!),
                              builder: (context, snap) {
                                final m = snap.data;
                                if (m == null) return const SizedBox.shrink();
                                final childColor = AppColors.profileColor(
                                  m.colorIndex,
                                );
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: childColor.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        m.avatarKey ?? '👶',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        m.displayName,
                                        style: context.text.labelSmall
                                            ?.copyWith(
                                              color: childColor,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      if (reward.stock != null) ...[
                        Text(
                          '· Còn ${reward.stock}',
                          style: context.text.bodySmall?.copyWith(
                            color: context.semantic.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Nói trước, không để con phát hiện sau khi bấm: xu đã trừ mà
                  // phần thưởng chưa dùng được là chỗ dễ hiểu lầm nhất.
                  if (isChild) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: context.semantic.onSurfaceMuted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Cần bố mẹ duyệt',
                          style: context.text.labelSmall?.copyWith(
                            color: context.semantic.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isChild)
              _RedeemButton(
                reward: reward,
                session: session,
                rewardDao: rewardDao,
                walletDao: walletDao,
                redemptionService: redemptionService,
              ),
            if (session.isParent) ...[
              IconButton(
                onPressed: () => _showRewardEditor(
                  context,
                  rewardDao,
                  session.familyId,
                  reward,
                ),
                icon: Icon(
                  Icons.edit_outlined,
                  color: context.semantic.onSurfaceMuted,
                ),
                tooltip: 'Sửa',
              ),
              IconButton(
                onPressed: () => rewardDao.deleteReward(reward.id),
                icon: Icon(
                  Icons.delete_outline,
                  color: context.semantic.onSurfaceMuted,
                ),
                tooltip: 'Xoá',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RedeemButton extends StatefulWidget {
  const _RedeemButton({
    required this.reward,
    required this.session,
    required this.rewardDao,
    required this.walletDao,
    required this.redemptionService,
  });

  final Reward reward;
  final AppSession session;
  final RewardRepository rewardDao;
  final WalletRepository walletDao;
  final RedemptionService redemptionService;

  @override
  State<_RedeemButton> createState() => _RedeemButtonState();
}

class _RedeemButtonState extends State<_RedeemButton> {
  bool _loading = false;

  Future<void> _redeem() async {
    setState(() => _loading = true);
    try {
      // Đi qua service: nó kiểm còn hàng và đủ xu **trước khi** trừ xu.
      await widget.redemptionService.redeem(
        familyId: widget.session.familyId,
        memberId: widget.session.activeMemberId,
        reward: widget.reward,
        clientOpId:
            'redeem-${widget.reward.id}-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã gửi yêu cầu đổi "${widget.reward.title}". Chờ bố mẹ duyệt.',
            ),
          ),
        );
      }
    } on RedemptionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } on WalletException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return StreamBuilder<WalletBalance>(
      stream: widget.walletDao.watchBalance(widget.session.activeMemberId),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? WalletBalance.zero;
        final currentSpend = balance.of(Jar.spend);
        final cost = widget.reward.costPoints;
        final hasEnough = currentSpend >= cost;
        final deficit = cost - currentSpend;

        if (!hasEnough) {
          return FilledButton.tonal(
            onPressed: null,
            child: Text('Thiếu $deficit xu'),
          );
        }

        return FilledButton.tonal(
          onPressed: _redeem,
          child: const Text('Đổi'),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isParent,
    required this.onAdd,
    required this.onPickPreset,
  });

  final bool isParent;
  final VoidCallback onAdd;
  final ValueChanged<RewardPreset> onPickPreset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon('jar_gift', size: 60),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Chưa có phần thưởng nào',
              style: context.text.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isParent
                  ? 'Tạo phần thưởng để bé có động lực!'
                  : 'Bố mẹ chưa tạo phần thưởng.',
              style: context.text.bodyMedium?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (isParent) ...[
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton(
                onPressed: onAdd,
                child: const Text('THÊM PHẦN THƯỞNG'),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // Template hiện **ngay ở trang trống**, không chôn trong bottom
              // sheet sau nút "+". Trang trống kèm một nút là chỗ nhiều bố mẹ
              // bỏ app: không phải vì thiếu tính năng, mà vì không biết bắt đầu
              // từ đâu. Thấy vài gợi ý cụ thể thì bấm một cái là có ngay.
              _PresetSuggestions(onPick: onPickPreset),
            ],
          ],
        ),
      ),
    );
  }
}

/// Vài template gợi ý, bấm một cái là tạo luôn.
class _PresetSuggestions extends StatelessWidget {
  const _PresetSuggestions({required this.onPick});

  final ValueChanged<RewardPreset> onPick;

  @override
  Widget build(BuildContext context) {
    // Sáu cái đầu, không phải cả 12: trang trống cần **gợi ý**, không cần
    // catalogue. Còn lại xem trong bottom sheet.
    final suggestions = kRewardPresets.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOẶC CHỌN NHANH',
          style: context.text.labelSmall?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            for (final preset in suggestions)
              GestureDetector(
                onTap: () => onPick(preset),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(AppRadius.field),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon.task(preset.iconKey, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        preset.titleVi,
                        style: context.text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${preset.defaultCost}',
                        style: context.text.bodySmall?.copyWith(
                          color: context.semantic.xuText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Form thêm hoặc sửa phần thưởng.
///
/// Bố mẹ có thể tạo mới hoặc chỉnh sửa tên, hình đại diện, mức giá (xu) và số
/// lượng tồn kho (`stock`) nếu có.
class _RewardEditorSheet extends StatefulWidget {
  const _RewardEditorSheet({
    required this.rewardDao,
    required this.familyId,
    this.reward,
  });

  final RewardRepository rewardDao;
  final String familyId;
  final Reward? reward;

  @override
  State<_RewardEditorSheet> createState() => _RewardEditorSheetState();
}

class _RewardEditorSheetState extends State<_RewardEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _stockController;
  late int _cost;
  late String _type;
  String? _selectedPreset;
  late String _iconKey;
  bool _hasStockLimit = false;
  String? _targetMemberId;

  bool get _isEditing => widget.reward != null;

  @override
  void initState() {
    super.initState();
    final r = widget.reward;
    _titleController = TextEditingController(text: r?.title ?? '');
    _cost = r?.costPoints ?? 50;
    _type = r?.rewardType ?? RewardType.custom.name;
    _iconKey = r?.iconKey ?? kDefaultRewardIconKey;
    _hasStockLimit = r?.stock != null;
    _stockController = TextEditingController(
      text: r?.stock != null ? '${r!.stock}' : '',
    );
    if (r?.metaJson != null && r!.metaJson!.isNotEmpty) {
      try {
        final map = jsonDecode(r.metaJson!) as Map<String, dynamic>;
        _targetMemberId = map['targetMemberId'] as String?;
      } on Object {
        _targetMemberId = null;
      }
    }
    _titleController.addListener(_onTitleChanged);
  }

  void _onTitleChanged() => setState(() {});

  @override
  void dispose() {
    _titleController
      ..removeListener(_onTitleChanged)
      ..dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _cost <= 0) return;

    final stock = _hasStockLimit
        ? int.tryParse(_stockController.text.trim())
        : null;

    final meta = <String, dynamic>{};
    if (widget.reward?.metaJson != null &&
        widget.reward!.metaJson!.isNotEmpty) {
      try {
        meta.addAll(
          jsonDecode(widget.reward!.metaJson!) as Map<String, dynamic>,
        );
      } on Object {
        // Bỏ qua nếu json lỗi
      }
    }
    if (_targetMemberId != null) {
      meta['targetMemberId'] = _targetMemberId;
    } else {
      meta.remove('targetMemberId');
    }
    final metaJson = meta.isNotEmpty ? jsonEncode(meta) : null;

    if (_isEditing) {
      await widget.rewardDao.updateReward(
        widget.reward!.id,
        RewardsCompanion(
          title: Value(title),
          costPoints: Value(_cost),
          rewardType: Value(_type),
          iconKey: Value(_iconKey),
          stock: Value(stock),
          metaJson: Value(metaJson),
        ),
      );
    } else {
      final id = 'reward-${DateTime.now().millisecondsSinceEpoch}';
      await widget.rewardDao.createReward(
        RewardsCompanion.insert(
          id: id,
          familyId: widget.familyId,
          title: title,
          costPoints: _cost,
          rewardType: Value(_type),
          iconKey: Value(_iconKey),
          stock: Value(stock),
          metaJson: Value(metaJson),
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPaddingMobile,
        right: AppSpacing.screenPaddingMobile,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Sửa phần thưởng' : 'Thêm phần thưởng',
                  style: context.text.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Đóng',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!_isEditing) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Chọn nhanh', style: context.text.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: kRewardPresets.map((preset) {
                  final selected = _selectedPreset == preset.key;
                  return PresetChip(
                    iconKey: preset.iconKey,
                    label: preset.titleVi,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        _selectedPreset = selected ? null : preset.key;
                        if (!selected) {
                          _titleController.text = preset.titleVi;
                          _cost = preset.defaultCost;
                          _type = preset.rewardType;
                          _iconKey = preset.iconKey;
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            Text('Dành cho bé nào', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Gán phần thưởng riêng cho từng độ tuổi hoặc dùng chung cho tất cả các con.',
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Consumer(
              builder: (context, ref, _) {
                final memberDao = ref.watch(memberRepositoryProvider);
                return StreamBuilder<List<Member>>(
                  stream: memberDao.watchMembers(widget.familyId),
                  builder: (context, snap) {
                    final children = (snap.data ?? const <Member>[])
                        .where((m) => m.kind == MemberKind.child.name)
                        .toList();

                    return Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        ChoiceChip(
                          label: const Text('Tất cả các bé'),
                          selected: _targetMemberId == null,
                          onSelected: (sel) {
                            if (sel) setState(() => _targetMemberId = null);
                          },
                        ),
                        ...children.map((c) {
                          final isSel = _targetMemberId == c.id;
                          final cColor = AppColors.profileColor(c.colorIndex);
                          return ChoiceChip(
                            avatar: CircleAvatar(
                              backgroundColor: cColor.withValues(alpha: 0.25),
                              child: Text(
                                c.avatarKey ?? '👶',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            label: Text(c.displayName),
                            selected: isSel,
                            onSelected: (sel) {
                              setState(
                                () => _targetMemberId = sel ? c.id : null,
                              );
                            },
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),
            Text('Giá (xu)', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Bớt 10 xu',
                  onPressed: _cost > 10
                      ? () => setState(() => _cost -= 10)
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                SizedBox(
                  width: 100,
                  child: Center(
                    child: XuBadge(amount: _cost, large: true),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Thêm 10 xu',
                  onPressed: () => setState(() => _cost += 10),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Chọn hình', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            IconPickerGrid(
              iconKeys: kRewardIconKeys,
              selected: _iconKey,
              onSelected: (key) => setState(() => _iconKey = key),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Tên phần thưởng', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Tên phần thưởng'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.xl),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Giới hạn số lượng', style: context.text.titleSmall),
              subtitle: Text(
                'Tự động hết hàng khi con đổi đủ số lần quy định',
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
              value: _hasStockLimit,
              onChanged: (val) {
                setState(() {
                  _hasStockLimit = val;
                  if (!val) {
                    _stockController.clear();
                  } else if (_stockController.text.isEmpty) {
                    _stockController.text = '1';
                  }
                });
              },
            ),
            if (_hasStockLimit) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số lượng còn lại',
                  hintText: 'VD: 5',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _titleController.text.trim().isEmpty ? null : _save,
                child: const Text('LƯU'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
