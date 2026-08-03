import 'package:beong/data/seed/presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('có đúng 24 preset task', () {
    expect(kTaskPresets.length, 24);
  });

  test('key preset không trùng', () {
    final keys = kTaskPresets.map((p) => p.key).toSet();
    expect(keys.length, kTaskPresets.length);
  });

  test('có đúng 3 routine dựng sẵn', () {
    expect(kRoutinePresets.length, 3);
  });

  test('mỗi task trong routine đều có trong preset', () {
    for (final routine in kRoutinePresets) {
      for (final key in routine.taskKeys) {
        expect(
          presetByKey(key),
          isNotNull,
          reason:
              'Routine "${routine.key}" cần preset "$key" nhưng không tìm thấy',
        );
      }
    }
  });

  test('preset có điểm hợp lệ (5-500)', () {
    for (final p in kTaskPresets) {
      expect(
        p.defaultPoints,
        allOf(greaterThanOrEqualTo(5), lessThanOrEqualTo(500)),
        reason: 'Preset "${p.key}" có ${p.defaultPoints} điểm',
      );
    }
  });

  test('presetByKey trả đúng hoặc null', () {
    expect(presetByKey('brush_teeth_morning'), isNotNull);
    expect(presetByKey('brush_teeth_morning')!.titleVi, 'Đánh răng buổi sáng');
    expect(presetByKey('khong_ton_tai'), isNull);
  });
}
