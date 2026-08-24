import 'package:beong/core/theme/app_colors.dart';
import 'package:beong/core/theme/app_spacing.dart';
import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/kid_scale.dart';
import 'package:beong/core/widgets/app_icon.dart';
import 'package:beong/core/widgets/xu_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Thẻ một việc trong danh sách của con.
///
/// **Có state cục bộ, và đó là chủ ý.** Trạng thái thật đi một vòng dài: ghi
/// DB → cộng xu → xét thưởng trọn bộ → xét huy hiệu → luồng phát lại → dựng
/// lại. Nếu thẻ chỉ vẽ theo trạng thái thật thì trong suốt vòng đó con chạm
/// vào mà **không có gì xảy ra**, rồi đột nhiên mọi thứ nhảy một lượt. Cờ
/// `_vuaBam` lấp đúng khoảng lặng ấy: ô tròn tích ngay trong khung hình chạm.
class TaskCard extends StatefulWidget {
  const TaskCard({
    required this.title,
    required this.points,
    required this.isCompleted,
    required this.onToggle,
    super.key,
    this.iconKey,
    this.colorIndex = 0,
    this.isPending = false,
    this.isMissed = false,
  });

  final String title;
  final int points;
  final bool isCompleted;
  final bool isPending;
  final bool isMissed;
  final int colorIndex;

  /// Khoá emoji trong `task_icons.dart`. NULL → icon mặc định ⭐.
  final String? iconKey;
  final VoidCallback onToggle;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  /// Con vừa chạm, trạng thái thật chưa về.
  ///
  /// Nhả ra ngay khi trạng thái thật tới, để thẻ không giữ một lời hứa sai nếu
  /// việc ghi hỏng — sai mà im lặng còn khó lần ra hơn một cú chậm.
  bool _vuaBam = false;

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted || widget.isPending || widget.isMissed) {
      _vuaBam = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final points = widget.points;
    final iconKey = widget.iconKey;
    final isCompleted = widget.isCompleted;
    final isPending = widget.isPending;
    final isMissed = widget.isMissed;

    final scale = KidScaleScope.of(context);
    final profileColor = AppColors.profileColor(widget.colorIndex);
    final isDone = isCompleted || isPending || _vuaBam;
    final avatarSize = scale.tapTarget - AppSpacing.lg;

    return Card(
      child: InkWell(
        onTap: isDone || isMissed
            ? null
            : () {
                // Phản hồi xúc giác (haptic) nhẹ khi con chạm hoàn thành việc (§9)
                unawaited(HapticFeedback.lightImpact());
                // Tích ngay trong khung hình chạm, không chờ DB.
                setState(() => _vuaBam = true);
                widget.onToggle();
              },
        borderRadius: BorderRadius.circular(scale.cardRadius),
        child: ConstrainedBox(
          // Vùng chạm rộng theo tuổi — ngón tay trẻ nhỏ kém chính xác.
          constraints: BoxConstraints(minHeight: scale.tapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                _IconAvatar(
                  iconKey: iconKey,
                  faded: isDone,
                  boxSize: avatarSize,
                  emojiSize: scale.taskEmojiSize,
                  radius: scale.cardRadius * 0.7,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: context.text.bodyLarge?.copyWith(
                          fontSize:
                              (context.text.bodyLarge?.fontSize ?? 16) *
                              scale.textScale,
                          fontWeight: FontWeight.w700,
                          // Gạch ngang là "xong rồi". Việc đang chờ duyệt thì
                          // **chưa** xong: gạch nó đi là nói với con rằng phần
                          // của con đã trọn vẹn, trong khi xu chưa cộng và bố mẹ
                          // vẫn có thể mở lại.
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isDone
                              ? context.semantic.onSurfaceMuted
                              : context.colors.onSurface,
                        ),
                      ),
                      if (isPending)
                        Text(
                          'Chờ bố mẹ duyệt',
                          style: context.text.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.semantic.warning,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                XuBadge(amount: points, pill: true),
                const SizedBox(width: AppSpacing.sm),
                _Checkbox(
                  // `_vuaBam` cũng tính là đã tích: đó chính là chỗ lấp khoảng
                  // lặng giữa cú chạm và lúc trạng thái thật về.
                  checked: isCompleted || _vuaBam,
                  pending: isPending,
                  missed: isMissed,
                  color: profileColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconAvatar extends StatelessWidget {
  const _IconAvatar({
    required this.iconKey,
    required this.faded,
    required this.boxSize,
    required this.emojiSize,
    required this.radius,
  });

  final String? iconKey;
  final bool faded;
  final double boxSize;

  /// Cạnh của icon. Vẫn theo `KidScale.taskEmojiSize` — icon càng to với bé càng
  /// nhỏ, đúng như khi còn dùng emoji.
  final double emojiSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.5 : 1,
      child: Container(
        width: boxSize,
        height: boxSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.primaryContainer,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: AppIcon.task(iconKey, size: emojiSize),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({
    required this.checked,
    required this.pending,
    required this.missed,
    required this.color,
  });

  final bool checked;

  /// Con bấm xong nhưng bố mẹ chưa duyệt — xu **chưa** cộng.
  final bool pending;
  final bool missed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (pending) {
      // Đồng hồ chứ không phải dấu tích, và khác **hình** chứ không chỉ khác
      // màu (WCAG 1.4.1): dấu tích xanh y như việc đã duyệt là nói với con
      // rằng xong rồi, trong khi xu chưa vào ví.
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.semantic.warning, width: 2),
        ),
        child: Icon(
          Icons.hourglass_top_rounded,
          size: 18,
          color: context.semantic.warning,
        ),
      );
    }

    if (missed) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.semantic.danger, width: 2),
        ),
        child: Icon(Icons.close, size: 18, color: context.semantic.danger),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? color : Colors.transparent,
        border: Border.all(
          color: checked ? color : context.semantic.onSurfaceMuted,
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : null,
    );
  }
}
