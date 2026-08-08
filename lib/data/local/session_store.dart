import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/data/local/settings_dao.dart';

/// Lưu và đọc lại session của **thiết bị này**.
///
/// Session không phải dữ liệu gia đình: nó chỉ trả lời "máy này đang mở hồ sơ
/// nào, với vai gì". Vì vậy nó nằm ở `device_settings` local, không đồng bộ lên
/// server (ADR-021 — cấu hình gia đình mới thuộc tài khoản bố mẹ).
///
/// Vai lưu ở đây **không cấp quyền** (ADR-018): nó chỉ quyết định mở màn hình
/// nào. Khi có backend, quyền suy ra từ credential.
class SessionStore {
  const SessionStore(this._settings);

  final SettingsDao _settings;

  static const _keyFamilyId = 'session.family_id';
  static const _keyMemberId = 'session.active_member_id';
  static const _keyIsParent = 'session.is_parent';

  static const Set<String> _allKeys = {
    _keyFamilyId,
    _keyMemberId,
    _keyIsParent,
  };

  /// Session đã lưu, hoặc `null` nếu máy chưa từng đăng nhập.
  ///
  /// Thiếu bất kỳ khoá nào cũng coi như **chưa có session**: một session nửa
  /// vời (có gia đình, không có thành viên) sẽ làm router dựng màn hình trống
  /// thay vì đưa về onboarding.
  Future<AppSession?> load() async {
    final values = await _settings.readAll(_allKeys);

    final familyId = values[_keyFamilyId];
    final memberId = values[_keyMemberId];
    if (familyId == null || familyId.isEmpty) return null;
    if (memberId == null || memberId.isEmpty) return null;

    return AppSession(
      familyId: familyId,
      activeMemberId: memberId,
      // Thiếu cờ vai thì mặc định là con — vai hẹp hơn. Đoán sai theo hướng
      // rộng hơn sẽ mở màn hình bố mẹ cho bé.
      isParent: values[_keyIsParent] == 'true',
    );
  }

  Future<void> save(AppSession session) async {
    await _settings.writeAll({
      _keyFamilyId: session.familyId,
      _keyMemberId: session.activeMemberId,
      _keyIsParent: session.isParent.toString(),
    });
  }

  Future<void> clear() => _settings.remove(_allKeys);
}
