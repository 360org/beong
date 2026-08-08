import 'package:beong/data/local/database.dart';
import 'package:beong/data/local/tables/tables.dart';
import 'package:drift/drift.dart';

part 'settings_dao.g.dart';

/// Đọc/ghi cấu hình của thiết bị này — xem [DeviceSettings].
@DriftAccessor(tables: [DeviceSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  /// Giá trị của [key], hoặc `null` nếu chưa từng ghi.
  Future<String?> read(String key) async {
    final row = await (select(
      deviceSettings,
    )..where((t) => t.settingKey.equals(key))).getSingleOrNull();
    return row?.settingValue;
  }

  /// Đọc nhiều khoá trong **một** truy vấn.
  ///
  /// Dùng ở lúc khởi động: mỗi truy vấn thêm là thêm độ trễ trước khung hình
  /// đầu, và session cần ba khoá cùng lúc.
  Future<Map<String, String>> readAll(Set<String> keys) async {
    if (keys.isEmpty) return const {};
    final rows = await (select(
      deviceSettings,
    )..where((t) => t.settingKey.isIn(keys))).get();
    return {for (final row in rows) row.settingKey: row.settingValue};
  }

  Future<void> write(String key, String value) async {
    await into(deviceSettings).insertOnConflictUpdate(
      DeviceSetting(settingKey: key, settingValue: value),
    );
  }

  Future<void> writeAll(Map<String, String> entries) async {
    // Một batch cho cả nhóm: session gồm ba khoá, ghi rời thì có khoảnh khắc
    // trên đĩa chỉ có một phần — mở app đúng lúc đó sẽ đọc ra session nửa vời.
    await batch((b) {
      for (final entry in entries.entries) {
        b.insert(
          deviceSettings,
          DeviceSetting(settingKey: entry.key, settingValue: entry.value),
          onConflict: DoUpdate<$DeviceSettingsTable, DeviceSetting>(
            (_) => DeviceSetting(
              settingKey: entry.key,
              settingValue: entry.value,
            ),
          ),
        );
      }
    });
  }

  Future<void> remove(Iterable<String> keys) async {
    await (delete(
      deviceSettings,
    )..where((t) => t.settingKey.isIn(keys.toList()))).go();
  }
}
