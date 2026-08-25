import 'package:beong/app/app.dart';
import 'package:beong/core/diagnostics/nhat_ky_loi.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/du_lieu_may_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:beong/core/providers/theme_mode_provider.dart';
import 'package:beong/core/services/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo dịch vụ push notification
  await PushNotificationService.instance.initialize();

  // Gắn **trước** mọi thứ khác: lỗi lúc mở DB hay lúc nạp session cũng phải vào
  // được nhật ký, và đó chính là loại lỗi khó tái tạo nhất.
  ganBatLoiToanCuc();

  // Container dựng ở đây chứ không để `ProviderScope` tự tạo, để phần nạp lại
  // session dùng **đúng** connection DB mà app sẽ dùng sau đó. Nếu mở một DB
  // riêng chỉ để đọc session thì có hai connection tới cùng file SQLite.
  final container = ProviderContainer();

  // Màu trước khung hình đầu: nạp sau `runApp` thì máy đang để chế độ tối sẽ
  // thấy một nhịp màn hình trắng.
  await container.read(themeModeSettingProvider.notifier).restore();

  // Máy này đã có gia đình nào chưa — router cần biết **trước** khung hình đầu
  // để phân biệt "máy trống" với "máy có dữ liệu, chưa chọn ai đang dùng".
  try {
    await container.read(mayDaCoDuLieuProvider.notifier).nap();
  } on Exception catch (error, stack) {
    nhatKyLoi.ghi(
      'Khởi động: Đọc danh sách gia đình thất bại: $error',
      stack: stack,
      nguon: 'startup',
    );
  }

  // Nạp trước khung hình đầu: nếu để router chạy trước rồi mới nạp, người dùng
  // thấy màn hình onboarding nháy lên rồi mới về đúng chỗ.
  try {
    final restored = await container.read(sessionStoreProvider).load();
    if (restored != null) {
      container.read(sessionProvider.notifier).restore(restored);

      // Sinh việc cho hôm nay **trước khung hình đầu** (`03-data-model.md` §3).
      // Không có bước này, bố mẹ mở app thấy "0 / 0 việc hôm nay" dù đã tạo
      // routine, và lượt quá hạn không bao giờ được đánh dấu bỏ lỡ.
      //
      // Lỗi ở đây không được chặn app khởi động: hỏng bộ lập lịch thì tệ, nhưng
      // không mở được app thì tệ hơn.
      try {
        await container
            .read(dayStartServiceProvider)
            .runIfNeeded(familyId: restored.familyId);
      } on Exception catch (error, stack) {
        nhatKyLoi.ghi(
          'Khởi động: Bộ sinh việc đầu ngày thất bại: $error',
          stack: stack,
          nguon: 'startup',
        );
        debugPrint('Không chạy được bộ sinh việc đầu ngày: $error\n$stack');
      }
    }
  } on Exception catch (error, stack) {
    nhatKyLoi.ghi(
      'Khởi động: Nạp session thất bại: $error',
      stack: stack,
      nguon: 'startup',
    );
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BeOngApp(),
    ),
  );
}
