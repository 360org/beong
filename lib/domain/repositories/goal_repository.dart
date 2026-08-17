// Tầng repository — xem `README.md` cùng thư mục để biết vì sao có tầng này và
// vì sao mặt cắt của nó chỉ bằng thứ `lib/features` thật sự dùng.

import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/goal_dao.dart';

// Kiểu dữ liệu tầng UI nhận về từ các phương thức dưới đây. Xuất lại từ đây để
// `lib/features` chỉ import một chỗ, và để ràng buộc "features không import
// lib/data" giữ được (`test/unit/kien_truc_test.dart`).
export 'package:beong/data/local/database.dart' show SavingsGoal;

/// Mục tiêu để dành của trẻ.
abstract interface class GoalRepository {
  Future<void> abandonActive(String memberId);
  Future<SavingsGoal?> activeGoal(String memberId);
  Stream<SavingsGoal?> watchActiveGoal(String memberId);
  Future<SavingsGoal> setGoal({
    required String familyId,
    required String memberId,
    required String title,
    required int targetXu,
    String? iconKey,
    String? imagePath,
  });
}

/// Bản chạy trên máy: đọc ghi thẳng SQLite qua [GoalDao].
///
/// Sprint 3 sẽ có bản thứ hai đứng cạnh bản này, và **chỉ chỗ đó** phải quyết
/// định đọc local hay đọc máy chủ. Tầng UI không đổi một dòng nào.
final class LocalGoalRepository implements GoalRepository {
  const LocalGoalRepository(this._dao);

  final GoalDao _dao;

  @override
  Future<void> abandonActive(String memberId) => _dao.abandonActive(memberId);

  @override
  Future<SavingsGoal?> activeGoal(String memberId) => _dao.activeGoal(memberId);

  @override
  Stream<SavingsGoal?> watchActiveGoal(String memberId) =>
      _dao.watchActiveGoal(memberId);

  @override
  Future<SavingsGoal> setGoal({
    required String familyId,
    required String memberId,
    required String title,
    required int targetXu,
    String? iconKey,
    String? imagePath,
  }) => _dao.setGoal(
    familyId: familyId,
    memberId: memberId,
    title: title,
    targetXu: targetXu,
    iconKey: iconKey,
    imagePath: imagePath,
  );
}
