// Tầng repository — xem `README.md` cùng thư mục để biết vì sao có tầng này và
// vì sao mặt cắt của nó chỉ bằng thứ `lib/features` thật sự dùng.

import 'package:beong/data/local/jar_dao.dart';
import 'package:beong/domain/entities/jar_def.dart';

// Kiểu dữ liệu tầng UI cần cùng với các phương thức dưới đây. Xuất lại từ đây để
// `lib/features` chỉ phải import một chỗ, và để ràng buộc "features không import
// lib/data" giữ được.
export 'package:beong/data/local/jar_dao.dart' show JarException;

/// Các hũ của gia đình — ADR-024, số hũ không cố định ba.
abstract interface class JarRepository {
  /// [memberId] `null` = bộ hũ chung của nhà. Truyền id một bé để đọc/ghi bộ
  /// riêng của bé đó; bé chưa có bộ riêng thì đọc ra bộ chung.
  Future<List<JarDef>> activeJars(String familyId, {String? memberId});
  Future<JarDef> addJar({
    required String familyId,
    required String title,
    required String emoji,
    int pct = 0,
    String? memberId,
  });
  Future<bool> coHuRieng(String memberId);
  Future<void> seedDefaults(String familyId);
  Future<void> setArchived({
    required String familyId,
    required String jarKey,
    required bool archived,
    String? memberId,
  });
  Future<void> tachBoRieng({
    required String familyId,
    required String memberId,
  });
  Future<void> updateJar({
    required String familyId,
    required String jarKey,
    String? title,
    String? emoji,
    int? pct,
    String? memberId,
  });
  Stream<List<JarDef>> watchActiveJars(String familyId, {String? memberId});
  Stream<List<({JarDef jar, bool archived})>> watchAllJars(
    String familyId, {
    String? memberId,
  });
}

/// Bản chạy trên máy: đọc ghi thẳng SQLite qua [JarDao].
///
/// Sprint 3 sẽ có bản thứ hai đứng cạnh bản này, và **chỉ chỗ đó** phải quyết
/// định đọc local hay đọc máy chủ. Tầng UI không đổi một dòng nào.
final class LocalJarRepository implements JarRepository {
  const LocalJarRepository(this._dao);

  final JarDao _dao;

  @override
  Future<List<JarDef>> activeJars(String familyId, {String? memberId}) =>
      _dao.activeJars(familyId, memberId: memberId);

  @override
  Future<JarDef> addJar({
    required String familyId,
    required String title,
    required String emoji,
    int pct = 0,
    String? memberId,
  }) => _dao.addJar(
    familyId: familyId,
    title: title,
    emoji: emoji,
    pct: pct,
    memberId: memberId,
  );

  @override
  Future<bool> coHuRieng(String memberId) => _dao.coHuRieng(memberId);

  @override
  Future<void> seedDefaults(String familyId) => _dao.seedDefaults(familyId);

  @override
  Future<void> setArchived({
    required String familyId,
    required String jarKey,
    required bool archived,
    String? memberId,
  }) => _dao.setArchived(
    familyId: familyId,
    jarKey: jarKey,
    archived: archived,
    memberId: memberId,
  );

  @override
  Future<void> tachBoRieng({
    required String familyId,
    required String memberId,
  }) => _dao.tachBoRieng(familyId: familyId, memberId: memberId);

  @override
  Future<void> updateJar({
    required String familyId,
    required String jarKey,
    String? title,
    String? emoji,
    int? pct,
    String? memberId,
  }) => _dao.updateJar(
    familyId: familyId,
    jarKey: jarKey,
    title: title,
    emoji: emoji,
    pct: pct,
    memberId: memberId,
  );

  @override
  Stream<List<JarDef>> watchActiveJars(String familyId, {String? memberId}) =>
      _dao.watchActiveJars(familyId, memberId: memberId);

  @override
  Stream<List<({JarDef jar, bool archived})>> watchAllJars(
    String familyId, {
    String? memberId,
  }) => _dao.watchAllJars(familyId, memberId: memberId);
}
