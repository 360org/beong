import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 3/8/2026 là thứ Hai — mốc dễ kiểm tra bằng mắt cho lịch theo thứ.
  const monday = CalendarDate(2026, 8, 3);

  group('Schedule.occursOn', () {
    test('daily rơi vào mọi ngày', () {
      const schedule = Schedule.daily();
      for (var i = 0; i < 7; i++) {
        expect(schedule.occursOn(monday.addDays(i)), isTrue);
      }
    });

    test('custom chỉ rơi vào thứ đã chọn', () {
      const schedule = Schedule.custom({1, 3, 5}); // Hai, Tư, Sáu
      expect(schedule.occursOn(monday), isTrue);
      expect(schedule.occursOn(monday.addDays(1)), isFalse); // thứ Ba
      expect(schedule.occursOn(monday.addDays(2)), isTrue); // thứ Tư
      expect(schedule.occursOn(monday.addDays(6)), isFalse); // Chủ nhật
    });

    test('once chỉ rơi vào đúng ngày đó', () {
      const schedule = Schedule.once(CalendarDate(2026, 8, 5));
      expect(schedule.occursOn(const CalendarDate(2026, 8, 5)), isTrue);
      expect(schedule.occursOn(const CalendarDate(2026, 8, 4)), isFalse);
    });

    test('custom rỗng không bao giờ rơi vào ngày nào', () {
      expect(const Schedule.custom({}).occursOn(monday), isFalse);
    });
  });

  group('Schedule.occurrencesBetween', () {
    test('daily trong 7 ngày cho ra 8 ngày (bao gồm hai đầu)', () {
      const schedule = Schedule.daily();
      expect(schedule.occurrencesBetween(monday, monday.addDays(7)).length, 8);
    });

    test('khoảng đảo ngược cho ra rỗng', () {
      const schedule = Schedule.daily();
      expect(schedule.occurrencesBetween(monday.addDays(3), monday), isEmpty);
    });

    test('custom cho đúng các thứ trong khoảng', () {
      const schedule = Schedule.custom({6, 7}); // cuối tuần
      final days = schedule
          .occurrencesBetween(monday, monday.addDays(13))
          .toList();
      expect(days.length, 4); // hai cuối tuần
      expect(days.every((d) => d.weekday >= 6), isTrue);
    });
  });

  group('planInstances', () {
    test('sinh một lượt cho mỗi task × người × ngày', () {
      final planned = planInstances(
        tasks: const [
          SchedulableTask(
            taskId: 't1',
            schedule: Schedule.daily(),
            assigneeIds: ['an', 'binh'],
            points: 20,
          ),
        ],
        from: monday,
        horizonDays: 2,
      );

      // 3 ngày (hôm nay + 2) × 2 trẻ.
      expect(planned.length, 6);
      expect(planned.where((p) => p.memberId == 'an').length, 3);
    });

    test('chốt xu tại thời điểm sinh — ADR-007', () {
      final planned = planInstances(
        tasks: const [
          SchedulableTask(
            taskId: 't1',
            schedule: Schedule.daily(),
            assigneeIds: ['an'],
            points: 35,
          ),
        ],
        from: monday,
        horizonDays: 0,
      );
      expect(planned.single.pointsSnapshot, 35);
    });

    test('bỏ qua task đã tắt', () {
      final planned = planInstances(
        tasks: const [
          SchedulableTask(
            taskId: 't1',
            schedule: Schedule.daily(),
            assigneeIds: ['an'],
            points: 20,
            active: false,
          ),
        ],
        from: monday,
      );
      expect(planned, isEmpty);
    });

    test('bỏ qua task chưa giao cho ai', () {
      final planned = planInstances(
        tasks: const [
          SchedulableTask(
            taskId: 't1',
            schedule: Schedule.daily(),
            assigneeIds: [],
            points: 20,
          ),
        ],
        from: monday,
      );
      expect(planned, isEmpty);
    });

    test('task trong routine dùng lịch và người của routine', () {
      // Tầng gọi truyền lịch routine xuống — ADR-011. Kiểm tra hệ quả:
      // hai task cùng routine sinh cùng ngày, cùng người.
      const routineSchedule = Schedule.custom({1, 2, 3, 4, 5});
      final planned = planInstances(
        tasks: const [
          SchedulableTask(
            taskId: 'danh-rang',
            schedule: routineSchedule,
            assigneeIds: ['an'],
            points: 10,
          ),
          SchedulableTask(
            taskId: 'gap-chan',
            schedule: routineSchedule,
            assigneeIds: ['an'],
            points: 10,
          ),
        ],
        from: monday,
        horizonDays: 6,
      );

      final byDate = <CalendarDate, int>{};
      for (final p in planned) {
        byDate[p.dueDate] = (byDate[p.dueDate] ?? 0) + 1;
      }
      // 5 ngày trong tuần, mỗi ngày 2 task.
      expect(byDate.length, 5);
      expect(byDate.values.every((count) => count == 2), isTrue);
    });

    test('chạy hai lần cho ra kết quả giống hệt nhau', () {
      const tasks = [
        SchedulableTask(
          taskId: 't1',
          schedule: Schedule.daily(),
          assigneeIds: ['an'],
          points: 20,
        ),
      ];
      expect(
        planInstances(tasks: tasks, from: monday),
        planInstances(tasks: tasks, from: monday),
      );
    });

    test('mốc mặc định là 7 ngày', () {
      final planned = planInstances(
        tasks: const [
          SchedulableTask(
            taskId: 't1',
            schedule: Schedule.daily(),
            assigneeIds: ['an'],
            points: 20,
          ),
        ],
        from: monday,
      );
      expect(planned.length, kScheduleHorizonDays + 1);
    });
  });

  group('Schedule.isExhaustedAfter', () {
    test('once đã qua thì coi như hết', () {
      const schedule = Schedule.once(CalendarDate(2026, 8, 1));
      expect(schedule.isExhaustedAfter(const CalendarDate(2026, 8, 2)), isTrue);
      expect(
        schedule.isExhaustedAfter(const CalendarDate(2026, 8, 1)),
        isFalse,
      );
    });

    test('daily không bao giờ hết', () {
      expect(
        const Schedule.daily().isExhaustedAfter(const CalendarDate(2030, 1, 1)),
        isFalse,
      );
    });
  });

  group('RepeatType', () {
    test('tên hằng không đổi — dữ liệu cũ phụ thuộc vào chúng', () {
      expect(RepeatType.values.map((e) => e.name).toList(), [
        'once',
        'daily',
        'custom',
      ]);
    });
  });
}
