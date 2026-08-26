import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/icon_picker.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/repositories/reward_repository.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bảng đề xuất Điều ước / Phần thưởng của con (§11).
///
/// Bé đề xuất món quà mình muốn kèm số xu gợi ý. Phần thưởng được tạo ở trạng thái
/// chờ bố mẹ duyệt và định giá chính thức.
Future<bool?> showWishSheet(
  BuildContext context, {
  required String familyId,
  required String memberId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _WishSheet(familyId: familyId, memberId: memberId),
    ),
  );
}

class _WishSheet extends ConsumerStatefulWidget {
  const _WishSheet({
    required this.familyId,
    required this.memberId,
  });

  final String familyId;
  final String memberId;

  @override
  ConsumerState<_WishSheet> createState() => _WishSheetState();
}

class _WishSheetState extends ConsumerState<_WishSheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  int _suggestedCost = 50;
  String _iconKey = 'gift';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _titleController
      ..removeListener(_onChanged)
      ..dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitWish() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _busy = true);

    final rewardDao = ref.read(rewardRepositoryProvider);
    final id = 'wish-${DateTime.now().millisecondsSinceEpoch}';

    await rewardDao.createReward(
      RewardsCompanion.insert(
        id: id,
        familyId: widget.familyId,
        title: title,
        costPoints: _suggestedCost,
        iconKey: Value(_iconKey),
        rewardType: Value(RewardType.custom.name),
        metaJson: Value('{"proposerId":"${widget.memberId}","note":"${_noteController.text.trim()}"}'),
      ),
    );

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi điều ước "$title" đến bố mẹ!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_busy && _titleController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Điều ước của con',
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Con muốn có phần thưởng gì? Hãy gửi đề xuất để bố mẹ duyệt nhé!',
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
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
          Text('Con muốn nhận quà gì?', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Đi công viên nước, Mua truyện tranh...',
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Con đề xuất bao nhiêu xu?', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Bớt 10 xu',
                onPressed: _suggestedCost > 10
                    ? () => setState(() => _suggestedCost -= 10)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 100,
                child: Center(
                  child: XuBadge(amount: _suggestedCost, large: true),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Thêm 10 xu',
                onPressed: () => setState(() => _suggestedCost += 10),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Lời nhắn gửi bố mẹ (tuỳ chọn)', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'Vì sao con muốn món quà này?...',
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSubmit ? _submitWish : null,
              child: const Text('GỬI CHO BỐ MẸ'),
            ),
          ),
        ],
      ),
    );
  }
}
