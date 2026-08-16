import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Khoá gắn vào `RepaintBoundary` bọc cả app, để chụp được màn hình đang hiện.
///
/// Chụp bằng chính cây widget chứ không xin quyền chụp màn hình của hệ điều
/// hành: xin quyền đó là thêm một mục phải khai với store cho một tính năng
/// dùng vài lần trong đời máy, và ảnh chụp của hệ điều hành còn lấy cả thanh
/// trạng thái lẫn thông báo đang kéo xuống — thứ có thể chứa tin nhắn riêng tư
/// của người khác.
final GlobalKey khoaChupManHinh = GlobalKey();

/// Chụp màn hình hiện tại, lưu ra file PNG và trả về đường dẫn.
///
/// Trả `null` nếu chưa dựng xong cây widget hoặc chụp hỏng — chỗ gọi phải chạy
/// tiếp mà không có ảnh, vì báo lỗi thất bại chỉ vì không chụp được ảnh thì
/// người dùng mất luôn cả báo cáo.
Future<String?> chupManHinh({double tyLe = 2.0}) async {
  final boundary =
      khoaChupManHinh.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
  if (boundary == null) return null;

  try {
    // `pixelRatio` 2.0 chứ không phải tỷ lệ thật của máy: ảnh 3x của điện thoại
    // đời mới ra file vài MB, quá nặng để đính vào một issue.
    final image = await boundary.toImage(pixelRatio: tyLe);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) return null;

    final dir = await getTemporaryDirectory();
    // Tên file có mốc thời gian: gửi báo cáo thứ hai không đè lên ảnh của báo
    // cáo thứ nhất khi cả hai còn đang chờ trong ứng dụng chia sẻ.
    final file = File(
      p.join(
        dir.path,
        'beong-loi-${DateTime.now().millisecondsSinceEpoch}.png',
      ),
    );
    await file.writeAsBytes(data.buffer.asUint8List());
    return file.path;
  } on Object catch (error, stack) {
    debugPrint('Không chụp được màn hình: $error\n$stack');
    return null;
  }
}
