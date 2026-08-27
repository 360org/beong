import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/domain/entities/presets.dart';
import 'package:beong/domain/services/age_band.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/jar_splitter.dart';
import 'package:flutter/material.dart';

/// Form cấu hình hồ sơ bé toàn diện: thông tin cá nhân, PIN, danh mục hũ riêng,
/// slider tỷ lệ có chốt khoá, option con tự chia xu và danh sách việc mẫu theo buổi kèm +- xu.
class ChildProfileForm extends StatefulWidget {
  const ChildProfileForm({
    required this.controller,
    required this.colorIndex,
    required this.onColorChanged,
    required this.avatar,
    required this.onAvatarChanged,
    required this.birthYear,
    required this.onBirthYearChanged,
    this.title = 'Thêm bé',
    this.autofocus = true,
    this.onClose,
    this.selectedPresetKeys = const <String>{},
    this.onPresetsChanged,
    this.presetPoints = const <String, int>{},
    this.onPresetPointsChanged,
    this.hasPin = false,
    this.onTogglePin,
    this.customJarSplit,
    this.onJarSplitChanged,
    this.allowSelfAllocation = false,
    this.onToggleSelfAllocation,
    this.showPresets = true,
    this.showJars = true,
    super.key,
  });

  final TextEditingController controller;
  final int colorIndex;
  final ValueChanged<int> onColorChanged;
  final String avatar;
  final ValueChanged<String> onAvatarChanged;
  final int? birthYear;
  final ValueChanged<int?> onBirthYearChanged;

  /// Tiêu đề trên đầu form.
  final String title;

  /// Bàn phím bật sẵn. Tắt trong bottom sheet.
  final bool autofocus;

  /// Nút đóng/huỷ form.
  final VoidCallback? onClose;

  /// Danh sách việc mẫu đã chọn.
  final Set<String> selectedPresetKeys;
  final ValueChanged<Set<String>>? onPresetsChanged;

  /// Điểm xu tuỳ chỉnh cho từng việc mẫu (key -> points).
  final Map<String, int> presetPoints;
  final ValueChanged<Map<String, int>>? onPresetPointsChanged;

  /// Trạng thái bật/tắt mã PIN hồ sơ.
  final bool hasPin;
  final ValueChanged<bool>? onTogglePin;

  /// Tỷ lệ hũ riêng cho bé.
  final JarSplit? customJarSplit;
  final ValueChanged<JarSplit?>? onJarSplitChanged;

  /// Tuỳ chọn con tự chia xu riêng cho bé này.
  final bool allowSelfAllocation;
  final ValueChanged<bool>? onToggleSelfAllocation;

  /// Ẩn/hiện mục việc mẫu và hũ.
  final bool showPresets;
  final bool showJars;

  @override
  State<ChildProfileForm> createState() => _ChildProfileFormState();
}

class _ChildProfileFormState extends State<ChildProfileForm> {
  late bool _useCustomJars;
  late int _spendPct;
  late int _savePct;
  late int _givePct;

  // Trạng thái khoá từng hũ khi chỉnh slider
  bool _lockSpend = false;
  bool _lockSave = false;
  bool _lockGive = false;

  // Trạng thái mở rộng "Xem thêm" cho từng buổi
  bool _expandMorning = false;
  bool _expandAfternoon = false;
  bool _expandEvening = false;
  bool _expandHabits = false;

  late Map<String, int> _pointsMap;

  @override
  void initState() {
    super.initState();
    _useCustomJars = widget.customJarSplit != null;
    final split = widget.customJarSplit ?? JarSplit.defaultSplit;
    _spendPct = split.spend;
    _savePct = split.save;
    _givePct = split.give;

    _pointsMap = Map<String, int>.from(widget.presetPoints);
    for (final p in kTaskPresets) {
      _pointsMap.putIfAbsent(p.key, () => p.defaultPoints);
    }
  }

  void _updateSplit() {
    if (!_useCustomJars) {
      widget.onJarSplitChanged?.call(null);
    } else {
      widget.onJarSplitChanged?.call(
        JarSplit(spend: _spendPct, save: _savePct, give: _givePct),
      );
    }
  }

