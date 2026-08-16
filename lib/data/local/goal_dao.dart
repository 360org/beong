import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/tables/tables.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

part 'goal_dao.g.dart';

/// Lỗi khi thao tác mục tiêu tiết kiệm.
class GoalException implements Exception {
  const GoalException(this.message);
  final String message;

  @override
  String toString() => 'GoalException: $message';
}

/// Mục tiêu tiết kiệm của trẻ — `03-data-model.md` §savings_goals.
///
/// Bảng `savings_goals` có từ schema v1 nhưng **không có gì đọc hay ghi nó** —
/// cùng loại lỗi với `jars` và `badges_earned` trước đây: cột có sẵn trong
/// schema không có nghĩa là tính năng đã tồn tại.
///
/// Quy tắc của tài liệu: **mỗi trẻ chỉ một mục tiêu `active`**. Nhiều mục tiêu
/// cùng lúc làm loãng bài học trì hoãn thoả mãn — con chuyển mục tiêu mỗi khi
/// mục tiêu cũ còn xa, và không mục tiêu nào tới đích. [setGoal] tự chuyển mục
/// tiêu đang chạy sang `abandoned` thay vì để hai hàng `active` cùng tồn tại.
@DriftAccessor(tables: [SavingsGoals])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  GoalDao(super.attachedDatabase);

  static const _uuid = Uuid();

  /// Mục tiêu đang chạy của một trẻ, `null` nếu chưa đặt.
  Future<SavingsGoal?> activeGoal(String memberId) {
    return _activeQuery(memberId).getSingleOrNull();
  }

  /// Theo dõi mục tiêu đang chạy.
  Stream<SavingsGoal?> watchActiveGoal(String memberId) {
    return _activeQuery(memberId).watchSingleOrNull();
  }

  SimpleSelectStatement<$SavingsGoalsTable, SavingsGoal> _activeQuery(
    String memberId,
  ) {
    return select(savingsGoals)
      ..where(
        (g) =>
            g.memberId.equals(memberId) &
            g.status.equals(GoalStatus.active.name),
      )
      // `limit(1)` chứ không phải `getSingle`: dữ liệu cũ có thể có hai hàng
      // `active` (trước khi [setGoal] tồn tại), và ném exception ở màn hình
      // chính của con là cái giá quá đắt cho một hàng thừa.
      ..orderBy([(g) => OrderingTerm.desc(g.createdAt)])
      ..limit(1);
  }

  /// Đặt mục tiêu mới, thay mục tiêu đang chạy nếu có.
  Future<SavingsGoal> setGoal({
    required String familyId,
    required String memberId,
    required String title,
    required int targetXu,
    String? iconKey,
    String? imagePath,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw const GoalException('Mục tiêu phải có tên');
    }
    if (targetXu <= 0) {
      throw const GoalException('Mục tiêu phải lớn hơn 0 xu');
    }

    return transaction(() async {
      await _abandonActive(memberId);
      final id = _uuid.v4();
      await into(savingsGoals).insert(
        SavingsGoalsCompanion.insert(
          id: id,
          familyId: familyId,
          memberId: memberId,
          title: trimmed,
          targetXu: targetXu,
          iconKey: Value(iconKey),
          imagePath: Value(imagePath),
        ),
      );
      return (select(
        savingsGoals,
      )..where((g) => g.id.equals(id))).getSingle();
    });
  }

  /// Bỏ mục tiêu đang chạy.
  Future<void> abandonActive(String memberId) => _abandonActive(memberId);

  Future<void> _abandonActive(String memberId) async {
    await (update(savingsGoals)..where(
          (g) =>
              g.memberId.equals(memberId) &
              g.status.equals(GoalStatus.active.name),
        ))
        .write(
          SavingsGoalsCompanion(status: Value(GoalStatus.abandoned.name)),
        );
  }

  /// Đánh dấu đã tới đích. Gọi nhiều lần vô hại — chỉ hàng `active` bị đổi, nên
  /// lần thứ hai không tìm thấy gì và không ghi đè `reached_at` đã có.
  Future<void> markReached(String goalId) async {
    await (update(savingsGoals)..where(
          (g) => g.id.equals(goalId) & g.status.equals(GoalStatus.active.name),
        ))
        .write(
          SavingsGoalsCompanion(
            status: Value(GoalStatus.reached.name),
            reachedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Mục tiêu đã tới đích, mới nhất trước — để khoe lại trong Sổ của con.
  Stream<List<SavingsGoal>> watchReachedGoals(String memberId) {
    return (select(savingsGoals)
          ..where(
            (g) =>
                g.memberId.equals(memberId) &
                g.status.equals(GoalStatus.reached.name),
          )
          ..orderBy([(g) => OrderingTerm.desc(g.reachedAt)]))
        .watch();
  }
}
