import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/domain/services/penalty_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Các mức dựng sẵn. Chip rời chứ không phải thanh trượt: bố mẹ nghĩ theo "một
/// nửa", "một phần tư", không nghĩ theo 37%, và thanh trượt gợi ý một độ chính
/// xác không có thật.
///
/// Ai cần con số khác thì có chip "Khác…" để tự nhập (xem [_CustomChip]) — mức
/// dựng sẵn là đường nhanh, không phải giới hạn.
const List<int> kPenaltyLevels = [0, 10, 20, 25, 50, 75, 100];

/// Cấu hình trừ xu của gia đình — ADR-022.
class PenaltySettingsScreen extends ConsumerWidget {
  const PenaltySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    final memberDao = ref.watch(memberRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Trừ xu', style: context.text.titleLarge)),
      body: StreamBuilder<PenaltyPolicy>(
        stream: memberDao.watchPenaltyPolicy(session.familyId),
        builder: (context, snap) {
          final policy = snap.data;
          if (policy == null) return const SizedBox.shrink();

          Future<void> save(PenaltyPolicy next) =>
              memberDao.setPenaltyPolicy(session.familyId, next);

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingMobile,
              vertical: AppSpacing.lg,
            ),
            children: [
              const _WhyThisIsOffByDefault(),
              const SizedBox(height: AppSpacing.xxl),
              _LevelPicker(
                title: 'Hết ngày mà chưa làm',
                subtitle:
                    'Cuối ngày, mỗi việc chưa làm bị trừ phần trăm này của '
                    'điểm việc đó.',
                value: policy.missedPct,
                onChanged: (v) => save(policy.copyWith(missedPct: v)),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _LevelPicker(
                title: 'Bấm xong nhưng chưa làm',
                subtitle:
                    'Khi bố mẹ mở lại việc để con làm lại, mỗi lần mở lại bị '
                    'trừ phần trăm này.',
                value: policy.reopenPct,
                onChanged: (v) => save(policy.copyWith(reopenPct: v)),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _Example(policy: policy),
            ],
          );
        },
      ),
    );
  }
}

/// Cảnh báo hiện **trước** các lựa chọn, không phải chú thích cuối trang.
class _WhyThisIsOffByDefault extends StatelessWidget {
  const _WhyThisIsOffByDefault();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppIcon('warning', size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Mặc định tắt, và nên cân nhắc',
                    style: context.text.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nhiều tài liệu nuôi dạy khuyên không trừ điểm: nó dễ biến '
              '"mình muốn làm" thành "làm không thì bị trừ", và động lực kiểu '
              'sợ mất mát thường tắt ngay khi bố mẹ không để ý nữa.\n\n'
              'Bé Ong không quyết thay bố mẹ, nhưng cũng không bật sẵn. Nếu '
              'nhà mình dùng, nên bắt đầu ở mức thấp và nói trước với con.',
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelPicker extends StatelessWidget {
  const _LevelPicker({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: context.text.bodySmall?.copyWith(
            color: context.semantic.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final level in kPenaltyLevels)
              _LevelChip(
                label: level == 0 ? 'Tắt' : '$level%',
                selected: level == value,
                onTap: () => onChanged(level),
              ),
            _CustomChip(value: value, onChanged: onChanged),
          ],
        ),
      ],
    );
  }
}

/// Một chip mức.
///
/// Không đặt `alignment` ở Container: trong Wrap ràng buộc là lỏng, và Container
/// có alignment sẽ nở ra chiếm hết bề rộng — các chip xếp thành cột thay vì nằm
/// cạnh nhau. Căn giữa bằng padding dọc, bề rộng để nó tự co theo chữ.
class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Viền thay cho nền đặc — dùng cho chip "Khác…" để nó khác nhóm mức cố định.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 64),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primary
              : context.colors.primaryContainer,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.field),
          ),
          border: outlined && !selected
              ? Border.all(color: context.colors.primary, width: 1.5)
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: selected
                ? context.colors.onPrimary
                : outlined
                ? context.colors.primary
                : context.colors.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Chip mở hộp nhập số phần trăm tuỳ ý.
///
/// Danh sách mức dựng sẵn phủ phần lớn nhu cầu, nhưng có nhà muốn đúng 15% hay
/// 35%. Chip này hiện **đang chọn** khi mức hiện tại không nằm trong danh sách,
/// nên bố mẹ luôn thấy được con số mình đã nhập.
class _CustomChip extends StatelessWidget {
  const _CustomChip({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  bool get _isCustom => !kPenaltyLevels.contains(value);

  Future<void> _ask(BuildContext context) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => _PercentDialog(initial: _isCustom ? value : null),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return _LevelChip(
      label: _isCustom ? '$value%' : 'Khác…',
      selected: _isCustom,
      outlined: true,
      onTap: () => unawaited(_ask(context)),
    );
  }
}

/// Hộp nhập phần trăm. Từ chối giá trị ngoài 0–100 kèm lời giải thích, không
/// kẹp lặng lẽ: đây là con số bố mẹ nhập, nhập sai thì phải biết là mình sai.
class _PercentDialog extends StatefulWidget {
  const _PercentDialog({required this.initial});

  final int? initial;

  @override
  State<_PercentDialog> createState() => _PercentDialogState();
}

class _PercentDialogState extends State<_PercentDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial?.toString() ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      setState(() => _error = 'Nhập một số nguyên, ví dụ 15');
      return;
    }
    if (parsed < 0 || parsed > 100) {
      setState(() => _error = 'Phải trong khoảng 0 đến 100');
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nhập mức trừ'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          suffixText: '%',
          hintText: '0 – 100',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Thôi'),
        ),
        TextButton(onPressed: _submit, child: const Text('Xong')),
      ],
    );
  }
}

/// Ví dụ bằng số thật, tính từ chính chính sách đang chọn.
///
/// Bố mẹ đặt phần trăm rất dễ hình dung sai nó thành bao nhiêu xu, nên trang này
/// tự tính hộ thay vì để họ phát hiện ra vào cuối ngày.
class _Example extends StatelessWidget {
  const _Example({required this.policy});

  final PenaltyPolicy policy;

  @override
  Widget build(BuildContext context) {
    if (!policy.isEnabled) {
      return Text(
        'Đang tắt — con không bị trừ xu trong trường hợp nào.',
        style: context.text.bodyMedium?.copyWith(
          color: context.semantic.onSurfaceMuted,
        ),
      );
    }

    // Cùng bộ số với ví dụ trong docs: 10 việc x 10 xu, làm 8, 3 việc làm lại.
    final summary = summarizeDay(
      tasks: [
        for (var i = 0; i < 3; i++)
          const DayTaskOutcome(points: 10, completed: true, reopenCount: 1),
        for (var i = 0; i < 5; i++)
          const DayTaskOutcome(points: 10, completed: true),
        for (var i = 0; i < 2; i++)
          const DayTaskOutcome(points: 10, completed: false),
      ],
      policy: policy,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thử một ngày', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Con có 10 việc, mỗi việc 10 xu. Làm xong 8 việc, trong đó 3 '
              'việc phải làm lại một lần.',
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Line(label: 'Kiếm được', value: '+${summary.earned} xu'),
            _Line(
              label: '2 việc chưa làm',
              value: '-${summary.missedPenalty} xu',
            ),
            _Line(
              label: '3 lần làm lại',
              value: '-${summary.reopenPenalty} xu',
            ),
            const Divider(height: AppSpacing.xl),
            _Line(
              label: 'Cả ngày',
              value: '${summary.net >= 0 ? '+' : ''}${summary.net} xu',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
