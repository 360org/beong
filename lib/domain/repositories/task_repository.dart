// Tầng repository — xem `README.md` cùng thư mục để biết vì sao có tầng này và
// vì sao mặt cắt của nó chỉ bằng thứ `lib/features` thật sự dùng.

import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/domain/services/family_clock.dart';

// Kiểu dữ liệu tầng UI nhận về từ các phương thức dưới đây. Xuất lại từ đây để
// `lib/features` chỉ import một chỗ, và để ràng buộc "features không import
// lib/data" giữ được (`test/unit/kien_truc_test.dart`).
export 'package:beong/data/local/database.dart'
    show Routine, RoutinesCompanion, Task, TaskInstance, TasksCompanion;

/// Việc nhà, thói quen, và lượt việc theo ngày.
abstract interface class TaskRepository {
  Future<List<Routine>> activeRoutines(String familyId);
  Future<List<Task>> activeTasks(String familyId);
  Future<void> archiveRoutine(String routineId);
  Future<void> createRoutine({
    required RoutinesCompanion routine,
    required List<String> assigneeIds,
    required List<TasksCompanion> routineTasks,
  });
  Future<void> createTask(TasksCompanion task, List<String> assigneeIds);
  Future<List<String>> routineAssigneesOf(String routineId);
  Future<void> setRoutineAssignees({
    required String routineId,
    required List<String> memberIds,
  });
  Future<void> detachTaskFromRoutine(String taskId);
  Future<int> generateInstances({
    required String familyId,
    required CalendarDate today,
  });
  Future<TaskInstance?> getInstanceById(String instanceId);
  Future<Task> getTaskById(String taskId);
  Future<List<TaskInstance>> pendingReview(String familyId);
  Future<void> updateRoutine({
    required String routineId,
    String? title,
    String? iconKey,
    int? completionBonus,
    String? repeatType,
    String? repeatDays,
  });
  Stream<List<Task>> watchActiveTasks(String familyId);
  Stream<List<TaskInstance>> watchApprovedForMember({
    required String memberId,
    required CalendarDate date,
  });
  Stream<List<TaskInstance>> watchInstancesForMember({
    required String memberId,
    required CalendarDate date,
  });
  Future<void> attachTaskToRoutine({
    required String taskId,
    required String routineId,
  });
  Future<void> reorderRoutineTasks({
    required String routineId,
    required List<String> taskIds,
  });
  Stream<List<Routine>> watchActiveRoutines(String familyId);
  Stream<TaskInstance?> watchInstance(String instanceId);
}

/// Bản chạy trên máy: đọc ghi thẳng SQLite qua [TaskDao].
///
/// Sprint 3 sẽ có bản thứ hai đứng cạnh bản này, và **chỉ chỗ đó** phải quyết
/// định đọc local hay đọc máy chủ. Tầng UI không đổi một dòng nào.
final class LocalTaskRepository implements TaskRepository {
  const LocalTaskRepository(this._dao);

  final TaskDao _dao;

  @override
  Future<List<Routine>> activeRoutines(String familyId) =>
      _dao.activeRoutines(familyId);

  @override
  Future<List<Task>> activeTasks(String familyId) => _dao.activeTasks(familyId);

  @override
  Future<void> archiveRoutine(String routineId) =>
      _dao.archiveRoutine(routineId);

  @override
  Future<void> createRoutine({
    required RoutinesCompanion routine,
    required List<String> assigneeIds,
    required List<TasksCompanion> routineTasks,
  }) => _dao.createRoutine(
    routine: routine,
    assigneeIds: assigneeIds,
    routineTasks: routineTasks,
  );

  @override
  Future<void> createTask(TasksCompanion task, List<String> assigneeIds) =>
      _dao.createTask(task, assigneeIds);

  @override
  Future<List<String>> routineAssigneesOf(String routineId) =>
      _dao.routineAssigneesOf(routineId);

  @override
  Future<void> setRoutineAssignees({
    required String routineId,
    required List<String> memberIds,
  }) => _dao.setRoutineAssignees(routineId: routineId, memberIds: memberIds);

  @override
  Future<void> detachTaskFromRoutine(String taskId) =>
      _dao.detachTaskFromRoutine(taskId);

  @override
  Future<int> generateInstances({
    required String familyId,
    required CalendarDate today,
  }) => _dao.generateInstances(familyId: familyId, today: today);

  @override
  Future<TaskInstance?> getInstanceById(String instanceId) =>
      _dao.getInstanceById(instanceId);

  @override
  Future<Task> getTaskById(String taskId) => _dao.getTaskById(taskId);

  @override
  Future<List<TaskInstance>> pendingReview(String familyId) =>
      _dao.pendingReview(familyId);

  @override
  Future<void> updateRoutine({
    required String routineId,
    String? title,
    String? iconKey,
    int? completionBonus,
    String? repeatType,
    String? repeatDays,
  }) => _dao.updateRoutine(
    routineId: routineId,
    title: title,
    iconKey: iconKey,
    completionBonus: completionBonus,
    repeatType: repeatType,
    repeatDays: repeatDays,
  );

  @override
  Stream<List<Task>> watchActiveTasks(String familyId) =>
      _dao.watchActiveTasks(familyId);

  @override
  Stream<List<TaskInstance>> watchApprovedForMember({
    required String memberId,
    required CalendarDate date,
  }) => _dao.watchApprovedForMember(memberId: memberId, date: date);

  @override
  Stream<List<TaskInstance>> watchInstancesForMember({
    required String memberId,
    required CalendarDate date,
  }) => _dao.watchInstancesForMember(memberId: memberId, date: date);

  @override
  Future<void> attachTaskToRoutine({
    required String taskId,
    required String routineId,
  }) => _dao.attachTaskToRoutine(taskId: taskId, routineId: routineId);

  @override
  Future<void> reorderRoutineTasks({
    required String routineId,
    required List<String> taskIds,
  }) => _dao.reorderRoutineTasks(routineId: routineId, taskIds: taskIds);

  @override
  Stream<List<Routine>> watchActiveRoutines(String familyId) =>
      _dao.watchActiveRoutines(familyId);

  @override
  Stream<TaskInstance?> watchInstance(String instanceId) =>
      _dao.watchInstance(instanceId);
}
