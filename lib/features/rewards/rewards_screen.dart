import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/preset_chip.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/reward_dao.dart';
import 'package:beong/data/local/wallet_dao.dart';
import 'package:beong/data/seed/reward_presets.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final rewardDao = ref.watch(rewardDaoProvider);
    final walletDao = ref.watch(walletDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Phần thưởng', style: context.text.titleLarge),
        actions: [
          if (!session.isParent)
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
      body: StreamBuilder<List<Reward>>(
        stream: rewardDao.watchRewards(session.familyId),
        builder: (context, snap) {
          final rewards = snap.data ?? [];

          if (rewards.isEmpty) {
            return _EmptyState(
              isParent: session.isParent,
              onAdd: () => _showAddReward(context, rewardDao, session.familyId),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingMobile,
              vertical: AppSpacing.lg,
            ),
            children: [
              ...rewards.map(
                (reward) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _RewardCard(
                    reward: reward,
                    session: session,
                    rewardDao: rewardDao,
                    walletDao: walletDao,
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
                  _showAddReward(context, rewardDao, session.familyId),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddReward(
    BuildContext context,
    RewardDao rewardDao,
    String familyId,
  ) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _AddRewardSheet(
          rewardDao: rewardDao,
          familyId: familyId,
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.session,
    required this.rewardDao,
    required this.walletDao,
  });

  final Reward reward;
  final AppSession session;
  final RewardDao rewardDao;
  final WalletDao walletDao;

  @override
  Widget build(BuildContext context) {
    final isChild = !session.isParent;

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
              child: Text(
                iconForKey(reward.iconKey),
                style: const TextStyle(fontSize: 24),
              ),
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
                  Row(
                    children: [
                      XuBadge(amount: reward.costPoints, pill: true),
                      if (reward.stock != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          'Còn ${reward.stock}',
                          style: context.text.bodySmall?.copyWith(
                            color: context.semantic.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isChild)
              _RedeemButton(
                reward: reward,
                session: session,
                rewardDao: rewardDao,
                walletDao: walletDao,
              ),
            if (session.isParent)
              IconButton(
                onPressed: () => rewardDao.deleteReward(reward.id),
                icon: Icon(
                  Icons.delete_outline,
                  color: context.semantic.onSurfaceMuted,
                ),
                tooltip: 'Xoá',
              ),
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
  });

  final Reward reward;
  final AppSession session;
  final RewardDao rewardDao;
  final WalletDao walletDao;

  @override
  State<_RedeemButton> createState() => _RedeemButtonState();
}

class _RedeemButtonState extends State<_RedeemButton> {
  bool _loading = false;

  Future<void> _redeem() async {
    setState(() => _loading = true);
    try {
      final redemptionId =
          'redeem-${widget.reward.id}-${DateTime.now().millisecondsSinceEpoch}';

      await widget.walletDao.debit(
        familyId: widget.session.familyId,
        memberId: widget.session.activeMemberId,
        jar: Jar.spend,
        amount: widget.reward.costPoints,
        reason: TxReason.rewardRedeemed,
        clientOpId: redemptionId,
        refType: 'reward',
        refId: widget.reward.id,
      );

      await widget.rewardDao.redeem(
        redemption: RedemptionsCompanion.insert(
          id: redemptionId,
          familyId: widget.session.familyId,
          rewardId: widget.reward.id,
          memberId: widget.session.activeMemberId,
          costSnapshot: widget.reward.costPoints,
          metaSnapshot: Value(widget.reward.metaJson),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã đổi "${widget.reward.title}"!')),
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

    return FilledButton.tonal(
      onPressed: _redeem,
      child: const Text('Đổi'),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isParent, required this.onAdd});

  final bool isParent;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 56)),
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
            ],
          ],
        ),
      ),
    );
  }
}

class _AddRewardSheet extends StatefulWidget {
  const _AddRewardSheet({
    required this.rewardDao,
    required this.familyId,
  });

  final RewardDao rewardDao;
  final String familyId;

  @override
  State<_AddRewardSheet> createState() => _AddRewardSheetState();
}

class _AddRewardSheetState extends State<_AddRewardSheet> {
  final _titleController = TextEditingController();
  int _cost = 50;
  String _type = RewardType.custom.name;
  String? _selectedPreset;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _cost <= 0) return;

    final preset = _selectedPreset == null
        ? null
        : rewardPresetByKey(_selectedPreset!);
    final id = 'reward-${DateTime.now().millisecondsSinceEpoch}';
    await widget.rewardDao.createReward(
      RewardsCompanion.insert(
        id: id,
        familyId: widget.familyId,
        title: title,
        costPoints: _cost,
        rewardType: Value(_type),
        iconKey: Value(preset?.iconKey),
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPaddingMobile,
        right: AppSpacing.screenPaddingMobile,
        top: AppSpacing.xxl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thêm phần thưởng', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            Text('Chọn nhanh', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: kRewardPresets.map((preset) {
                final selected = _selectedPreset == preset.key;
                return PresetChip(
                  emoji: iconForKey(preset.iconKey),
                  label: preset.titleVi,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _selectedPreset = selected ? null : preset.key;
                      if (!selected) {
                        _titleController.text = preset.titleVi;
                        _cost = preset.defaultCost;
                        _type = preset.rewardType;
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Giá (xu)', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
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
                  onPressed: () => setState(() => _cost += 10),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Tên phần thưởng', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Tên phần thưởng'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('LƯU'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
