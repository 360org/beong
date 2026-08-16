import 'package:flutter/material.dart';

/// Bảng màu của Bé Ong.
///
/// Token lấy từ `docs/04-design-system.md` §1. Không hard-code màu ở nơi khác —
/// mọi widget đọc màu qua [Theme.of] hoặc [AppColors].
///
/// ## Ba màu thương hiệu và cách chia vai
///
/// Vàng mật của Bé Ong và xanh lá của 360 **không gánh được chữ trắng** (1.58:1
/// và 2.13:1, ngưỡng WCAG AA là 4.5:1), còn xanh dương của 360 thì gánh được
/// (4.65:1). Vai của từng màu suy ra từ chính ràng buộc đó:
///
/// | Màu | Vai | Quy tắc |
/// |---|---|---|
/// | Vàng mật `#FFC53D` | Nhận diện Bé Ong, chiếm nhiều diện tích: nút chính, xu, linh vật, danh hiệu | **Chỉ đi với chữ đậm** (11.00:1) |
/// | Dương 360 `#0077CD` | Tương tác và cấu trúc: `colorScheme.primary`, viền, thanh tiến độ | Đi được với chữ trắng |
/// | Lá 360 `#00CE2C` | Hoàn thành, duyệt | Nền sáng phải hạ độ sáng thành [successLight] |
///
/// Nút chính dùng vàng + chữ đậm chứ không dùng trắng-trên-primary: vừa cho
/// vàng chiếm diện tích lớn nhất màn hình, vừa đạt 11.00:1 thay vì 4.65:1.
///
/// Mọi cặp màu ở đây được `app_theme_test.dart` kiểm lại ngưỡng tương phản ở
/// mỗi lần chạy CI — đừng sửa tay mà không chạy test.
abstract final class AppColors {
  // ---- Màu thương hiệu, giữ nguyên mã gốc ----

  /// Xanh dương 360 Corp.
  static const brand360Blue = Color(0xFF0077CD);

  /// Xanh lá 360 Corp. Quá sáng để làm chữ trên nền trắng — nền sáng dùng
  /// [successLight], nền tối mới dùng trực tiếp màu này.
  static const brand360Green = Color(0xFF00CE2C);

  /// Vàng mật của Bé Ong. Không bao giờ ghép với chữ trắng.
  static const beOngHoney = Color(0xFFFFC53D);

  // ---- Light ----
  static const Color primaryLight = brand360Blue;
  static const onPrimaryLight = Color(0xFFFFFFFF);
  static const primaryContainerLight = Color(0xFFE3F2FD);

  /// Phải khai báo tường minh: ColorScheme của Material 3 tự suy ra
  /// `secondaryContainer` màu **teal** khi bỏ trống, và màu đó lọt vào viên nền
  /// icon đang chọn ở thanh điều hướng — không thuộc bộ màu nào của Bé Ong hay
  /// 360. Bỏ hai dòng này là teal quay lại.
  static const Color secondaryLight = successLight;
  static const onSecondaryLight = Color(0xFFFFFFFF);
  static const secondaryContainerLight = Color(0xFFD3E9FA);
  static const Color onSecondaryContainerLight = onSurfaceLight;

  /// Nhãn thanh điều hướng khi **chưa** chọn.
  ///
  /// Không dùng [onSurfaceMutedLight]: nhãn nav chỉ 11px nên cần >= 4.5:1, mà
  /// màu mờ kia chỉ đạt 3.31:1 — ngưỡng 3:1 của nó chỉ dành cho chữ đậm >= 13px.
  static const navLabelLight = Color(0xFF757195);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceVariantLight = Color(0xFFF6F5FC);
  static const onSurfaceLight = Color(0xFF1B1046);
  static const onSurfaceMutedLight = Color(0xFF8E8AA8);
  static const outlineLight = Color(0xFFE4E1F2);

  // ---- Dark ----
  /// Sáng hơn [brand360Blue] để nổi trên nền tối (6.48:1); chữ trên nó là
  /// [onPrimaryDark] đậm, không phải trắng.
  static const primaryDark = Color(0xFF3AA0E8);
  static const onPrimaryDark = Color(0xFF12082E);
  static const primaryContainerDark = Color(0xFF10365C);
  static const Color secondaryDark = successDark;
  static const onSecondaryDark = Color(0xFF12082E);
  static const secondaryContainerDark = Color(0xFF16406B);
  static const Color onSecondaryContainerDark = onSurfaceDark;

  /// Xem [navLabelLight]. Trên nền tối màu mờ sẵn đã đạt 5.58:1 nên dùng lại.
  static const Color navLabelDark = onSurfaceMutedDark;
  static const surfaceDark = Color(0xFF14102A);
  static const surfaceVariantDark = Color(0xFF1E1940);
  static const onSurfaceDark = Color(0xFFF2F0FF);
  static const onSurfaceMutedDark = Color(0xFFA7A2C4);
  static const outlineDark = Color(0xFF332C5E);

  // ---- Ngữ nghĩa ----

  /// Lá 360 hạ độ sáng để gánh được chữ trắng trên nền sáng (4.80:1).
  static const successLight = Color(0xFF00851C);
  static const Color successDark = brand360Green;

  /// Lá 360 nguyên bản, chỉ dùng làm **nền trang trí với nội dung đậm** —
  /// không đặt chữ trắng lên (2.13:1).
  static const Color successBright = brand360Green;

