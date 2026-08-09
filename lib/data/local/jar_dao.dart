import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/tables/tables.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:drift/drift.dart';

part 'jar_dao.g.dart';

/// Lỗi khi thao tác hũ.
class JarException implements Exception {
  const JarException(this.message);
  final String message;

  @override
  String toString() => 'JarException: $message';
}

/// Các hũ của một gia đình — ADR-024.
///
/// Bảng `jars` có từ schema v5 nhưng **không có gì đọc hay ghi nó**: ba hũ mặc
/// định nằm cứng trong `kDefaultJars`, nên bố mẹ không lập được hũ nào khác.
/// Lớp này là chỗ duy nhất được sửa danh sách hũ.
///
/// Quy tắc xuyên suốt: **không xoá hũ, chỉ xếp lại (`is_archived`)**. Xu đã vào
/// hũ thì nằm trong sổ cái với `jar_key` đó mãi mãi (ADR-005 append-only); xoá
/// định nghĩa hũ đi thì số dư vẫn còn mà không còn tên để hiện — đúng cái lỗi
/// "xu biến mất" mà `WalletBalance` vừa phải sửa.
@DriftAccessor(tables: [Jars])
class JarDao extends DatabaseAccessor<AppDatabase> with _$JarDaoMixin {
  JarDao(super.attachedDatabase);

  /// Tạo ba hũ mặc định cho gia đình mới. Gọi nhiều lần vô hại.
  Future<void> seedDefaults(String familyId) async {
    final existing = await (select(
      jars,
    )..where((j) => j.familyId.equals(familyId))).get();
    if (existing.isNotEmpty) return;

    await batch((b) {
      for (final jar in kDefaultJars) {
        b.insert(
          jars,
          JarsCompanion.insert(
            id: '$familyId:${jar.key}',
            familyId: familyId,
            jarKey: jar.key,
            title: jar.title,
            emoji: jar.emoji,
            pct: Value(jar.pct),
            orderIndex: Value(jar.orderIndex),
          ),
        );
      }
    });
  }

  /// Hũ đang dùng, đã xếp thứ tự.
  Future<List<JarDef>> activeJars(String familyId) async {
    final rows =
        await (select(jars)
              ..where((j) => j.familyId.equals(familyId) & j.isArchived.not())
              ..orderBy([(j) => OrderingTerm(expression: j.orderIndex)]))
            .get();
    return rows.map(_toDef).toList();
  }

  /// Theo dõi hũ đang dùng.
  ///
  /// Gia đình chưa có hàng nào trong bảng (dữ liệu tạo trước v5) thì trả về ba
  /// hũ mặc định, **không** trả danh sách rỗng: màn chia xu rỗng thì con không
  /// chia được xu đi đâu cả.
  Stream<List<JarDef>> watchActiveJars(String familyId) {
    return (select(jars)
          ..where((j) => j.familyId.equals(familyId) & j.isArchived.not())
          ..orderBy([(j) => OrderingTerm(expression: j.orderIndex)]))
        .watch()
        .map((rows) => rows.isEmpty ? kDefaultJars : rows.map(_toDef).toList());
  }

  /// Cả hũ đã xếp lại — dùng ở màn quản lý hũ.
  Stream<List<({JarDef jar, bool archived})>> watchAllJars(String familyId) {
    return (select(jars)
          ..where((j) => j.familyId.equals(familyId))
          ..orderBy([(j) => OrderingTerm(expression: j.orderIndex)]))
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              (jar: _toDef(row), archived: row.isArchived),
          ],
        );
  }

  /// Thêm một hũ mới.
  ///
  /// Khoá hũ sinh từ **thời điểm tạo** chứ không từ tên hũ: bố mẹ đổi tên hũ là
  /// chuyện thường, mà khoá đã đi vào sổ cái thì không đổi được nữa.
  Future<JarDef> addJar({
    required String familyId,
    required String title,
    required String emoji,
    int pct = 0,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw const JarException('Hũ phải có tên');
    }

    final all = await (select(
      jars,
    )..where((j) => j.familyId.equals(familyId))).get();
    final jarKey = 'jar${DateTime.now().microsecondsSinceEpoch}';
    final nextOrder = all.fold(
      0,
      (max, j) => j.orderIndex >= max ? j.orderIndex + 1 : max,
    );

    await into(jars).insert(
      JarsCompanion.insert(
        id: '$familyId:$jarKey',
        familyId: familyId,
        jarKey: jarKey,
        title: trimmed,
        emoji: emoji,
        pct: Value(pct),
        orderIndex: Value(nextOrder),
      ),
    );

    return JarDef(
      key: jarKey,
      title: trimmed,
      emoji: emoji,
      pct: pct,
      orderIndex: nextOrder,
    );
  }

  /// Sửa tên/emoji/tỷ lệ của một hũ. Khoá hũ không đổi được.
  Future<void> updateJar({
    required String familyId,
    required String jarKey,
    String? title,
    String? emoji,
    int? pct,
  }) async {
    if (title != null && title.trim().isEmpty) {
      throw const JarException('Hũ phải có tên');
    }
    if (pct != null && (pct < 0 || pct > 100)) {
      throw const JarException('Tỷ lệ phải trong khoảng 0–100%');
    }

    await (update(jars)..where(
          (j) => j.familyId.equals(familyId) & j.jarKey.equals(jarKey),
        ))
        .write(
          JarsCompanion(
            title: title == null ? const Value.absent() : Value(title.trim()),
            emoji: emoji == null ? const Value.absent() : Value(emoji),
            pct: pct == null ? const Value.absent() : Value(pct),
          ),
        );
  }

  /// Xếp một hũ lại (hoặc mở lại).
  ///
  /// Không cho xếp lại hũ Tiêu: phần thưởng trừ xu từ hũ Tiêu (ADR-016), không
  /// có nó thì con không đổi được gì và thông báo lỗi sẽ nói về "hũ không tồn
  /// tại" thay vì nói ra nguyên nhân thật.
  Future<void> setArchived({
    required String familyId,
    required String jarKey,
    required bool archived,
  }) async {
    if (archived && jarKey == kJarSpend) {
      throw const JarException(
        'Không xếp lại hũ Tiêu được: phần thưởng trừ xu từ hũ này',
      );
    }
    if (archived) {
      final remaining = await activeJars(familyId);
      if (remaining.length <= 1) {
        throw const JarException('Phải còn ít nhất một hũ');
      }
    }

    await (update(jars)..where(
          (j) => j.familyId.equals(familyId) & j.jarKey.equals(jarKey),
        ))
        .write(JarsCompanion(isArchived: Value(archived)));
  }

  /// Ghi lại thứ tự theo danh sách khoá truyền vào.
  Future<void> reorder({
    required String familyId,
    required List<String> jarKeys,
  }) async {
    await batch((b) {
      for (var i = 0; i < jarKeys.length; i++) {
        b.update(
          jars,
          JarsCompanion(orderIndex: Value(i)),
          where: (j) =>
              j.familyId.equals(familyId) & j.jarKey.equals(jarKeys[i]),
        );
      }
    });
  }

  JarDef _toDef(JarRow row) => JarDef(
    key: row.jarKey,
    title: row.title,
    emoji: row.emoji,
    pct: row.pct,
    orderIndex: row.orderIndex,
  );
}
