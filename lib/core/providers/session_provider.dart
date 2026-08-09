import 'dart:async';

import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/data/local/session_store.dart';
import 'package:beong/data/local/settings_dao.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_provider.g.dart';

@immutable
class AppSession {
  const AppSession({
    required this.familyId,
    required this.activeMemberId,
    this.isParent = true,
  });

  final String familyId;
  final String activeMemberId;
  final bool isParent;

  @override
  bool operator ==(Object other) =>
      other is AppSession &&
      other.familyId == familyId &&
      other.activeMemberId == activeMemberId &&
      other.isParent == isParent;

  @override
  int get hashCode => Object.hash(familyId, activeMemberId, isParent);
}

@Riverpod(keepAlive: true)
SettingsDao settingsDao(Ref ref) => SettingsDao(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
SessionStore sessionStore(Ref ref) =>
    SessionStore(ref.watch(settingsDaoProvider));

@Riverpod(keepAlive: true)
class Session extends _$Session {
  @override
  AppSession? build() => null;

  SessionStore get _store => ref.read(sessionStoreProvider);

  /// Nạp lại session đã lưu ở lần mở app trước.
  ///
  /// Không ghi lại xuống DB: giá trị vừa đọc *từ* DB nên ghi lại là vô ích.
  /// Gọi trước `runApp` (xem `main.dart`) để khung hình đầu đã có đúng vai —
  /// nếu gọi sau, router kịp đẩy về onboarding rồi mới quay lại, người dùng
  /// thấy màn hình nhảy.
  // ignore: use_setters_to_change_properties, giữ dạng method cho rõ ở chỗ gọi
  void restore(AppSession session) => state = session;

  Future<void> login(AppSession session) async {
    state = session;
    await _store.save(session);
  }

  Future<void> switchMember(
    String memberId, {
    required bool isParent,
  }) async {
    final current = state;
    if (current == null) return;
    final next = AppSession(
      familyId: current.familyId,
      activeMemberId: memberId,
      isParent: isParent,
    );
    state = next;
    await _store.save(next);
  }

  Future<void> logout() async {
    state = null;
    await _store.clear();
  }
}
