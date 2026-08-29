import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gán buổi thói quen cho từng bé.
///
/// Chủ dự án chốt 26/08/2026: *"thói quen là chung, nhưng session được tạo ra
/// như sáng/trưa/tối => thêm option chọn profile... gán cho profile nào thì
/// profile đó hiển thị."* Nên quan hệ là **nhiều–nhiều**: một buổi gán được cho
/// nhiều bé, một bé có nhiều buổi.
///
/// Ràng buộc quan trọng nhất và dễ quên nhất: buổi **không gán cho ai** thì mọi
/// việc trong đó không sinh lượt cho bất kỳ bé nào (`schedule.dart:148` bỏ qua
/// khi `assigneeIds` rỗng). Đó là lý do bảng tạo buổi chặn nút lưu khi chưa
/// chọn bé — test cuối cùng ở đây canh đúng hệ quả ấy.
void main() {
  late AppDatabase db;
  late TaskDao taskDao;
  late MemberDao memberDao;

  const familyId = 'fam-1';
  const neo = 'con-neo';
  const simba = 'con-simba';
  const routineId = 'routine-sang';

  Future<void> themBe(String id, String ten) => memberDao.addMember(
    MembersCompanion.insert(
      id: id,
      familyId: familyId,
      kind: MemberKind.child.name,
      displayName: ten,
    ),
  );

  setUp(() async {
    db = AppDatabase.memory();
    taskDao = TaskDao(db);
    memberDao = MemberDao(db);

    await memberDao.createFamily(
      FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'),
    );
    await themBe(neo, 'Neo');
    await themBe(simba, 'Simba');

    await taskDao.createRoutine(
      routine: RoutinesCompanion.insert(
        id: routineId,
        familyId: familyId,
        title: 'Buổi sáng',
      ),
      assigneeIds: [neo],
      routineTasks: [
        TasksCompanion.insert(
          id: 'viec-1',
          familyId: familyId,
          title: 'Đánh răng buổi sáng',
          routineId: const Value(routineId),
          orderIndex: const Value(0),
        ),
      ],
    );
  });

  tearDown(() async => db.close());

  test('tạo buổi thì ghi luôn bé được gán', () async {
    expect(await taskDao.routineAssigneesOf(routineId), [neo]);
  });

  test('gán thêm bé thứ hai — một buổi dùng chung cho nhiều bé', () async {
    await taskDao.setRoutineAssignees(
      routineId: routineId,
      memberIds: [neo, simba],
    );
    final ids = await taskDao.routineAssigneesOf(routineId);
    expect(ids, unorderedEquals([neo, simba]));
  });

  test(
    'bỏ chọn một bé thì bé đó rời khỏi buổi thật, không chỉ ẩn đi',
    () async {
      await taskDao.setRoutineAssignees(
        routineId: routineId,
        memberIds: [neo, simba],
      );
      await taskDao.setRoutineAssignees(
        routineId: routineId,
        memberIds: [simba],
      );
      expect(await taskDao.routineAssigneesOf(routineId), [simba]);
    },
  );

  test('gán lại hai lần không nhân đôi bản ghi', () async {
    await taskDao.setRoutineAssignees(routineId: routineId, memberIds: [neo]);
    await taskDao.setRoutineAssignees(routineId: routineId, memberIds: [neo]);
    expect(await taskDao.routineAssigneesOf(routineId), [neo]);
  });

  group('việc trong buổi chỉ sinh lượt cho bé được gán', () {
    const today = CalendarDate(2026, 8, 26);

    Future<Set<String>> beCoViec() async {
      await taskDao.generateInstances(familyId: familyId, today: today);
      final rows = await db.select(db.taskInstances).get();
      return rows.map((r) => r.memberId).toSet();
    }

    test('gán cho Neo thì chỉ Neo có việc', () async {
      expect(await beCoViec(), {neo});
    });

    test('gán cho cả hai thì cả hai đều có việc', () async {
      await taskDao.setRoutineAssignees(
        routineId: routineId,
        memberIds: [neo, simba],
      );
      expect(await beCoViec(), {neo, simba});
    });

    test('buổi không gán cho ai thì KHÔNG bé nào có việc', () async {
      // Đây là lý do bảng tạo buổi chặn nút lưu khi chưa chọn bé: một buổi
      // trống người nhận trông vẫn bình thường trên màn quản lý, mà không đứa
      // trẻ nào nhìn thấy việc trong đó.
      await taskDao.setRoutineAssignees(routineId: routineId, memberIds: []);
      expect(await beCoViec(), isEmpty);
    });
  });
}
