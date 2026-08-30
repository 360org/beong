import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/icon_picker.dart';
import 'package:beong/core/widgets/sheet_header.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/repositories/member_repository.dart';
import 'package:beong/domain/repositories/task_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

/// Tạo một **buổi thói quen** (Buổi sáng, Buổi trưa, Buổi tối...) ngay trong
/// tab Nhiệm vụ.
///
/// Trước màn này, đường duy nhất tạo được thói quen là onboarding
/// (`onboarding_screen.dart:153`) — xong bước đó là không thêm buổi mới được
/// nữa. Bố mẹ muốn giao thêm việc phải đi đường khác: Cài đặt → hồ sơ bé → gán
/// việc mẫu, và đường đó sinh ra **việc lẻ** nằm ngoài mọi buổi. Hai đường song
/// song chính là gốc của chuyện một việc bị tạo hai lần.
///
/// **Chọn bé là bắt buộc.** Buổi không gán cho ai thì `schedulableTasks` bỏ qua
/// toàn bộ việc trong đó (`schedule.dart:148` — `assigneeIds.isEmpty` là
/// `continue`), tức là buổi có mà không bé nào thấy việc. Thà chặn ở nút lưu
/// còn hơn tạo ra một buổi im lặng không làm gì.
Future<bool?> showRoutineCreateSheet(
  BuildContext context, {
  required TaskRepository taskDao,
  required String familyId,
  required List<Member> children,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _RoutineCreateSheet(
        taskDao: taskDao,
        familyId: familyId,
        children: children,
      ),
    ),
  );
}

class _RoutineCreateSheet extends StatefulWidget {
  const _RoutineCreateSheet({
    required this.taskDao,
    required this.familyId,
    required this.children,
  });

  final TaskRepository taskDao;
  final String familyId;
  final List<Member> children;

  @override
  State<_RoutineCreateSheet> createState() => _RoutineCreateSheetState();
}

class _RoutineCreateSheetState extends State<_RoutineCreateSheet> {
  final _titleController = TextEditingController();
  final _selectedChildren = <String>{};

  DayPart? _dayPart;
  String _iconKey = kTaskIconKeys.first;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Nhà một bé thì không có gì để chọn — chọn sẵn cho bố mẹ đỡ một cú chạm.
    if (widget.children.length == 1) {
      _selectedChildren.add(widget.children.first.id);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _nhanBuoi(DayPart part) => switch (part) {
    DayPart.morning => 'Buổi sáng',
    DayPart.afternoon => 'Buổi trưa / chiều',
    DayPart.evening => 'Buổi tối',
  };

  Future<void> _luu() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedChildren.isEmpty) return;

    setState(() => _busy = true);
    await widget.taskDao.createRoutine(
      routine: RoutinesCompanion.insert(
        id: 'routine-${DateTime.now().millisecondsSinceEpoch}',
        familyId: widget.familyId,
        title: title,
        iconKey: Value(_iconKey),
        dayPart: Value(_dayPart?.name),
      ),
      assigneeIds: _selectedChildren.toList(),
      // Buổi mới chưa có việc nào — bố mẹ thêm việc vào sau ở màn sửa thói quen.
      routineTasks: const [],
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final coTheLuu =
        !_busy &&
        _titleController.text.trim().isNotEmpty &&
        _selectedChildren.isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(
              title: 'Thêm buổi thói quen',
              subtitle:
                  'Gom các việc làm cùng một lúc trong ngày vào một buổi.',
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Tên buổi', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _titleController,
              autofocus: true,
              maxLength: 60,
              decoration: const InputDecoration(
                hintText: 'Ví dụ: Buổi sáng, Sau giờ học',
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppSpacing.md),
            Text('Buổi trong ngày (tuỳ chọn)', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final part in DayPart.values)
                  ChoiceChip(
                    label: Text(_nhanBuoi(part)),
                    selected: _dayPart == part,
                    onSelected: (chon) =>
                        setState(() => _dayPart = chon ? part : null),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            Text('Chọn hình', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            IconPickerGrid(
              iconKeys: kTaskIconKeys,
              selected: _iconKey,
              onSelected: (key) => setState(() => _iconKey = key),
            ),

            const SizedBox(height: AppSpacing.lg),
            Text('Giao cho bé nào', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _selectedChildren.isEmpty
                  ? 'Chưa chọn bé nào — buổi này sẽ không hiện với ai cả.'
                  : 'Buổi này chỉ hiện với bé đã chọn.',
              style: context.text.bodySmall?.copyWith(
                color: _selectedChildren.isEmpty
                    ? context.semantic.danger
                    : context.semantic.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final child in widget.children)
                  FilterChip(
                    label: Text(child.displayName),
                    selected: _selectedChildren.contains(child.id),
                    onSelected: (chon) => setState(() {
                      if (chon) {
                        _selectedChildren.add(child.id);
                      } else {
                        _selectedChildren.remove(child.id);
                      }
                    }),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: coTheLuu ? _luu : null,
                child: const Text('TẠO BUỔI'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
