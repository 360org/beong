import 'package:beong/domain/entities/enums.dart';
import 'package:beong/features/parent_home/child_day_groups.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canh cách đếm "đã xong" trên thẻ con ở Trang chính.
///
/// Vì sao có file này: bản trước lấy **"khác `scheduled`" là xong**, nên việc
/// bỏ lỡ và việc bị từ chối cũng được đếm là xong. Lỗi nằm im chừng nào thẻ
/// chỉ hiện hôm nay — việc hôm nay chưa kịp bị đánh dấu bỏ lỡ. Vuốt ngang xem
/// ngày cũ (30/08/2026) là nó lộ ngay: một ngày con **không làm gì cả** hiện
/// "5/5" kèm dấu tích xanh, trong khi dòng đầu thẻ ghi "0/12 việc".
void main() {
  group('đếm việc đã xong', () {
    test('đã duyệt và chờ duyệt là xong', () {
      expect(daLamXong(InstanceStatus.approved.name), isTrue);
      expect(
        daLamXong(InstanceStatus.pendingReview.name),
        isTrue,
        reason: 'con đã làm và đã bấm xong, chỉ còn chờ bố mẹ nhìn',
      );
    });

    test('BỎ LỠ không phải là xong', () {
      expect(
        daLamXong(InstanceStatus.missed.name),
        isFalse,
        reason:
            'đây là lỗi đã từng hiện ra: ngày con không làm gì hiện 5/5 dấu '
            'tích xanh',
      );
    });

    test('bị từ chối không phải là xong', () {
      expect(daLamXong(InstanceStatus.rejected.name), isFalse);
    });

    test('chưa tới lượt thì chưa xong', () {
      expect(daLamXong(InstanceStatus.scheduled.name), isFalse);
    });
  });

  group('phân biệt việc hỏng với việc chưa làm', () {
    test('bỏ lỡ và bị từ chối là "hỏng"', () {
      expect(daHongViec(InstanceStatus.missed.name), isTrue);
      expect(daHongViec(InstanceStatus.rejected.name), isTrue);
    });

    test('việc chưa tới lượt KHÔNG phải hỏng', () {
      expect(
        daHongViec(InstanceStatus.scheduled.name),
        isFalse,
        reason: 'gạch ngang một việc con vẫn còn cơ hội làm là nói dối con',
      );
    });

    test('không trạng thái nào vừa xong vừa hỏng', () {
      for (final s in InstanceStatus.values) {
        expect(
          daLamXong(s.name) && daHongViec(s.name),
          isFalse,
          reason: '${s.name} không thể vừa xong vừa hỏng',
        );
      }
    });
  });
}
