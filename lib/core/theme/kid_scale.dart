import 'package:beong/domain/services/age_band.dart';
import 'package:flutter/material.dart';

/// Tham số giao diện theo nhóm tuổi — đi cùng [AgeBand].
///
/// Mọi khác biệt giao diện giữa các nhóm tuổi phải khai báo ở đây, **không**
/// rải `if (ageBand == ...)` trong widget. Thêm một chiều điều chỉnh mới thì
/// thêm một trường ở đây và điền cho cả ba nhóm — làm vậy để không bao giờ có
/// nhóm tuổi bị bỏ sót.
@immutable
class KidScale {
  const KidScale({
    required this.band,
    required this.textScale,
    required this.tapTarget,
    required this.taskEmojiSize,
    required this.cardRadius,
    required this.showMascot,
    required this.celebrateOnTap,
    required this.showStreakFlame,
  });

  final AgeBand band;

  /// Nhân với cỡ chữ gốc. Trẻ nhỏ cần chữ to hơn để đọc được.
  final double textScale;

  /// Chiều cao tối thiểu của vùng chạm. Ngón tay trẻ nhỏ kém chính xác nên
  /// vùng chạm phải rộng hơn mức 48dp của Material.
  final double tapTarget;

  /// Cỡ emoji trên thẻ việc. Với trẻ chưa đọc thông, emoji *là* nội dung —
  /// không phải trang trí — nên phải to.
  final double taskEmojiSize;

  /// Bo góc thẻ. Càng nhỏ tuổi càng bo tròn cho mềm mại.
  final double cardRadius;

  /// Hiện linh vật ong. Trẻ lớn thấy linh vật là "app cho em bé".
  final bool showMascot;

  /// Nảy + hoa giấy khi bấm xong việc. Trẻ lớn thấy rườm rà.
  final bool celebrateOnTap;

  /// Hiện ngọn lửa streak. Trẻ nhỏ chưa hiểu khái niệm "chuỗi ngày".
  final bool showStreakFlame;

  /// 5–8 tuổi: to, tròn, nhiều phản hồi.
  static const little = KidScale(
    band: AgeBand.little,
    textScale: 1.15,
    tapTarget: 64,
    taskEmojiSize: 32,
    cardRadius: 24,
    showMascot: true,
    celebrateOnTap: true,
    showStreakFlame: false,
  );

  /// 9–12 tuổi: cân bằng — vẫn vui, đã gọn.
  static const middle = KidScale(
    band: AgeBand.middle,
    textScale: 1,
    tapTarget: 56,
    taskEmojiSize: 26,
    cardRadius: 20,
    showMascot: true,
    celebrateOnTap: true,
    showStreakFlame: true,
  );

  /// 13–15 tuổi: gọn gàng, không linh vật, không hoa giấy.
  static const teen = KidScale(
    band: AgeBand.teen,
    textScale: 0.95,
    tapTarget: 52,
    taskEmojiSize: 22,
    cardRadius: 16,
    showMascot: false,
    celebrateOnTap: false,
    showStreakFlame: true,
  );

  static KidScale of(AgeBand band) => switch (band) {
    AgeBand.little => little,
    AgeBand.middle => middle,
    AgeBand.teen => teen,
  };

  /// Tiện dùng trong widget: suy nhóm tuổi từ năm sinh rồi lấy tham số.
  static KidScale forBirthYear(int? birthYear, {required int currentYear}) =>
      of(ageBandFor(birthYear: birthYear, currentYear: currentYear));

  // So sánh theo giá trị: [KidScaleScope.updateShouldNotify] dựa vào đây để
  // biết có phải dựng lại cây con hay không.
  @override
  bool operator ==(Object other) =>
      other is KidScale &&
      other.band == band &&
      other.textScale == textScale &&
      other.tapTarget == tapTarget &&
      other.taskEmojiSize == taskEmojiSize &&
      other.cardRadius == cardRadius &&
      other.showMascot == showMascot &&
      other.celebrateOnTap == celebrateOnTap &&
      other.showStreakFlame == showStreakFlame;

  @override
  int get hashCode => Object.hash(
    band,
    textScale,
    tapTarget,
    taskEmojiSize,
    cardRadius,
    showMascot,
    celebrateOnTap,
    showStreakFlame,
  );
}

/// Đưa [KidScale] xuống cây widget để widget con không phải nhận qua tham số.
///
/// Đặt ngay dưới màn hình của trẻ; màn hình của bố mẹ không cần.
class KidScaleScope extends InheritedWidget {
  const KidScaleScope({
    required this.scale,
    required super.child,
    super.key,
  });

  final KidScale scale;

  /// Trả [KidScale.middle] khi không có scope — màn hình bố mẹ dùng mặc định
  /// này, không cần bọc thêm.
  static KidScale of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KidScaleScope>()?.scale ??
      KidScale.middle;

  @override
  bool updateShouldNotify(KidScaleScope oldWidget) => scale != oldWidget.scale;
}
