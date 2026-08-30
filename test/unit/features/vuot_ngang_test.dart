import 'package:beong/features/parent_home/parent_home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canh ngưỡng nhận cú vuốt ngang trên thẻ con ở Trang chính.
///
/// Vì sao có file này: cử chỉ vuốt đã được báo là "làm xong" ngày 30/08/2026,
/// rồi chủ dự án thử trên máy thật và nó **không ăn**. Hai nguyên nhân, cả hai
/// đều không có test nào chạm tới:
///
/// 1. Cử chỉ chỉ gắn vào dải chữ tên con, cao chừng 40px — vuốt qua thân thẻ
///    không widget nào nhận. Phần này chỉ kiểm được bằng mắt trên app thật.
/// 2. Chỉ xét vận tốc ≥ 200. Vuốt chậm mà dứt khoát thì trượt. **Phần này
///    kiểm được**, và đó là việc của file này.
void main() {
  group('nhận cú vuốt ngang', () {
    test('vẩy nhanh dù đi ngắn vẫn tính', () {
      expect(
        laVuotNgangThatSu(quangDuong: 12, vanToc: 900),
        isTrue,
        reason: 'cú vẩy bằng cổ tay đi rất ngắn nhưng rất nhanh',
      );
    });

    test('kéo chậm mà đi đủ xa vẫn tính', () {
      expect(
        laVuotNgangThatSu(quangDuong: 120, vanToc: 30),
        isTrue,
        reason:
            'đây là cú vuốt chủ dự án làm và bản trước bỏ sót: kéo từ từ sang '
            'phải rồi nhấc tay, vận tốc cuối gần 0',
      );
    });

    test('vuốt sang trái cũng tính, không chỉ sang phải', () {
      expect(laVuotNgangThatSu(quangDuong: -120, vanToc: -30), isTrue);
      expect(laVuotNgangThatSu(quangDuong: -12, vanToc: -900), isTrue);
    });

    test('tay hơi lệch khi cuộn dọc thì KHÔNG tính', () {
      expect(
        laVuotNgangThatSu(quangDuong: 20, vanToc: 40),
        isFalse,
        reason:
            'ngưỡng thấp quá thì mỗi lần cuộn danh sách hơi chéo tay là modal '
            'lịch sử bật lên — phiền hơn là thiếu tính năng',
      );
    });

    test('chạm rồi nhấc, không di chuyển, thì KHÔNG tính', () {
      expect(laVuotNgangThatSu(quangDuong: 0, vanToc: 0), isFalse);
    });

    test('ngưỡng quãng đường không thấp hơn vùng chạm tối thiểu', () {
      // 48dp là vùng chạm tối thiểu của dự án. Ngắn hơn thì không còn phân
      // biệt được với một cú chạm hơi trượt tay.
      expect(kQuangDuongVuot, greaterThanOrEqualTo(48.0));
      expect(laVuotNgangThatSu(quangDuong: kQuangDuongVuot, vanToc: 0), isTrue);
      expect(
        laVuotNgangThatSu(quangDuong: kQuangDuongVuot - 1, vanToc: 0),
        isFalse,
      );
    });
  });

  group('vuốt đổi ngày ngay trên thẻ, không mở hộp thoại', () {
    // Chủ dự án 30/08/2026: "vuốt ngang sang là quay về lịch sử chứ không phải
    // vuốt qua rồi mới popup lên". Một cú vuốt mà kết quả là một lớp phủ mới
    // thì vẫn là rời khỏi màn hình đang xem, chỉ khác cách mở.

    int vuot(int hienTai, double quangDuong) => luiNgaySauVuot(
      hienTai: hienTai,
      quangDuong: quangDuong,
      vanToc: 0,
      toiDa: 30,
    );

    test('vuốt phải lùi về quá khứ', () {
      expect(vuot(0, 120), 1);
      expect(vuot(1, 120), 2);
    });

    test('vuốt trái quay lại phía hôm nay', () {
      expect(vuot(2, -120), 1);
      expect(vuot(1, -120), 0);
    });

    test('không đi quá hôm nay — không có tương lai để xem', () {
      expect(vuot(0, -120), 0);
    });

    test('không lùi quá giới hạn — xa hơn chỉ còn khoảng trắng', () {
      expect(vuot(30, 120), 30);
    });

    test('cú vẩy nhanh không kéo cũng biết hướng từ vận tốc', () {
      expect(
        luiNgaySauVuot(hienTai: 0, quangDuong: 0, vanToc: 900, toiDa: 30),
        1,
      );
      expect(
        luiNgaySauVuot(hienTai: 3, quangDuong: 0, vanToc: -900, toiDa: 30),
        2,
      );
    });
  });
}
