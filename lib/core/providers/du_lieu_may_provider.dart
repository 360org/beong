import 'package:beong/core/providers/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'du_lieu_may_provider.g.dart';

/// Máy này đã có gia đình nào chưa.
///
/// Router phải trả lời câu này **đồng bộ**, ngay trước khung hình đầu, nên
/// không dùng được `FutureProvider`: giá trị nạp một lần lúc khởi động
/// (`main.dart`) rồi cập nhật tại đúng hai chỗ làm nó đổi — tạo nhà xong, và
/// mỗi lần vào lại màn chọn người dùng.
///
/// Vì sao cần: trước đây `session == null` bị hiểu là *"máy chưa có gì"*, nên
/// bấm KHOÁ LẠI là rơi vào onboarding và tạo ra gia đình thứ hai — dữ liệu cũ
/// còn nguyên trong máy mà không màn hình nào mở tới được
/// (`docs/13-audit-luong-vao-app.md` §2).
@Riverpod(keepAlive: true)
class MayDaCoDuLieu extends _$MayDaCoDuLieu {
  @override
  bool build() => false;

  /// Đọc lại từ DB. Gọi lúc khởi động và sau khi tạo nhà.
  Future<void> nap() async {
    final families = await ref.read(memberRepositoryProvider).allFamilies();
    state = families.isNotEmpty;
  }

  /// Đánh dấu ngay không cần đọc lại DB — dùng sau khi onboarding vừa tạo nhà.
  void danhDauDaCo() => state = true;
}
