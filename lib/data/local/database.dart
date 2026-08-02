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
    BadgesEarned,
    Outbox,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// DB trong bộ nhớ, dùng cho test.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

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
    // Chưa có bước nâng cấp nào. Mỗi lần tăng schemaVersion phải thêm một bước
    // ở đây kèm test dựng DB phiên bản cũ rồi migrate — xem docs/03 §6.
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