  /// Cam, tách rõ khỏi vàng mật để "chờ duyệt" không lẫn với xu.
  static const warningLight = Color(0xFFB55800);
  static const warningDark = Color(0xFFFF922B);
  static const dangerLight = Color(0xFFE31313);
  static const dangerDark = Color(0xFFF87171);

  /// Màu đồng xu — cũng là màu mật ong. Đơn vị điểm gọi là "xu" (ADR-015).
  static const Color xuLight = beOngHoney;
  static const xuDark = Color(0xFFFFD166);

  /// Màu **chữ số xu**, khác màu nền xu.
  ///
  /// Nền badge xu là vàng mật pha mờ 15% nên gần như trắng; viết số bằng chính
  /// [xuLight] lên đó chỉ đạt 1.47:1 — đọc không được. Mật đậm này đạt 4.51:1
  /// trên nền badge. Nền tối thì vàng sáng lại đủ tương phản.
  static const xuTextLight = Color(0xFF906500);
  static const xuTextDark = Color(0xFFFFD166);

  /// Chữ đặt **trên nền mật** ([xuLight]/[xuDark]) — huy hiệu xu, danh hiệu.
  ///
  /// Khác [xuTextLight]: cái kia là màu chữ xu trên nền trang, còn đây là trên
  /// chính nền vàng. Không đảo theo chủ đề, vì nền mật ở cả hai chủ đề đều
  /// sáng — dùng màu chữ sáng của chủ đề tối lên đó là vàng trên vàng.
  static const Color onXu = onSurfaceLight;

  /// Màu hồ sơ trẻ — dùng làm nền avatar, viền card, cột biểu đồ.
  ///
  /// Mỗi màu đạt contrast >= 4.8:1 với chữ trắng (ngưỡng WCAG AA là 4.5, chừa
  /// biên an toàn). Giá trị được tính bằng cách giữ nguyên hue/saturation của
  /// bảng màu thiết kế rồi hạ độ sáng đến khi đạt ngưỡng — `app_theme_test.dart`
  /// kiểm tra lại ràng buộc này, đừng sửa tay mà không chạy test.
  ///
  /// Thứ tự cố định — `members.color` lưu chỉ số, đổi thứ tự sẽ đổi màu của
  /// những trẻ đã tạo trước đó.
  static const profilePalette = <Color>[
    Color(0xFF0066B0), // dương 360 (đậm hơn mã gốc cho đủ tương phản)
    Color(0xFFE3004D), // hồng
    Color(0xFF00851C), // lá 360 (đã hạ độ sáng)
    Color(0xFF9E6606), // cam
    Color(0xFF047D92), // lam
    Color(0xFF9B3CF6), // mận
    Color(0xFFE31313), // đỏ
    Color(0xFF0E8074), // ngọc
  ];

  static Color profileColor(int index) =>
      profilePalette[index % profilePalette.length];

  /// Gradient thẻ "Dashboard" — điểm nhấn chính của trang chủ trẻ em.
  ///
  /// Chạy từ xanh dương 360 sang xanh lá 360: nền dùng đúng hai màu công ty,
  /// còn linh vật vàng đặt lên trên — vàng và xanh là cặp bù màu nên con ong
  /// nổi hẳn. Mọi điểm dọc gradient đạt >= 4.65:1 với chữ trắng (kiểm trong
  /// `app_theme_test.dart`), nên chữ trắng đặt ở đâu trên thẻ cũng đọc được.
  ///
  /// Dùng chung cho cả hai chế độ: hai màu này đã đủ đậm để chữ trắng đọc được
  /// và đủ tươi để nổi trên nền tối.
  static const dashboardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand360Blue, successLight],
  );
}

/// Màu không nằm trong [ColorScheme] của Material nhưng dùng xuyên suốt app.
///
/// Truy cập qua `Theme.of(context).extension<AppSemanticColors>()!`, hoặc tiện hơn
/// là `context.semanticColors` trong `core/theme/theme_extensions.dart`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.xu,
    required this.xuText,
    required this.onXu,
    required this.onSurfaceMuted,
  });

  final Color success;
  final Color warning;
  final Color danger;

  /// Màu **nền** của xu (vàng mật). Đặt chữ lên thì dùng [xuText].
  final Color xu;

  /// Màu **chữ số** xu — xem [AppColors.xuTextLight] để biết vì sao phải tách.
  final Color xuText;

  /// Chữ đặt trên nền mật [xu].
  final Color onXu;

  final Color onSurfaceMuted;

  static const light = AppSemanticColors(
    success: AppColors.successLight,
    warning: AppColors.warningLight,
    danger: AppColors.dangerLight,
    xu: AppColors.xuLight,
    xuText: AppColors.xuTextLight,
    onXu: AppColors.onXu,
    onSurfaceMuted: AppColors.onSurfaceMutedLight,
  );

  static const dark = AppSemanticColors(
    success: AppColors.successDark,
    warning: AppColors.warningDark,
    danger: AppColors.dangerDark,
    xu: AppColors.xuDark,
    xuText: AppColors.xuTextDark,
    onXu: AppColors.onXu,
    onSurfaceMuted: AppColors.onSurfaceMutedDark,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? xu,
    Color? xuText,
    Color? onXu,
    Color? onSurfaceMuted,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      xu: xu ?? this.xu,
      xuText: xuText ?? this.xuText,
      onXu: onXu ?? this.onXu,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      xu: Color.lerp(xu, other.xu, t)!,
      xuText: Color.lerp(xuText, other.xuText, t)!,
      onXu: Color.lerp(onXu, other.onXu, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
    );
  }
}
