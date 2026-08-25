import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/icon_picker.dart';
import 'package:beong/core/widgets/loi_man_hinh.dart';
import 'package:beong/core/widgets/preset_chip.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/reward_presets.dart';
import 'package:beong/domain/repositories/reward_repository.dart';
import 'package:beong/domain/repositories/wallet_repository.dart';
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

    final rewardDao = ref.watch(rewardRepositoryProvider);
    final walletDao = ref.watch(walletRepositoryProvider);
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
      // `LuongDuLieu` chứ không `StreamBuilder` trần: luồng hỏng mà rơi về
      // danh sách rỗng thì màn hình nói "chưa có phần thưởng nào" — người dùng
      // thấy dữ liệu **sai** chứ không thấy lỗi.
      body: LuongDuLieu<List<Reward>>(
        stream: rewardDao.watchRewards(session.familyId),
        builder: (context, rewards) {
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
          : null,
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

    if (_isEditing) {
      await widget.rewardDao.updateReward(
        widget.reward!.id,
        RewardsCompanion(
          title: Value(title),
          costPoints: Value(_cost),
          rewardType: Value(_type),
          iconKey: Value(_iconKey),
          stock: Value(stock),
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
        top: AppSpacing.xxl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Sửa phần thưởng' : 'Thêm phần thưởng',
              style: context.text.titleLarge,
            ),
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
