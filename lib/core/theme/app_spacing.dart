/// Thang khoảng cách và bo góc — `docs/04-design-system.md` §3.
///
/// Không dùng số magic cho padding/margin/radius ở widget; luôn đi qua đây.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;
  static const giant = 56.0;

  /// Lề ngang của màn hình. Desktop rộng hơn để nội dung không dính mép.
  static const screenPaddingMobile = 20.0;
  static const screenPaddingDesktop = 32.0;

  /// Vùng chạm tối thiểu — trẻ nhỏ ngón tay chưa chính xác.
  static const minTouchTarget = 48.0;
}

/// Kích thước thanh điều hướng — `docs/04-design-system.md` §1.
///
/// Tách thành token vì đây là ràng buộc khả dụng, không phải tinh chỉnh thẩm mỹ:
/// icon nav là **nội dung duy nhất** với bé chưa đọc được nhãn, nên nó phải to
/// hơn mức 24dp mặc định của Material. `app_theme_test.dart` giữ các mốc này.
abstract final class AppNavMetrics {
  /// Cỡ icon. Mặc định Material là 24 — quá nhỏ khi icon phải tự mang nghĩa.
  static const iconSize = 30.0;

  /// Chiều cao thanh dưới. Đủ chỗ cho icon 30 + nhãn 12 mà không chật.
  static const barHeight = 80.0;

  /// Bo góc viên nền icon đang chọn.
  static const indicatorRadius = 18.0;

  static const labelSize = 12.0;
  static const railLabelSize = 13.0;
}

abstract final class AppRadius {
  /// Viên thuốc: chip, nút.
  static const pill = 999.0;
  static const card = 20.0;
  static const field = 16.0;
  static const sheet = 28.0;
}

/// Điểm gãy layout — `docs/02-architecture.md` §6.
abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const medium = 1024.0;

  static bool isCompact(double width) => width < compact;
  static bool isMedium(double width) => width >= compact && width < medium;
  static bool isExpanded(double width) => width >= medium;
}
