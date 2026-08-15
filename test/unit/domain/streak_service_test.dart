import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/streak_service.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

/// Tính lại streak từ lịch sử lượt việc và ghi vào bảng `streaks`.
///
/// `calculateStreak` có test riêng từ Sprint 1; nhóm test này lo phần **nối vào
/// dữ liệu thật** — phần trước đây không tồn tại, khiến bảng `streaks` luôn rỗng
/// và ngọn lửa trên màn hình con luôn hiện 0.
void main() {
  late AppDatabase db;
  late TaskDao taskDao;
  late MemberDao memberDao;
  late StreakService service;

  const familyId = 'fam-1';
  const childId = 'con-1';
  final today = CalendarDate.parse('2026-08-20');

  /// Một lượt việc đến hạn ngày [date], đã duyệt hay chưa tuỳ [done].
  Future<void> instance(String date, {required bool done, String? id}) => db
      .into(db.taskInstances)
      .insert(
        TaskInstancesCompanion.insert(
          id: id ?? '$date-${done ? 'ok' : 'no'}',
          familyId: familyId,
          taskId: 'task-1',
          memberId: childId,
          dueDate: date,
          pointsSnapshot: 10,
          status: Value(
            done ? InstanceStatus.approved.name : InstanceStatus.scheduled.name,
          ),
        ),
      );

  setUp(() async {
    db = AppDatabase.memory();
    taskDao = TaskDao(db);
    memberDao = MemberDao(db);
    service = StreakService(taskDao: taskDao, memberDao: memberDao);

    await memberDao.createFamily(
      FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'),
    );
    await memberDao.addMember(
      MembersCompanion.insert(
        id: childId,
        familyId: familyId,
        kind: MemberKind.child.name,
        displayName: 'Minh',
      ),
    );
    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: 'task-1',
            familyId: familyId,
            title: 'Đánh răng',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('chưa có lượt nào thì streak bằng 0 và vẫn ghi được hàng', () async {
    final result = await service.recalculate(memberId: childId, today: today);

    expect(result.current, 0);
    expect((await memberDao.getStreak(childId))?.currentLen, 0);
  });

  test('ba ngày liền làm hết thì streak bằng 3', () async {
    await instance('2026-08-17', done: true);
    await instance('2026-08-18', done: true);
    await instance('2026-08-19', done: true);

    final result = await service.recalculate(memberId: childId, today: today);

    expect(result.current, 3);
  });

  test('hôm nay không được tính vào streak', () async {
    // Ngày chưa kết thúc thì chưa phán xét được. Tính vào thì mỗi sáng streak
    // tụt về 0 khi con chưa kịp làm gì — cảm giác bị phạt vì trời vừa sáng.
    await instance('2026-08-19', done: true);
    await instance('2026-08-20', done: false);

    final result = await service.recalculate(memberId: childId, today: today);

    expect(result.current, 1, reason: 'chỉ tính ngày 19');
  });

  test('kỷ lục chỉ đi lên, đứt chuỗi không xoá thành tích cũ', () async {
    await instance('2026-08-15', done: true);
    await instance('2026-08-16', done: true);
    await instance('2026-08-17', done: true);
    await service.recalculate(memberId: childId, today: today);
    expect((await memberDao.getStreak(childId))?.bestLen, 3);

    // Hai ngày liền bỏ hết việc: một ngày còn được ân hạn (ADR-013), hai ngày
    // thì chuỗi đứt hẳn. Mỗi ngày **một** lượt — unique key
    // `(task_id, member_id, due_date)` không cho hai lượt cùng task cùng ngày,
    // nên cũng không dùng lại ngày đã có lượt ở trên.
    await instance('2026-08-18', done: false);
    await instance('2026-08-19', done: false);
    await service.recalculate(memberId: childId, today: today);

    final streak = await memberDao.getStreak(childId);
    expect(streak?.bestLen, 3, reason: 'kỷ lục là thành tích đã đạt');
    expect(
      streak?.currentLen,
      lessThan(3),
      reason: 'chuỗi hiện tại thì có thể tụt',
    );
  });

  test('tính lại nhiều lần cho cùng kết quả', () async {
    // Tính lại từ đầu mỗi lần chứ không cộng dồn, nên gọi hai lần không được
    // ra hai số khác nhau.
    await instance('2026-08-18', done: true);
    await instance('2026-08-19', done: true);

    final first = await service.recalculate(memberId: childId, today: today);
    final second = await service.recalculate(memberId: childId, today: today);

    expect(second.current, first.current);
  });

  test('ngày không có việc nào không làm đứt chuỗi', () async {
    // ADR-013: Chủ nhật không giao việc thì không phải lỗi của đứa trẻ.
    await instance('2026-08-17', done: true);
    // 18 không có lượt nào.
    await instance('2026-08-19', done: true);

    final result = await service.recalculate(memberId: childId, today: today);

    expect(result.current, 2);
  });
}
