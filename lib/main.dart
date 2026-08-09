import 'package:beong/app/app.dart';
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
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BeOngApp(),
    ),
  );
}
