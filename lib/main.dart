import 'package:beong/app/app.dart';
import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Container dựng ở đây chứ không để `ProviderScope` tự tạo, để phần nạp lại
  // session dùng **đúng** connection DB mà app sẽ dùng sau đó. Nếu mở một DB
  // riêng chỉ để đọc session thì có hai connection tới cùng file SQLite.
  final container = ProviderContainer();

  // Nạp trước khung hình đầu: nếu để router chạy trước rồi mới nạp, người dùng
  // thấy màn hình onboarding nháy lên rồi mới về đúng chỗ.
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
      debugPrint('Không chạy được bộ sinh việc đầu ngày: $error\n$stack');
    }
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BeOngApp(),
    ),
  );
}
