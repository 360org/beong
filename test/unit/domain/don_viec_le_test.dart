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

  group('nhận nuôi việc lẻ sinh ra SAU khi đã dọn', () {
    // Từ 30/08/2026 màn Nhiệm vụ không còn mục "Chưa xếp buổi". Việc rơi ra
    // khỏi buổi mà không ai nhận nuôi là **biến mất khỏi mọi màn hình** trong
    // khi vẫn nằm trong DB: bố mẹ không thấy để sửa, con không thấy để làm.

    test('bỏ một việc khỏi thói quen thì nó được nhận về buổi khác', () async {
      await don.chayNeuCan(familyId);

      // Bố mẹ bỏ "Đánh răng buổi sáng" khỏi buổi sáng.
      await taskDao.detachTaskFromRoutine('viec-trong-buoi');
      final truoc = await taskDao.activeTasks(familyId);
      expect(
        truoc.where((t) => t.routineId == null),
        hasLength(1),
        reason: 'dựng sai tình huống: chưa có việc lẻ nào để nhận nuôi',
      );

      await don.nhanNuoi(familyId);

      final sau = await taskDao.activeTasks(familyId);
      expect(
        sau.where((t) => t.routineId == null),
        isEmpty,
        reason: 'việc lẻ còn sót là việc không màn hình nào hiện ra nữa',
      );
    });

    test('ngừng dùng cả thói quen thì việc bên trong vẫn có chỗ ở', () async {
      await don.chayNeuCan(familyId);
      await taskDao.archiveRoutine(routineId);

      await don.nhanNuoi(familyId);

      final sau = await taskDao.activeTasks(familyId);
      expect(sau.where((t) => t.routineId == null), isEmpty);
      expect(sau, isNotEmpty, reason: 'không được tắt việc, chỉ chuyển buổi');
    });

    test('không có việc lẻ thì không tạo thêm buổi nào', () async {
      await don.chayNeuCan(familyId);
      final truoc = await taskDao.activeRoutines(familyId);

      final ketQua = await don.nhanNuoi(familyId);

      expect(ketQua.buoiMoiTao, 0);
      expect(await taskDao.activeRoutines(familyId), hasLength(truoc.length));
    });

    test('chạy được nhiều lần, không đẻ thêm buổi mỗi lần', () async {
      await don.chayNeuCan(familyId);
      await taskDao.detachTaskFromRoutine('viec-trong-buoi');

      await don.nhanNuoi(familyId);
      final sauLan1 = await taskDao.activeRoutines(familyId);
      await don.nhanNuoi(familyId);
      final sauLan2 = await taskDao.activeRoutines(familyId);

      expect(
        sauLan2,
        hasLength(sauLan1.length),
        reason:
            'nhanNuoi chạy mỗi lần mở app — đẻ thêm một buổi "Việc khác" mỗi '
            'lần là sau một tuần màn hình đầy buổi rác',
      );
    });
  });

  group('chặn và dọn việc trùng tên trong cùng một buổi', () {
    // Chủ dự án 30/08/2026: buổi "nữa đêm" có "Mặc đồ ngủ" **hai lần** — con
    // phải bấm hai lần và xu cộng gấp đôi cho cùng một hành động.

    test('createTask từ chối việc trùng tên trong cùng buổi', () async {
      await expectLater(
        taskDao.createTask(
          TasksCompanion.insert(
            id: 'trung-1',
            familyId: familyId,
            title: 'Đánh răng buổi sáng',
            routineId: const Value(routineId),
          ),
          const [],
        ),
        throwsA(isA<TaskTrungTenException>()),
      );
    });

    test('so tên bỏ qua hoa thường và khoảng trắng thừa', () async {
      await expectLater(
        taskDao.createTask(
          TasksCompanion.insert(
            id: 'trung-2',
            familyId: familyId,
            title: '  ĐÁNH   RĂNG buổi sáng ',
            routineId: const Value(routineId),
          ),
          const [],
        ),
        throwsA(isA<TaskTrungTenException>()),
        reason: 'gõ lệch khoảng trắng vẫn là cùng một việc với con',
      );
    });

    test('cùng tên nhưng KHÁC buổi thì vẫn tạo được', () async {
      await taskDao.createRoutine(
        routine: RoutinesCompanion.insert(
          id: 'routine-toi',
          familyId: familyId,
          title: 'Buổi tối',
        ),
        assigneeIds: [simba],
        routineTasks: const [],
      );

      await expectLater(
        taskDao.createTask(
          TasksCompanion.insert(
            id: 'khac-buoi',
            familyId: familyId,
            title: 'Đánh răng buổi sáng',
            routineId: const Value('routine-toi'),
          ),
          const [],
        ),
        completes,
        reason: 'hai bé đánh răng ở hai buổi khác nhau không phải bản sao',
      );
    });

    test(
      'createRoutine bỏ qua việc trùng trong danh sách truyền vào',
      () async {
        await taskDao.createRoutine(
          routine: RoutinesCompanion.insert(
            id: 'routine-trung',
            familyId: familyId,
            title: 'nữa đêm',
          ),
          assigneeIds: [neo],
          routineTasks: [
            TasksCompanion.insert(
              id: 'nd-1',
              familyId: familyId,
              title: 'Mặc đồ ngủ',
              routineId: const Value('routine-trung'),
            ),
            TasksCompanion.insert(
              id: 'nd-2',
              familyId: familyId,
              title: 'mặc đồ ngủ',
              routineId: const Value('routine-trung'),
            ),
          ],
        );

        final trong = (await taskDao.activeTasks(
          familyId,
        )).where((t) => t.routineId == 'routine-trung');
        expect(
          trong,
          hasLength(1),
          reason:
              'đường này chèn thẳng vào bảng, không đi qua createTask — không '
              'lọc ở đây thì buổi vừa tạo đã có sẵn hai việc y hệt',
        );
      },
    );

    test('donTrungTrongBuoi tắt bản trùng, GIỮ cái tạo trước', () async {
      // Dựng đúng đống dữ liệu cũ: hai việc y hệt trong một buổi, sinh ra từ
      // trước khi có chặn. Chèn thẳng qua DB để vượt qua chính cái chặn đó.
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'cu',
              familyId: familyId,
              title: 'Mặc đồ ngủ',
              routineId: const Value(routineId),
              createdAt: Value(DateTime(2026)),
            ),
          );
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'moi',
              familyId: familyId,
              title: 'Mặc đồ ngủ',
              routineId: const Value(routineId),
              // Rõ ràng sau cái 'cu', để "tạo trước / tạo sau" là khẳng định
              // chắc chắn chứ không phụ thuộc đồng hồ lúc chạy test.
              createdAt: Value(DateTime(2030)),
            ),
          );

      final daTat = await don.donTrungTrongBuoi(familyId);

      expect(daTat, 1);
      final conSong = (await taskDao.activeTasks(
        familyId,
      )).map((t) => t.id).toSet();
      expect(
        conSong,
        contains('cu'),
        reason:
            'giữ cái tạo trước: lượt việc và sổ cái đã trỏ vào nó lâu hơn, tắt '
            'nó đi là làm "Sổ của con" mất nhiều hơn',
      );
      expect(conSong, isNot(contains('moi')));
    });

    test(
      'donTrungTrongBuoi KHÔNG xoá, chỉ tắt — sổ cái trỏ tới task_id',
      () async {
        await db
            .into(db.tasks)
            .insert(
              TasksCompanion.insert(
                id: 'ban-sao',
                familyId: familyId,
                title: 'Đánh răng buổi sáng',
                routineId: const Value(routineId),
                createdAt: Value(DateTime(2030)),
              ),
            );

        await don.donTrungTrongBuoi(familyId);

        final van = await (db.select(
          db.tasks,
        )..where((t) => t.id.equals('ban-sao'))).getSingleOrNull();
        expect(van, isNotNull, reason: 'ADR-005: sổ cái chỉ ghi thêm');
        expect(van!.active, isFalse);
      },
    );

    test('không có gì trùng thì không đụng vào việc nào', () async {
      final daTat = await don.donTrungTrongBuoi(familyId);
      expect(daTat, 0);
    });
  });
}
