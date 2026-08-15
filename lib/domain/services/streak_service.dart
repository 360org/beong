import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/streak_calculator.dart';

/// Tính lại streak của trẻ từ lịch sử lượt việc, rồi ghi vào bảng `streaks`.
///
/// `calculateStreak` có từ Sprint 1 và có test đầy đủ, nhưng **chưa từng được
/// gọi từ đâu cả**: bảng `streaks` luôn rỗng, ngọn lửa trên màn hình con luôn
/// hiện 0, và ba huy hiệu streak không bao giờ đạt được. Logic đúng mà không nối
/// vào thì với người dùng nó không tồn tại.
///
/// Tính lại **từ đầu** mỗi lần thay vì cộng dồn: streak phụ thuộc vào cả chuỗi
/// ngày phía trước, mà bố mẹ mở lại một việc cũ hay khoản trừ cuối ngày đều làm
/// đổi kết quả của những ngày đã qua. Cộng dồn thì sai lệch tích tụ và không có
/// cách nào phát hiện.
class StreakService {
  const StreakService({required TaskDao taskDao, required MemberDao memberDao})
    : _tasks = taskDao,
      _members = memberDao;

  final TaskDao _tasks;
  final MemberDao _members;

  /// Số ngày lịch sử đem ra xét.
  ///
  /// 400 ngày là quá đủ cho huy hiệu 30 ngày và cho một streak dài kỷ lục, mà
  /// vẫn không phải quét toàn bộ lịch sử mỗi lần mở app.
  static const _lookbackDays = 400;

  /// Tính lại streak cho một trẻ. Trả về kết quả vừa ghi.
  Future<StreakResult> recalculate({
    required String memberId,
    required CalendarDate today,
  }) async {
    final instances = await _tasks.instancesForMemberSince(
      memberId: memberId,
      from: today.addDays(-_lookbackDays),
    );

    // Gom theo ngày: đến hạn bao nhiêu, đã duyệt bao nhiêu.
    final due = <String, int>{};
    final approved = <String, int>{};
    for (final instance in instances) {
      // **Bỏ hôm nay ra**: ngày chưa kết thúc thì chưa phán xét được, và tính
      // vào sẽ làm streak tụt xuống 0 mỗi sáng khi con chưa kịp làm gì.
      if (instance.dueDate == today.toString()) continue;
      due[instance.dueDate] = (due[instance.dueDate] ?? 0) + 1;
      if (instance.status == InstanceStatus.approved.name) {
        approved[instance.dueDate] = (approved[instance.dueDate] ?? 0) + 1;
      }
    }

    final days = due.keys.toList()..sort((a, b) => b.compareTo(a));
    final tallies = [
      for (final day in days)
        DayTally(
          date: CalendarDate.parse(day),
          due: due[day] ?? 0,
          approved: approved[day] ?? 0,
        ),
    ];

    final result = calculateStreak(tallies);
    final previous = await _members.getStreak(memberId);

    await _members.upsertStreak(
      memberId: memberId,
      currentLen: result.current,
      // Kỷ lục chỉ đi lên: đó là **thành tích đã đạt**, đứt chuỗi không xoá được
      // việc con đã từng làm được bấy nhiêu ngày.
      bestLen: result.current > (previous?.bestLen ?? 0)
          ? result.current
          : previous?.bestLen ?? 0,
      lastQualifiedDate: days.isEmpty ? null : days.first,
      graceUsedMonth: result.graceMonthKey.isEmpty
          ? null
          : result.graceMonthKey,
      graceCount: result.graceUsedInMonth,
    );

    return result;
  }
}
