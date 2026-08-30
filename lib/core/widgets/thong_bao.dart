import 'package:flutter/material.dart';

/// Thời lượng của mọi thông báo dạng thanh trượt.
///
/// Chủ dự án nêu 30/08/2026: *"Notification phải tự mất sau 2-3 giây, không
/// nằm mãi ở đó."* Mặc định của Material là **4 giây** — không phải "mãi mãi",
/// nhưng đủ lâu để một thanh đen che mất phần đầu của mục ngay dưới nó (ảnh
/// chụp: thanh "Đã bỏ ... khỏi thói quen" đè lên tiêu đề "Việc khác").
const kThoiLuongThongBao = Duration(seconds: 3);

/// Thời lượng cho thông báo **có nút hành động** (Hoàn tác...).
///
/// Vẫn nằm trong khoảng 2–3 giây chủ dự án yêu cầu, nhưng lấy mức trên: người
/// dùng phải kịp đọc câu vừa hiện **rồi** mới với tay bấm. Ngắn hơn nữa thì nút
/// Hoàn tác chỉ còn là trang trí.
const kThoiLuongThongBaoCoNut = Duration(seconds: 3);

/// Hiện một thông báo ngắn ở đáy màn hình.
///
/// Dùng hàm này thay cho `ScaffoldMessenger.of(context).showSnackBar(...)`
/// trực tiếp: thời lượng nằm ở **một chỗ**, nên đổi ý một lần là đổi cả app.
/// `test/unit/thong_bao_test.dart` canh việc đó.
///
/// Thông báo cũ bị đẩy đi ngay (`removeCurrentSnackBar`) thay vì xếp hàng chờ:
/// xếp hàng nghĩa là bấm nhanh ba nút thì thanh cuối cùng còn nằm đó sau chín
/// giây — đúng cái cảm giác "nằm mãi" mà chủ dự án phàn nàn.
void hienThongBao(
  BuildContext context,
  String noiDung, {
  SnackBarAction? hanhDong,
  bool noi = false,
}) {
  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(noiDung),
        action: hanhDong,
        behavior: noi ? SnackBarBehavior.floating : null,
        duration: hanhDong == null
            ? kThoiLuongThongBao
            : kThoiLuongThongBaoCoNut,
      ),
    );
}

/// Như [hienThongBao] nhưng cho nội dung không phải chuỗi thuần (có icon, có
/// chữ nhiều màu...). Giữ nguyên ràng buộc thời lượng.
void hienThongBaoTuyChinh(
  BuildContext context,
  Widget noiDung, {
  SnackBarAction? hanhDong,
  Color? mauNen,
  bool noi = false,
}) {
  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: noiDung,
        action: hanhDong,
        backgroundColor: mauNen,
        behavior: noi ? SnackBarBehavior.floating : null,
        duration: hanhDong == null
            ? kThoiLuongThongBao
            : kThoiLuongThongBaoCoNut,
      ),
    );
}
