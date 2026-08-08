import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/tables/tables.dart';
import 'package:beong/domain/entities/enums.dart';
import 'package:drift/drift.dart';

part 'member_dao.g.dart';

@DriftAccessor(tables: [Families, Members, Streaks])
class MemberDao extends DatabaseAccessor<AppDatabase> with _$MemberDaoMixin {
  MemberDao(super.attachedDatabase);

  /// Tạo gia đình mới.
  Future<void> createFamily(FamiliesCompanion family) {
    return into(families).insert(family);
  }

  Future<Family> getFamily(String familyId) {
    return (select(families)..where((f) => f.id.equals(familyId))).getSingle();
  }

  Stream<Family> watchFamily(String familyId) {
    return (select(
      families,
    )..where((f) => f.id.equals(familyId))).watchSingle();
  }

  /// Thêm thành viên (bố mẹ hoặc trẻ).
  Future<void> addMember(MembersCompanion member) {
    return into(members).insert(member);
  }

  /// Danh sách thành viên active của gia đình.
  Stream<List<Member>> watchMembers(String familyId) {
    return (select(members)
          ..where(
            (m) => m.familyId.equals(familyId) & m.deletedAt.isNull(),
          )
          ..orderBy([
            (m) => OrderingTerm.asc(m.kind),
            (m) => OrderingTerm.asc(m.displayName),
          ]))
        .watch();
  }

  /// Chỉ trẻ em.
  Future<List<Member>> children(String familyId) {
    return (select(members)..where(
          (m) =>
              m.familyId.equals(familyId) &
              m.kind.equals(MemberKind.child.name) &
              m.deletedAt.isNull(),
        ))
        .get();
  }

  Future<Member> getMember(String memberId) {
    return (select(members)..where((m) => m.id.equals(memberId))).getSingle();
  }

  Stream<Member> watchMember(String memberId) {
    return (select(
      members,
    )..where((m) => m.id.equals(memberId))).watchSingle();
  }

  Future<void> updateMember(String id, MembersCompanion companion) {
    return (update(members)..where((m) => m.id.equals(id))).write(companion);
  }

  /// Cập nhật streak cache cho một trẻ.
  Future<void> upsertStreak({
    required String memberId,
    required int currentLen,
    required int bestLen,
    String? lastQualifiedDate,
    String? graceUsedMonth,
    int graceCount = 0,
  }) {
    return into(streaks).insertOnConflictUpdate(
      StreaksCompanion.insert(
        memberId: memberId,
        currentLen: Value(currentLen),
        bestLen: Value(bestLen),
        lastQualifiedDate: Value(lastQualifiedDate),
        graceUsedMonth: Value(graceUsedMonth),
        graceCount: Value(graceCount),
      ),
    );
  }

  Future<Streak?> getStreak(String memberId) {
    return (select(
      streaks,
    )..where((s) => s.memberId.equals(memberId))).getSingleOrNull();
  }

  Stream<Streak?> watchStreak(String memberId) {
    return (select(
      streaks,
    )..where((s) => s.memberId.equals(memberId))).watchSingleOrNull();
  }
}
