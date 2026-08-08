import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/tables/tables.dart';
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

  /// Trẻ đánh dấu hoàn thành.
  Future<void> markCompleted(String instanceId) async {
    final instance = await (select(
      taskInstances,
    )..where((i) => i.id.equals(instanceId))).getSingle();

    if (instance.status != InstanceStatus.scheduled.name) return;

    final task = await (select(
      tasks,
    )..where((t) => t.id.equals(instance.taskId))).getSingle();

    final newStatus = task.approvalMode == ApprovalMode.auto.name
        ? InstanceStatus.approved.name
        : InstanceStatus.pendingReview.name;

    await (update(taskInstances)..where((i) => i.id.equals(instanceId))).write(
      TaskInstancesCompanion(
        status: Value(newStatus),
        completedAt: Value(DateTime.now()),
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
