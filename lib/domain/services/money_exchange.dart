import 'package:meta/meta.dart';

/// Đơn vị tiền dùng làm mốc quy đổi: **nghìn đồng**.
///
/// `families.exchange_rate_xu` lưu "bao nhiêu xu đổi được một đơn vị tiền", và
/// đơn vị đó chốt ở đây là 1.000 đ. Lấy 1 đồng làm mốc thì tỷ lệ thành số lẻ vô
/// nghĩa (0,1 xu = 1 đ); lấy nghìn đồng thì bố mẹ đặt được số tròn kiểu "10 xu
/// = 1.000 đ" và trẻ cũng nghĩ tiền theo nghìn.
const int kDongPerUnit = 1000;

/// Quy đổi xu ra tiền thật — ADR-017.
///
/// Mặc định **tắt** (`exchange_rate_xu` NULL). Gắn việc nhà với tiền là chủ đề
/// gây tranh cãi trong nuôi dạy con, và mặc định là một lời khuyên ngầm; nhà nào
/// muốn thì tự bật.
@immutable
class MoneyExchange {
  const MoneyExchange(this.xuPerUnit);

  /// Số xu đổi được [kDongPerUnit] đồng. `null` hoặc `<= 0` là tắt quy đổi.
  final int? xuPerUnit;

  /// Nhà này có bật quy đổi không.
  bool get enabled => (xuPerUnit ?? 0) > 0;

  /// Số **đồng** tương ứng với [xu], `null` khi tắt quy đổi.
  ///
  /// Làm tròn xuống: hiện nhiều hơn số con thật sự đổi được là hứa hão, và lời
  /// hứa hão về tiền thì bố mẹ phải trả bằng tiền thật.
  int? dongFor(int xu) {
    final rate = xuPerUnit;
    if (rate == null || rate <= 0) return null;
    return (xu * kDongPerUnit) ~/ rate;
  }

  /// Chuỗi hiện cho người đọc, ví dụ `≈ 6.500 đ`. `null` khi tắt quy đổi.
  ///
  /// Có dấu ≈ vì con số đã làm tròn xuống — bỏ dấu đi thì nó đọc như một cam
  /// kết chính xác tới từng đồng.
  String? labelFor(int xu) {
    final dong = dongFor(xu);
    return dong == null ? null : '≈ ${dinhDangDong(dong)} đ';
  }
}

/// Ngăn cách hàng nghìn bằng dấu **chấm**, đúng lối viết số của tiếng Việt.
///
/// Tự viết thay vì dùng `NumberFormat` của `intl`: cả app đang tránh `intl` cho
/// phần định dạng hiển thị (xem `core/utils/ngay_viet.dart`), và trộn hai lối
/// thì có ngày một màn hình hiện `6,500` còn màn kia hiện `6.500`.
String dinhDangDong(int dong) {
  final digits = dong.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return dong < 0 ? '-$buffer' : buffer.toString();
}
