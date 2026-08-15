import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/tables/tables.dart';
import 'package:beong/domain/entities/badge_def.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:drift/drift.dart';

part 'badge_dao.g.dart';

/// Huy hiệu của trẻ — `01-product-spec.md` §4.6.
///
/// Bảng `badges_earned` có trong schema từ Sprint 1 nhưng **không có gì đọc hay
/// ghi nó**, giống hệt tình trạng của bảng `jars` trước ADR-024. Lớp này là chỗ
/// duy nhất trao huy hiệu.
@DriftAccessor(
  tables: [BadgesEarned, TaskInstances, Streaks, Redemptions, Tasks],
)
class BadgeDao extends DatabaseAccessor<AppDatabase> with _$BadgeDaoMixin {
  BadgeDao(super.attachedDatabase);

  /// Số liệu đủ để xét mọi huy hiệu.
  Future<BadgeProgress> progressOf(String memberId) async {
    final done =
        await (select(taskInstances)..where(
              (i) =>
                  i.memberId.equals(memberId) &
                  i.status.equals(InstanceStatus.approved.name),
            ))
            .get();

    final streak = await (select(
      streaks,
    )..where((s) => s.memberId.equals(memberId))).getSingleOrNull();

    final redeemed =
        await (select(redemptions)..where(
              (r) =>
                  r.memberId.equals(memberId) &
                  r.status.isNotValue(RedemptionStatus.rejected.name),
            ))
            .get();

    return BadgeProgress(
      // `bestLen` chứ không phải `currentLen`: huy hiệu là ghi nhận thành
      // tích **đã đạt**. Lấy chuỗi hiện tại thì con đứt một ngày là mất huy
      // hiệu đã có — vừa vô lý vừa đúng kiểu trừng phạt mà ADR-022 tránh.
      streakDays: streak?.bestLen ?? 0,
      tasksDone: done.length,
      routinePerfectDays: await _routinePerfectDays(memberId),
      redemptions: redeemed.length,
    );
  }

  /// Số ngày trẻ làm **trọn bộ** ít nhất một routine.
  Future<int> _routinePerfectDays(String memberId) async {
    final rows =
        await (select(taskInstances).join([
              innerJoin(tasks, tasks.id.equalsExp(taskInstances.taskId)),
            ])..where(
              taskInstances.memberId.equals(memberId) &
                  tasks.routineId.isNotNull(),
            ))
            .get();

    // Gom theo (ngày, routine); ngày nào mọi lượt của routine đó đều đã duyệt
    // thì tính là một ngày trọn bộ.
    final buckets = <String, List<String>>{};
    for (final row in rows) {
      final instance = row.readTable(taskInstances);
      final task = row.readTable(tasks);
      buckets
          .putIfAbsent('${instance.dueDate}|${task.routineId}', () => [])
          .add(instance.status);
    }

    return buckets.values
        .where(
          (statuses) =>
              statuses.isNotEmpty &&
              statuses.every((s) => s == InstanceStatus.approved.name),
        )
        .length;
  }

  /// Khoá huy hiệu đã trao.
  Future<Set<String>> earnedKeys(String memberId) async {
    final rows = await (select(
      badgesEarned,
    )..where((b) => b.memberId.equals(memberId))).get();
    return rows.map((b) => b.badgeKey).toSet();
  }

  /// Theo dõi huy hiệu đã trao.
  Stream<Set<String>> watchEarnedKeys(String memberId) =>
      (select(badgesEarned)..where((b) => b.memberId.equals(memberId)))
          .watch()
          .map((rows) => rows.map((b) => b.badgeKey).toSet());

  /// Xét và trao huy hiệu mới. Trả về những huy hiệu **vừa** đạt.
  ///
  /// Gọi được nhiều lần vô hại: unique key `(member_id, badge_key)` chặn trùng,
  /// và ta chỉ trả về phần chênh lệch nên UI không chúc mừng lại cái cũ.
  Future<List<BadgeDef>> awardNewBadges({
    required String familyId,
    required String memberId,
  }) async {
    final progress = await progressOf(memberId);
    final already = await earnedKeys(memberId);
    final fresh = earnedBadges(
      progress,
    ).where((b) => !already.contains(b.key)).toList();
    if (fresh.isEmpty) return const [];

    await batch((b) {
      for (final badge in fresh) {
        b.insert(
          badgesEarned,
          BadgesEarnedCompanion.insert(
            id: '$memberId:${badge.key}',
            familyId: familyId,
            memberId: memberId,
            badgeKey: badge.key,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
    return fresh;
  }
}
