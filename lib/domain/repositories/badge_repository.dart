// Tầng repository — xem `README.md` cùng thư mục để biết vì sao có tầng này và
// vì sao mặt cắt của nó chỉ bằng thứ `lib/features` thật sự dùng.

import 'package:beong/data/local/badge_dao.dart';
import 'package:beong/domain/entities/badge_def.dart';

/// Huy hiệu đã đạt và tiến độ tới các mốc chưa đạt.
abstract interface class BadgeRepository {
  Future<BadgeProgress> progressOf(String memberId);
  Stream<Set<String>> watchEarnedKeys(String memberId);
}

/// Bản chạy trên máy: đọc ghi thẳng SQLite qua [BadgeDao].
///
/// Sprint 3 sẽ có bản thứ hai đứng cạnh bản này, và **chỉ chỗ đó** phải quyết
/// định đọc local hay đọc máy chủ. Tầng UI không đổi một dòng nào.
final class LocalBadgeRepository implements BadgeRepository {
  const LocalBadgeRepository(this._dao);

  final BadgeDao _dao;

  @override
  Future<BadgeProgress> progressOf(String memberId) =>
      _dao.progressOf(memberId);

  @override
  Stream<Set<String>> watchEarnedKeys(String memberId) =>
      _dao.watchEarnedKeys(memberId);
}