  void _adjustSpend(int newSpend) {
    final clamped = newSpend.clamp(0, 100);
    setState(() {
      _spendPct = clamped;
      final remaining = 100 - _spendPct;
      if (_lockSave && !_lockGive) {
        _givePct = (remaining - _savePct).clamp(0, 100);
      } else if (_lockGive && !_lockSave) {
        _savePct = (remaining - _givePct).clamp(0, 100);
      } else {
        _savePct = (remaining * 0.8).round().clamp(0, remaining);
        _givePct = remaining - _savePct;
      }
    });
    _updateSplit();
  }

  void _adjustSave(int newSave) {
    final clamped = newSave.clamp(0, 100);
    setState(() {
      _savePct = clamped;
      final remaining = 100 - _savePct;
      if (_lockSpend && !_lockGive) {
        _givePct = (remaining - _spendPct).clamp(0, 100);
      } else if (_lockGive && !_lockSpend) {
        _spendPct = (remaining - _givePct).clamp(0, 100);
      } else {
        _spendPct = (remaining * 0.8).round().clamp(0, remaining);
        _givePct = remaining - _spendPct;
      }
    });
    _updateSplit();
  }

  void _adjustGive(int newGive) {
    final clamped = newGive.clamp(0, 100);
    setState(() {
      _givePct = clamped;
      final remaining = 100 - _givePct;
      if (_lockSpend && !_lockSave) {
        _savePct = (remaining - _spendPct).clamp(0, 100);
      } else if (_lockSave && !_lockSpend) {
        _spendPct = (remaining - _savePct).clamp(0, 100);
      } else {
        _spendPct = (remaining * 0.6).round().clamp(0, remaining);
        _savePct = remaining - _spendPct;
      }
    });
    _updateSplit();
  }

  void _changePresetPoint(String key, int delta) {
    setState(() {
      final current = _pointsMap[key] ?? 10;
      final next = (current + delta).clamp(1, 500);
      _pointsMap[key] = next;
    });
    widget.onPresetPointsChanged?.call(_pointsMap);
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.profileColor(widget.colorIndex);

    final morningTasks = kTaskPresets.where((p) => p.dayPart == 'morning').toList();
    final afternoonTasks = kTaskPresets.where((p) => p.dayPart == 'afternoon').toList();
    final eveningTasks = kTaskPresets.where((p) => p.dayPart == 'evening').toList();
    final habitTasks = kTaskPresets.where((p) => p.dayPart == null).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: context.text.titleLarge),
              if (widget.onClose != null)
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Đóng',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Nhập tên, tuổi, chọn màu, con vật và cấu hình riêng cho bé.',
            style: context.text.bodyMedium?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Text(widget.avatar, style: const TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: widget.controller,
            decoration: const InputDecoration(hintText: 'Tên bé'),
            textCapitalization: TextCapitalization.words,
            autofocus: widget.autofocus,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'BÉ MẤY TUỔI',
            style: context.text.labelSmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Giao diện tự điều chỉnh theo tuổi: bé nhỏ thì chữ và icon to hơn, '
            'bé lớn thì gọn gàng hơn.',
            style: context.text.bodySmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AgePicker(
            birthYear: widget.birthYear,
            onChanged: widget.onBirthYearChanged,
            color: color,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'CON VẬT',
            style: context.text.labelSmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: kAvatarEmojis.map((emoji) {
              final selected = emoji == widget.avatar;
              return GestureDetector(
                onTap: () => widget.onAvatarChanged(emoji),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.25)
                        : context.colors.primaryContainer,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: color, width: 2.5)
                        : null,
                  ),
                  child: AppIcon(iconKeyForEmoji(emoji), size: 28),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'MÀU ĐẠI DIỆN',
            style: context.text.labelSmall?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: List.generate(AppColors.profilePalette.length, (i) {
              final swatch = AppColors.profileColor(i);
              final selected = i == widget.colorIndex;
              return GestureDetector(
                onTap: () => widget.onColorChanged(i),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(
                            color: context.colors.onSurface,
                            width: 3,
                          )
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.xl),

          // --- 1. Mật khẩu PIN ---
          if (widget.onTogglePin != null) ...[
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Mật khẩu bảo vệ hồ sơ (PIN 4 số)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                widget.hasPin
                    ? 'Đang bật mã khoá bảo vệ hồ sơ bé'
                    : 'Bé có thể mở hồ sơ mà không cần nhập PIN',
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
              value: widget.hasPin,
              onChanged: widget.onTogglePin,
            ),
          ],

          // --- 2. Tuỳ chọn con tự chia xu theo từng bé ---
          if (widget.onToggleSelfAllocation != null) ...[
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Cho phép bé tự chia xu vào hũ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                widget.allowSelfAllocation
                    ? 'Xu kiếm được vào hũ chờ, bé tự kéo chia vào các hũ'
                    : 'Xu tự động phân bổ vào các hũ theo tỷ lệ định sẵn',
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.onSurfaceMuted,
                ),
              ),
              value: widget.allowSelfAllocation,
              onChanged: widget.onToggleSelfAllocation,
            ),
          ],

