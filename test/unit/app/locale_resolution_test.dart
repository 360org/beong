import 'package:beong/app/app.dart';
import 'package:beong/core/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supported = L10n.supportedLocales;

  group('resolveAppLocale', () {
    test('máy đặt tiếng Việt thì dùng tiếng Việt', () {
      expect(
        resolveAppLocale(const [Locale('vi')], supported).languageCode,
        'vi',
      );
    });

    test('máy đặt tiếng Anh thì dùng tiếng Anh', () {
      expect(
        resolveAppLocale(const [Locale('en')], supported).languageCode,
        'en',
      );
    });

    test('ngôn ngữ không hỗ trợ rơi về tiếng Việt, không phải tiếng Anh', () {
      // Đây là lỗi thật đã gặp: máy đặt tiếng Nhật/Pháp mà app hiện tiếng Anh.
      expect(
        resolveAppLocale(const [Locale('ja')], supported).languageCode,
        'vi',
      );
      expect(
        resolveAppLocale(const [Locale('fr')], supported).languageCode,
        'vi',
      );
    });

    test('không biết ngôn ngữ máy thì về tiếng Việt', () {
      expect(resolveAppLocale(null, supported).languageCode, 'vi');
      expect(resolveAppLocale(const [], supported).languageCode, 'vi');
    });

    test('tôn trọng thứ tự ưu tiên người dùng đặt trên máy', () {
      // Người dùng đặt: Nhật (không hỗ trợ) > Anh > Việt → phải ra tiếng Anh.
      expect(
        resolveAppLocale(
          const [Locale('ja'), Locale('en'), Locale('vi')],
          supported,
        ).languageCode,
        'en',
      );
    });

    test('khớp theo mã ngôn ngữ, bỏ qua mã vùng', () {
      expect(
        resolveAppLocale(const [Locale('en', 'GB')], supported).languageCode,
        'en',
      );
      expect(
        resolveAppLocale(const [Locale('vi', 'VN')], supported).languageCode,
        'vi',
      );
    });

    test('locale mặc định phải nằm trong danh sách hỗ trợ', () {
      expect(
        supported.map((l) => l.languageCode),
        contains(kFallbackLocale.languageCode),
      );
    });
  });
}
