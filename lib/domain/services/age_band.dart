/// Nhóm tuổi của trẻ, dùng để điều chỉnh giao diện — spec §4 "5–15 tuổi".
///
/// **5–15 tuổi không phải một nhóm người dùng.** Bé 6 tuổi chưa đọc thông, cần
/// icon to và ăn mừng rộn ràng; bé 14 tuổi thấy giao diện trẻ con là bỏ app.
/// Một giao diện "dễ thương" duy nhất sẽ mất nhóm lớn, nên tầng UI đọc
/// [AgeBand] rồi tự điều chỉnh (xem `core/theme/kid_scale.dart`).
///
/// Chỉ lưu `birthYear` (không lưu ngày sinh đầy đủ) là đủ: ranh giới nhóm
/// không cần chính xác đến tháng, và hỏi ít thông tin trẻ em thì tốt hơn.
library;

/// Ba nhóm tuổi, theo mốc phát triển đọc–viết và nhu cầu tự chủ.
enum AgeBand {
  /// 5–8 tuổi. Đọc chậm hoặc chưa đọc được: icon phải mang nghĩa, chữ to,
  /// vùng chạm rộng, ăn mừng thật rõ khi làm xong.
  little,

  /// 9–12 tuổi. Đọc tốt, thích sưu tầm và thấy tiến độ. Vẫn vui nhưng bớt
  /// "em bé".
  middle,

  /// 13–15 tuổi. Từ chối mọi thứ trông trẻ con. Muốn gọn gàng, số liệu rõ,
  /// tự quản lý — linh vật và ăn mừng phải giảm hẳn.
  teen,
}

/// Tuổi nhỏ nhất app nhắm tới. Dưới mốc này vẫn xếp vào [AgeBand.little].
const int kMinSupportedAge = 5;

/// Tuổi lớn nhất app nhắm tới. Trên mốc này vẫn xếp vào [AgeBand.teen].
const int kMaxSupportedAge = 15;

/// Nhóm tuổi dùng khi chưa biết năm sinh.
///
/// Chọn [AgeBand.middle] vì đây là lựa chọn ít gây hại nhất: không hạ thấp trẻ
/// lớn (mất người dùng), cũng không quá khô khan với trẻ nhỏ (vẫn dùng được).
const AgeBand kDefaultAgeBand = AgeBand.middle;

/// Suy ra nhóm tuổi từ năm sinh.
///
/// [currentYear] truyền vào chứ không đọc `DateTime.now()` để hàm này test
/// được và không lệ thuộc đồng hồ máy — cùng lý do với `CalendarDate` ở
/// `family_clock.dart`.
///
/// Trả về [kDefaultAgeBand] khi [birthYear] là `null` hoặc vô lý (năm ở tương
/// lai, hoặc cho ra tuổi ngoài khoảng người thật).
AgeBand ageBandFor({required int? birthYear, required int currentYear}) {
  if (birthYear == null) return kDefaultAgeBand;

  final age = currentYear - birthYear;
  // Chặn dữ liệu rác: năm sinh tương lai, hoặc tuổi không thể là trẻ em.
  if (age < 0 || age > 120) return kDefaultAgeBand;

  return ageBandForAge(age);
}

/// Xếp nhóm theo tuổi đã biết. Tuổi ngoài dải 5–15 được kẹp về nhóm gần nhất.
AgeBand ageBandForAge(int age) {
  if (age <= 8) return AgeBand.little;
  if (age <= 12) return AgeBand.middle;
  return AgeBand.teen;
}
