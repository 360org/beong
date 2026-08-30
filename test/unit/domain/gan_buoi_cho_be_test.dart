import 'dart:io';

import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gán một buổi cho thêm một bé thì bé đó phải có việc **ngay hôm nay**.
///
/// Chủ dự án nêu 30/08/2026: *"trong tab tasks đã chọn session cho tất cả rồi
/// nhưng trong profile của bé mới vẫn empty."*
///
/// Gốc không nằm ở việc ghi người nhận — chỗ đó ghi đúng. Nó nằm ở chỗ bộ sinh
/// lượt việc chạy **một lần mỗi ngày** (`DayStartService`, khoá
/// `rollover.last_run_date`). Đổi người nhận giữa ngày thì bé mới không có
/// lượt nào cho tới hôm sau, trong khi màn Nhiệm vụ đã ghi "Tất cả". Hai màn
/// nói ngược nhau và bố mẹ không có cách nào biết ai đúng.
void main() {
  late AppDatabase db;
  late TaskDao taskDao;
  late MemberDao memberDao;

  const familyId = 'fam-1';
  const neo = 'con-neo';
  const beMoi = 'con-moi';
  const routineId = 'buoi-sang';
  const today = CalendarDate(2026, 8, 30);

  Future<List<TaskInstance>> luotCua(String memberId) =>
      taskDao.instancesForMember(memberId: memberId, date: today);

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
    await themBe(neo, 'NEO');

    await taskDao.createRoutine(
      routine: RoutinesCompanion.insert(
        id: routineId,
        familyId: familyId,
        title: 'Buổi sáng',
        repeatType: Value(RepeatType.daily.name),
      ),
      assigneeIds: const [neo],
      routineTasks: [
        TasksCompanion.insert(
          id: 'viec-1',
          familyId: familyId,
          title: 'Đánh răng',
          routineId: const Value(routineId),
          repeatType: Value(RepeatType.daily.name),
          points: const Value(10),
        ),
        TasksCompanion.insert(
          id: 'viec-2',
          familyId: familyId,
          title: 'Gấp chăn',
          routineId: const Value(routineId),
          repeatType: Value(RepeatType.daily.name),
          points: const Value(10),
        ),
      ],
    );
    await taskDao.generateInstances(familyId: familyId, today: today);
  });

  tearDown(() async => db.close());

  test('bé đang có trong buổi thì có đủ việc của buổi', () async {
    expect((await luotCua(neo)).length, 2);
  });

  test('bé mới thêm vào nhà, chưa gán buổi nào, thì chưa có việc', () async {
    await themBe(beMoi, 'Thêm Bé');
    expect(await luotCua(beMoi), isEmpty);
  });

  test('gán buổi cho bé mới thì bé nhận **toàn bộ** việc của buổi', () async {
    await themBe(beMoi, 'Thêm Bé');

    await taskDao.setRoutineAssignees(
      routineId: routineId,
      memberIds: const [neo, beMoi],
    );
    await taskDao.generateInstances(familyId: familyId, today: today);

    final cuaBeMoi = await luotCua(beMoi);
    expect(
      cuaBeMoi.map((i) => i.taskId).toSet(),
      {'viec-1', 'viec-2'},
      reason:
          'chủ dự án nêu rõ: gán buổi cho một bé nghĩa là **toàn bộ** việc '
          'trong buổi đó thuộc về bé, không phải chọn lại từng việc',
    );
  });

  test('bé cũ không bị đụng tới, không sinh thêm lượt trùng', () async {
    await themBe(beMoi, 'Thêm Bé');
    await taskDao.setRoutineAssignees(
      routineId: routineId,
      memberIds: const [neo, beMoi],
    );
    await taskDao.generateInstances(familyId: familyId, today: today);
    // Gọi lại lần nữa: giao diện gọi sau mỗi lần lưu, gọi thừa phải vô hại.
    await taskDao.generateInstances(familyId: familyId, today: today);

    expect((await luotCua(neo)).length, 2);
    expect((await luotCua(beMoi)).length, 2);
  });

  _canhGoiSinhLuot();

  test('bỏ một bé khỏi buổi thì lượt đã sinh của bé đó vẫn còn', () async {
    await taskDao.setRoutineAssignees(
      routineId: routineId,
      memberIds: const [],
    );
    await taskDao.generateInstances(familyId: familyId, today: today);

    expect(
      (await luotCua(neo)).length,
      2,
      reason:
          'ADR-005 sổ chỉ ghi thêm: xoá lượt đã sinh là xoá cả xu con đã kiếm '
          'từ chúng nếu việc đã xong',
    );
  });
}

/// Canh chỗ **thật sự** hỏng.
///
/// Các test ở trên chạy qua DAO, và DAO chưa bao giờ sai: nó ghi người nhận
/// đúng, sinh lượt đúng. Cái sai là màn "Sửa thói quen" ghi người nhận xong
/// rồi **không gọi sinh lượt**, nên phải chờ tới ngày hôm sau. Không test nào
/// ở tầng DAO bắt được khoảng đó — nó nằm giữa hai lời gọi đúng.
void _canhGoiSinhLuot() {
  test('màn nào đổi người nhận của buổi cũng phải sinh lượt ngay', () {
    final thieu = <String>[];

    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final noiDung = entity.readAsStringSync();
      if (!noiDung.contains('setRoutineAssignees(')) continue;
      if (noiDung.contains('generateInstances(')) continue;
      thieu.add(entity.path);
    }

    expect(
      thieu,
      isEmpty,
      reason:
          'file đổi người nhận của buổi mà không sinh lượt: bé mới sẽ thấy hồ '
          'sơ rỗng cho tới ngày hôm sau, trong khi màn Nhiệm vụ đã ghi tên bé '
          'vào buổi rồi',
    );
  });
}
