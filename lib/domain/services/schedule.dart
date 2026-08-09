import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:meta/meta.dart';

/// Lịch lặp của một task hoặc routine.
///
/// Task nằm trong routine **không có lịch riêng** — nó kế thừa lịch của routine
/// (ADR-011). Quy tắc đó được áp ở tầng gọi, không ở đây.
@immutable
class Schedule {
  const Schedule({
    required this.type,
    this.weekdays = const {},
    this.onceDate,
  });

  const Schedule.daily() : this(type: RepeatType.daily);

  /// [weekdays] dùng 1 = thứ Hai … 7 = Chủ nhật.
  const Schedule.custom(Set<int> weekdays)
    : this(type: RepeatType.custom, weekdays: weekdays);

  const Schedule.once(CalendarDate date)
    : this(type: RepeatType.once, onceDate: date);

  final RepeatType type;
  final Set<int> weekdays;
  final CalendarDate? onceDate;

  /// Lịch này có rơi vào ngày [date] không?
  bool occursOn(CalendarDate date) => switch (type) {
    RepeatType.daily => true,
    RepeatType.custom => weekdays.contains(date.weekday),
    RepeatType.once => onceDate == date,
  };

  /// Lịch đã qua hẳn tính đến [date] — dùng để ngừng sinh instance cho task
  /// `once` đã xong, khỏi quét vô ích mỗi lần mở app.
  bool isExhaustedAfter(CalendarDate date) =>
      type == RepeatType.once && (onceDate == null || onceDate! < date);

  /// Liệt kê các ngày lịch rơi vào, trong khoảng `[from, to]` (bao gồm hai đầu).
  Iterable<CalendarDate> occurrencesBetween(
    CalendarDate from,
    CalendarDate to,
  ) sync* {
    if (to < from) return;
    var cursor = from;
    while (cursor <= to) {
      if (occursOn(cursor)) yield cursor;
      cursor = cursor.addDays(1);
    }
  }
}

/// Một lượt việc cần được tạo trong DB.
@immutable
class PlannedInstance {
  const PlannedInstance({
    required this.taskId,
    required this.memberId,
    required this.dueDate,
    required this.pointsSnapshot,
  });

  final String taskId;
  final String memberId;
  final CalendarDate dueDate;

  /// Xu được chốt tại thời điểm sinh lượt việc — ADR-007. Bố mẹ đổi giá task
  /// sau đó không được làm thay đổi những lượt đã sinh.
  final int pointsSnapshot;

  @override
  bool operator ==(Object other) =>
      other is PlannedInstance &&
      other.taskId == taskId &&
      other.memberId == memberId &&
      other.dueDate == dueDate &&
      other.pointsSnapshot == pointsSnapshot;

  @override
  int get hashCode => Object.hash(taskId, memberId, dueDate, pointsSnapshot);

  @override
  String toString() =>
      'PlannedInstance($taskId, $memberId, $dueDate, $pointsSnapshot xu)';
}

/// Đầu vào tối thiểu để lập lịch cho một task — cố ý không dùng entity đầy đủ
/// để logic này test được mà không cần dựng cả DB.
@immutable
class SchedulableTask {
  const SchedulableTask({
    required this.taskId,
    required this.schedule,
    required this.assigneeIds,
    required this.points,
    this.active = true,
  });

  final String taskId;

  /// Lịch hiệu lực: của routine nếu task thuộc routine, ngược lại của chính task.
  final Schedule schedule;

  /// Người được giao: theo routine nếu task thuộc routine, ngược lại theo task.
  final List<String> assigneeIds;

  final int points;
  final bool active;
}

/// Số ngày sinh trước. Đủ để trẻ xem được tuần tới mà không phình dữ liệu.
const kScheduleHorizonDays = 7;

/// Lập danh sách lượt việc cần có trong khoảng `[from, from + horizon]`.
///
/// Hàm thuần: không đọc DB, không biết cái gì đã tồn tại. Tầng gọi ghi xuống
/// bằng `INSERT ... ON CONFLICT DO NOTHING` với unique key
/// `(task_id, member_id, due_date)` — nhiều thiết bị cùng chạy vẫn không sinh trùng.
List<PlannedInstance> planInstances({
  required Iterable<SchedulableTask> tasks,
  required CalendarDate from,
  int horizonDays = kScheduleHorizonDays,
}) {
  final to = from.addDays(horizonDays);
  final planned = <PlannedInstance>[];

  for (final task in tasks) {
    if (!task.active || task.assigneeIds.isEmpty) continue;
    for (final date in task.schedule.occurrencesBetween(from, to)) {
      for (final memberId in task.assigneeIds) {
        planned.add(
          PlannedInstance(
            taskId: task.taskId,
            memberId: memberId,
            dueDate: date,
            pointsSnapshot: task.points,
          ),
        );
      }
    }
  }

  return planned;
}
