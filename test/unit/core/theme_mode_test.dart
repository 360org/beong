import 'package:beong/core/providers/database_provider.dart';
import 'package:beong/core/providers/theme_mode_provider.dart';
import 'package:beong/data/local/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chế độ giao diện lưu trong `device_settings`.
void main() {
  test('giá trị lạ hoặc chưa lưu đều về theo hệ thống', () {
    // Khoá này nằm trong file DB người dùng chạm được. Ném exception ở đây là
    // app không mở được vì một chuỗi rác.
    expect(decodeThemeMode(null), ThemeMode.system);
    expect(decodeThemeMode(''), ThemeMode.system);
    expect(decodeThemeMode('tối thui'), ThemeMode.system);
    expect(decodeThemeMode('light'), ThemeMode.light);
    expect(decodeThemeMode('dark'), ThemeMode.dark);
    expect(decodeThemeMode('system'), ThemeMode.system);
  });

  test('tên tiếng Việt cho đủ ba chế độ', () {
    for (final mode in ThemeMode.values) {
      expect(tenCheDoGiaoDien(mode), isNotEmpty);
    }
    expect(tenCheDoGiaoDien(ThemeMode.dark), 'Tối');
  });

  group('lưu và nạp lại', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.memory();
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('mặc định là theo hệ thống', () {
      expect(container.read(themeModeSettingProvider), ThemeMode.system);
    });

    test('đặt rồi thì lần mở sau vẫn nhớ', () async {
      await container
          .read(themeModeSettingProvider.notifier)
          .set(ThemeMode.dark);
      expect(container.read(themeModeSettingProvider), ThemeMode.dark);

      // Container mới = lần mở app sau, cùng file DB.
      final next = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(next.dispose);

      expect(
        next.read(themeModeSettingProvider),
        ThemeMode.system,
        reason: 'trước khi restore thì chưa biết gì',
      );
      await next.read(themeModeSettingProvider.notifier).restore();
      expect(next.read(themeModeSettingProvider), ThemeMode.dark);
    });
  });
}
