import 'dart:io';

import 'package:beong/core/theme/app_theme.dart';
import 'package:beong/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Chỉ ba weight này được nhúng — xem `pubspec.yaml`.
const _embeddedWeights = {500, 700, 800};

void main() {
  group('font Nunito được nhúng và áp đúng', () {
    test('fontFamily đã bật (không còn để null như Sprint 0)', () {
      expect(AppTypography.fontFamily, 'Nunito');
    });

    test('mọi style trong textTheme đều mang font Nunito', () {
      final theme = AppTypography.textTheme(const Color(0xFF1B1046));
      final styles = <String, TextStyle?>{
        'displayLarge': theme.displayLarge,
        'titleLarge': theme.titleLarge,
        'titleMedium': theme.titleMedium,
        'bodyLarge': theme.bodyLarge,
        'bodyMedium': theme.bodyMedium,
        'labelLarge': theme.labelLarge,
        'bodySmall': theme.bodySmall,
      };
      for (final entry in styles.entries) {
        expect(entry.value?.fontFamily, 'Nunito', reason: entry.key);
      }
    });

    test('ThemeData sáng và tối đều dùng Nunito', () {
      // Đặt ở ThemeData để TextStyle viết tay trong widget cũng thừa hưởng.
      expect(AppTheme.light().textTheme.bodyLarge?.fontFamily, 'Nunito');
      expect(AppTheme.dark().textTheme.bodyLarge?.fontFamily, 'Nunito');
    });

    test('chỉ dùng weight đã nhúng file — tránh bị giả lập đậm/mảnh', () {
      final weights = <String, FontWeight?>{
        'displayL': AppTypography.displayL.fontWeight,
        'titleL': AppTypography.titleL.fontWeight,
        'titleM': AppTypography.titleM.fontWeight,
        'body': AppTypography.body.fontWeight,
        'label': AppTypography.label.fontWeight,
        'caption': AppTypography.caption.fontWeight,
      };
      for (final entry in weights.entries) {
        expect(
          _embeddedWeights,
          contains(entry.value?.value),
          reason:
              '${entry.key} dùng weight ${entry.value?.value}, '
              'chưa có file static tương ứng',
        );
      }
    });

    test('file font và giấy phép OFL có mặt trên đĩa', () {
      // Nunito là font OFL: phát hành kèm app thì phải kèm giấy phép.
      expect(File('assets/fonts/OFL.txt').existsSync(), isTrue);
      for (final name in ['Medium', 'Bold', 'ExtraBold']) {
        expect(
          File('assets/fonts/Nunito-$name.ttf').existsSync(),
          isTrue,
          reason: 'thiếu Nunito-$name.ttf',
        );
      }
    });

    test('pubspec khai báo đúng các weight đã sinh file', () {
      final pubspec =
          loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
      final families = (pubspec['flutter'] as YamlMap)['fonts'] as YamlList;
      final nunito = families.firstWhere(
        (f) => (f as YamlMap)['family'] == 'Nunito',
      );
      final declared = ((nunito as YamlMap)['fonts'] as YamlList)
          .map((f) => (f as YamlMap)['weight'] as int)
          .toSet();
      expect(declared, _embeddedWeights);
    });
  });
}
