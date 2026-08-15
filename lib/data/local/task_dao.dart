import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/tables/tables.dart';
import 'package:beong/data/seed/presets.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:beong/domain/services/schedule.dart';
import 'package:drift/drift.dart';

part 'task_dao.g.dart';

@DriftAccessor(
  tables: [
    Tasks,
    TaskAssignees,
    TaskInstances,
    Routines,
    RoutineAssignees,
    PointTransactions,
  ],
)
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.attachedDatabase);

  Future<Task> getTaskById(String taskId) {
    return (select(tasks)..where((t) => t.id.equals(taskId))).getSingle();
  }

  /// Tất cả task active của một gia đình, gồm cả task thuộc routine.
  Future<List<Task>> activeTasks(String familyId) {
    return (select(tasks)..where(
          (t) =>
              t.familyId.equals(familyId) &
              t.active.equals(true) &
              t.deletedAt.isNull(),
        ))
        .get();
  }

  /// Tất cả routine active của một gia đình.
  Future<List<Routine>> activeRoutines(String familyId) {
    return (select(routines)..where(
          (r) =>
              r.familyId.equals(familyId) &
              r.active.equals(true) &
              r.deletedAt.isNull(),
        ))
        .get();
  }

  /// Gán icon cho những việc còn thiếu icon.
  ///
  /// Sheet thêm việc trước đây không có ô chọn hình, nên mọi việc bố mẹ tự tạo
  /// đều có `icon_key = NULL` và hiện ⭐ — giống hệt nhau, mất tác dụng của hình
  /// (trẻ đọc hình trước khi đọc chữ). Việc mới thì không còn đường nào tạo ra
  /// thiếu icon, nhưng dữ liệu cũ vẫn còn.
  ///
  /// Lấy icon của preset nếu việc đó sinh từ template; không thì dùng ✏️ — hình
  /// trung tính đọc ra "có việc cần làm", thay vì ⭐ vốn là dấu hiệu **thiếu**
  /// icon chứ không phải một lựa chọn.
  ///
  /// Trả về số việc đã sửa.
  Future<int> backfillMissingIcons(String familyId) async {
    final rows =
        await (select(tasks)..where(
              (t) =>
                  t.familyId.equals(familyId) &
                  (t.iconKey.isNull() | t.iconKey.equals('')),
            ))
            .get();
    if (rows.isEmpty) return 0;

    await batch((b) {
      for (final row in rows) {
        final fromPreset = row.presetKey == null
            ? null
            : presetByKey(row.presetKey!)?.iconKey;
        b.update(
          tasks,
          TasksCompanion(iconKey: Value(fromPreset ?? kDefaultTaskIconKey)),
          where: (t) => t.id.equals(row.id),
        );
      }
    });
    return rows.length;
  }

  /// Như [activeTasks] nhưng phát lại mỗi khi bảng đổi.
  ///
  /// Màn Nhiệm vụ trước đây nạp một lần trong `initState`, nên việc vừa tạo từ
  /// sheet "+" **không hiện ra**: sheet đóng lại mà không có ai bảo danh sách nạp
  /// lại, và đổi tab cũng không giúp vì mỗi tab giữ state riêng
  /// (`StatefulShellRoute`). Bố mẹ thấy việc mình vừa tạo biến mất, trong khi nó
  /// nằm đúng trong DB.
  Stream<List<Task>> watchActiveTasks(String familyId) {
    return (select(tasks)..where(
          (t) =>
              t.familyId.equals(familyId) &
              t.active.equals(true) &
              t.deletedAt.isNull(),
        ))
        .watch();
  }

  /// Như [activeRoutines] nhưng phát lại mỗi khi bảng đổi.
  Stream<List<Routine>> watchActiveRoutines(String familyId) {
    return (select(routines)..where(
          (r) =>
              r.familyId.equals(familyId) &
              r.active.equals(true) &
              r.deletedAt.isNull(),
        ))
        .watch();
  }

  /// Danh sách người được giao cho một task lẻ.
  Future<List<String>> assigneesOf(String taskId) async {
    final rows = await (select(
      taskAssignees,
    )..where((a) => a.taskId.equals(taskId))).get();
    return rows.map((r) => r.memberId).toList();
  }

  /// Danh sách người được giao cho một routine.
  Future<List<String>> routineAssigneesOf(String routineId) async {
    final rows = await (select(
      routineAssignees,
    )..where((a) => a.routineId.equals(routineId))).get();
    return rows.map((r) => r.memberId).toList();
  }

  /// Dựng [SchedulableTask] cho toàn bộ task active của gia đình.
  Future<List<SchedulableTask>> schedulableTasks(String familyId) async {
    final allTasks = await activeTasks(familyId);
    final routineCache = <String, Routine>{};
    final routineAssigneeCache = <String, List<String>>{};
    final result = <SchedulableTask>[];

    for (final t in allTasks) {
      Schedule schedule;
      List<String> assignees;

      if (t.routineId != null) {
        final routine = routineCache[t.routineId!] ??= await (select(
          routines,
        )..where((r) => r.id.equals(t.routineId!))).getSingle();
        if (!routine.active || routine.deletedAt != null) continue;

        schedule = _routineSchedule(routine);
        assignees = routineAssigneeCache[t.routineId!] ??=
            await routineAssigneesOf(t.routineId!);
      } else {
        schedule = _taskSchedule(t);
        assignees = await assigneesOf(t.id);
      }

      result.add(
        SchedulableTask(
          taskId: t.id,
          schedule: schedule,
          assigneeIds: assignees,
          points: t.points,
        ),
      );
    }

    return result;
  }

  /// Sinh instance cho 7 ngày tới và đánh dấu missed cho quá hạn.
  Future<int> generateInstances({
    required String familyId,
    required CalendarDate today,
  }) async {
    final stasks = await schedulableTasks(familyId);
    final planned = planInstances(tasks: stasks, from: today);
    var written = 0;

    for (final p in planned) {
      final id = '${p.taskId}:${p.memberId}:${p.dueDate}';
      final existing =
          await (selectOnly(taskInstances)
                ..addColumns([taskInstances.id])
                ..where(taskInstances.id.equals(id))
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) continue;

      await into(taskInstances).insert(
        TaskInstancesCompanion.insert(
          id: id,
          familyId: familyId,
          taskId: p.taskId,
          memberId: p.memberId,
          dueDate: p.dueDate.toString(),
          pointsSnapshot: p.pointsSnapshot,
        ),
        mode: InsertMode.insertOrIgnore,
      );
      written++;
    }

    await _markMissed(familyId, today);
    return written;
  }

  /// Instance hôm nay của một trẻ, sắp theo routine rồi task lẻ.
  Future<List<TaskInstance>> instancesForMember({
    required String memberId,
    required CalendarDate date,
  }) {
    return (select(taskInstances)
          ..where(
            (i) =>
                i.memberId.equals(memberId) & i.dueDate.equals(date.toString()),
          )
          ..orderBy([(i) => OrderingTerm.asc(i.createdAt)]))
        .get();
  }

  /// Stream instance hôm nay của một trẻ.
  Stream<List<TaskInstance>> watchInstancesForMember({
    required String memberId,
    required CalendarDate date,
  }) {
    return (select(taskInstances)
          ..where(
            (i) =>
                i.memberId.equals(memberId) & i.dueDate.equals(date.toString()),
          )
          ..orderBy([(i) => OrderingTerm.asc(i.createdAt)]))
        .watch();
  }

  Future<TaskInstance?> getInstanceById(String instanceId) {
    return (select(
      taskInstances,
    )..where((i) => i.id.equals(instanceId))).getSingleOrNull();
  }

  /// Theo dõi một lượt việc. Dùng cho chỗ cần trạng thái **sống**, ví dụ dòng
  /// lịch sử trong Sổ của con: bố mẹ duyệt hay mở lại không ghi dòng sổ cái nào,
  /// nên nếu chỉ tra một lần thì trạng thái hiển thị sẽ đứng lại.
  Stream<TaskInstance?> watchInstance(String instanceId) {
    return (select(
      taskInstances,
    )..where((i) => i.id.equals(instanceId))).watchSingleOrNull();
  }

  /// Con bấm xong, việc vào hàng đợi duyệt.
  ///
  /// **Quyết định auto/manual không nằm ở đây** mà ở `TaskReviewService`: nó
  /// phụ thuộc cấu hình gia đình lẫn cấu hình task, và cộng xu là việc của ví.
  Future<void> markPendingReview(String instanceId) async {
    await (update(taskInstances)..where((i) => i.id.equals(instanceId))).write(
      TaskInstancesCompanion(
        status: Value(InstanceStatus.pendingReview.name),
        completedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Chốt việc là đã xong. [reviewerId] để `null` khi không ai duyệt (nhà tắt
  /// tính năng duyệt) — cột `reviewed_by` trống nói đúng điều đã xảy ra.
  Future<void> markApproved({
    required String instanceId,
    required String? reviewerId,
  }) async {
    final now = DateTime.now();
    final instance = await getInstanceById(instanceId);

    await (update(taskInstances)..where((i) => i.id.equals(instanceId))).write(
      TaskInstancesCompanion(
        status: Value(InstanceStatus.approved.name),
        // Giữ mốc con bấm xong nếu đã có: đó là lúc việc thật sự được làm, khác
        // với lúc bố mẹ mở app ra duyệt.
        completedAt: Value(instance?.completedAt ?? now),
        reviewedAt: Value(now),
        reviewedBy: Value(reviewerId),
      ),
    );
  }

  /// Bố mẹ duyệt instance.
  Future<void> approve({
    required String instanceId,
    required String reviewerId,
  }) async {
    await (update(taskInstances)..where((i) => i.id.equals(instanceId))).write(
      TaskInstancesCompanion(
        status: Value(InstanceStatus.approved.name),
        reviewedAt: Value(DateTime.now()),
        reviewedBy: Value(reviewerId),
      ),
    );
  }

  /// Bố mẹ từ chối instance.
  Future<void> reject({
    required String instanceId,
    required String reviewerId,
  }) async {
    await (update(taskInstances)..where((i) => i.id.equals(instanceId))).write(
      TaskInstancesCompanion(
        status: Value(InstanceStatus.rejected.name),
        reviewedAt: Value(DateTime.now()),
        reviewedBy: Value(reviewerId),
      ),
    );
  }

  /// Kiểm tra và cộng bonus trọn bộ routine — ADR-011.
  ///
  /// Gọi sau mỗi lần approve. Trả về true nếu đã cộng bonus.
  Future<bool> checkAndAwardRoutineBonus({
    required String instanceId,
    required String familyId,
  }) async {
    final instance = await (select(
      taskInstances,
    )..where((i) => i.id.equals(instanceId))).getSingle();

    final task = await (select(
      tasks,
    )..where((t) => t.id.equals(instance.taskId))).getSingle();
    if (task.routineId == null) return false;

    final routine = await (select(
      routines,
    )..where((r) => r.id.equals(task.routineId!))).getSingle();
    if (routine.completionBonus <= 0) return false;

    final routineTasks =
        await (select(tasks)..where(
              (t) =>
                  t.routineId.equals(task.routineId!) &
                  t.active.equals(true) &
                  t.deletedAt.isNull(),
            ))
            .get();
    final routineTaskIds = routineTasks.map((t) => t.id).toSet();

    final dayInstances =
        await (select(taskInstances)..where(
              (i) =>
                  i.memberId.equals(instance.memberId) &
                  i.dueDate.equals(instance.dueDate),
            ))
            .get();

    final relevant = dayInstances.where(
      (i) => routineTaskIds.contains(i.taskId),
    );
    final allApproved =
        relevant.isNotEmpty &&
        relevant.every((i) => i.status == InstanceStatus.approved.name);

    if (!allApproved) return false;

    // UUID v5-style deterministic ID for idempotency.
    final bonusOpId =
        'routine-bonus:${task.routineId}:${instance.memberId}:${instance.dueDate}';

    final existing =
        await (selectOnly(pointTransactions)
              ..addColumns([pointTransactions.id])
              ..where(pointTransactions.clientOpId.equals(bonusOpId))
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) return false;

    await into(pointTransactions).insert(
      PointTransactionsCompanion.insert(
        id: bonusOpId,
        familyId: familyId,
        memberId: instance.memberId,
        jar: Jar.spend.name,
        delta: routine.completionBonus,
        reason: TxReason.routineBonus.name,
        clientOpId: bonusOpId,
        refType: const Value('routine'),
        refId: Value(task.routineId),
        note: Value('Trọn bộ ${routine.title}'),
      ),
      mode: InsertMode.insertOrIgnore,
    );
    return true;
  }

  /// Tạo task mới.
  Future<void> createTask(TasksCompanion task, List<String> assigneeIds) {
    return transaction(() async {
      await into(tasks).insert(task);
      for (final memberId in assigneeIds) {
        await into(taskAssignees).insert(
          TaskAssigneesCompanion.insert(
            taskId: task.id.value,
            memberId: memberId,
          ),
        );
      }
    });
  }

  /// Tạo routine mới kèm tasks.
  Future<void> createRoutine({
    required RoutinesCompanion routine,
    required List<String> assigneeIds,
    required List<TasksCompanion> routineTasks,
  }) {
    return transaction(() async {
      await into(routines).insert(routine);
      for (final memberId in assigneeIds) {
        await into(routineAssignees).insert(
          RoutineAssigneesCompanion.insert(
            routineId: routine.id.value,
            memberId: memberId,
          ),
        );
      }
      for (final task in routineTasks) {
        await into(tasks).insert(task);
      }
    });
  }

  /// Sửa thông tin của một routine.
  Future<void> updateRoutine({
    required String routineId,
    String? title,
    String? iconKey,
    int? completionBonus,
    String? repeatType,
    String? repeatDays,
  }) {
    return (update(routines)..where((r) => r.id.equals(routineId))).write(
      RoutinesCompanion(
        title: title == null ? const Value.absent() : Value(title.trim()),
        iconKey: iconKey == null ? const Value.absent() : Value(iconKey),
        completionBonus: completionBonus == null
            ? const Value.absent()
            : Value(completionBonus),
        repeatType: repeatType == null
            ? const Value.absent()
            : Value(repeatType),
        repeatDays: repeatDays == null
            ? const Value.absent()
            : Value(repeatDays),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Ghi lại thứ tự việc trong routine theo danh sách id truyền vào.
  ///
  /// Thứ tự là **nội dung** của routine chứ không phải chuyện hiển thị: "Buổi
  /// sáng" mà đánh răng trước khi ăn sáng là sai quy trình, và trẻ nhỏ làm theo
  /// đúng thứ tự nhìn thấy.
  Future<void> reorderRoutineTasks({
    required String routineId,
    required List<String> taskIds,
  }) {
    return batch((b) {
      for (var i = 0; i < taskIds.length; i++) {
        b.update(
          tasks,
          TasksCompanion(
            orderIndex: Value(i),
            updatedAt: Value(DateTime.now()),
          ),
          where: (t) => t.id.equals(taskIds[i]) & t.routineId.equals(routineId),
        );
      }
    });
  }

  /// Bỏ một việc ra khỏi routine — việc vẫn còn, chỉ thành việc lẻ.
  ///
  /// Không xoá hẳn: lượt đã sinh và các dòng sổ cái vẫn trỏ tới `task_id` này
  /// (ADR-005 append-only). Xoá đi thì "Sổ của con" mất tên việc.
  Future<void> detachTaskFromRoutine(String taskId) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        routineId: const Value(null),
        orderIndex: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Đưa một việc lẻ vào cuối một routine.
  Future<void> attachTaskToRoutine({
    required String taskId,
    required String routineId,
  }) async {
    final existing = await (select(
      tasks,
    )..where((t) => t.routineId.equals(routineId))).get();
    final nextOrder = existing.fold(
      0,
      (max, t) => (t.orderIndex ?? 0) >= max ? (t.orderIndex ?? 0) + 1 : max,
    );
    await (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        routineId: Value(routineId),
        orderIndex: Value(nextOrder),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Ngừng dùng một routine. Việc bên trong tách ra thành việc lẻ, không mất.
  Future<void> archiveRoutine(String routineId) {
    return transaction(() async {
      final inside = await (select(
        tasks,
      )..where((t) => t.routineId.equals(routineId))).get();
      for (final task in inside) {
        await detachTaskFromRoutine(task.id);
      }
      await (update(routines)..where((r) => r.id.equals(routineId))).write(
        RoutinesCompanion(
          active: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Mọi lượt việc của một trẻ từ ngày [from] trở đi — dùng để tính lại streak.
  Future<List<TaskInstance>> instancesForMemberSince({
    required String memberId,
    required CalendarDate from,
  }) {
    return (select(taskInstances)
          ..where(
            (i) =>
                i.memberId.equals(memberId) &
                i.dueDate.isBiggerOrEqualValue(from.toString()),
          )
          ..orderBy([(i) => OrderingTerm.desc(i.dueDate)]))
        .get();
  }

  /// Instance đang chờ duyệt của một gia đình.
  Future<List<TaskInstance>> pendingReview(String familyId) {
    return (select(taskInstances)
          ..where(
            (i) =>
                i.familyId.equals(familyId) &
                i.status.equals(InstanceStatus.pendingReview.name),
          )
          ..orderBy([(i) => OrderingTerm.asc(i.completedAt)]))
        .get();
  }

  /// Bố mẹ **mở lại** một lượt việc — ADR-022.
  ///
  /// Dùng khi con bấm xong nhưng thực tế chưa làm. Lượt về lại `scheduled` để
  /// con làm lại, và `reopenCount` tăng một.
  ///
  /// Xu đã cộng (nếu việc đã được duyệt trước đó) **không** bị thu hồi ở đây.
  /// Khi con làm lại và được duyệt, `clientOpId` của khoản cộng vẫn là cũ nên
  /// không cộng thêm lần hai — tức việc này cuối cùng vẫn chỉ đáng đúng số xu
  /// của nó, cộng thêm một khoản trừ cho lần phải làm lại. Thu hồi xu *và* trừ
  /// phạt là trừ hai lần cho một lỗi.
  ///
  /// Trả về lượt sau khi cập nhật, để bên gọi biết `reopenCount` mới mà tính
  /// khoản trừ.
  Future<TaskInstance> reopen({
    required String instanceId,
    required String reviewerId,
  }) async {
    return transaction(() async {
      final instance = await (select(
        taskInstances,
      )..where((i) => i.id.equals(instanceId))).getSingle();

      await (update(
        taskInstances,
      )..where((i) => i.id.equals(instanceId))).write(
        TaskInstancesCompanion(
          status: Value(InstanceStatus.scheduled.name),
          reopenCount: Value(instance.reopenCount + 1),
          reviewedBy: Value(reviewerId),
          reviewedAt: Value(DateTime.now()),
          completedAt: const Value(null),
        ),
      );

      return (select(
        taskInstances,
      )..where((i) => i.id.equals(instanceId))).getSingle();
    });
  }

  /// Những lượt đã bỏ mà **chưa** bị áp khoản trừ — ADR-022.
  ///
  /// Có cột `missedPenaltyAt` nên chỉ quét phần chưa xử lý, thay vì quét lại cả
  /// lịch sử mỗi lần mở app.
  Future<List<TaskInstance>> pendingMissedPenalties(String familyId) {
    return (select(taskInstances)
          ..where(
            (i) =>
                i.familyId.equals(familyId) &
                i.status.equals(InstanceStatus.missed.name) &
                i.missedPenaltyAt.isNull(),
          )
          ..orderBy([(i) => OrderingTerm.asc(i.dueDate)]))
        .get();
  }

  /// Ghi nhận đã xử lý khoản trừ "bỏ việc" cho lượt này.
  ///
  /// Gọi cả khi khoản trừ ra 0 xu (mức 0%, hoặc con đang hết xu) — nếu không,
  /// lượt đó sẽ bị quét lại mãi mãi.
  Future<void> markMissedPenaltyApplied(String instanceId) async {
    await (update(taskInstances)..where((i) => i.id.equals(instanceId))).write(
      TaskInstancesCompanion(missedPenaltyAt: Value(DateTime.now())),
    );
  }

  /// Việc **đã xong** hôm nay của một trẻ, để bố mẹ mở lại nếu thấy chưa làm
  /// thật — ADR-023.
  ///
  /// Cần khi nhà tắt tính năng duyệt: lúc đó không có hàng đợi nào, nên nếu
  /// không có danh sách này thì bố mẹ không còn đường nào để mở lại việc.
  Stream<List<TaskInstance>> watchApprovedForMember({
    required String memberId,
    required CalendarDate date,
  }) {
    return (select(taskInstances)
          ..where(
            (i) =>
                i.memberId.equals(memberId) &
                i.dueDate.equals(date.toString()) &
                i.status.equals(InstanceStatus.approved.name),
          )
          ..orderBy([(i) => OrderingTerm.desc(i.completedAt)]))
        .watch();
  }

  /// Đánh dấu missed cho instance quá hạn.
  Future<void> _markMissed(String familyId, CalendarDate today) async {
    final todayStr = today.toString();
    await (update(taskInstances)..where(
          (i) =>
              i.familyId.equals(familyId) &
              i.status.equals(InstanceStatus.scheduled.name) &
              i.dueDate.isSmallerThanValue(todayStr),
        ))
        .write(
          const TaskInstancesCompanion(
            status: Value('missed'),
          ),
        );
  }

  Schedule _taskSchedule(Task t) {
    final type = RepeatType.values.firstWhere((e) => e.name == t.repeatType);
    return switch (type) {
      RepeatType.daily => const Schedule.daily(),
      RepeatType.custom => Schedule.custom(
        t.repeatDays
            .split(',')
            .where((s) => s.isNotEmpty)
            .map(int.parse)
            .toSet(),
      ),
      RepeatType.once => Schedule.once(
        CalendarDate.parse(t.onceDate ?? '2000-01-01'),
      ),
    };
  }

  Schedule _routineSchedule(Routine r) {
    final type = RepeatType.values.firstWhere((e) => e.name == r.repeatType);
    return switch (type) {
      RepeatType.daily => const Schedule.daily(),
      RepeatType.custom => Schedule.custom(
        r.repeatDays
            .split(',')
            .where((s) => s.isNotEmpty)
            .map(int.parse)
            .toSet(),
      ),
      RepeatType.once => const Schedule.daily(),
    };
  }
}
