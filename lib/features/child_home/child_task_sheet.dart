import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/family_clock_provider.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/icon_picker.dart';
import 'package:beong/core/widgets/preset_chip.dart';
import 'package:beong/core/widgets/sheet_header.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/entities/presets.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sheet cho phép trẻ tự thêm việc nhà khi tự giác làm mà bố mẹ chưa giao.
Future<bool?> showChildTaskSheet(
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
      child: _ChildTaskSheet(familyId: familyId, memberId: memberId),
    ),
  );
}

class _ChildTaskSheet extends ConsumerStatefulWidget {
  const _ChildTaskSheet({
    required this.familyId,
    required this.memberId,
  });

  final String familyId;
  final String memberId;

  @override
  ConsumerState<_ChildTaskSheet> createState() => _ChildTaskSheetState();
}

class _ChildTaskSheetState extends ConsumerState<_ChildTaskSheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  int _suggestedPoints = 10;
  String _iconKey = 'clipboard';
  String? _selectedPreset;
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

  Future<void> _submitTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _busy = true);

    final taskDao = ref.read(taskRepositoryProvider);
    final id = 'task-self-${DateTime.now().millisecondsSinceEpoch}';

    // Tạo task mới gán riêng cho con, chế độ bố mẹ duyệt
    await taskDao.createTask(
      TasksCompanion.insert(
        id: id,
        familyId: widget.familyId,
        title: title,
        points: Value(_suggestedPoints),
        iconKey: Value(_iconKey),
        presetKey: Value(_selectedPreset),
        approvalMode: Value(ApprovalMode.manual.name),
        proofMode: Value(ProofMode.note.name),
        repeatType: Value(RepeatType.once.name),
        onceDate: Value(DateTime.now().toIso8601String().substring(0, 10)),
      ),
      [widget.memberId],
    );

    final today =
        (ref.read(familyClockProvider(widget.familyId)).value ??
                fallbackFamilyClock())
            .today();

    // Sinh lượt việc cho ngày hôm nay
    await taskDao.generateInstances(
      familyId: widget.familyId,
      today: today,
    );

    // Tìm instance vừa sinh và tự động hoàn thành gửi bố mẹ duyệt
    final instances = await taskDao
        .watchInstancesForMember(memberId: widget.memberId, date: today)
        .first;
    final createdInstance = instances.firstWhere(
      (i) => i.taskId == id,
      orElse: () => instances.first,
    );

    final note = _noteController.text.trim();
    await ref
        .read(taskReviewServiceProvider)
        .complete(
          createdInstance.id,
          proofNote: note.isEmpty ? 'Con tự làm việc này' : note,
        );

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã gửi việc "$title" ($_suggestedPoints xu) để bố mẹ duyệt khen con!',
          ),
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
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_task_rounded,
                  color: context.colors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: SheetHeader(
                  title: 'Con tự thêm việc',
                  subtitle:
                      'Con vừa tự giác làm việc gì? Hãy thêm để bố mẹ biết và '
                      'thưởng xu nhé!',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Chọn nhanh việc con đã làm', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: kTaskPresets.take(8).map((preset) {
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
                      _suggestedPoints = preset.defaultPoints;
                      _iconKey = preset.iconKey;
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Tên việc con đã làm', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Tưới cây, Dọn đồ chơi, Đọc sách...',
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Chọn hình', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          IconPickerGrid(
            iconKeys: kTaskIconKeys,
            selected: _iconKey,
            onSelected: (key) => setState(() => _iconKey = key),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Con đề xuất nhận bao nhiêu xu?',
            style: context.text.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Bớt 5 xu',
                onPressed: _suggestedPoints > 5
                    ? () => setState(() => _suggestedPoints -= 5)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 100,
                child: Center(
                  child: XuBadge(amount: _suggestedPoints, large: true),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Thêm 5 xu',
                onPressed: () => setState(() => _suggestedPoints += 5),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Lời nhắn cho bố mẹ (tuỳ chọn)', style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'Con đã làm việc này như thế nào?...',
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSubmit ? _submitTask : null,
              child: const Text('GỬI BỐ MẸ DUYỆT'),
            ),
          ),
        ],
      ),
    );
  }
}
