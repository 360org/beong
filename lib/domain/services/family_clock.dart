/// Ngày "hôm nay" theo góc nhìn của một gia đình — ADR-008.
///
/// **Không được dùng `DateTime.now().day` ở bất kỳ đâu khác trong app.**
/// Một ngày của gia đình không bắt đầu lúc 00:00: trẻ làm việc lúc 23h30 vẫn
/// phải tính cho ngày hôm đó, không thì streak đứt oan. Ngày mới bắt đầu lúc
/// `families.day_rollover_hour` (mặc định 4h sáng) theo múi giờ của gia đình.
library;

import 'package:meta/meta.dart';

/// Một ngày lịch, không có giờ và không có múi giờ.
///
/// Dùng thay cho [DateTime] ở mọi chỗ nói về "ngày đến hạn" — [DateTime] mang
/// theo giờ và múi giờ, và đó chính là nguồn gốc của phần lớn lỗi lệch ngày.
@immutable
class CalendarDate implements Comparable<CalendarDate> {
  const CalendarDate(this.year, this.month, this.day);

  factory CalendarDate.fromDateTime(DateTime dt) =>
      CalendarDate(dt.year, dt.month, dt.day);

  /// Đọc lại từ dạng lưu trong DB (`YYYY-MM-DD`).
  factory CalendarDate.parse(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) {
      throw FormatException('Ngày không đúng định dạng YYYY-MM-DD', iso);
    }
    return CalendarDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  final int year;
  final int month;
  final int day;

  /// 1 = thứ Hai … 7 = Chủ nhật, khớp với `repeatDays` trong DB.
  int get weekday => DateTime(year, month, day).weekday;

  CalendarDate addDays(int days) =>
      CalendarDate.fromDateTime(DateTime(year, month, day + days));

  int differenceInDays(CalendarDate other) => DateTime(
    year,
    month,
    day,
  ).difference(DateTime(other.year, other.month, other.day)).inDays;

  /// Khoá tháng dạng `YYYY-MM`, dùng cho hạn mức ngày ân hạn của streak.
  String get monthKey =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  @override
  int compareTo(CalendarDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  bool operator <(CalendarDate other) => compareTo(other) < 0;
  bool operator <=(CalendarDate other) => compareTo(other) <= 0;
  bool operator >(CalendarDate other) => compareTo(other) > 0;
  bool operator >=(CalendarDate other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}'
      '-${day.toString().padLeft(2, '0')}';
}

/// Quy đổi thời điểm thật sang ngày của gia đình.
@immutable
class FamilyClock {
  const FamilyClock({
    required this.timeZoneOffset,
    this.dayRolloverHour = 4,
  }) : assert(
         dayRolloverHour >= 0 && dayRolloverHour <= 12,
         'Giờ đổi ngày phải nằm trong 0..12',
       );

  /// Lệch múi giờ của gia đình so với UTC.
  ///
  /// Lưu trong `families.timezone` dưới dạng tên IANA; tầng data quy đổi sang
  /// offset trước khi dựng [FamilyClock]. Giữ ở dạng offset để logic này thuần
  /// tuý, không phụ thuộc thư viện múi giờ và test được dễ dàng.
  final Duration timeZoneOffset;

  /// Giờ bắt đầu ngày mới. 4 nghĩa là 03:59 vẫn thuộc ngày hôm trước.
  final int dayRolloverHour;

  /// Ngày của gia đình tại thời điểm [instant].
  CalendarDate dateAt(DateTime instant) {
    final local = instant.toUtc().add(timeZoneOffset);
    final shifted = local.subtract(Duration(hours: dayRolloverHour));
    return CalendarDate(shifted.year, shifted.month, shifted.day);
  }

  /// Hôm nay theo giờ gia đình.
  CalendarDate today([DateTime? now]) => dateAt(now ?? DateTime.now());
}
