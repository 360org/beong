import 'dart:async';

import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/repositories/wallet_repository.dart';
import 'package:flutter/material.dart';

/// Con tự chia xu từ hũ chờ vào các hũ — ADR-024, chế độ `manual`.
///
/// Thể hiện rõ số dư hiện tại và số xu cộng thêm (+X xu) sau khi chia.
class AllocateXuSheet extends StatefulWidget {
  const AllocateXuSheet({
    required this.familyId,
    required this.memberId,
    required this.inbox,
    required this.walletDao,
    required this.jars,
    super.key,
  });

  final String familyId;
  final String memberId;

  /// Số xu đang chờ chia.
  final int inbox;

  final WalletRepository walletDao;

  /// Hũ đang dùng của gia đình, đọc từ bảng `jars` (ADR-024).
  final List<JarDef> jars;

  @override
  State<AllocateXuSheet> createState() => _AllocateXuSheetState();
}

class _AllocateXuSheetState extends State<AllocateXuSheet> {
  /// Số xu con đã đặt vào từng hũ, chưa lưu.
  final _draft = <String, int>{};
  WalletBalance _currentBalance = WalletBalance.zero;

  int get _placed => _draft.values.fold(0, (a, b) => a + b);
  int get _left => widget.inbox - _placed;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCurrentBalance());
  }

  Future<void> _loadCurrentBalance() async {
    final balance = await widget.walletDao.balanceOf(widget.memberId);
    if (mounted) {
      setState(() => _currentBalance = balance);
    }
  }

  void _add(String jarKey, int amount) {
    if (amount > _left) return;
    setState(() => _draft[jarKey] = (_draft[jarKey] ?? 0) + amount);
  }

  void _clear(String jarKey) => setState(() => _draft.remove(jarKey));

  Future<void> _save() async {
    final opBase =
        'allocate:${widget.memberId}:${DateTime.now().millisecondsSinceEpoch}';

    for (final entry in _draft.entries) {
      if (entry.value <= 0) continue;
      await widget.walletDao.moveFromInboxToKey(
        familyId: widget.familyId,
        memberId: widget.memberId,
        toJarKey: entry.key,
        amount: entry.value,
        clientOpId: '$opBase:${entry.key}',
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chia xu vào hũ', style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Con quyết định để bao nhiêu vào hũ nào.',
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.card),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppIcon('jar_inbox'),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Còn $_left xu chưa chia',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final jar in widget.jars)
            _JarRow(
              jar: jar,
              currentAmount: _currentBalance.ofKey(jar.key),
              placed: _draft[jar.key] ?? 0,
              canAdd: _left > 0,
              onAdd: (amount) => _add(jar.key, amount),
              onClear: () => _clear(jar.key),
              remaining: _left,
            ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placed > 0 ? () => unawaited(_save()) : null,
              child: Text(
                _left == 0 ? 'XONG' : 'LƯU ($_placed XU)',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JarRow extends StatelessWidget {
  const _JarRow({
    required this.jar,
    required this.currentAmount,
    required this.placed,
    required this.canAdd,
    required this.remaining,
    required this.onAdd,
    required this.onClear,
  });

  final JarDef jar;
  final int currentAmount;
  final int placed;
  final bool canAdd;
  final int remaining;
  final ValueChanged<int> onAdd;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          AppIcon(iconKeyForEmoji(jar.emoji), size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(jar.title, style: context.text.bodyLarge),
                Row(
                  children: [
                    Text(
                      'Hiện có $currentAmount xu',
                      style: context.text.bodySmall?.copyWith(
                        color: context.semantic.onSurfaceMuted,
                      ),
                    ),
                    if (placed > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: context.semantic.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '+$placed xu → ${currentAmount + placed}',
                          style: context.text.labelSmall?.copyWith(
                            color: context.semantic.success,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (placed > 0)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 20),
              tooltip: 'Bỏ ra',
            ),
          _StepButton(label: '+1', onTap: canAdd ? () => onAdd(1) : null),
          const SizedBox(width: AppSpacing.xs),
          _StepButton(label: '+5', onTap: canAdd ? () => onAdd(5) : null),
          const SizedBox(width: AppSpacing.xs),
          _StepButton(
            label: 'Hết',
            onTap: canAdd ? () => onAdd(remaining) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTouchTarget,
          minHeight: AppSpacing.minTouchTarget,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? context.colors.primaryContainer
              : context.colors.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.field),
          ),
        ),
        child: Text(
          label,
          style: context.text.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: enabled
                ? context.colors.onPrimaryContainer
                : context.semantic.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}
