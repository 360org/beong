import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Biểu cảm của linh vật, đổi theo tiến độ làm việc trong ngày.
///
/// Với trẻ chưa đọc thông, mặt con ong *là* cách báo tiến độ — nhìn mặt biết
/// mình đang làm tốt hay chưa, không cần đọc số.
enum BeeMood {
  /// Chưa làm việc nào. Buồn ngủ, chưa "bay".
  sleepy,

  /// Đang làm dở.
  happy,

  /// Xong hết việc trong ngày.
  celebrating;

  /// Chọn biểu cảm từ tiến độ. [total] = 0 nghĩa là hôm nay không có việc —
  /// coi như đang ngủ, không phải đã hoàn thành.
  static BeeMood fromProgress({required int completed, required int total}) {
    if (total == 0 || completed == 0) return BeeMood.sleepy;
    if (completed >= total) return BeeMood.celebrating;
    return BeeMood.happy;
  }
}

/// Linh vật ong của Bé Ong.
///
/// Vẽ bằng [CustomPainter] chứ không dùng emoji 🐝: emoji đổi hình theo nền
/// tảng (Apple/Google/Samsung vẽ khác nhau) nên không dùng được làm nhận diện
/// thương hiệu, và không điều khiển được biểu cảm.
///
/// Khi [BeeMood.celebrating] thì tự nảy nhẹ; các trạng thái khác đứng yên để
/// không gây nhiễu thị giác.
class BeeMascot extends StatefulWidget {
  const BeeMascot({
    required this.mood,
    super.key,
    this.size = 72,
    this.onTap,
  });

  /// Màu viền ngoài thân ong.
  ///
  /// Thân ong màu vàng mật chỉ đạt 2.94:1 với nền gradient xanh của thẻ
  /// dashboard — dưới ngưỡng 3:1 mà WCAG 1.4.11 đòi cho hình mang nghĩa (mặt
  /// ong chính là cách báo tiến độ cho trẻ chưa đọc số). Viền kem kiểu sticker
  /// này là thứ tiếp giáp nền, và nó đạt ngưỡng, nên linh vật tách khỏi nền ở
  /// mọi màu nền. `app_theme_test.dart` kiểm lại ràng buộc đó.
  static const outlineColor = Color(0xFFFFF6E2);

  final BeeMood mood;
  final double size;
  final VoidCallback? onTap;

  @override
  State<BeeMascot> createState() => _BeeMascotState();
}

class _BeeMascotState extends State<BeeMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(BeeMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.mood == BeeMood.celebrating) {
      unawaited(_controller.repeat(reverse: true));
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final onTap = widget.onTap;
        if (onTap != null) {
          onTap();
        } else {
          // Nảy một lượt khi chạm vào linh vật
          unawaited(
            _controller.forward(from: 0).then((_) {
              if (widget.mood == BeeMood.celebrating) {
                unawaited(_controller.repeat(reverse: true));
              } else {
                _controller.value = 0;
              }
            }),
          );
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Nảy tối đa 8% chiều cao — đủ thấy vui, không tới mức nhấp nháy.
          final lift = Curves.easeInOut.transform(_controller.value);
          return Transform.translate(
            offset: Offset(0, -lift * widget.size * 0.08),
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _BeePainter(mood: widget.mood),
            ),
          );
        },
      ),
    );
  }
}

class _BeePainter extends CustomPainter {
  _BeePainter({required this.mood});

  final BeeMood mood;

  // Toàn bộ hình vẽ trong hệ toạ độ 0..1 rồi nhân theo `size`, nên linh vật
  // giữ đúng tỷ lệ ở mọi cỡ.
  static const _bodyColor = Color(0xFFFFC53D);
  static const _stripeColor = Color(0xFF3D2E00);
  static const _inkColor = Color(0xFF1B1046);
  static const _cheekColor = Color(0x33E3004D);
  static const _wingColor = Color(0x99FFFFFF);
  static const _wingEdge = Color(0x331B1046);

