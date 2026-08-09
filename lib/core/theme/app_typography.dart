import 'package:flutter/material.dart';

/// Kiểu chữ — `docs/04-design-system.md` §2.
///
/// Font **Nunito**, nhúng sẵn trong `assets/fonts/` (khai báo ở `pubspec.yaml`).
/// Chọn Nunito vì đạt cả ba yêu cầu của app này cùng lúc: nét bo tròn nên thân
/// thiện với trẻ, chiều cao chữ thường lớn nên dễ đọc, và đủ 134 ký tự tiếng
/// Việt có dấu — phần lớn font "trẻ em" trên Google Fonts thiếu dấu tiếng Việt
/// hoặc đặt dấu sai vị trí.
abstract final class AppTypography {
  /// Đổi giá trị này là toàn bộ app chuyển font, không phải sửa chỗ nào khác.
  ///
  /// Chỉ có ba weight được nhúng (500/700/800) — dùng weight khác sẽ bị nền
  /// tảng giả lập bằng cách làm đậm/mảnh nhân tạo, trông xấu. Cần weight mới
  /// thì sinh thêm file static.
  static const String fontFamily = 'Nunito';

  /// Trần phóng chữ. Tôn trọng cài đặt hệ thống nhưng chặn ở 1.6 để layout
  /// của trẻ không vỡ khi phụ huynh bật cỡ chữ rất lớn.
  static const maxTextScale = 1.6;

  static const displayL = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const titleL = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  static const titleM = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// Nhãn nhóm — luôn viết hoa ở tầng widget, không viết hoa sẵn trong chuỗi
  /// (để bản dịch còn tự nhiên).
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.8,
  );

  static const caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextTheme textTheme(Color onSurface) => TextTheme(
    displayLarge: displayL.copyWith(color: onSurface),
    titleLarge: titleL.copyWith(color: onSurface),
    titleMedium: titleM.copyWith(color: onSurface),
    bodyLarge: body.copyWith(color: onSurface),
    bodyMedium: body.copyWith(color: onSurface),
    labelLarge: label.copyWith(color: onSurface),
    bodySmall: caption.copyWith(color: onSurface),
    // `.apply` đặt family cho mọi style một lượt, kể cả các style Material tự
    // điền — an toàn hơn là gắn tay vào từng hằng ở trên và quên mất một cái.
  ).apply(fontFamily: fontFamily);
}
