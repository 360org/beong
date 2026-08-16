import 'dart:io';

import 'package:beong/data/local/tables/tables.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Database local — nguồn sự thật khi app chạy (ADR-002).
///
/// Backend chỉ là lớp đồng bộ; UI luôn đọc từ đây nên không bao giờ phải chờ mạng.
@DriftDatabase(
  tables: [
    Families,
    Members,
    Routines,
    RoutineAssignees,
    Tasks,
    TaskAssignees,
    TaskInstances,
    PointTransactions,
    Rewards,
    Redemptions,
    SavingsGoals,
    Streaks,
    BadgesEarned,
    Outbox,
    DeviceSettings,
    Jars,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// DB trong bộ nhớ, dùng cho test.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    beforeOpen: (details) async {
      // Bắt buộc: SQLite tắt khoá ngoại theo mặc định.
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (m, from, to) async {
      // v6 -> v7: icon cho mục tiêu tiết kiệm. Cột nullable, mục tiêu cũ hiện
      // icon mặc định.
      if (from < 7) {
        await m.addColumn(savingsGoals, savingsGoals.iconKey);
      }
      // v1 -> v2: bảng cấu hình thiết bị, để session sống qua lần mở app sau.
      if (from < 2) {
        await m.createTable(deviceSettings);
      }
      // v2 -> v3: cấu hình trừ xu (ADR-022). Mọi cột đều có default nên gia
      // đình đang dùng bản cũ nâng lên là **tắt** trừ xu, không tự bật.
      // v5 -> v6: nhóm các dòng sổ cái của cùng một thao tác. Dòng cũ để NULL
      // và lấy `id` làm nhóm — không backfill, vì suy ngược từ `client_op_id`
      // không đáng tin (xem doc của cột).
      if (from < 6) {
        await m.addColumn(pointTransactions, pointTransactions.opGroupId);
      }
      // v4 -> v5: hũ thành bảng + chế độ chia xu (ADR-024). Không di trú
      // `point_transactions`: ba hũ mặc định dùng đúng key cũ.
      if (from < 5) {
        await m.createTable(jars);
        await m.addColumn(families, families.allocationMode);
      }
      // v3 -> v4: cờ cần duyệt (ADR-023). Default false, tức là gia đình đang
      // dùng bản cũ nâng lên sẽ **đổi hành vi**: trước đây mọi việc phải duyệt.
      // Xem ADR-023 phần hệ quả — đây là đổi có chủ ý, không phải sơ suất.
      if (from < 4) {
        await m.addColumn(families, families.requireApproval);
      }
      if (from < 3) {
        await m.addColumn(families, families.missedPenaltyPct);
        await m.addColumn(families, families.reopenPenaltyPct);
        await m.addColumn(taskInstances, taskInstances.reopenCount);
        await m.addColumn(taskInstances, taskInstances.missedPenaltyAt);
      }
    },
    // Mỗi lần tăng schemaVersion phải thêm một bước ở đây kèm test dựng DB
    // phiên bản cũ rồi migrate — xem docs/03 §6.
  );

  /// Chỉ mục theo `docs/03-data-model.md` §4.
  Future<void> _createIndexes() async {
    const statements = <String>[
      'CREATE INDEX IF NOT EXISTS idx_instances_family_due_status ON task_instances (family_id, due_date, status)',
      'CREATE INDEX IF NOT EXISTS idx_instances_member_due ON task_instances (member_id, due_date)',
      'CREATE INDEX IF NOT EXISTS idx_tx_member_created ON point_transactions (member_id, created_at DESC)',
      'CREATE INDEX IF NOT EXISTS idx_tx_member_jar ON point_transactions (member_id, jar)',
      'CREATE INDEX IF NOT EXISTS idx_redemptions_family_status ON redemptions (family_id, status)',
      'CREATE INDEX IF NOT EXISTS idx_tasks_routine_order ON tasks (routine_id, order_index)',
    ];
    for (final sql in statements) {
      await customStatement(sql);
    }
  }
}

/// Mở DB trên thiết bị thật.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'beong.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
