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
  Future<List<JarDef>> activeJars(String familyId);
  Future<JarDef> addJar({
    required String familyId,
    required String title,
    required String emoji,
    int pct = 0,
  });
  Future<void> seedDefaults(String familyId);
  Future<void> setArchived({
    required String familyId,
    required String jarKey,
    required bool archived,
  });
  Future<void> updateJar({
    required String familyId,
    required String jarKey,
    String? title,
    String? emoji,
    int? pct,
  });
  Stream<List<JarDef>> watchActiveJars(String familyId);
  Stream<List<({JarDef jar, bool archived})>> watchAllJars(String familyId);
}

/// Bản chạy trên máy: đọc ghi thẳng SQLite qua [JarDao].
///
/// Sprint 3 sẽ có bản thứ hai đứng cạnh bản này, và **chỉ chỗ đó** phải quyết
/// định đọc local hay đọc máy chủ. Tầng UI không đổi một dòng nào.
final class LocalJarRepository implements JarRepository {
  const LocalJarRepository(this._dao);

  final JarDao _dao;

  @override
  Future<List<JarDef>> activeJars(String familyId) => _dao.activeJars(familyId);

  @override
  Future<JarDef> addJar({
    required String familyId,
    required String title,
    required String emoji,
    int pct = 0,
  }) => _dao.addJar(familyId: familyId, title: title, emoji: emoji, pct: pct);

  @override
  Future<void> seedDefaults(String familyId) => _dao.seedDefaults(familyId);

  @override
  Future<void> setArchived({
    required String familyId,
    required String jarKey,
    required bool archived,
  }) =>
      _dao.setArchived(familyId: familyId, jarKey: jarKey, archived: archived);

  @override
  Future<void> updateJar({
    required String familyId,
    required String jarKey,
    String? title,
    String? emoji,
    int? pct,
  }) => _dao.updateJar(
    familyId: familyId,
    jarKey: jarKey,
    title: title,
    emoji: emoji,
    pct: pct,
  );

  @override
  Stream<List<JarDef>> watchActiveJars(String familyId) =>
      _dao.watchActiveJars(familyId);

  @override
  Stream<List<({JarDef jar, bool archived})>> watchAllJars(String familyId) =>
      _dao.watchAllJars(familyId);
}
