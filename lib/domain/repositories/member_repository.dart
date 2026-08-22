// Tầng repository — xem `README.md` cùng thư mục để biết vì sao có tầng này và
// vì sao mặt cắt của nó chỉ bằng thứ `lib/features` thật sự dùng.

import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/member_dao.dart';
import 'package:beong/domain/entities/jar_def.dart';
import 'package:beong/domain/services/money_exchange.dart';
import 'package:beong/domain/services/penalty_policy.dart';

// Kiểu dữ liệu tầng UI nhận về từ các phương thức dưới đây. Xuất lại từ đây để
// `lib/features` chỉ import một chỗ, và để ràng buộc "features không import
// lib/data" giữ được (`test/unit/kien_truc_test.dart`).
export 'package:beong/data/local/database.dart'
    show FamiliesCompanion, Family, Member, MembersCompanion, Streak;

/// Gia đình, thành viên, và các cấu hình chung của nhà.
///
/// Đây là repository đầu tiên sync đụng tới: hồ sơ con do bố mẹ tạo trên máy bố
/// mẹ rồi mới về máy con (`09-onboarding-pairing.md`), nên `watchMembers` sẽ là
/// chỗ đầu tiên phải trả lời "local hay máy chủ".
abstract interface class MemberRepository {
  Future<void> addMember(MembersCompanion member);
  Future<List<Family>> allFamilies();
  Future<List<Member>> children(String familyId);
  Future<void> createFamily(FamiliesCompanion family);
  Future<void> setAllocationMode(String familyId, AllocationMode mode);
  Future<void> setDayRolloverHour(String familyId, int hour);
  Future<void> setPenaltyPolicy(String familyId, PenaltyPolicy policy);
  Future<void> setRequireApproval(String familyId, {required bool value});
  Stream<AllocationMode> watchAllocationMode(String familyId);
  Stream<int> watchDayRolloverHour(String familyId);
  Stream<MoneyExchange> watchExchangeRate(String familyId);
  Stream<Family> watchFamily(String familyId);
  Stream<Member> watchMember(String memberId);
  Stream<List<Member>> watchMembers(String familyId);
  Stream<PenaltyPolicy> watchPenaltyPolicy(String familyId);
  Stream<bool> watchRequireApproval(String familyId);
  Stream<Streak?> watchStreak(String memberId);
  Future<void> setExchangeRate(String familyId, int? xuPerUnit);
}

/// Bản chạy trên máy: đọc ghi thẳng SQLite qua [MemberDao].
///
/// Sprint 3 sẽ có bản thứ hai đứng cạnh bản này, và **chỉ chỗ đó** phải quyết
/// định đọc local hay đọc máy chủ. Tầng UI không đổi một dòng nào.
final class LocalMemberRepository implements MemberRepository {
  const LocalMemberRepository(this._dao);

  final MemberDao _dao;

  @override
  Future<void> addMember(MembersCompanion member) => _dao.addMember(member);

  @override
  Future<List<Family>> allFamilies() => _dao.allFamilies();

  @override
  Future<List<Member>> children(String familyId) => _dao.children(familyId);

  @override
  Future<void> createFamily(FamiliesCompanion family) =>
      _dao.createFamily(family);

  @override
  Future<void> setAllocationMode(String familyId, AllocationMode mode) =>
      _dao.setAllocationMode(familyId, mode);

  @override
  Future<void> setDayRolloverHour(String familyId, int hour) =>
      _dao.setDayRolloverHour(familyId, hour);

  @override
  Future<void> setPenaltyPolicy(String familyId, PenaltyPolicy policy) =>
      _dao.setPenaltyPolicy(familyId, policy);

  @override
  Future<void> setRequireApproval(String familyId, {required bool value}) =>
      _dao.setRequireApproval(familyId, value: value);

  @override
  Stream<AllocationMode> watchAllocationMode(String familyId) =>
      _dao.watchAllocationMode(familyId);

  @override
  Stream<int> watchDayRolloverHour(String familyId) =>
      _dao.watchDayRolloverHour(familyId);

  @override
  Stream<MoneyExchange> watchExchangeRate(String familyId) =>
      _dao.watchExchangeRate(familyId);

  @override
  Stream<Family> watchFamily(String familyId) => _dao.watchFamily(familyId);

  @override
  Stream<Member> watchMember(String memberId) => _dao.watchMember(memberId);

  @override
  Stream<List<Member>> watchMembers(String familyId) =>
      _dao.watchMembers(familyId);

  @override
  Stream<PenaltyPolicy> watchPenaltyPolicy(String familyId) =>
      _dao.watchPenaltyPolicy(familyId);

  @override
  Stream<bool> watchRequireApproval(String familyId) =>
      _dao.watchRequireApproval(familyId);

  @override
  Stream<Streak?> watchStreak(String memberId) => _dao.watchStreak(memberId);

  @override
  Future<void> setExchangeRate(String familyId, int? xuPerUnit) =>
      _dao.setExchangeRate(familyId, xuPerUnit);
}
