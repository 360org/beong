import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bundle ID / application ID phải giữ nguyên `net.beong.app` — ADR-026.
///
/// Không đổi được sau khi phát hành: cả hai store coi ID này là danh tính vĩnh
/// viễn của app, đổi nghĩa là một app khác, mất hết người dùng và đánh giá.
///
/// Test này tồn tại vì giá trị đó nằm rải ở **7 file thuộc 4 nền tảng**, và một
/// lần `flutter create` lại hay một lần sửa Xcode là đủ để một chỗ lệch đi. Lệch
/// thì build vẫn xanh và chỉ chết ở bước upload với "App not found" — thông báo
/// không nói gì về nguyên nhân. Rẻ hơn nhiều nếu chặn ở đây.
void main() {
  const bundleId = 'net.beong.app';

  /// Bỏ qua khi chạy ở thư mục khác gốc repo (một số IDE làm vậy).
  String? read(String path) {
    final file = File(path);
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  test('Android khai đúng namespace và applicationId', () {
    final gradle = read('android/app/build.gradle.kts');
    if (gradle == null) return;

    expect(gradle, contains('namespace = "$bundleId"'));
    expect(gradle, contains('applicationId = "$bundleId"'));
  });

  test('package của MainActivity khớp bundle ID', () {
    // Thư mục Kotlin phải khớp `package`, nếu không Android không tìm thấy
    // Activity lúc chạy — mà lỗi hiện ra là "ClassNotFoundException", không nói
    // gì tới tên gói.
    final path =
        'android/app/src/main/kotlin/${bundleId.replaceAll('.', '/')}/MainActivity.kt';
    final source = read(path);
    if (source == null) {
      fail('Không thấy $path — thư mục package không còn khớp $bundleId');
    }
    expect(source, contains('package $bundleId'));
  });

  test('iOS và macOS khai đúng PRODUCT_BUNDLE_IDENTIFIER', () {
    for (final path in const [
      'ios/Runner.xcodeproj/project.pbxproj',
      'macos/Runner/Configs/AppInfo.xcconfig',
    ]) {
      final source = read(path);
      if (source == null) continue;
      expect(
        source,
        contains(bundleId),
        reason: '$path không còn khai $bundleId',
      );
    }
  });

  test('Fastlane hai nền tảng trỏ đúng app', () {
    // Sai chỗ này thì fastlane upload lên **app khác** của cùng tài khoản, hoặc
    // báo "App not found" tuỳ store.
    expect(
      read('ios/fastlane/Appfile'),
      contains('app_identifier("$bundleId")'),
    );
    expect(
      read('android/fastlane/Appfile'),
      contains('package_name("$bundleId")'),
    );
  });

  test('ExportOptions template dùng bundle ID làm khoá profile', () {
    final template = read('ios/ExportOptions.plist.template');
    if (template == null) return;

    // CI thay `__PROFILE_NAME__` theo khoá này. Khoá lệch bundle ID thì xcodebuild
    // báo "No profile matching" mà không in ra tên nó đang tìm.
    expect(template, contains('<key>$bundleId</key>'));
  });
}
