import 'package:beong/features/settings/ty_gia_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

/// Đọc con số bố mẹ gõ vào ô tỷ giá quy đổi.
///
/// Chủ dự án nêu 30/08/2026: *"chỗ quy đổi xu phải có option cho người dùng
/// chọn nhập số quy đổi."* Mở ô nhập ra là mở luôn đường cho một con số bất kỳ
/// đi thẳng vào `families.exchange_rate_xu` — trước đó chỗ này chỉ nhận sáu
/// mức do app tự chọn, nên chưa bao giờ phải đề phòng.
///
/// Nguy nhất là số **0**: `MoneyExchange.dongFor` chia cho tỷ giá, nên một số 0
/// lọt qua không chỉ hiện sai mà làm hỏng mọi màn có hiện tiền.
void main() {
  group('nhận', () {
    test('số thường', () {
      expect(docTyGia('15'), 15);
      expect(docTyGia('1'), 1);
    });

    test('có khoảng trắng thừa hai đầu', () {
      expect(docTyGia('  15  '), 15);
    });

    test('gõ kèm dấu chấm ngăn nghìn theo lối viết tiếng Việt', () {
      expect(
        docTyGia('1.000'),
        1000,
        reason:
            'bố mẹ Việt gõ số nghìn có dấu chấm — đọc thành 1 rồi lặng lẽ đặt '
            'tỷ giá gấp nghìn lần là kiểu sai không ai kịp thấy',
      );
    });

    test('đúng mức trần', () {
      expect(docTyGia('$kTyGiaToiDa'), kTyGiaToiDa);
    });
  });

  group('từ chối', () {
    test('số 0 — chia cho 0 ở mọi màn có hiện tiền', () {
      expect(docTyGia('0'), isNull);
      expect(docTyGia('000'), isNull);
    });

    test('số âm', () {
      expect(docTyGia('-5'), isNull);
    });

    test('ô trống', () {
      expect(docTyGia(''), isNull);
      expect(docTyGia('   '), isNull);
    });

    test('chữ, hoặc số lẫn chữ', () {
      expect(docTyGia('mười'), isNull);
      expect(docTyGia('15 xu'), isNull);
    });

    test('số thập phân — tỷ giá là số xu, không có nửa xu', () {
      expect(docTyGia('1,5'), isNull);
    });

    test('vượt trần', () {
      expect(
        docTyGia('${kTyGiaToiDa + 1}'),
        isNull,
        reason:
            'quá mức này thì mọi số tiền hiện ra đều làm tròn xuống 0 đ — tỷ '
            'giá còn nhưng thôi mang nghĩa gì',
      );
    });

    test('số quá lớn đến mức tràn kiểu số', () {
      expect(docTyGia('9' * 30), isNull);
    });
  });
}
