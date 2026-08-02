import 'package:flutter/material.dart';

/// Kiểu chữ — `docs/04-design-system.md` §2.
///
/// Font Nunito sẽ được nhúng ở Sprint 1 (cần file .ttf trong `assets/fonts/`).
/// Tạm thời dùng font hệ thống để không chặn tiến độ; đổi [fontFamily] là xong.
abstract final class AppTypography {
  /// Font hệ thống ở Sprint 0. Nunito sẽ được nhúng ở Sprint 1 — khi có file
  /// .ttf trong `assets/fonts/`, đổi giá trị này thành `'Nunito'` là toàn bộ
  /// app chuyển font, không phải sửa chỗ nào khác.
  // TODO(sprint1): đổi sang 'Nunito' sau khi nhúng font.
  static const String? fontFamily = null;

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
  );
}
