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

/// Form hồ sơ một bé: tên, tuổi, con vật, màu, gán việc mẫu, hũ riêng và PIN.
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
    this.hasPin = false,
    this.onTogglePin,
    this.customJarSplit,
    this.onJarSplitChanged,
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

  /// Trạng thái bật/tắt mã PIN hồ sơ.
  final bool hasPin;
  final ValueChanged<bool>? onTogglePin;

  /// Tỷ lệ hũ riêng cho bé.
  final JarSplit? customJarSplit;
  final ValueChanged<JarSplit?>? onJarSplitChanged;

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

  @override
  void initState() {
    super.initState();
    _useCustomJars = widget.customJarSplit != null;
    final split = widget.customJarSplit ?? JarSplit.defaultSplit;
    _spendPct = split.spend;
    _savePct = split.save;
    _givePct = split.give;
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

  @override
  Widget build(BuildContext context) {
    final color = AppColors.profileColor(widget.colorIndex);

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
            'Nhập tên, tuổi, chọn màu, con vật và thiết lập riêng cho bé.',
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
            'MÀU',
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

          // --- 5. Bật/Tắt mật khẩu PIN ---
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

          // --- 7. Tuỳ chỉnh hũ xu riêng theo bé ---
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
              'Tuỳ biến tỷ lệ hũ theo độ tuổi: bé nhỏ có thể tăng hũ Chi tiêu/Đồ chơi, '
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
                    _JarSlider(
                      label: 'Tiêu / Đồ chơi',
                      emoji: '🛍️',
                      value: _spendPct,
                      onChanged: (val) {
                        setState(() {
                          _spendPct = val;
                          final rest = 100 - _spendPct;
                          _savePct = (rest * 0.8).round();
                          _givePct = rest - _savePct;
                        });
                        _updateSplit();
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _JarSlider(
                      label: 'Để dành / Học tập',
                      emoji: '🐷',
                      value: _savePct,
                      onChanged: (val) {
                        setState(() {
                          _savePct = val;
                          final rest = 100 - _savePct;
                          _spendPct = (rest * 0.8).round();
                          _givePct = rest - _spendPct;
                        });
                        _updateSplit();
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _JarSlider(
                      label: 'Cho đi / Chia sẻ',
                      emoji: '💝',
                      value: _givePct,
                      onChanged: (val) {
                        setState(() {
                          _givePct = val;
                          final rest = 100 - _givePct;
                          _spendPct = (rest * 0.6).round();
                          _savePct = rest - _spendPct;
                        });
                        _updateSplit();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],

          // --- 4. Gán việc nhà mẫu hàng loạt ---
          if (widget.showPresets && widget.onPresetsChanged != null) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GÁN VIỆC NHÀ MẪU CHO BÉ',
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
              'Tích chọn các việc hàng ngày để tự động tạo và giao sẵn cho bé.',
              style: context.text.bodySmall?.copyWith(
                color: context.semantic.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: kTaskPresets.map((preset) {
                final isSelected = widget.selectedPresetKeys.contains(preset.key);
                return FilterChip(
                  avatar: AppIcon.task(preset.iconKey, size: 18),
                  label: Text(preset.titleVi),
                  selected: isSelected,
                  onSelected: (selected) {
                    final current = Set<String>.from(widget.selectedPresetKeys);
                    if (selected) {
                      current.add(preset.key);
                    } else {
                      current.remove(preset.key);
                    }
                    widget.onPresetsChanged?.call(current);
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _JarSlider extends StatelessWidget {
  const _JarSlider({
    required this.label,
    required this.emoji,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String emoji;
  final int value;
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
              color: context.semantic.xuText,
            ),
          ),
        ),
      ],
    );
  }
}

/// Hàng chip chọn tuổi, cuộn ngang. Lưu **năm sinh** chứ không lưu tuổi.
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
    final currentYear = FamilyClock(
      timeZoneOffset: DateTime.now().timeZoneOffset,
    ).today().year;
    final years = birthYearOptions(currentYear: currentYear);

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: years.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final year = years[index];
          final selected = year == birthYear;

          return GestureDetector(
            onTap: () => onChanged(selected ? null : year),
            child: Container(
              width: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.25)
                    : context.colors.primaryContainer,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.field),
                ),
                border: selected ? Border.all(color: color, width: 2.5) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${currentYear - year}',
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'tuổi',
                    style: context.text.labelSmall?.copyWith(
                      color: context.semantic.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
