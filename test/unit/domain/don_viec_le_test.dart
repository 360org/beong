import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/settings_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/don_viec_le.dart';
import 'package:beong/domain/services/family_clock.dart';
// `isNotNull` có ở cả drift lẫn matcher; test này cần bản của matcher.
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

/// Dựng lại đúng tình huống trên máy chủ dự án (26/08/2026): việc mẫu đi qua
/// hai đường nên bị tạo hai bản, bé thấy "Đánh răng buổi sáng" hai lần và phải
/// bấm xong hai lần mới hết việc.
void main() {
  late AppDatabase db;
  late TaskDao taskDao;
  late MemberDao memberDao;
  late SettingsDao settingsDao;
  late DonViecLe don;

  const familyId = 'fam-1';
  const neo = 'con-neo';
  const simba = 'con-simba';
  const routineId = 'routine-sang';

  Future<void> themVietLe(
    String id,
    String title,
    List<String> nguoiNhan,
  ) => taskDao.createTask(
    TasksCompanion.insert(id: id, familyId: familyId, title: title),
    nguoiNhan,
  );

  setUp(() async {
    db = AppDatabase.memory();
    taskDao = TaskDao(db);
    memberDao = MemberDao(db);
    settingsDao = SettingsDao(db);
    don = DonViecLe(taskDao: taskDao, settingsDao: settingsDao);

    await memberDao.createFamily(
      FamiliesCompanion.insert(id: familyId, name: 'Nhà mình'),
    );
    for (final (id, ten) in [(neo, 'Neo'), (simba, 'Simba')]) {
      await memberDao.addMember(
        MembersCompanion.insert(
          id: id,
          familyId: familyId,
          kind: MemberKind.child.name,
          displayName: ten,
        ),
      );
    }

    // Đường 1 — onboarding: buổi sáng của Neo, có "Đánh răng buổi sáng".
    await taskDao.createRoutine(
      routine: RoutinesCompanion.insert(
        id: routineId,
        familyId: familyId,
        title: 'Buổi sáng',
      ),
      assigneeIds: [neo],
      routineTasks: [
        TasksCompanion.insert(
          id: 'viec-trong-buoi',
          familyId: familyId,
          title: 'Đánh răng buổi sáng',
          routineId: const Value(routineId),
          orderIndex: const Value(0),
        ),
      ],
    );
  });

  tearDown(() async => db.close());

  test('tắt bản lẻ trùng, giữ bản trong buổi', () async {
    // Đường 2 — gán việc mẫu: đúng việc ấy, đúng bé ấy, lần thứ hai.
    await themVietLe('viec-le-trung', 'Đánh răng buổi sáng', [neo]);

    final ketQua = await don.chay(familyId);

    expect(ketQua.daTatTrung, 1);
    final conSong = await taskDao.activeTasks(familyId);
    expect(conSong.map((t) => t.id), ['viec-trong-buoi']);
  });

  test('KHÔNG xoá bản trùng — chỉ tắt, vì sổ cái trỏ tới task_id', () async {
    await themVietLe('viec-le-trung', 'Đánh răng buổi sáng', [neo]);
    await don.chay(familyId);

    final van = await (db.select(
      db.tasks,
    )..where((t) => t.id.equals('viec-le-trung'))).getSingleOrNull();
    expect(van, isNotNull, reason: 'bản ghi phải còn để sổ cái còn tên việc');
    expect(van!.active, isFalse);
  });

  test('cùng tên nhưng khác bé thì KHÔNG phải bản trùng', () async {
    // Buổi sáng chỉ gán cho Neo. Simba cũng phải đánh răng — đó là việc riêng
    // của Simba, không phải bản sao.
    await themVietLe('viec-cua-simba', 'Đánh răng buổi sáng', [simba]);

    final ketQua = await don.chay(familyId);

    expect(ketQua.daTatTrung, 0);
    expect(ketQua.daGomVaoBuoi, 1);
    final task = await taskDao.getTaskById('viec-cua-simba');
    expect(task.active, isTrue);
    expect(task.routineId, isNotNull);
  });

  test('việc lẻ còn lại được gom vào buổi, nhóm theo tập người nhận', () async {
    await themVietLe('rieng-neo', 'Rửa bát', [neo]);
    await themVietLe('rieng-simba', 'Tưới cây', [simba]);
    await themVietLe('chung', 'Dọn phòng khách', [neo, simba]);

    final ketQua = await don.chay(familyId);

    // Ba tập người nhận khác nhau -> đúng ba buổi, không phải ba việc lẻ và
    // cũng không phải một buổi gộp sai người.
    expect(ketQua.buoiMoiTao, 3);
    expect(ketQua.daGomVaoBuoi, 3);

    final chung = await taskDao.getTaskById('chung');
    final nguoiNhan = await taskDao.routineAssigneesOf(chung.routineId!);
    expect(nguoiNhan, unorderedEquals([neo, simba]));
  });

  test('sau khi dọn, không còn việc nào đứng ngoài buổi', () async {
    await themVietLe('a', 'Rửa bát', [neo]);
    await themVietLe('b', 'Tưới cây', [simba]);
    await themVietLe('c', 'Đánh răng buổi sáng', [neo]);

    await don.chay(familyId);

    final conSong = await taskDao.activeTasks(familyId);
    expect(conSong.where((t) => t.routineId == null), isEmpty);
  });

  test('bé không còn thấy việc lặp hai lần trong ngày', () async {
    await themVietLe('viec-le-trung', 'Đánh răng buổi sáng', [neo]);
    await don.chay(familyId);

    await taskDao.generateInstances(
      familyId: familyId,
      today: const CalendarDate(2026, 8, 26),
    );
    // `generateInstances` sinh trước cho nhiều ngày, nên phải lọc đúng một
    // ngày mới trả lời được câu hỏi "hôm đó bé thấy việc này mấy lần".
    final homDo =
        await (db.select(db.taskInstances)..where(
              (i) => i.memberId.equals(neo) & i.dueDate.equals('2026-08-26'),
            ))
            .get();
    expect(homDo, hasLength(1));
  });

  test('chạy lần hai không làm gì thêm', () async {
    await themVietLe('a', 'Rửa bát', [neo]);

    final lan1 = await don.chayNeuCan(familyId);
    final lan2 = await don.chayNeuCan(familyId);

    expect(lan1.daChay, isTrue);
    expect(lan2.daChay, isFalse, reason: 'đã dọn rồi thì thôi');
  });

  test('nhà chưa có việc lẻ nào thì không tạo buổi rác', () async {
    final ketQua = await don.chay(familyId);
    expect(ketQua.coThayDoi, isFalse);
    expect(ketQua.buoiMoiTao, 0);
  });
}
