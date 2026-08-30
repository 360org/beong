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

  /// Bé này đã có bộ hũ riêng chưa.
  Future<bool> coHuRieng(String memberId) async {
    final rows = await (select(
      jars,
    )..where((j) => j.memberId.equals(memberId))).get();
    return rows.isNotEmpty;
  }

  /// Điều kiện lọc hũ theo chủ.
  ///
  /// Bé đã có bộ riêng thì **chỉ** lấy hàng của bé — không trộn thêm hũ chung.
  /// Trộn thì tổng của bé đó thành lớn hơn 100%, mà mọi thứ ở tầng chia xu đều
  /// dựa vào tổng đúng 100 (`wallet_dao.planFor`).
  Expression<bool> _thuocVe(Jars j, String familyId, String? memberId) {
    if (memberId == null) {
      return j.familyId.equals(familyId) & j.memberId.isNull();
    }
    return j.familyId.equals(familyId) & j.memberId.equals(memberId);
  }

  /// Hũ đang dùng của một chủ, đã xếp thứ tự.
  ///
  /// [memberId] `null` = bộ chung của nhà. Truyền id một bé mà bé đó **chưa** có
  /// bộ riêng thì trả về bộ chung — đó là bộ bé đang thật sự dùng.
  Future<List<JarDef>> activeJars(String familyId, {String? memberId}) async {
    final chuThucSu = memberId != null && await coHuRieng(memberId)
        ? memberId
        : null;
    final rows =
        await (select(jars)
              ..where(
                (j) => _thuocVe(j, familyId, chuThucSu) & j.isArchived.not(),
              )
              ..orderBy([(j) => OrderingTerm(expression: j.orderIndex)]))
            .get();
    return rows.map(_toDef).toList();
  }

  /// Tách bộ hũ riêng cho một bé bằng cách **sao chép** bộ chung của nhà.
  ///
  /// Giữ nguyên `jar_key`, tên, emoji, tỷ lệ và thứ tự. Giữ `jar_key` là bắt
  /// buộc: sổ cái ghi `(member_id, jar)` nên đổi khoá là số dư đang có của bé
  /// rơi vào một hũ không còn ai hiển thị.
  ///
  /// Gọi nhiều lần vô hại — bé đã có bộ riêng thì thoát ngay.
  Future<void> tachBoRieng({
    required String familyId,
    required String memberId,
  }) async {
    if (await coHuRieng(memberId)) return;

    final chung = await (select(
      jars,
    )..where((j) => j.familyId.equals(familyId) & j.memberId.isNull())).get();

    await batch((b) {
      for (final row in chung) {
        b.insert(
          jars,
          JarsCompanion.insert(
            id: '$memberId:${row.jarKey}',
            familyId: familyId,
            memberId: Value(memberId),
            jarKey: row.jarKey,
            title: row.title,
            emoji: row.emoji,
            pct: Value(row.pct),
            orderIndex: Value(row.orderIndex),
            isArchived: Value(row.isArchived),
          ),
        );
      }
    });
  }

  /// Theo dõi hũ đang dùng.
  ///
  /// Gia đình chưa có hàng nào trong bảng (dữ liệu tạo trước v5) thì trả về ba
  /// hũ mặc định, **không** trả danh sách rỗng: màn chia xu rỗng thì con không
  /// chia được xu đi đâu cả.
  Stream<List<JarDef>> watchActiveJars(String familyId, {String? memberId}) {
    // Không lọc trong SQL theo "bé có bộ riêng chưa": câu trả lời đổi khi bé
    // được tách bộ, và một `where` cố định thì stream không biết mà phát lại.
    // Lấy cả nhà rồi chọn ở Dart — vài chục hàng, không đáng tối ưu.
    return (select(jars)
          ..where((j) => j.familyId.equals(familyId) & j.isArchived.not())
          ..orderBy([(j) => OrderingTerm(expression: j.orderIndex)]))
        .watch()
        .map((rows) => _chonTheoChu(rows, memberId));
  }

  /// Chọn đúng bộ hũ của một chủ trong danh sách cả nhà.
  List<JarDef> _chonTheoChu(List<JarRow> rows, String? memberId) {
    final rieng = rows.where((r) => r.memberId == memberId).toList();
    if (rieng.isNotEmpty) return rieng.map(_toDef).toList();

    // Bé chưa có bộ riêng thì dùng bộ chung.
    final chung = rows.where((r) => r.memberId == null).toList();
    if (chung.isNotEmpty) return chung.map(_toDef).toList();

    // Nhà tạo trước v5 chưa có hàng nào: trả ba hũ mặc định chứ **không** trả
    // rỗng — màn chia xu rỗng thì con không chia được xu đi đâu cả.
    return kDefaultJars;
  }

  /// Cả hũ đã xếp lại — dùng ở màn quản lý hũ.
  Stream<List<({JarDef jar, bool archived})>> watchAllJars(
    String familyId, {
    String? memberId,
  }) {
    return (select(jars)
          ..where((j) => j.familyId.equals(familyId))
          ..orderBy([(j) => OrderingTerm(expression: j.orderIndex)]))
        .watch()
        .map((rows) {
          final rieng = rows.where((r) => r.memberId == memberId).toList();
          final chon = rieng.isNotEmpty
              ? rieng
              : rows.where((r) => r.memberId == null).toList();
          return [
            for (final row in chon)
              (jar: _toDef(row), archived: row.isArchived),
          ];
        });
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
    String? memberId,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw const JarException('Hũ phải có tên');
    }

    // Hũ riêng cho một bé: tách bộ trước, để hũ mới đứng cạnh **bản sao** của
    // các hũ chung chứ không đứng một mình. Không tách thì bé đó có đúng một
    // hũ với tỷ lệ N%, còn 100−N% không có chỗ nào chứa.
    if (memberId != null) {
      await tachBoRieng(familyId: familyId, memberId: memberId);
    }

    final all =
        await (select(jars)..where(
              (j) => memberId == null
                  ? j.familyId.equals(familyId) & j.memberId.isNull()
                  : j.memberId.equals(memberId),
            ))
            .get();
    final jarKey = 'jar${DateTime.now().microsecondsSinceEpoch}';
    final nextOrder = all.fold(
      0,
      (max, j) => j.orderIndex >= max ? j.orderIndex + 1 : max,
    );

    await into(jars).insert(
      JarsCompanion.insert(
        id: '${memberId ?? familyId}:$jarKey',
        familyId: familyId,
        memberId: Value(memberId),
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
    String? memberId,
  }) async {
    if (title != null && title.trim().isEmpty) {
      throw const JarException('Hũ phải có tên');
    }
    if (pct != null && (pct < 0 || pct > 100)) {
      throw const JarException('Tỷ lệ phải trong khoảng 0–100%');
    }

    // Lọc cả `member_id`: sau v9, cùng một `jar_key` tồn tại ở bộ chung **và**
    // ở bản sao của từng bé. Thiếu vế này thì sửa tỷ lệ hũ của Neo cũng sửa
    // luôn hũ cùng tên của Simba và của cả nhà.
    await (update(jars)..where(
          (j) => _thuocVe(j, familyId, memberId) & j.jarKey.equals(jarKey),
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
    String? memberId,
  }) async {
    if (archived && jarKey == kJarSpend) {
      throw const JarException(
        'Không xếp lại hũ Tiêu được: phần thưởng trừ xu từ hũ này',
      );
    }
    if (archived) {
      final remaining = await activeJars(familyId, memberId: memberId);
      if (remaining.length <= 1) {
        throw const JarException('Phải còn ít nhất một hũ');
      }
    }

    await (update(jars)..where(
          (j) => _thuocVe(j, familyId, memberId) & j.jarKey.equals(jarKey),
        ))
        .write(JarsCompanion(isArchived: Value(archived)));
  }

  /// Ghi lại thứ tự theo danh sách khoá truyền vào.
  Future<void> reorder({
    required String familyId,
    required List<String> jarKeys,
    String? memberId,
  }) async {
    await batch((b) {
      for (var i = 0; i < jarKeys.length; i++) {
        b.update(
          jars,
          JarsCompanion(orderIndex: Value(i)),
          where: (j) =>
              _thuocVe(j, familyId, memberId) & j.jarKey.equals(jarKeys[i]),
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
