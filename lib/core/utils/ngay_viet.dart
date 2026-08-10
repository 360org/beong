/// Hiển thị ngày tháng theo cách người Việt đọc.
///
/// Không dùng `DateFormat` của `intl` cho những dạng ngắn này: `intl` cần nạp dữ
/// liệu locale và vẫn cho ra `10 thg 8` — đúng ngữ pháp nhưng dài, và trong một
/// danh sách dày thì `10/08` dễ quét mắt hơn. Dạng `dd/MM` cũng là dạng người
/// Việt viết tay, không nhập nhằng ngày–tháng như `MM/DD` của tiếng Anh.
library;

import 'package:beong/domain/services/family_clock.dart';

/// `10/08` — ngày trong năm nay.
String ngayNganGon(CalendarDate date) =>
    '${_hai(date.day)}/${_hai(date.month)}';

/// `10/08/2026` — khi cần rõ cả năm.
String ngayDayDu(CalendarDate date) =>
    '${_hai(date.day)}/${_hai(date.month)}/${date.year}';

/// Ngày của một `DateTime`, kèm giờ phút: `10/08 14:05`.
///
/// Dùng trong "Sổ của con": một dòng sổ không có mốc thời gian thì không tra
/// được, mà ghi cả năm thì chiếm chỗ vô ích vì gần như mọi dòng đều của năm nay.
String ngayGio(DateTime dt) =>
    '${_hai(dt.day)}/${_hai(dt.month)} ${_hai(dt.hour)}:${_hai(dt.minute)}';

/// Thứ trong tuần viết tắt: `T2`…`T7`, `CN`.
///
/// 1 = thứ Hai, khớp `DateTime.weekday` và cột `repeat_days` trong DB.
String thuNganGon(int weekday) => switch (weekday) {
  1 => 'T2',
  2 => 'T3',
  3 => 'T4',
  4 => 'T5',
  5 => 'T6',
  6 => 'T7',
  _ => 'CN',
};

/// `'1,3,5'` -> `'T2, T4, T6'`.
///
/// Rỗng thì trả về `null` để chỗ gọi tự quyết nói gì — mỗi màn có cách diễn đạt
/// riêng cho trạng thái "chưa chọn thứ nào".
String? thuTuChuoi(String repeatDays) {
  final days =
      repeatDays
          .split(',')
          .where((s) => s.isNotEmpty)
          .map(int.tryParse)
          .whereType<int>()
          .toSet()
          .toList()
        ..sort();
  if (days.isEmpty) return null;
  if (days.length == 7) return 'Hằng ngày';
  return days.map(thuNganGon).join(', ');
}

String _hai(int n) => n.toString().padLeft(2, '0');
