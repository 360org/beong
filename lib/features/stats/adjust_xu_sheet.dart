import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/sheet_header.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/repositories/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Bố mẹ cộng hoặc trừ xu tay cho một trẻ.
///
/// `WalletRepository.manualAdjust` viết từ Sprint 1 và schema có sẵn ràng buộc "bắt
/// buộc ghi lý do", nhưng **không có chỗ nào gọi nó** — bố mẹ không có cách nào
/// sửa xu. Thưởng thêm cho một việc tốt ngoài danh sách, hay sửa một lần cộng
/// nhầm, đều phải bó tay.
Future<bool?> showAdjustXuSheet(
  BuildContext context, {
  required String familyId,
  required String memberId,
  required String childName,
  required String reviewerId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _AdjustSheet(
        familyId: familyId,
        memberId: memberId,
        childName: childName,
        reviewerId: reviewerId,
      ),
    ),
  );
}

class _AdjustSheet extends ConsumerStatefulWidget {
  const _AdjustSheet({
    required this.familyId,
    required this.memberId,
    required this.childName,
    required this.reviewerId,
  });

  final String familyId;
  final String memberId;
  final String childName;
  final String reviewerId;

  @override
  ConsumerState<_AdjustSheet> createState() => _AdjustSheetState();
}

class _AdjustSheetState extends ConsumerState<_AdjustSheet> {
  final _reason = TextEditingController();

  /// Cộng hay trừ. Tách khỏi con số thay vì cho gõ số âm: gõ dấu trừ rất dễ
  /// sót, mà sót một dấu ở đây là cộng thay vì trừ.
  bool _adding = true;
  int _amount = 10;
  String _jarKey = kJarSpend;
  bool _busy = false;
  String? _error;

  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _reason.addListener(_onReasonChanged);
  }

  void _onReasonChanged() => setState(() {});

  @override
  void dispose() {
    _reason
      ..removeListener(_onReasonChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(walletRepositoryProvider)
          .manualAdjustToJarKey(
            familyId: widget.familyId,
            memberId: widget.memberId,
            jarKey: _jarKey,
            delta: _adding ? _amount : -_amount,
            reasonNote: _reason.text,
            clientOpId: _uuid.v4(),
            createdBy: widget.reviewerId,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on WalletException catch (e) {
      // Hiện lỗi ngay trong sheet thay vì đóng lại: ca thường gặp nhất là trừ
      // quá số xu đang có, và bố mẹ cần sửa con số chứ không cần mở lại sheet.
      if (mounted) {
        setState(() {
          _error = e.message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_busy && _reason.text.trim().isNotEmpty && _amount > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            title: 'Sửa xu của ${widget.childName}',
            subtitle:
                'Lý do sẽ hiện trong Sổ của con. Không có con số nào rơi từ '
                'trên trời xuống.',
          ),
          const SizedBox(height: AppSpacing.xl),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                icon: Icon(Icons.add_rounded),
                label: Text('Cộng'),
              ),
              ButtonSegment(
                value: false,
                icon: Icon(Icons.remove_rounded),
                label: Text('Trừ'),
              ),
            ],
            selected: {_adding},
            onSelectionChanged: (s) => setState(() {
              _adding = s.first;
              _error = null;
            }),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Bao nhiêu xu', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Bớt 5 xu',
                onPressed: _amount > 5
                    ? () => setState(() => _amount -= 5)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 120,
                child: Center(child: XuBadge(amount: _amount, large: true)),
              ),
              IconButton.filledTonal(
                tooltip: 'Thêm 5 xu',
                onPressed: () => setState(() => _amount += 5),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Vào hũ nào', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _JarPicker(
            familyId: widget.familyId,
            memberId: widget.memberId,
            selected: _jarKey,
            onSelected: (key) => setState(() {
              _jarKey = key;
              _error = null;
            }),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Vì sao', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Giúp bà xách đồ',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.danger,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSave ? _save : null,
              child: const Text('LƯU'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chọn hũ nhận khoản điều chỉnh.
///
/// Đọc từ bảng `jars` chứ không liệt kê ba hũ cứng: từ ADR-024 nhà nào cũng có
/// thể có hũ riêng, và cộng xu vào một hũ không tồn tại thì số đó biến mất khỏi
/// mọi màn hình.
class _JarPicker extends ConsumerWidget {
  const _JarPicker({
    required this.familyId,
    required this.memberId,
    required this.selected,
    required this.onSelected,
  });

  final String familyId;

  /// Hũ của **bé đang được sửa xu**, không phải bộ chung: cộng/trừ vào một hũ
  /// bé không có là ghi vào một chỗ không màn hình nào của bé hiện ra.
  final String memberId;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<JarDef>>(
      stream: ref
          .watch(jarRepositoryProvider)
          .watchActiveJars(familyId, memberId: memberId),
      builder: (context, snap) {
        final jars = snap.data ?? kDefaultJars;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final jar in jars)
              ChoiceChip(
                avatar: AppIcon(iconKeyForEmoji(jar.emoji), size: 18),
                label: Text(jar.title),
                selected: jar.key == selected,
                onSelected: (_) => onSelected(jar.key),
              ),
          ],
        );
      },
    );
  }
}
