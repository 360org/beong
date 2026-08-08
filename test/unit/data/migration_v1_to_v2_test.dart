import 'dart:io';

import 'package:beong/data/local/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// `docs/03-data-model.md` §6: mỗi lần tăng `schemaVersion` phải có test dựng DB
/// phiên bản cũ rồi migrate. Đây là test cho bước v1 → v2 (thêm
/// `device_settings`).
///
/// Cách dựng "DB phiên bản cũ": mở DB ở phiên bản hiện tại, **bỏ đúng thứ mà v2
/// thêm vào** rồi hạ `user_version` về 1. Không phải bản sao lịch sử hoàn hảo
/// của schema v1, nhưng nó kiểm đúng điều dễ sai nhất: máy đã cài bản cũ, có
/// dữ liệu thật, nâng cấp lên bản mới thì **không mất dữ liệu và không crash**.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('beong_migration_');
    dbFile = File(p.join(tempDir.path, 'beong.sqlite'));
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('nâng v1 lên v2 tạo device_settings và giữ nguyên dữ liệu cũ', () async {
    // --- Dựng một máy "đang chạy bản v1", có dữ liệu gia đình thật.
    final v1 = AppDatabase(NativeDatabase(dbFile));
    await v1
        .into(v1.families)
        .insert(FamiliesCompanion.insert(id: 'fam-1', name: 'Nhà mình'));
    await v1.customStatement('DROP TABLE device_settings');
    await v1.customStatement('PRAGMA user_version = 1');
    await v1.close();

    // --- Mở lại bằng bản hiện tại: drift phải chạy onUpgrade(1 -> 2).
    final v2 = AppDatabase(NativeDatabase(dbFile));
    addTearDown(v2.close);

    final version = await v2.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], 2, reason: 'đã nâng cấp');

    // Bảng mới dùng được ngay, không cần cài lại app.
    await v2
        .into(v2.deviceSettings)
        .insert(
          DeviceSettingsCompanion.insert(settingKey: 'k', settingValue: 'v'),
        );
    expect(await v2.select(v2.deviceSettings).get(), hasLength(1));

    // Và dữ liệu cũ vẫn còn — đây là điều thật sự phải bảo đảm.
    final families = await v2.select(v2.families).get();
    expect(families.single.name, 'Nhà mình');
  });
}
