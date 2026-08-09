import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// ADR-013. Streak cố ý "dễ": mục tiêu là xây thói quen, không phải trừng phạt
/// đứa trẻ vì bị ốm hay đi chơi xa.
void main() {
  /// Dựng danh sách ngày giảm dần từ [from] lùi về trước.
  List<DayTally> tallies(CalendarDate from, List<(int due, int done)> days) {
    return [
      for (var i = 0; i < days.length; i++)
        DayTally(
          date: from.addDays(-i),
          due: days[i].$1,
          approved: days[i].$2,
        ),
    ];
  }

  const yesterday = CalendarDate(2026, 8, 15);

  test('danh sách rỗng cho streak 0', () {
    expect(calculateStreak([]).current, 0);
  });

  test('chuỗi ngày hoàn thành hết', () {
    final result = calculateStreak(
      tallies(yesterday, [(4, 4), (3, 3), (5, 5)]),
    );
    expect(result.current, 3);
  });

  test('đạt đúng ngưỡng 80% vẫn được tính', () {
    final result = calculateStreak(tallies(yesterday, [(5, 4)]));
    expect(result.current, 1);
  });

  test('dưới ngưỡng thì phải dùng ngày ân hạn', () {
    final result = calculateStreak(tallies(yesterday, [(5, 3)]));
    expect(result.current, 1);
    expect(result.graceUsedInMonth, 1);
  });

  test('ngày không có việc không cộng streak nhưng cũng không làm đứt', () {
    final result = calculateStreak(
      tallies(yesterday, [(3, 3), (0, 0), (3, 3)]),
    );
    expect(result.current, 2, reason: 'Ngày trung tính không được cộng vào');
  });

  test('nhiều ngày trung tính liên tiếp không phá streak', () {
    final result = calculateStreak(
      tallies(yesterday, [(2, 2), (0, 0), (0, 0), (0, 0), (2, 2)]),
    );
    expect(result.current, 2);
  });

  test('chỉ có một ngày ân hạn mỗi tháng', () {
    // Hai ngày hụt liên tiếp trong cùng tháng: ngày đầu được ân hạn, ngày sau dừng.
    final result = calculateStreak(
      tallies(yesterday, [(5, 1), (5, 1), (5, 5)]),
    );
    expect(result.current, 1);
    expect(result.graceUsedInMonth, 1);
  });

  test('ngày ân hạn làm mới sang tháng mới', () {
    // 1/9 hụt (ân hạn tháng 9), 31/8 hụt (ân hạn tháng 8), 30/8 đạt.
    final result = calculateStreak([
      const DayTally(date: CalendarDate(2026, 9, 1), due: 4, approved: 1),
      const DayTally(date: CalendarDate(2026, 8, 31), due: 4, approved: 1),
      const DayTally(date: CalendarDate(2026, 8, 30), due: 4, approved: 4),
    ]);
    expect(result.current, 3, reason: 'Mỗi tháng có ngày ân hạn riêng');
  });

  test('streak dừng ở ngày hụt thứ hai trong tháng', () {
    final result = calculateStreak(
      tallies(yesterday, [(4, 4), (4, 0), (4, 0), (4, 4), (4, 4)]),
    );
    // đạt, hụt (ân hạn), hụt (hết ân hạn -> dừng)
    expect(result.current, 2);
  });

  test('ngày đầu tiên đã hụt hai lần thì streak về 0 sau khi hết ân hạn', () {
    final result = calculateStreak(
      tallies(yesterday, [(4, 0), (4, 0)]),
    );
    expect(result.current, 1);
  });

  test('toàn ngày trung tính cho streak 0, không âm', () {
    final result = calculateStreak(tallies(yesterday, [(0, 0), (0, 0)]));
    expect(result.current, 0);
  });

  test('DayTally.ratio coi ngày không có việc là hoàn thành', () {
    const tally = DayTally(
      date: CalendarDate(2026, 8, 15),
      due: 0,
      approved: 0,
    );
    expect(tally.ratio, 1);
    expect(tally.isNeutral, isTrue);
  });
}
