import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/domain/entities/enums.dart';
// `isNull` có ở cả drift lẫn matcher; test này cần bản của matcher.
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

/// Sửa routine: đổi tên, đổi thứ tự việc, thêm/bỏ việc, ngừng dùng.
///
/// Ràng buộc xuyên suốt: **không xoá task**. Lượt việc đã sinh và các dòng sổ cái
/// đều trỏ tới `task_id` (ADR-005 append-only), nên xoá task đi là "Sổ của con"
/// mất tên việc — con nhìn lại chỉ thấy một dòng cộng xu không rõ từ đâu.
void main() {
  late AppDatabase db;
  late TaskDao taskDao;
  late MemberDao memberDao;

  const familyId = 'fam-1';
  const childId = 'con-1';
  const routineId = 'routine-sang';

  Future<void> addRoutineTask(String id, int order) => db
      .into(db.tasks)
      .insert(
        TasksCompanion.insert(
          id: id,
          familyId: familyId,
          title: 'Việc $id',
          routineId: const Value(routineId),
          orderIndex: Value(order),
        ),
      );

  Future<List<String>> orderedTaskIds() async {
    final rows =
        await (db.select(db.tasks)
              ..where((t) => t.routineId.equals(routineId))
              ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
            .get();
    return rows.map((t) => t.id).toList();
  }

  setUp(() async {
    db = AppDatabase.memory();
    taskDao = TaskDao(db);
    memberDao = MemberDao(db);

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
    await taskDao.createRoutine(
      routine: RoutinesCompanion.insert(
        id: routineId,
        familyId: familyId,
        title: 'Buổi sáng',
      ),
      assigneeIds: [childId],
      routineTasks: [],
    );
    await addRoutineTask('t1', 0);
    await addRoutineTask('t2', 1);
    await addRoutineTask('t3', 2);
  });

  tearDown(() async {
    await db.close();
  });

  group('sửa thông tin routine', () {
    test('đổi tên và xu thưởng trọn bộ', () async {
      await taskDao.updateRoutine(
        routineId: routineId,
        title: '  Buổi sáng vui vẻ  ',
        completionBonus: 25,
      );

      final routine = (await taskDao.activeRoutines(familyId)).single;
      expect(
        routine.title,
        'Buổi sáng vui vẻ',
        reason: 'phải cắt khoảng trắng',
      );
      expect(routine.completionBonus, 25);
    });

    test('không truyền trường nào thì trường đó giữ nguyên', () async {
      await taskDao.updateRoutine(routineId: routineId, title: 'Tên mới');

      final routine = (await taskDao.activeRoutines(familyId)).single;
      expect(routine.completionBonus, 10, reason: 'giá trị mặc định ban đầu');
    });
  });

  group('đổi thứ tự việc trong routine', () {
    test('ghi đúng thứ tự truyền vào', () async {
      await taskDao.reorderRoutineTasks(
        routineId: routineId,
        taskIds: ['t3', 't1', 't2'],
      );

      expect(await orderedTaskIds(), ['t3', 't1', 't2']);
    });

    test('không đụng tới việc của routine khác', () async {
      await taskDao.createRoutine(
        routine: RoutinesCompanion.insert(
          id: 'routine-toi',
          familyId: familyId,
          title: 'Buổi tối',
        ),
        assigneeIds: [childId],
        routineTasks: [],
      );
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'khac',
              familyId: familyId,
              title: 'Việc buổi tối',
              routineId: const Value('routine-toi'),
              orderIndex: const Value(0),
            ),
          );

      // Truyền nhầm id của routine khác vào: câu update có điều kiện
      // `routineId` nên không được đụng tới nó.
      await taskDao.reorderRoutineTasks(
        routineId: routineId,
        taskIds: ['khac', 't1'],
      );

      final other = await taskDao.getTaskById('khac');
      expect(other.orderIndex, 0);
      expect(other.routineId, 'routine-toi');
    });
  });

  group('thêm và bỏ việc', () {
    test('bỏ việc khỏi routine thì việc vẫn còn, thành việc lẻ', () async {
      await taskDao.detachTaskFromRoutine('t2');

      final task = await taskDao.getTaskById('t2');
      expect(task.routineId, isNull);
      expect(task.orderIndex, isNull);
      expect(
        (await taskDao.activeTasks(familyId)).map((t) => t.id),
        contains('t2'),
        reason: 'không được xoá task — sổ cái vẫn trỏ tới nó',
      );
      expect(await orderedTaskIds(), ['t1', 't3']);
    });

    test('đưa việc lẻ vào routine thì nó nằm cuối', () async {
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'le',
              familyId: familyId,
              title: 'Việc lẻ',
            ),
          );

      await taskDao.attachTaskToRoutine(taskId: 'le', routineId: routineId);

      expect(await orderedTaskIds(), ['t1', 't2', 't3', 'le']);
    });
  });

  group('ngừng dùng routine', () {
    test('routine rời danh sách nhưng việc bên trong không mất', () async {
      await taskDao.archiveRoutine(routineId);

      expect(await taskDao.activeRoutines(familyId), isEmpty);

      final remaining = await taskDao.activeTasks(familyId);
      expect(
        remaining.map((t) => t.id),
        containsAll(['t1', 't2', 't3']),
        reason: 'ba việc phải còn, chỉ là không thuộc routine nào nữa',
      );
      expect(remaining.every((t) => t.routineId == null), isTrue);
    });
  });
}
