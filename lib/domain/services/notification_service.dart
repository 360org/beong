import 'package:beong/domain/entities/enums.dart';

/// Dữ liệu một thông báo trong hệ thống.
class BeOngNotification {
  const BeOngNotification({
    required this.id,
    required this.memberId,
    required this.recipientRole,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.scheduledFor,
  });

  final String id;
  final String memberId;
  final MemberKind recipientRole; // parent | child
  final String title;
  final String body;
  final String category; // routine_reminder | task_deadline | approval_needed | streak_warning | summary
  final DateTime createdAt;
  final DateTime? scheduledFor;
}

/// Dịch vụ điều phối và lọc thông báo theo nguyên tắc "Nhắc nhẹ, không cằn nhằn".
///
/// Tuân thủ quy định tại `docs/01-product-spec.md` §4.7:
/// - Tối đa 2 thông báo/ngày cho trẻ.
/// - Không gửi sau giờ đi ngủ đã đặt (mặc định 21:00).
/// - Gộp các thông báo chờ duyệt cho phụ huynh (tối đa 1 lần/giờ).
class NotificationService {
  NotificationService({this.bedtimeHour = 21});

  final int bedtimeHour;

  /// Đếm số thông báo đã gửi cho trẻ trong ngày.
  final Map<String, List<DateTime>> _childDailySentLog = {};

  /// Ghi nhận thời điểm gửi duyệt gần nhất cho phụ huynh.
  final Map<String, DateTime> _parentLastApprovalSent = {};

  /// Kiểm tra xem thông báo có được phép gửi đi hay không.
  bool shouldSend(BeOngNotification notification, {DateTime? now}) {
    final current = now ?? DateTime.now();

    // 1. Kiểm tra giờ đi ngủ (không gửi sau bedtimeHour cho trẻ)
    if (notification.recipientRole == MemberKind.child) {
      if (current.hour >= bedtimeHour || current.hour < 6) {
        return false;
      }

      // 2. Giới hạn tối đa 2 thông báo/ngày cho trẻ
      final timestamps = _childDailySentLog[notification.memberId] ?? [];
      final todaySent = timestamps.where((t) =>
          t.year == current.year &&
          t.month == current.month &&
          t.day == current.day).toList();

      if (todaySent.length >= 2) {
        return false;
      }
    }

    // 3. Gộp thông báo duyệt cho phụ huynh (tối đa 1 lần/giờ)
    if (notification.recipientRole == MemberKind.parent &&
        notification.category == 'approval_needed') {
      final lastSent = _parentLastApprovalSent[notification.memberId];
      if (lastSent != null && current.difference(lastSent).inMinutes < 60) {
        return false;
      }
    }

    return true;
  }

  /// Ghi nhận thông báo đã được gửi thành công.
  void recordSent(BeOngNotification notification, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (notification.recipientRole == MemberKind.child) {
      _childDailySentLog
          .putIfAbsent(notification.memberId, () => [])
          .add(current);
    } else if (notification.recipientRole == MemberKind.parent &&
        notification.category == 'approval_needed') {
      _parentLastApprovalSent[notification.memberId] = current;
    }
  }
}
