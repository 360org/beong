import 'package:beong/domain/entities/enums.dart';
import 'package:beong/domain/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late NotificationService service;

  setUp(() {
    service = NotificationService(bedtimeHour: 21);
  });

  group('NotificationService Policy Tests', () {
    test('Trẻ chỉ nhận tối đa 2 thông báo trong một ngày', () {
      final notif1 = BeOngNotification(
        id: 'n-1',
        memberId: 'child-1',
        recipientRole: MemberKind.child,
        title: 'Nhắc việc',
        body: 'Đến giờ đọc sách rồi!',
        category: 'routine_reminder',
        createdAt: DateTime(2026, 8, 23, 8, 0),
      );

      final notif2 = BeOngNotification(
        id: 'n-2',
        memberId: 'child-1',
        recipientRole: MemberKind.child,
        title: 'Sắp hết hạn',
        body: 'Nhiệm vụ sắp hết hạn nè bé!',
        category: 'task_deadline',
        createdAt: DateTime(2026, 8, 23, 14, 0),
      );

      final notif3 = BeOngNotification(
        id: 'n-3',
        memberId: 'child-1',
        recipientRole: MemberKind.child,
        title: 'Nhắc nhở thêm',
        body: 'Làm bài tập nhé',
        category: 'routine_reminder',
        createdAt: DateTime(2026, 8, 23, 16, 0),
      );

      final time1 = DateTime(2026, 8, 23, 8, 0);
      expect(service.shouldSend(notif1, now: time1), isTrue);
      service.recordSent(notif1, now: time1);

      final time2 = DateTime(2026, 8, 23, 14, 0);
      expect(service.shouldSend(notif2, now: time2), isTrue);
      service.recordSent(notif2, now: time2);

      final time3 = DateTime(2026, 8, 23, 16, 0);
      expect(service.shouldSend(notif3, now: time3), isFalse);
    });

    test('Chặn gửi thông báo cho trẻ sau giờ đi ngủ', () {
      final nightNotif = BeOngNotification(
        id: 'n-night',
        memberId: 'child-1',
        recipientRole: MemberKind.child,
        title: 'Nhắc việc',
        body: 'Làm việc nhé!',
        category: 'routine_reminder',
        createdAt: DateTime(2026, 8, 23, 21, 30),
      );

      final lateTime = DateTime(2026, 8, 23, 21, 30);
      expect(service.shouldSend(nightNotif, now: lateTime), isFalse);
    });

    test('Phụ huynh gộp thông báo duyệt tối đa 1 lần mỗi giờ', () {
      final parentNotif1 = BeOngNotification(
        id: 'p-1',
        memberId: 'parent-1',
        recipientRole: MemberKind.parent,
        title: 'Có việc cần duyệt',
        body: 'Bé vừa làm xong việc!',
        category: 'approval_needed',
        createdAt: DateTime(2026, 8, 23, 10, 0),
      );

      final parentNotif2 = BeOngNotification(
        id: 'p-2',
        memberId: 'parent-1',
        recipientRole: MemberKind.parent,
        title: 'Có việc cần duyệt',
        body: 'Bé làm thêm 1 việc nữa!',
        category: 'approval_needed',
        createdAt: DateTime(2026, 8, 23, 10, 20),
      );

      final time1 = DateTime(2026, 8, 23, 10, 0);
      expect(service.shouldSend(parentNotif1, now: time1), isTrue);
      service.recordSent(parentNotif1, now: time1);

      // Cách 20 phút -> chặn gửi
      final time2 = DateTime(2026, 8, 23, 10, 20);
      expect(service.shouldSend(parentNotif2, now: time2), isFalse);

      // Cách 65 phút -> cho phép gửi
      final time3 = DateTime(2026, 8, 23, 11, 5);
      expect(service.shouldSend(parentNotif2, now: time3), isTrue);
    });
  });
}
