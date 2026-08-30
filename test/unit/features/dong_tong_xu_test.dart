import 'package:beong/features/stats/stats_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dòng tổng ở màn Thống kê.
///
/// Chủ dự án nêu 30/08/2026: *"phần thống kê trên header profile nên show
/// total xu."* Đi tìm thì hoá ra tổng **có** — nhưng nằm chung một dòng với
/// giá trị quy đổi tiền, và cả dòng ẩn đi khi nhà tắt quy đổi. Quy đổi mặc
/// định tắt (ADR-017), nên với hầu hết các nhà tổng xu không hiện ở đâu cả:
/// muốn biết con có bao nhiêu thì phải tự cộng nhẩm năm ô hũ.
void main() {
  test('nhà tắt quy đổi vẫn thấy tổng', () {
    expect(
      dongTongXu(342, null),
      'Tổng 342 xu',
      reason: 'đây là ca mặc định của mọi nhà, và là ca từng mất hẳn dòng này',
    );
  });

  test('nhà bật quy đổi thì tổng đứng trước, tiền theo sau', () {
    expect(dongTongXu(342, '≈ 22.800 đ'), 'Tổng 342 xu  ≈ 22.800 đ');
  });

  test('không xu nào cũng hiện số 0, không bỏ trống', () {
    expect(
      dongTongXu(0, null),
      'Tổng 0 xu',
      reason: 'trống thì bố mẹ không biết là chưa có xu hay app chưa đọc xong',
    );
  });
}