          // --- 3. Cấu hình hũ xu riêng & Slider có chốt khoá ---
          if (widget.showJars && widget.onJarSplitChanged != null) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'CẤU HÌNH HŨ XU CHO BÉ',
              style: context.text.labelSmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tuỳ biến tỷ lệ hũ theo độ tuổi: bé nhỏ tăng hũ Chi tiêu/Đồ chơi, '
              'bé lớn tăng hũ Tiết kiệm/Học tập.',
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            RadioGroup<bool>(
              groupValue: _useCustomJars,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _useCustomJars = val);
                  _updateSplit();
                }
              },
              child: const Column(
                children: [
                  RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Theo quy tắc chung của gia đình (50 / 40 / 10)'),
                    value: false,
                  ),
                  RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Tuỳ chỉnh tỷ lệ riêng cho bé này'),
                    value: true,
                  ),
                ],
              ),
            ),
            if (_useCustomJars) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Column(
                  children: [
                    _SmartJarSlider(
                      label: 'Tiêu / Đồ chơi',
                      emoji: '🛍️',
                      value: _spendPct,
                      locked: _lockSpend,
                      onToggleLock: () => setState(() => _lockSpend = !_lockSpend),
                      onChanged: _adjustSpend,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _SmartJarSlider(
                      label: 'Để dành / Học tập',
                      emoji: '🐷',
                      value: _savePct,
                      locked: _lockSave,
                      onToggleLock: () => setState(() => _lockSave = !_lockSave),
                      onChanged: _adjustSave,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _SmartJarSlider(
                      label: 'Cho đi / Chia sẻ',
                      emoji: '💝',
                      value: _givePct,
                      locked: _lockGive,
                      onToggleLock: () => setState(() => _lockGive = !_lockGive),
                      onChanged: _adjustGive,
                    ),
                    const Divider(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng tỷ lệ: ${_spendPct + _savePct + _givePct}%',
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: (_spendPct + _savePct + _givePct) == 100
                                ? context.semantic.success
                                : context.semantic.danger,
                          ),
                        ),
                        Text(
                          'Tự động cân bằng = 100%',
                          style: context.text.bodySmall?.copyWith(
                            color: context.semantic.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],

          // --- 4. Gán việc nhà mẫu phân theo 4 Buổi & Chỉnh +- Xu ---
          if (widget.showPresets && widget.onPresetsChanged != null) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GÁN VIỆC MẪU CHO BÉ',
                  style: context.text.labelSmall?.copyWith(
                    color: context.semantic.onSurfaceMuted,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final allKeys = kTaskPresets.map((p) => p.key).toSet();
                    final isAll = widget.selectedPresetKeys.length == allKeys.length;
                    widget.onPresetsChanged?.call(isAll ? <String>{} : allKeys);
                  },
                  child: Text(
                    widget.selectedPresetKeys.length == kTaskPresets.length
                        ? 'Bỏ chọn hết'
                        : 'Chọn tất cả',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            Text(
              'Tích chọn việc nhà hàng ngày để tự động tạo và giao sẵn cho bé.',
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Nhóm 1: Buổi sáng
            _buildSessionGroup(
              title: '🌅 Buổi Sáng',
              presets: morningTasks,
              expanded: _expandMorning,
              onToggleExpand: () => setState(() => _expandMorning = !_expandMorning),
            ),

            // Nhóm 2: Buổi trưa / chiều
            _buildSessionGroup(
              title: '☀️ Buổi Trưa / Chiều',
              presets: afternoonTasks,
              expanded: _expandAfternoon,
              onToggleExpand: () => setState(() => _expandAfternoon = !_expandAfternoon),
            ),

            // Nhóm 3: Buổi tối
            _buildSessionGroup(
              title: '🌙 Buổi Tối',
              presets: eveningTasks,
              expanded: _expandEvening,
              onToggleExpand: () => setState(() => _expandEvening = !_expandEvening),
            ),

            // Nhóm 4: Thói quen & Giúp đỡ
            _buildSessionGroup(
              title: '🔄 Thói Quen & Giúp Đỡ',
              presets: habitTasks,
              expanded: _expandHabits,
              onToggleExpand: () => setState(() => _expandHabits = !_expandHabits),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionGroup({
    required String title,
    required List<TaskPreset> presets,
    required bool expanded,
    required VoidCallback onToggleExpand,
  }) {
    final visible = expanded ? presets : presets.take(3).toList();
    final hiddenCount = presets.length - visible.length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: context.colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${presets.where((p) => widget.selectedPresetKeys.contains(p.key)).length}/${presets.length} đã chọn',
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final preset in visible) ...[
            _PresetItemTile(
              preset: preset,
              points: _pointsMap[preset.key] ?? preset.defaultPoints,
              selected: widget.selectedPresetKeys.contains(preset.key),
              onSelected: (selected) {
                final current = Set<String>.from(widget.selectedPresetKeys);
                if (selected) {
                  current.add(preset.key);
                } else {
                  current.remove(preset.key);
                }
                widget.onPresetsChanged?.call(current);
              },
              onDecrease: () => _changePresetPoint(preset.key, -5),
              onIncrease: () => _changePresetPoint(preset.key, 5),
            ),
            const SizedBox(height: 4),
          ],
          if (presets.length > 3)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onToggleExpand,
                icon: Icon(
                  expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 18,
                ),
                label: Text(
                  expanded ? 'Thu gọn' : '+ Xem thêm ($hiddenCount việc)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PresetItemTile extends StatelessWidget {
  const _PresetItemTile({
    required this.preset,
    required this.points,
    required this.selected,
    required this.onSelected,
    required this.onDecrease,
    required this.onIncrease,
  });

  final TaskPreset preset;
  final int points;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    return Container(
      decoration: BoxDecoration(
        color: selected ? primary.withValues(alpha: 0.12) : context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(
          color: selected ? primary : context.colors.outlineVariant.withValues(alpha: 0.5),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (val) => onSelected(val ?? false),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            AppIcon.task(preset.iconKey, size: 22),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                preset.titleVi,
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? primary : context.colors.onSurface,
                ),
              ),
            ),
            if (selected) ...[
              IconButton(
                onPressed: points > 5 ? onDecrease : null,
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                tooltip: 'Giảm 5 xu',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$points xu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onIncrease,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                visualDensity: VisualDensity.compact,
                tooltip: 'Tăng 5 xu',
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${preset.defaultPoints} xu',
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.onSurfaceMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SmartJarSlider extends StatelessWidget {
  const _SmartJarSlider({
    required this.label,
    required this.emoji,
    required this.value,
    required this.locked,
    required this.onToggleLock,
    required this.onChanged,
  });

  final String label;
  final String emoji;
  final int value;
  final bool locked;
  final VoidCallback onToggleLock;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: onToggleLock,
          icon: Icon(
            locked ? Icons.lock_rounded : Icons.lock_open_rounded,
            size: 18,
            color: locked ? context.colors.primary : context.semantic.onSurfaceMuted,
          ),
          tooltip: locked ? 'Đã chốt khoá tỷ lệ' : 'Khoá cố định tỷ lệ này',
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          flex: 4,
          child: Slider(
            value: value.toDouble(),
            max: 100,
            divisions: 20,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$value%',
            textAlign: TextAlign.end,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _AgePicker extends StatelessWidget {
  const _AgePicker({
    required this.birthYear,
    required this.onChanged,
    required this.color,
  });

  final int? birthYear;
  final ValueChanged<int?> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final clock = FamilyClock(timeZoneOffset: now.timeZoneOffset);
    final currentYear = clock.today().year;

    final selectedAge = birthYear != null ? currentYear - birthYear! : null;

    final ages = [
      for (var a = kMinSupportedAge; a <= kMaxSupportedAge; a++) a,
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final age in ages) ...[
          GestureDetector(
            onTap: () => onChanged(currentYear - age),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: age == selectedAge
                    ? color.withValues(alpha: 0.25)
                    : context.colors.primaryContainer,
                shape: BoxShape.circle,
                border: age == selectedAge
                    ? Border.all(color: color, width: 2.5)
                    : null,
              ),
              child: Text(
                '$age',
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: age == selectedAge ? color : context.colors.onSurface,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
