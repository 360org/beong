import 'package:beong/domain/services/family_clock.dart';
import 'package:flutter_test/flutter_test.dart';

/// ADR-008: ngày của gia đình bắt đầu lúc 4h sáng theo múi giờ của họ.
/// Đây là chỗ dễ sai nhất trong toàn app — mọi phép tính ngày đều đi qua đây.
void main() {
  const vietnam = Duration(hours: 7);

  group('CalendarDate', () {
    test('weekday dùng 1 = thứ Hai … 7 = Chủ nhật', () {
      expect(const CalendarDate(2026, 8, 3).weekday, 1); // thứ Hai
      expect(const CalendarDate(2026, 8, 9).weekday, 7); // Chủ nhật
    });

    test('addDays vượt qua ranh giới tháng và năm', () {
      expect(
        const CalendarDate(2026, 8, 31).addDays(1),
        const CalendarDate(2026, 9, 1),
      );
      expect(
        const CalendarDate(2026, 12, 31).addDays(1),
        const CalendarDate(2027, 1, 1),
      );
      expect(
        const CalendarDate(2026, 3, 1).addDays(-1),
        const CalendarDate(2026, 2, 28),
      );
    });

    test('xử lý đúng năm nhuận', () {
      expect(
        const CalendarDate(2028, 2, 28).addDays(1),
        const CalendarDate(2028, 2, 29),
      );
    });

    test('so sánh theo thứ tự thời gian', () {
      expect(
        const CalendarDate(2026, 8, 1) < const CalendarDate(2026, 8, 2),
        isTrue,
      );
      expect(
        const CalendarDate(2026, 9, 1) > const CalendarDate(2026, 8, 31),
        isTrue,
      );
      expect(
        const CalendarDate(2027, 1, 1) > const CalendarDate(2026, 12, 31),
        isTrue,
      );
    });

    test('chuyển đổi qua lại với chuỗi ISO', () {
      const date = CalendarDate(2026, 8, 2);
      expect(date.toString(), '2026-08-02');
      expect(CalendarDate.parse('2026-08-02'), date);
    });

    test('monthKey dùng cho hạn mức ngày ân hạn', () {
      expect(const CalendarDate(2026, 8, 31).monthKey, '2026-08');
      expect(const CalendarDate(2026, 9, 1).monthKey, '2026-09');
    });

    test('differenceInDays', () {
      expect(
        const CalendarDate(
          2026,
          8,
          10,
        ).differenceInDays(const CalendarDate(2026, 8, 3)),
        7,
      );
    });
  });

  group('FamilyClock — giờ đổi ngày', () {
    const clock = FamilyClock(timeZoneOffset: vietnam);

    test('việc làm lúc 23h30 vẫn tính cho ngày hôm đó', () {
      // 23:30 ngày 2/8 giờ Việt Nam = 16:30 UTC.
      final instant = DateTime.utc(2026, 8, 2, 16, 30);
      expect(clock.dateAt(instant), const CalendarDate(2026, 8, 2));
    });

    test('3h59 sáng vẫn thuộc ngày hôm trước', () {
      final instant = DateTime.utc(2026, 8, 2, 20, 59); // 03:59 ngày 3/8 VN
      expect(clock.dateAt(instant), const CalendarDate(2026, 8, 2));
    });

    test('4h00 sáng là ngày mới', () {
      final instant = DateTime.utc(2026, 8, 2, 21); // 04:00 ngày 3/8 VN
      expect(clock.dateAt(instant), const CalendarDate(2026, 8, 3));
    });

    test('giữa trưa cho ra đúng ngày đang diễn ra', () {
      final instant = DateTime.utc(2026, 8, 2, 5); // 12:00 ngày 2/8 VN
      expect(clock.dateAt(instant), const CalendarDate(2026, 8, 2));
    });

    test('gia đình ở múi giờ khác cho ra ngày khác tại cùng thời điểm', () {
      const hanoi = FamilyClock(timeZoneOffset: Duration(hours: 7));
      const california = FamilyClock(timeZoneOffset: Duration(hours: -7));
      final instant = DateTime.utc(2026, 8, 2, 12);

      expect(hanoi.dateAt(instant), const CalendarDate(2026, 8, 2)); // 19:00
      expect(
        california.dateAt(instant),
        const CalendarDate(2026, 8, 2),
      ); // 05:00
    });

    test('dayRolloverHour = 0 thì ngày đổi lúc nửa đêm', () {
      const midnight = FamilyClock(
        timeZoneOffset: vietnam,
        dayRolloverHour: 0,
      );
      final instant = DateTime.utc(2026, 8, 2, 17, 30); // 00:30 ngày 3/8 VN
      expect(midnight.dateAt(instant), const CalendarDate(2026, 8, 3));
      expect(clock.dateAt(instant), const CalendarDate(2026, 8, 2));
    });

    test('chặn giờ đổi ngày vô lý', () {
      expect(
        () => FamilyClock(timeZoneOffset: vietnam, dayRolloverHour: 25),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
