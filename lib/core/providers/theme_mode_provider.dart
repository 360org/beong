import 'package:beong/core/providers/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

/// Khoá lưu chế độ giao diện trong `device_settings`.
///
/// Nằm ở `device_settings` chứ không ở bảng gia đình: sáng/tối là chuyện của
/// **cái máy** này. Máy bố để tối, máy con để sáng, không việc gì phải giống
/// nhau — và cũng không nên đồng bộ qua server rồi đổi giao diện máy người khác.
const kThemeModeKey = 'theme_mode';

/// Đọc tên chế độ đã lưu. Giá trị lạ hoặc chưa lưu đều về [ThemeMode.system].
///
/// Không dùng `ThemeMode.values.byName` trần: khoá này nằm trong một file DB
/// người dùng có thể sửa, và ném exception lúc khởi động vì một chuỗi rác thì
/// app không mở được.
ThemeMode decodeThemeMode(String? raw) {
  for (final mode in ThemeMode.values) {
    if (mode.name == raw) return mode;
  }
  return ThemeMode.system;
}

/// Chế độ giao diện: theo hệ thống / sáng / tối.
@Riverpod(keepAlive: true)
class ThemeModeSetting extends _$ThemeModeSetting {
  /// Mặc định theo hệ thống. Giá trị đã lưu được nạp bằng [restore] **trước**
  /// `runApp` (xem `main.dart`) để khung hình đầu đã đúng màu — nạp sau thì
  /// người dùng để máy chế độ tối sẽ thấy màn hình trắng loé lên một nhịp.
  @override
  ThemeMode build() => ThemeMode.system;

  Future<void> restore() async {
    state = decodeThemeMode(
      await ref.read(settingsDaoProvider).read(kThemeModeKey),
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsDaoProvider).write(kThemeModeKey, mode.name);
  }
}

/// Tên tiếng Việt của từng chế độ, dùng chung cho ô Cài đặt và sheet chọn.
String tenCheDoGiaoDien(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Theo hệ thống',
  ThemeMode.light => 'Sáng',
  ThemeMode.dark => 'Tối',
};
