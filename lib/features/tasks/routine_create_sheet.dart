import 'dart:async';

import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/icon_picker.dart';
import 'package:beong/core/widgets/sheet_header.dart';
import 'package:beong/core/widgets/xu_badge.dart';
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

  /// Việc thêm ngay trong bảng này, chưa ghi vào DB cho tới khi bấm TẠO BUỔI.
  ///
  /// Giữ ở bộ nhớ chứ không tạo từng việc một khi bố mẹ gõ xong: bấm HUỶ giữa
  /// chừng mà đã ghi vào DB thì để lại một đống việc mồ côi không thuộc buổi
  /// nào — đúng thứ bản này đang dọn.
  final _vietNhap = <_ViecNhap>[];

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

  /// Hỏi tên + hình + xu cho một việc, rồi thêm vào danh sách nháp.
  Future<void> _themViec() async {
    final viec = await showModalBottomSheet<_ViecNhap>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: const _ThemViecNhapSheet(),
      ),
    );
    if (viec != null && mounted) {
      setState(() => _vietNhap.add(viec));
    }
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
    final routineId = 'routine-${DateTime.now().millisecondsSinceEpoch}';
    await widget.taskDao.createRoutine(
      routine: RoutinesCompanion.insert(
        id: routineId,
        familyId: widget.familyId,
        title: title,
        iconKey: Value(_iconKey),
        dayPart: Value(_dayPart?.name),
      ),
      assigneeIds: _selectedChildren.toList(),
      routineTasks: [
        for (var i = 0; i < _vietNhap.length; i++)
          TasksCompanion.insert(
            id: '$routineId-task-$i',
            familyId: widget.familyId,
            title: _vietNhap[i].ten,
            iconKey: Value(_vietNhap[i].iconKey),
            points: Value(_vietNhap[i].xu),
            routineId: Value(routineId),
            orderIndex: Value(i),
          ),
      ],
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

            const SizedBox(height: AppSpacing.lg),
            Text('Việc trong buổi', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _vietNhap.isEmpty
                  ? 'Thêm luôn ở đây, hoặc để trống rồi thêm sau.'
                  : '${_vietNhap.length} việc sẽ được tạo cùng buổi này.',
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < _vietNhap.length; i++)
              _DongViecNhap(
                // Key theo nội dung: thiếu key thì xoá việc giữa danh sách là
                // Flutter tái dùng State theo vị trí và dòng dưới đội tên dòng
                // vừa xoá.
                key: ValueKey('${_vietNhap[i].ten}-$i'),
                viec: _vietNhap[i],
                onXoa: () => setState(() => _vietNhap.removeAt(i)),
                onDoiXu: (xu) => setState(() => _vietNhap[i].xu = xu),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _busy ? null : () => unawaited(_themViec()),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm việc'),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
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

/// Một việc đang chờ được tạo cùng buổi. Chưa có mặt trong DB.
class _ViecNhap {
  _ViecNhap({required this.ten, required this.iconKey, required this.xu});

  final String ten;
  final String iconKey;
  int xu;
}

/// Một dòng việc nháp: hình, tên, chỉnh xu tại chỗ, và nút bỏ ra.
class _DongViecNhap extends StatelessWidget {
  const _DongViecNhap({
    required this.viec,
    required this.onXoa,
    required this.onDoiXu,
    super.key,
  });

  final _ViecNhap viec;
  final VoidCallback onXoa;
  final ValueChanged<int> onDoiXu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          AppIcon(viec.iconKey),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(viec.ten, style: context.text.bodyMedium)),
          IconButton(
            icon: const Icon(Icons.remove_rounded),
            tooltip: 'Bớt 5 xu',
            // Sàn 0: xu âm cho một việc chưa làm thì không có nghĩa gì.
            onPressed: viec.xu <= 0
                ? null
                : () => onDoiXu((viec.xu - 5).clamp(0, viec.xu)),
          ),
          XuBadge(amount: viec.xu),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Thêm 5 xu',
            onPressed: () => onDoiXu(viec.xu + 5),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Bỏ việc này ra',
            onPressed: onXoa,
          ),
        ],
      ),
    );
  }
}

/// Bảng nhỏ hỏi tên + hình cho một việc mới trong buổi đang tạo.
class _ThemViecNhapSheet extends StatefulWidget {
  const _ThemViecNhapSheet();

  @override
  State<_ThemViecNhapSheet> createState() => _ThemViecNhapSheetState();
}

class _ThemViecNhapSheetState extends State<_ThemViecNhapSheet> {
  final _controller = TextEditingController();
  String _iconKey = kTaskIconKeys.first;
  int _xu = 10;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ten = _controller.text.trim();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(title: 'Thêm việc vào buổi'),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Tên việc',
                hintText: 'Ví dụ: Gấp chăn màn',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text('Thưởng', style: context.text.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_rounded),
                  tooltip: 'Bớt 5 xu',
                  onPressed: _xu <= 0
                      ? null
                      : () => setState(() => _xu = (_xu - 5).clamp(0, _xu)),
                ),
                XuBadge(amount: _xu),
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Thêm 5 xu',
                  onPressed: () => setState(() => _xu += 5),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Chọn hình', style: context.text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            IconPickerGrid(
              iconKeys: kTaskIconKeys,
              selected: _iconKey,
              onSelected: (key) => setState(() => _iconKey = key),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: ten.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(
                        _ViecNhap(ten: ten, iconKey: _iconKey, xu: _xu),
                      ),
                child: const Text('THÊM VÀO BUỔI'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
