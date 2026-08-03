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
}

@Riverpod(keepAlive: true)
class Session extends _$Session {
  @override
  AppSession? build() => null;

  // ignore: use_setters_to_change_properties, kept as method for call-site clarity
  void login(AppSession session) => state = session;

  void switchMember(String memberId, {required bool isParent}) {
    final current = state;
    if (current == null) return;
    state = AppSession(
      familyId: current.familyId,
      activeMemberId: memberId,
      isParent: isParent,
    );
  }

  void logout() => state = null;
}