  // Bố cục theo chiều dọc, tất cả tính theo cạnh canvas (0..1):
  //   0.26..0.86  thân
  //   0.40..0.62  vùng mặt (mắt, má, miệng)
  //   0.68..0.86  bụng — chỉ vẽ sọc ở đây
  // Sọc *không được* lấn vào vùng mặt, nếu không mắt sẽ nằm trên sọc.
  static const _bodyTop = 0.26;
  static const _bodyBottom = 0.86;
  static const _bellyStart = 0.68;
  static const _eyeY = 0.455;
  static const _mouthY = 0.565;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);

    final bodyRect = Rect.fromLTRB(
      0.17 * s,
      _bodyTop * s,
      0.83 * s,
      _bodyBottom * s,
    );

    _paintWings(canvas, s, p);
    _paintBody(canvas, bodyRect, s);
    _paintStripes(canvas, bodyRect, s);
    _paintAntennae(canvas, s, p);
    _paintFace(canvas, s, p);
  }

  void _paintWings(Canvas canvas, double s, Offset Function(double, double) p) {
    final fill = Paint()..color = _wingColor;
    final edge = Paint()
      ..color = _wingEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.014 * s;

    for (final left in [true, false]) {
      final dir = left ? -1.0 : 1.0;
      canvas
        ..save()
        ..translate(p(0.5 + dir * 0.30, 0.42).dx, p(0.5, 0.42).dy)
        ..rotate(dir * 0.45);
      // Cánh to và nhô ra hẳn khỏi thân, có viền để đọc được trên nền tím.
      final wing = Rect.fromCenter(
        center: Offset.zero,
        width: 0.34 * s,
        height: 0.24 * s,
      );
      canvas
        ..drawOval(wing, fill)
        ..drawOval(wing, edge)
        ..restore();
    }
  }

  void _paintBody(Canvas canvas, Rect bodyRect, double s) {
    canvas
      // Viền kem kiểu sticker, vẽ trước và dày hơn thân nên nhô ra thành đường
      // bao — đây là thứ tách linh vật khỏi nền, xem [BeeMascot.outlineColor].
      ..drawOval(
        bodyRect,
        Paint()
          ..color = BeeMascot.outlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.075 * s
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawOval(bodyRect, Paint()..color = _bodyColor)
      // Viền tối rất mảnh cho thân có nét, không thay vai của viền kem.
      ..drawOval(
        bodyRect,
        Paint()
          ..color = _stripeColor.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.012 * s,
      );
  }

  void _paintStripes(Canvas canvas, Rect bodyRect, double s) {
    // Sọc phải nằm trong thân: clip theo chính hình oval của thân.
    canvas
      ..save()
      ..clipPath(Path()..addOval(bodyRect));

    final stripe = Paint()..color = _stripeColor.withValues(alpha: 0.85);
    // Hai sọc ở phần bụng, cách hẳn vùng mặt phía trên.
    for (final top in [_bellyStart, _bellyStart + 0.085]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bodyRect.left, top * s, bodyRect.width, 0.055 * s),
          Radius.circular(0.02 * s),
        ),
        stripe,
      );
    }
    canvas.restore();
  }

  void _paintAntennae(
    Canvas canvas,
    double s,
    Offset Function(double, double) p,
  ) {
    final paint = Paint()
      ..color = _inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.026 * s
      ..strokeCap = StrokeCap.round;

    for (final left in [true, false]) {
      final dir = left ? -1.0 : 1.0;
      final start = p(0.5 + dir * 0.10, _bodyTop + 0.02);
      final tip = p(0.5 + dir * 0.19, 0.09);
      canvas
        ..drawPath(
          Path()
            ..moveTo(start.dx, start.dy)
            ..quadraticBezierTo(
              p(0.5 + dir * 0.11, 0.16).dx,
              p(0.5, 0.16).dy,
              tip.dx,
              tip.dy,
            ),
          paint,
        )
        ..drawCircle(tip, 0.038 * s, Paint()..color = _inkColor);
    }
  }

  void _paintFace(Canvas canvas, double s, Offset Function(double, double) p) {
    final ink = Paint()..color = _inkColor;
    const eyeY = _eyeY;

    if (mood == BeeMood.sleepy) {
      // Mắt nhắm: hai nét cong xuống.
      final lid = Paint()
        ..color = _inkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.028 * s
        ..strokeCap = StrokeCap.round;
      for (final dir in [-1.0, 1.0]) {
        final c = p(0.5 + dir * 0.11, eyeY);
        canvas.drawArc(
          Rect.fromCenter(center: c, width: 0.11 * s, height: 0.09 * s),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          lid,
        );
      }
    } else {
      for (final dir in [-1.0, 1.0]) {
        canvas
          ..drawCircle(p(0.5 + dir * 0.11, eyeY), 0.040 * s, ink)
          // Đốm sáng cho mắt có sức sống.
          ..drawCircle(
            p(0.5 + dir * 0.11 + 0.014, eyeY - 0.014),
            0.014 * s,
            Paint()..color = Colors.white.withValues(alpha: 0.9),
          );
      }
    }

    // Má hồng — chi tiết làm mặt "mềm" hẳn, giữ ở mọi biểu cảm.
    for (final dir in [-1.0, 1.0]) {
      canvas.drawCircle(
        p(0.5 + dir * 0.215, _mouthY - 0.01),
        0.050 * s,
        Paint()..color = _cheekColor,
      );
    }

    // Miệng: cười càng tươi khi càng vui.
    final mouth = Paint()
      ..color = _inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.026 * s
      ..strokeCap = StrokeCap.round;

    final (width, height) = switch (mood) {
      BeeMood.sleepy => (0.10, 0.05),
      BeeMood.happy => (0.16, 0.10),
      BeeMood.celebrating => (0.20, 0.16),
    };

    if (mood == BeeMood.celebrating) {
      // Miệng mở tròn khi ăn mừng — tô đặc, dễ đọc hơn nét mảnh.
      canvas.drawArc(
        Rect.fromCenter(
          center: p(0.5, _mouthY),
          width: width * s,
          height: height * s,
        ),
        0,
        math.pi,
        false,
        Paint()..color = _inkColor,
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(
          center: p(0.5, _mouthY),
          width: width * s,
          height: height * s,
        ),
        math.pi * 0.12,
        math.pi * 0.76,
        false,
        mouth,
      );
    }
  }

  @override
  bool shouldRepaint(_BeePainter oldDelegate) => oldDelegate.mood != mood;
}
