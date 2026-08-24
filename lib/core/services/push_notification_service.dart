import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service quản lý Push Notification (FCM / Local Notification / Supabase trigger).
///
/// Hỗ trợ cả 2 chế độ:
/// 1. Local-first: Thông báo nội bộ máy (nhắc việc, streak).
/// 2. Remote FCM: Bắn thông báo giữa Bố Mẹ và Con qua Supabase Edge Function `notify-fcm`.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Khởi tạo và xin quyền thông báo
  Future<void> initialize() async {
    // ponytail: Tích hợp hook nền tảng. Khi build với firebase_messaging trên thiết bị thật,
    // token sẽ được đồng bộ tự động lên backend.
    debugPrint('🔔 [PushNotificationService] Initialized');
  }

  /// Gửi thông báo từ xa qua Supabase Edge Function `notify-fcm`
  Future<bool> sendRemoteNotification({
    required String supabaseUrl,
    required String supabaseAnonKey,
    required String familyId,
    required String title,
    required String body,
    String? targetRole, // 'parent' | 'child' | 'all'
    String? targetMemberId,
    Map<String, String>? data,
  }) async {
    try {
      final endpoint = Uri.parse('$supabaseUrl/functions/v1/notify-fcm');
      final payload = <String, dynamic>{
        'family_id': familyId,
        ...?targetRole != null ? {'target_role': targetRole} : null,
        ...?targetMemberId != null
            ? {'target_member_id': targetMemberId}
            : null,
        'title': title,
        'body': body,
        'data': data ?? <String, String>{},
      };

      final response = await http
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $supabaseAnonKey',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } on Exception catch (e) {
      debugPrint('❌ [PushNotificationService] Failed to send push: $e');
      return false;
    }
  }

  /// Đồng bộ token thiết bị lên Supabase Database
  Future<void> syncDeviceToken({
    required String supabaseUrl,
    required String supabaseAnonKey,
    required String familyId,
    required String memberId,
    required String token,
  }) async {
    _fcmToken = token;
    final platform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
            ? 'ios'
            : Platform.isMacOS
                ? 'macos'
                : 'web';

    try {
      final endpoint = Uri.parse('$supabaseUrl/rest/v1/device_tokens');
      await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
          'apikey': supabaseAnonKey,
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode({
          'family_id': familyId,
          'member_id': memberId,
          'fcm_token': token,
          'platform': platform,
          'device_name': Platform.localHostname,
        }),
      );
    } on Exception catch (e) {
      debugPrint('❌ [PushNotificationService] Failed to sync token: $e');
    }
  }
}
