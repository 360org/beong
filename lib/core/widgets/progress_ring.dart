import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Vòng tiến độ có linh vật ở giữa.
///
/// Vòng tròn (không phải thanh ngang) vì trẻ nhỏ đọc "đầy/chưa đầy" nhanh hơn
/// đọc tỷ lệ — và nó đủ lớn để đặt linh vật vào giữa, biến tiến độ thành một
/// hình duy nhất thay vì hai thông tin rời.
///
/// Tiến độ chạy mượt khi đổi giá trị để trẻ thấy được "vừa tiến thêm".
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    required this.size,
    required this.trackColor,
    required this.valueColor,
    super.key,
    this.strokeWidth = 10,
    this.child,
  });

  /// 0..1. Giá trị ngoài khoảng bị kẹp lại.
  final double progress;
  final double size;
  final Color trackColor;
  final Color valueColor;
  final double strokeWidth;

  /// Nội dung giữa vòng — thường là linh vật hoặc số việc.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              trackColor: trackColor,
              valueColor: valueColor,
              strokeWidth: strokeWidth,
            ),
            child: child == null ? null : Center(child: child),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.valueColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color valueColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      rect,
      -math.pi / 2, // Bắt đầu từ 12 giờ, chạy theo chiều kim đồng hồ.
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = valueColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.valueColor != valueColor ||
      old.strokeWidth != strokeWidth;
}
