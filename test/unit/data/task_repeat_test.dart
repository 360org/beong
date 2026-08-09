import 'package:beong/core/theme/task_icons.dart';
import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/data/local/task_dao.dart';
import 'package:beong/data/seed/presets.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/family_clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lịch lặp của task, từ chuỗi lưu trong DB tới lượt việc thật sinh ra.
///
/// Khối "Lặp lại" trong sheet thêm việc ghi `repeat_days` dạng `'1,3,5'` với quy
/// ước **1 = thứ Hai**. Bộ lịch đọc lại bằng `CalendarDate.weekday`. Hai bên lệch
/// quy ước một bậc thì việc hiện sai ngày — mà sai kiểu đó rất khó thấy: việc vẫn
/// xuất hiện đều đặn, chỉ vào thứ khác thứ bố mẹ chọn.
void main() {
  late AppDatabase db;
  late TaskDao taskDao;
  late MemberDao memberDao;

  const familyId = 'fam-1';
  const childId = 'con-1';

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
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> createTask({
    required String id,
    required RepeatType repeat,
    String repeatDays = '',
    String? onceDate,
  }) => taskDao.createTask(
    TasksCompanion.insert(
      id: id,
      familyId: familyId,
      title: 'Việc $id',
      points: const Value(10),
      repeatType: Value(repeat.name),
      repeatDays: Value(repeatDays),
      onceDate: Value(onceDate),
    ),
    [childId],
  );

  /// Có lượt nào của [taskId] vào ngày [date] không?
  Future<bool> hasInstanceOn(String taskId, String date) async {
    await taskDao.generateInstances(
      familyId: familyId,
      today: CalendarDate.parse(date),
    );
    final rows = await db.select(db.taskInstances).get();
    return rows.any((r) => r.taskId == taskId && r.dueDate == date);
  }

  group('lặp theo thứ trong tuần', () {
    // 2026-08-10 là thứ Hai; 11 thứ Ba; 12 thứ Tư.
    test('quy ước 1 = thứ Hai khớp giữa DB và bộ lịch', () async {
      expect(CalendarDate.parse('2026-08-10').weekday, 1);
      expect(CalendarDate.parse('2026-08-16').weekday, 7);
    });

    test('chọn T2 và T4 thì chỉ sinh lượt vào hai thứ đó', () async {
      await createTask(
        id: 'hai-tu',
        repeat: RepeatType.custom,
        repeatDays: '1,3',
      );

      expect(await hasInstanceOn('hai-tu', '2026-08-10'), isTrue);
      expect(await hasInstanceOn('hai-tu', '2026-08-12'), isTrue);
      expect(
        await hasInstanceOn('hai-tu', '2026-08-11'),
        isFalse,
        reason: 'thứ Ba không được chọn',
      );
    });

    test(
      'chọn Chủ nhật thì sinh vào Chủ nhật, không lệch sang thứ Bảy',
      () async {
        // Ca bắt lỗi off-by-one hay gặp nhất: 0-based vs 1-based, và
        // Sunday-first vs Monday-first.
        await createTask(
          id: 'chu-nhat',
          repeat: RepeatType.custom,
          repeatDays: '7',
        );

        expect(await hasInstanceOn('chu-nhat', '2026-08-16'), isTrue);
        expect(await hasInstanceOn('chu-nhat', '2026-08-15'), isFalse);
      },
    );

    test('hằng ngày sinh mọi ngày', () async {
      await createTask(id: 'moi-ngay', repeat: RepeatType.daily);

      expect(await hasInstanceOn('moi-ngay', '2026-08-10'), isTrue);
      expect(await hasInstanceOn('moi-ngay', '2026-08-11'), isTrue);
    });

    test('một lần chỉ sinh đúng ngày đã đặt', () async {
      await createTask(
        id: 'mot-lan',
        repeat: RepeatType.once,
        onceDate: '2026-08-11',
      );

      expect(await hasInstanceOn('mot-lan', '2026-08-11'), isTrue);
      expect(await hasInstanceOn('mot-lan', '2026-08-12'), isFalse);
    });

    test('custom mà không chọn thứ nào thì không sinh lượt nào', () async {
      // Đây là lý do sheet quy đổi `custom` + rỗng thành `daily` trước khi lưu:
      // nếu để nguyên, bố mẹ tạo ra một việc không bao giờ xuất hiện.
      await createTask(
        id: 'rong',
        repeat: RepeatType.custom,
      );

      expect(await hasInstanceOn('rong', '2026-08-10'), isFalse);
      expect(await hasInstanceOn('rong', '2026-08-11'), isFalse);
    });
  });

  group('bù icon cho việc thiếu icon', () {
    test('việc tự tạo không icon được gán ✏️', () async {
      await taskDao.createTask(
        TasksCompanion.insert(
          id: 'khong-icon',
          familyId: familyId,
          title: 'Việc cũ',
        ),
        [childId],
      );

      expect(await taskDao.backfillMissingIcons(familyId), 1);

      final task = await taskDao.getTaskById('khong-icon');
      expect(task.iconKey, kDefaultTaskIconKey);
      expect(
        iconForKey(task.iconKey),
        isNot(taskIconFallback),
        reason: '⭐ là dấu hiệu thiếu icon, không phải một lựa chọn',
      );
    });

    test('việc sinh từ template lấy đúng icon của template', () async {
      final preset = kTaskPresets.first;
      await taskDao.createTask(
        TasksCompanion.insert(
          id: 'tu-preset',
          familyId: familyId,
          title: preset.titleVi,
          presetKey: Value(preset.key),
        ),
        [childId],
      );

      await taskDao.backfillMissingIcons(familyId);

      expect(
        (await taskDao.getTaskById('tu-preset')).iconKey,
        preset.iconKey,
      );
    });

    test('không ghi đè icon bố mẹ đã chọn', () async {
      await taskDao.createTask(
        TasksCompanion.insert(
          id: 'co-icon',
          familyId: familyId,
          title: 'Đọc sách',
          iconKey: const Value('books'),
        ),
        [childId],
      );

      expect(
        await taskDao.backfillMissingIcons(familyId),
        0,
        reason: 'không có việc nào thiếu icon',
      );
      expect((await taskDao.getTaskById('co-icon')).iconKey, 'books');
    });

    test('chuỗi rỗng cũng được coi là thiếu icon', () async {
      await taskDao.createTask(
        TasksCompanion.insert(
          id: 'icon-rong',
          familyId: familyId,
          title: 'Việc lạ',
          iconKey: const Value(''),
        ),
        [childId],
      );

      expect(await taskDao.backfillMissingIcons(familyId), 1);
      expect(
        (await taskDao.getTaskById('icon-rong')).iconKey,
        kDefaultTaskIconKey,
      );
    });
  });
}
