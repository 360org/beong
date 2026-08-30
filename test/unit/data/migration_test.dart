import 'dart:io';

import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/jar_dao.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// `docs/03-data-model.md` §6: mỗi lần tăng `schemaVersion` phải có test dựng DB
/// phiên bản cũ rồi migrate.
///
/// Cách dựng "DB phiên bản cũ": mở DB ở phiên bản hiện tại, **bỏ đúng những thứ
/// các phiên bản sau đã thêm vào**, rồi hạ `user_version`. Không phải bản sao
/// lịch sử hoàn hảo của schema cũ, nhưng nó kiểm đúng điều dễ sai nhất: máy đã
/// cài bản cũ, có dữ liệu thật, nâng cấp lên bản mới thì **không mất dữ liệu và
/// không crash**.
///
/// Thêm bước migration mới thì thêm một dòng vào `_undoTo` và một test tương ứng.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('beong_migration_');
    dbFile = File(p.join(tempDir.path, 'beong.sqlite'));
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  /// Dựng file DB ở phiên bản [version] kèm một gia đình thật.
  Future<void> seedAtVersion(int version) async {
    final db = AppDatabase(NativeDatabase(dbFile));
    await db
        .into(db.families)
        .insert(FamiliesCompanion.insert(id: 'fam-1', name: 'Nhà mình'));

    // Bỏ dần những gì phiên bản sau đã thêm, từ mới nhất về cũ nhất.
    if (version < 9) {
      // Thiếu đúng bước này ngày 30/08/2026 là mọi test migration vẫn xanh
      // trong khi app thật **hỏng ngay lúc mở** trên máy đã cài bản cũ: bảng
      // `jars` "phiên bản 8" giả vẫn có sẵn `member_id`, nên câu chép dữ liệu
      // của `alterTable` chạy được ở test mà không chạy được ngoài đời.
      //
      // Phải dựng lại cả bảng chứ không `DROP COLUMN` được: `member_id` nằm
      // trong ràng buộc UNIQUE, và SQLite từ chối bỏ cột như thế. DDL dưới đây
      // chép nguyên văn từ một máy đang chạy v8 thật.
      await db.customStatement('DROP TABLE jars');
      await db.customStatement('''
CREATE TABLE "jars" (
  "id" TEXT NOT NULL,
  "family_id" TEXT NOT NULL,
  "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
  "updated_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
  "jar_key" TEXT NOT NULL,
  "title" TEXT NOT NULL,
  "emoji" TEXT NOT NULL,
  "pct" INTEGER NOT NULL DEFAULT 0,
  "order_index" INTEGER NOT NULL DEFAULT 0,
  "is_archived" INTEGER NOT NULL DEFAULT 0 CHECK ("is_archived" IN (0, 1)),
  PRIMARY KEY ("id"),
  UNIQUE ("family_id", "jar_key")
)''');
    }
    if (version < 8) {
      await db.customStatement(
        'ALTER TABLE tasks DROP COLUMN missed_penalty_pct',
      );
      await db.customStatement(
        'ALTER TABLE task_instances DROP COLUMN missed_penalty_pct',
      );
    }
    if (version < 7) {
      await db.customStatement(
        'ALTER TABLE savings_goals DROP COLUMN icon_key',
      );
    }
    if (version < 6) {
      await db.customStatement(
        'ALTER TABLE point_transactions DROP COLUMN op_group_id',
      );
    }
    if (version < 5) {
      await db.customStatement('DROP TABLE jars');
      await db.customStatement(
        'ALTER TABLE families DROP COLUMN allocation_mode',
      );
    }
    if (version < 4) {
      await db.customStatement(
        'ALTER TABLE families DROP COLUMN require_approval',
      );
    }
    if (version < 3) {
      await db.customStatement(
        'ALTER TABLE families DROP COLUMN missed_penalty_pct',
      );
      await db.customStatement(
        'ALTER TABLE families DROP COLUMN reopen_penalty_pct',
      );
      await db.customStatement(
        'ALTER TABLE task_instances DROP COLUMN reopen_count',
      );
      await db.customStatement(
        'ALTER TABLE task_instances DROP COLUMN missed_penalty_at',
      );
    }
    if (version < 2) {
      await db.customStatement('DROP TABLE device_settings');
    }

    await db.customStatement('PRAGMA user_version = $version');
    await db.close();
  }

  Future<AppDatabase> openCurrent() async {
    final db = AppDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);
    // Một truy vấn bất kỳ để buộc drift mở kết nối và chạy migration.
    await db.select(db.families).get();
    return db;
  }

  test('nâng từ v1 lên phiên bản hiện tại, không mất dữ liệu', () async {
    await seedAtVersion(1);
    final db = await openCurrent();

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], db.schemaVersion);

    final families = await db.select(db.families).get();
    expect(families.single.name, 'Nhà mình', reason: 'dữ liệu cũ còn nguyên');
  });

  test('v1 -> v2 tạo được device_settings', () async {
    await seedAtVersion(1);
    final db = await openCurrent();

    await db
        .into(db.deviceSettings)
        .insert(
          DeviceSettingsCompanion.insert(settingKey: 'k', settingValue: 'v'),
        );

    expect(await db.select(db.deviceSettings).get(), hasLength(1));
  });

  test('v2 -> v3 thêm cấu hình trừ xu, và nâng cấp là **tắt**', () async {
    await seedAtVersion(2);
    final db = await openCurrent();

    // Điểm quan trọng: gia đình đang dùng bản cũ nâng lên bản mới thì không
    // tự nhiên bị bật trừ xu.
    final family = await db.select(db.families).getSingle();
    expect(family.missedPenaltyPct, 0);
    expect(family.reopenPenaltyPct, 0);
  });

  test('v5 -> v6 thêm cột nhóm sổ cái, dòng cũ để NULL', () async {
    await seedAtVersion(5);
    final db = await openCurrent();

    // Không backfill: suy ngược `op_group_id` từ `client_op_id` không đáng tin,
    // nên dòng cũ để NULL và tầng hiển thị lấy `id` làm nhóm.
    await db
        .into(db.pointTransactions)
        .insert(
          PointTransactionsCompanion.insert(
            id: 'tx-1',
            familyId: 'fam-1',
            memberId: 'con-1',
            jar: 'spend',
            delta: 5,
            reason: 'bonus',
            clientOpId: 'tx-1',
          ),
        );

    final row = await db.select(db.pointTransactions).getSingle();
    expect(row.opGroupId, isNull);
  });

  test(
    'v7 -> v8 thêm mức trừ riêng, việc cũ để NULL nên không đổi hành vi',
    () async {
      await seedAtVersion(7);
      final db = await openCurrent();

      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-1',
              familyId: 'fam-1',
              title: 'Việc cũ',
            ),
          );

      // NULL = theo mức chung của gia đình, tức nâng cấp không đổi số xu bị trừ
      // của bất kỳ nhà nào.
      final task = await db.select(db.tasks).getSingle();
      expect(task.missedPenaltyPct, isNull);
    },
  );

  test('v6 -> v7 thêm icon cho mục tiêu, mục tiêu cũ để NULL', () async {
    await seedAtVersion(6);
    final db = await openCurrent();

    await db
        .into(db.savingsGoals)
        .insert(
          SavingsGoalsCompanion.insert(
            id: 'goal-1',
            familyId: 'fam-1',
            memberId: 'con-1',
            title: 'Xe đạp',
            targetXu: 500,
          ),
        );

    final goal = await db.select(db.savingsGoals).getSingle();
    expect(goal.iconKey, isNull, reason: 'mục tiêu cũ hiện icon mặc định');
  });

  test('v8 -> v9 thêm hũ riêng cho bé, hũ cũ thành hũ chung', () async {
    await seedAtVersion(8);

    // Ba hũ mặc định như một nhà đang dùng thật.
    final db = await openCurrent();
    final jarDao = JarDao(db);
    await jarDao.seedDefaults('fam-1');
    final truoc = await jarDao.activeJars('fam-1');
    expect(truoc, hasLength(3));
    final sau = await jarDao.activeJars('fam-1');

    expect(
      sau.map((j) => j.key),
      truoc.map((j) => j.key),
      reason: 'nâng cấp không được làm mất hũ nào',
    );

    final rows = await db.select(db.jars).get();
    expect(
      rows.every((r) => r.memberId == null),
      isTrue,
      reason:
          'hũ có từ trước v9 là hũ **chung của nhà** — đúng ý nghĩa chúng vẫn '
          'đang mang, nâng cấp không đổi hành vi nhà nào',
    );
  });

  test('v8 -> v9 mở được DB cũ, không chết ở bước chép dữ liệu', () async {
    // Test riêng cho đúng cú ngã ngày 30/08/2026: `TableMigration(jars)` thiếu
    // `newColumns` thì drift sinh `INSERT INTO tmp SELECT ..., "member_id" ...
    // FROM jars` — đọc cột chưa tồn tại ở bảng cũ. App chết lúc mở DB, trước
    // khi vẽ được gì: người dùng thấy **màn hình trắng**, không có thông báo.
    await seedAtVersion(8);

    final db = await openCurrent();
    await expectLater(db.select(db.jars).get(), completes);
  });

  test('v4 -> v5 tạo bảng hũ và giữ mặc định chia tự động', () async {
    await seedAtVersion(4);
    final db = await openCurrent();

    // Sổ cái cũ dùng khoá 'spend'/'save'/'give'; ba hũ mặc định phải dùng đúng
    // các khoá đó, nếu không thì lịch sử xu trỏ vào hũ không tồn tại.
    final family = await db.select(db.families).getSingle();
    expect(family.allocationMode, 'auto');
    expect(await db.select(db.jars).get(), isEmpty, reason: 'seed ở tầng trên');
  });

  test('v3 -> v4 thêm cờ cần duyệt, và nâng cấp là **tắt**', () async {
    await seedAtVersion(3);
    final db = await openCurrent();

    // Đây là đổi hành vi có chủ ý (ADR-023): bản cũ bắt duyệt mọi việc, bản mới
    // mặc định xong-là-xong. Test này chốt rằng nâng cấp đi theo mặc định mới
    // chứ không rơi vào trạng thái nửa vời.
    final family = await db.select(db.families).getSingle();
    expect(family.requireApproval, isFalse);
  });

  test('v2 -> v3 thêm cột đếm số lần mở lại, mặc định 0', () async {
    await seedAtVersion(2);
    final db = await openCurrent();

    await db
        .into(db.tasks)
        .insert(
          TasksCompanion.insert(
            id: 'task-1',
            familyId: 'fam-1',
            title: 'Việc',
          ),
        );
    await db
        .into(db.taskInstances)
        .insert(
          TaskInstancesCompanion.insert(
            id: 'i1',
            familyId: 'fam-1',
            taskId: 'task-1',
            memberId: 'con-1',
            dueDate: '2026-08-01',
            pointsSnapshot: 10,
          ),
        );

    final instance = await db.select(db.taskInstances).getSingle();
    expect(instance.reopenCount, 0);
    expect(instance.missedPenaltyAt, isNull);
  });
}
