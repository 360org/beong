import 'dart:async';
import 'dart:math' as math;

import 'package:beong/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Hoa giấy rơi một lượt khi con làm xong việc — `KidScale.celebrateOnTap`.
///
/// Cờ `celebrateOnTap` có từ lâu nhưng **chưa nối vào hiệu ứng nào**: bé 5 tuổi
/// tick xong một việc và không có gì xảy ra ngoài việc thẻ đổi màu. Phần thưởng
/// tức thì là thứ giữ trẻ nhỏ quay lại, và nó phải đến **ngay lúc bấm**, không
/// phải cuối ngày.
///
/// Tự vẽ bằng [CustomPainter] chứ không thêm gói hoa giấy:
/// - Gói ngoài kéo theo bản quyền và cập nhật phải theo, cho một hiệu ứng 20 dòng.
/// - App là offline-first (ADR-002) nên mọi thứ phải nằm trong bundle.
/// - Tự vẽ thì màu lấy đúng từ bảng màu hồ sơ của bé, không lệch tông.
///
/// Không lặp lại: hoa giấy chạy **một lượt rồi tự dọn**. Hiệu ứng lặp mãi sẽ hút
/// hết chú ý khỏi những việc còn lại.
/// Khoá của lớp vẽ hoa giấy — dùng trong test.
const Key confettiLayerKey = ValueKey('hoa-giay');

class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    required this.child,
    required this.play,
    this.seedColor,
    super.key,
  });

  final Widget child;

  /// Đổi từ `false` sang `true` là chạy một lượt. Truyền cùng giá trị nhiều lần
  /// không chạy lại — nếu không, mỗi lần widget dựng lại sẽ nổ hoa giấy.
  final bool play;

  /// Màu chủ đạo, thường là màu hồ sơ của bé.
  final Color? seedColor;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  /// Dựng trong [initState], **không** dùng `late final` khởi tạo lười.
  ///
  /// Với `late final`, thẻ việc nào bị tháo mà chưa từng được bấm sẽ chạm vào
  /// `_controller` lần đầu ở `dispose()` — tức là tạo `Ticker` trên một element
  /// đã tháo, và Flutter ném "Looking up a deactivated widget's ancestor is
  /// unsafe". Đó là ca **thường gặp nhất**: gần như mọi thẻ việc đều bị tháo mà
  /// không ai bấm.
  late final AnimationController _controller;

  List<_Piece> _pieces = const [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // 900ms: đủ thấy, chưa kịp làm con phải chờ mới bấm được việc tiếp theo.
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(ConfettiBurst old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) _burst();
  }

  void _burst() {
    // Seed theo thời điểm bấm: mỗi lần một hình khác, không thành ra một hiệu
    // ứng lặp y hệt nhau.
    final random = math.Random(DateTime.now().microsecondsSinceEpoch);
    // Lấy đúng màu thương hiệu, không bịa màu mới: hoa giấy lệch tông trông như
    // của app khác dán vào.
    final palette = [
      widget.seedColor ?? AppColors.beOngHoney,
      AppColors.beOngHoney,
      AppColors.brand360Green,
      AppColors.brand360Blue,
    ];
    setState(() {
      _pieces = [
        for (var i = 0; i < 18; i++)
          _Piece(
            angle: random.nextDouble() * math.pi * 2,
            distance: 40 + random.nextDouble() * 70,
            spin: (random.nextDouble() - 0.5) * 8,
            size: 5 + random.nextDouble() * 5,
            color: palette[random.nextInt(palette.length)],
          ),
      ];
    });
    // Nổ hoa giấy rồi tự tắt — không ai chờ kết quả.
    unawaited(_controller.forward(from: 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        // `IgnorePointer`: hoa giấy phủ lên thẻ việc, không có nó thì trong lúc
        // bay nó ăn mất cú bấm tiếp theo của con.
        if (_pieces.isNotEmpty)
          Positioned.fill(
            // Key để test nhận ra đúng lớp này: `find.byType(CustomPaint)` bắt
            // cả painter nội bộ của Material nên không dùng được.
            key: confettiLayerKey,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(
                    pieces: _pieces,
                    progress: _controller.value,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

@immutable
class _Piece {
  const _Piece({
    required this.angle,
    required this.distance,
    required this.spin,
    required this.size,
    required this.color,
  });

  final double angle;
  final double distance;
  final double spin;
  final double size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.pieces, required this.progress});

  final List<_Piece> pieces;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    // Chậm dần rồi rơi xuống: bay đều trông như máy, không như hoa giấy thật.
    final eased = Curves.easeOutCubic.transform(progress);
    final fade = progress < 0.6 ? 1.0 : 1 - (progress - 0.6) / 0.4;

    for (final piece in pieces) {
      final travelled = piece.distance * eased;
      final gravity = 26 * progress * progress;
      final offset =
          center +
          Offset(
            math.cos(piece.angle) * travelled,
            math.sin(piece.angle) * travelled + gravity,
          );

      canvas
        ..save()
        ..translate(offset.dx, offset.dy)
        ..rotate(piece.spin * eased);

      final paint = Paint()..color = piece.color.withValues(alpha: fade);
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: piece.size,
              height: piece.size * 1.6,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.progress != progress || old.pieces != pieces;
}
