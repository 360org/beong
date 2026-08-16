import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/domain/services/age_band.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:flutter/material.dart';

/// Form hồ sơ một bé: tên, tuổi, con vật, màu.
///
/// Dùng chung cho bước "Thêm bé" của onboarding và ô "Thêm bé" trong Cài đặt.
/// Trước đây form này nằm kín trong onboarding, nên nhà hai con chỉ khai được
/// một bé rồi hết đường — muốn thêm bé thứ hai phải đăng xuất và làm lại từ
/// đầu, mất luôn dữ liệu cũ.
class ChildProfileForm extends StatelessWidget {
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

  /// Bàn phím bật sẵn. Tắt trong bottom sheet: bàn phím che mất ô chọn con vật
  /// và màu ngay khi sheet vừa mở.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.profileColor(colorIndex);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nhập tên, tuổi, chọn màu và con vật cho bé.',
            style: context.text.bodyMedium?.copyWith(
              color: context.semantic.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Text(avatar, style: const TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Tên bé'),
            textCapitalization: TextCapitalization.words,
            autofocus: autofocus,
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
            birthYear: birthYear,
            onChanged: onBirthYearChanged,
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
              final selected = emoji == avatar;
              return GestureDetector(
                onTap: () => onAvatarChanged(emoji),
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
              final selected = i == colorIndex;
              return GestureDetector(
                onTap: () => onColorChanged(i),
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
        ],
      ),
    );
  }
}

/// Hàng chip chọn tuổi, cuộn ngang. Lưu **năm sinh** chứ không lưu tuổi.
///
/// Lưu tuổi thì sang năm dữ liệu sai; lưu năm sinh thì nhóm tuổi tự chuyển khi
/// bé lớn lên — xem `ageBandFor`. Bố mẹ nghĩ theo tuổi nên chip hiện tuổi, còn
/// năm sinh chỉ là thứ được lưu xuống DB.
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
            // Bấm lại chip đang chọn để bỏ chọn — bố mẹ không muốn khai tuổi
            // thì vẫn đi tiếp được.
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
