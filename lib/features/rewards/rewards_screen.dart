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
import 'package:beong/domain/services/redemption_service.dart';
import 'package:beong/features/rewards/redemption_queue.dart';
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
    final redemptionService = ref.watch(redemptionServiceProvider);

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

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingMobile,
              vertical: AppSpacing.lg,
            ),
            children: [
              // Hàng đợi/phiếu hiện **trên** danh sách phần thưởng, và hiện cả
              // khi chưa có phần thưởng nào: phiếu đang chờ là việc phải làm,
              // không được ẩn sau một trang trống.
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
              if (rewards.isEmpty)
                _EmptyState(
                  isParent: session.isParent,
                  onAdd: () =>
                      _showAddReward(context, rewardDao, session.familyId),
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
                  _showAddReward(context, rewardDao, session.familyId),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  /// Tạo phần thưởng trực tiếp từ template, không mở thêm màn nào.
  ///
  /// Bố mẹ sửa lại tên/giá sau được — mục đích là để trang không còn trống sau
  /// **một** cú chạm.
  Future<void> _createFromPreset(
    RewardDao rewardDao,
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
    required this.redemptionService,
  });

  final Reward reward;
  final AppSession session;
  final RewardDao rewardDao;
  final WalletDao walletDao;
  final RedemptionService redemptionService;

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
                redemptionService: redemptionService,
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
    required this.redemptionService,
  });

  final Reward reward;
  final AppSession session;
  final RewardDao rewardDao;
  final WalletDao walletDao;
  final RedemptionService redemptionService;

  @override
  State<_RedeemButton> createState() => _RedeemButtonState();
}

class _RedeemButtonState extends State<_RedeemButton> {
  bool _loading = false;

  Future<void> _redeem() async {
    setState(() => _loading = true);
    try {
      // Đi qua service: nó kiểm còn hàng và đủ xu **trước khi** trừ xu. Bản cũ
      // trừ xu rồi mới ghi phiếu, nên phần thưởng hết hàng là con mất xu mà
      // không có phiếu nào.
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
              widget.reward.requiresApproval
                  ? 'Đã gửi yêu cầu đổi "${widget.reward.title}". Chờ bố mẹ duyệt.'
                  : 'Đã đổi "${widget.reward.title}"!',
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

    return FilledButton.tonal(
      onPressed: _redeem,
      child: const Text('Đổi'),
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
                      Text(
                        iconForKey(preset.iconKey),
                        style: const TextStyle(fontSize: 18),
                      ),
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
